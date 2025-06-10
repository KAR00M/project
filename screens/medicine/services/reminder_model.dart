import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final String medicine;
  final int hour;
  final int minute;
  final int repeatHours;
  final String category;

  Reminder({
    required this.medicine,
    required this.hour,
    required this.minute,
    required this.repeatHours,
    required this.category,
    String? id,
  }) : id = id ?? '';

  factory Reminder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reminder(
      id: doc.id,
      medicine: data['medicine'] ?? 'Unnamed',
      hour: data['hour'] ?? 0,
      minute: data['minute'] ?? 0,
      repeatHours: data['repeat_hours'] ?? 0,
      category: data['category'] ?? 'General',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicine': medicine,
      'hour': hour,
      'minute': minute,
      'repeat_hours': repeatHours,
      'category': category,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}