import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lastver/screens/medicine/services/reminder_model.dart';


class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late StreamSubscription<QuerySnapshot> _subscription;

  void setupListener({
    required Function(List<Reminder>) onData,
    required Function(dynamic) onError,
  }) {
    _subscription = _firestore
        .collection('reminders')
        .orderBy('created_at')
        .snapshots()
        .listen((snapshot) {
      final reminders = snapshot.docs.map((doc) => Reminder.fromFirestore(doc)).toList();
      onData(reminders);
    }, onError: onError);
  }

  Future<void> addReminder(Reminder reminder) async {
    await _firestore.collection('reminders').add(reminder.toMap());
  }

  Future<void> deleteReminder(String id) async {
    await _firestore.collection('reminders').doc(id).delete();
  }

  void dispose() {
    _subscription.cancel();
  }
}