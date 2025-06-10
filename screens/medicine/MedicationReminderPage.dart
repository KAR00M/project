import 'package:flutter/material.dart';
import 'package:lastver/screens/medicine/services/firestore_service.dart';
import 'package:lastver/screens/medicine/services/notification_service.dart';
import 'package:lastver/screens/medicine/services/reminder_model.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'AddReminderPage.dart';

class MedicationReminderPage extends StatefulWidget {
  final Color backgroundColor;
  final Color appBarColor;
  final Color cardColor;
  final Color textColor;
  final Color iconColor;

  const MedicationReminderPage({
    Key? key,
    required this.backgroundColor,
    this.appBarColor = const Color(0xFF00796B),
    this.cardColor = Colors.white,
    this.textColor = Colors.black,
    this.iconColor = Colors.teal,
  }) : super(key: key);

  @override
  _MedicationReminderPageState createState() => _MedicationReminderPageState();
}

class _MedicationReminderPageState extends State<MedicationReminderPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  List<Reminder> reminders = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _firestoreService.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('Starting app initialization...');
      await NotificationService.initialize();

      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        _showSnackBar('Please enable notifications in settings', Colors.orange);
        debugPrint('Notification permission not granted');
      } else {
        debugPrint('Notification permission granted');
      }

      await _setupFirestoreListener();
      setState(() => _isLoading = false);
      debugPrint('App initialized successfully');
    } catch (e) {
      _showSnackBar('Error initializing app: $e', Colors.red);
      debugPrint('Error during initialization: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _setupFirestoreListener() async {
    debugPrint('Setting up Firestore listener...');
    _firestoreService.setupListener(
      onData: (List<Reminder> updatedReminders) {
        if (mounted) {
          setState(() {
            reminders = updatedReminders;
            _hasError = false;
          });
          debugPrint('Reminders updated: ${reminders.length} reminders loaded');
          _rescheduleNotifications(updatedReminders);
        }
      },
      onError: (e) {
        _showSnackBar('Error fetching reminders: $e', Colors.red);
        debugPrint('Error fetching reminders from Firestore: $e');
        if (mounted) setState(() => _hasError = true);
      },
    );
  }

  Future<void> _rescheduleNotifications(List<Reminder> reminders) async {
    try {
      await _notificationService.cancelAllNotifications();
      debugPrint('Cancelled all previous scheduled notifications');

      for (final reminder in reminders) {
        final now = DateTime.now();
        final scheduleTime = DateTime(
          now.year,
          now.month,
          now.day,
          reminder.hour,
          reminder.minute,
        );

        if (scheduleTime.isBefore(now)) continue;

        await _notificationService.scheduleReminder(
          id: reminder.id.hashCode,
          medicineName: reminder.medicine,
          scheduleTime: scheduleTime,
          dosage: '1 dose',
        );
      }

      debugPrint('Scheduled notifications for ${reminders.length} reminders');
    } catch (e) {
      debugPrint('Error rescheduling notifications: $e');
      _showSnackBar('Error scheduling notifications: $e', Colors.red);
    }
  }

  Future<void> _addReminder(String medicine, TimeOfDay time, int repeatHours, String category) async {
    try {
      final reminder = Reminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicine: medicine,
        hour: time.hour,
        minute: time.minute,
        repeatHours: repeatHours,
        category: category,
      );

      debugPrint('Adding reminder: $medicine at ${time.format(context)}, repeat every $repeatHours hours');
      await _firestoreService.addReminder(reminder);
      _showSnackBar('Reminder added successfully!', Colors.green);
      debugPrint('Reminder added to Firestore successfully');
    } catch (e) {
      _showSnackBar('Error adding reminder: $e', Colors.red);
      debugPrint('Error adding reminder: $e');
    }
  }

  Future<void> _deleteReminder(String id, String medicine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete', style: TextStyle(color: widget.textColor)),
        content: Text('Delete reminder for $medicine?', style: TextStyle(color: widget.textColor)),
        backgroundColor: widget.backgroundColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: widget.iconColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        debugPrint('Deleting reminder with ID: $id for $medicine');
        await _firestoreService.deleteReminder(id);
        await _notificationService.cancelNotification(id.hashCode);
        _showSnackBar('Reminder deleted', Colors.red);
        debugPrint('Reminder deleted and notification canceled');
      } catch (e) {
        _showSnackBar('Error deleting reminder: $e', Colors.red);
        debugPrint('Error deleting reminder: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      debugPrint('Deletion canceled by user');
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    debugPrint('Refreshing reminders and rescheduling notifications...');
    try {
      await _rescheduleNotifications(reminders);
      _showSnackBar('Reminders refreshed', widget.iconColor);
    } catch (e) {
      _showSnackBar('Error refreshing: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Medication Reminders',
          style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        ),
        backgroundColor: widget.appBarColor,
        centerTitle: true,
        iconTheme: IconThemeData(color: widget.iconColor),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddReminderPage(
              onSave: _addReminder,
              backgroundColor: widget.backgroundColor,
              appBarColor: widget.appBarColor,
              textColor: widget.textColor,
              iconColor: widget.iconColor,
            ),
          ),
        ),
        backgroundColor: widget.iconColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasError) return _buildErrorView();
    if (reminders.isEmpty) return _buildEmptyView();
    return _buildReminderList();
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: widget.iconColor),
          const SizedBox(height: 16),
          Text('Something went wrong', style: TextStyle(color: widget.textColor)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _initializeApp,
            style: ElevatedButton.styleFrom(backgroundColor: widget.iconColor),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_active, size: 100, color: widget.iconColor),
          const SizedBox(height: 20),
          Text(
            'No reminders yet!',
            style: TextStyle(fontSize: 18, color: widget.textColor),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the + button to add your first reminder',
            style: TextStyle(color: widget.textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return _buildReminderCard(reminder);
        },
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    final repeatText = reminder.repeatHours > 0
        ? 'Every ${reminder.repeatHours} hours'
        : 'No repeat';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      color: widget.cardColor,
      child: ListTile(
        leading: Icon(
          _getCategoryIcon(reminder.category),
          color: widget.iconColor,
        ),
        title: Text(
          reminder.medicine,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${time.format(context)} • $repeatText',
              style: TextStyle(color: widget.textColor),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(reminder.category),
              backgroundColor: widget.iconColor.withOpacity(0.1),
              labelStyle: TextStyle(fontSize: 12, color: widget.textColor),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red[400]),
          onPressed: () => _deleteReminder(reminder.id, reminder.medicine),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'pill':
        return Icons.medical_services;
      case 'injection':
        return Icons.airline_seat_flat_angled;
      case 'syrup':
        return Icons.local_drink;
      default:
        return Icons.medical_services;
    }
  }
}
