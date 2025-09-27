// lib/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String? id;
  final String patientId;
  final String details;
  final bool isUrgent;
  final String type;
  final Timestamp timestamp; // นี่คือเวลาที่จะให้แจ้งเตือนเด้ง (Reminder Time)
  
  // [NEW] เพิ่ม field นี้สำหรับเก็บเวลานัดหมายจริง
  final Timestamp? appointmentTime; 

  static const CollectionName = 'notifications';

  NotificationItem({
    this.id,
    required this.patientId,
    required this.details,
    this.isUrgent = false,
    required this.type,
    required this.timestamp,
    this.appointmentTime, // [NEW]
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json, String id) {
    return NotificationItem(
      id: id,
      patientId: json['patientId'] as String,
      details: json['details'] as String,
      isUrgent: json['isUrgent'] as bool? ?? false,
      type: json['type'] as String,
      timestamp: json['timestamp'] as Timestamp,
      appointmentTime: json['appointmentTime'] as Timestamp?, // [NEW]
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'details': details,
      'isUrgent': isUrgent,
      'type': type,
      'timestamp': timestamp,
      'appointmentTime': appointmentTime, // [NEW]
    };
  }
}