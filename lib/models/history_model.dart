import 'package:cloud_firestore/cloud_firestore.dart';

class History {
  final String? id;
  final String patientName;
  final String patientHn;
  final String details;
  final String type;
  final Timestamp completedDate;
  final String userId; // <<< เพิ่มฟิลด์นี้

  static const String collectionName = 'history';

  History({
    this.id,
    required this.patientName,
    required this.patientHn,
    required this.details,
    required this.type,
    required this.completedDate,
    required this.userId, // <<< เพิ่มใน constructor
  });

  factory History.fromJson(Map<String, dynamic> json, String id) {
    return History(
      id: id,
      patientName: json['patientName'] as String,
      patientHn: json['patientHn'] as String,
      details: json['details'] as String,
      type: json['type'] as String,
      completedDate: json['completedDate'] as Timestamp,
      userId: json['userId'] as String, // <<< เพิ่มการดึงข้อมูล
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientName': patientName,
      'patientHn': patientHn,
      'details': details,
      'type': type,
      'completedDate': completedDate,
      'userId': userId, // <<< เพิ่มข้อมูลตอนแปลงเป็น JSON
    };
  }
}