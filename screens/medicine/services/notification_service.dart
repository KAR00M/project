import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io'; // لـ Platform.isAndroid

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static late tz.Location _appTimeZone;
  static bool _isInitialized = false;
  static const String _channelKey = 'medication_channel';
  static const int _welcomeNotificationId = 1001;
  static const int _repeatingNotificationId = 1002;

  static Future<void> initialize({String timeZone = 'Africa/Cairo'}) async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      _appTimeZone = tz.getLocation(timeZone);

      await _requestAllRequiredPermissions();
      await _setupNotificationChannels();
      _setNotificationListeners();

      _isInitialized = true;
      await _sendWelcomeNotification();
      await _scheduleRepeatingNotification();

      // إصلاح خاص لأجهزة شاومي
      if (Platform.isAndroid) {
        await _applyXiaomiFixes();
      }
    } catch (e) {
      debugPrint('فشل تهيئة خدمة الإشعارات: $e');
      rethrow;
    }
  }

  // الدالة المطلوبة لإعادة الجدولة
  Future<void> rescheduleNotifications() async {
    try {
      debugPrint('إعادة جدولة جميع الإشعارات...');
      await cancelAllNotifications();
      await _sendWelcomeNotification();
      await _scheduleRepeatingNotification();
      debugPrint('تمت إعادة الجدولة بنجاح');
    } catch (e) {
      debugPrint('فشل في إعادة الجدولة: $e');
    }
  }

  static Future<void> _applyXiaomiFixes() async {
    try {
      await [
        Permission.ignoreBatteryOptimizations,
        Permission.accessNotificationPolicy,
      ].request();

      debugPrint('تم تطبيق إصلاحات شاومي');
    } catch (e) {
      debugPrint('فشل تطبيق إصلاحات شاومي: $e');
    }
  }

  static Future<bool> _requestAllRequiredPermissions() async {
    try {
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
      }

      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }

      return isAllowed;
    } catch (e) {
      debugPrint('فشل في طلب الصلاحيات: $e');
      return false;
    }
  }

  static Future<void> _setupNotificationChannels() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: 'تذكير الأدوية',
          channelDescription: 'إشعارات مواعيد تناول الأدوية',
          importance: NotificationImportance.Max, // مهم لأجهزة شاومي
          defaultColor: Colors.teal,
          ledColor: Colors.white,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          locked: true, // يمنع المستخدم من إغلاق الإشعار
        ),
      ],
    );
  }

  static void _setNotificationListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceived,
      onNotificationCreatedMethod: _onNotificationCreated,
      onNotificationDisplayedMethod: _onNotificationDisplayed,
      onDismissActionReceivedMethod: _onDismissActionReceived,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _onActionReceived(ReceivedAction receivedAction) async {}

  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreated(ReceivedNotification notification) async {}

  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayed(ReceivedNotification notification) async {}

  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceived(ReceivedAction receivedAction) async {}

  static Future<void> _sendWelcomeNotification() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _welcomeNotificationId,
          channelKey: _channelKey,
          title: 'مرحبًا بكم في تطبيق الأدوية',
          body: 'سنذكركم بمواعيد أدويتكم تلقائيًا',
          notificationLayout: NotificationLayout.Default,
          payload: {'type': 'welcome'},
        ),
      );
    } catch (e) {
      debugPrint('فشل إرسال الإشعار الترحيبي: $e');
    }
  }

  static Future<void> _scheduleRepeatingNotification() async {
    try {
      await AwesomeNotifications().cancel(_repeatingNotificationId);
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _repeatingNotificationId,
          channelKey: _channelKey,
          title: 'تذكير دوري',
          body: 'هذا تذكير لك كل 3 ساعات',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationInterval(
          interval: Duration(minutes: 180), // Duration object
          allowWhileIdle: true,
          repeats: true,
        ),
      );
    } catch (e) {
      debugPrint('فشل جدولة الإشعار المتكرر: $e');
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String medicineName,
    required DateTime scheduleTime,
    required String dosage,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final tzTime = tz.TZDateTime.from(scheduleTime, _appTimeZone);
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _channelKey,
          title: 'موعد تناول $medicineName',
          body: 'جرعة: $dosage',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(
          date: tzTime,
          allowWhileIdle: true,
        ),
      );
    } catch (e) {
      debugPrint('فشل جدولة التذكير: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
    } catch (e) {
      debugPrint('فشل إلغاء الإشعار: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
    } catch (e) {
      debugPrint('فشل إلغاء جميع الإشعارات: $e');
    }
  }

  // دالة مساعدة لفحص الإشعارات المجدولة
  static Future<void> debugScheduledNotifications() async {
    try {
      final notifications = await AwesomeNotifications().listScheduledNotifications();
      debugPrint('=== الإشعارات المجدولة === (العدد: ${notifications.length})');

      for (final notification in notifications) {
        final content = notification.content;
        final schedule = notification.schedule;

        String nextTrigger = 'غير محدد';

        if (schedule != null) {
          // حساب الوقت التالي يدوياً لأن getNextValidDate غير متوفر
          if (schedule is NotificationInterval) {
            nextTrigger = 'كل ${schedule.interval} ثانية';
          }
          else if (schedule is NotificationCalendar) {
            nextTrigger = 'يوميًا في ${schedule.hour}:${schedule.minute}';
          }
          else if (schedule is NotificationAndroidCrontab) {
            nextTrigger = 'حسب جدولة كرون: ${schedule.initialDateTime}';
          }
        }

        debugPrint('''
      ID: ${content?.id}
      Title: ${content?.title}
      Next Trigger: $nextTrigger
      Channel: ${content?.channelKey}
      ''');
      }
    } catch (e) {
      debugPrint('فشل في عرض الإشعارات المجدولة: $e');
    }
  }
}