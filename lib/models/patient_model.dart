// lib/models/patient_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String? id;
  String name;
  String hn;
  String location;
  String department;
  String status;
  bool isNPO;
  Timestamp? medicationTime;
  
  // เพิ่ม field นี้เพื่อระบุว่าใครเป็นคนสร้างเคสนี้
  final String creatorId;

  static const collectionName = 'patients';

  Patient({
    this.id,
    required this.name,
    required this.hn,
    required this.location,
    required this.department,
    this.status = 'กำลังดำเนินการ', // เปลี่ยนค่าเริ่มต้น
    this.isNPO = false,
    this.medicationTime,
    required this.creatorId,
  });

  String get building => location;

  factory Patient.fromJson(Map<String, dynamic> json, String id) {
    return Patient(
      id: id,
      name: json['name'] as String,
      hn: json['hn'] as String,
      location: json['location'] as String,
      department: json['department'] as String,
      status: json['status'] as String? ?? 'กำลังดำเนินการ',
      isNPO: json['isNPO'] as bool? ?? false,
      medicationTime: json['medicationTime'] as Timestamp?,
      creatorId: json['creatorId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hn': hn,
      'location': location,
      'department': department,
      'status': status,
      'isNPO': isNPO,
      'medicationTime': medicationTime,
      'creatorId': creatorId,
    };
  }
}