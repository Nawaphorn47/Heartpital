// lib/models/patient_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String? id;
  String name;
  String hn;
  String location;
  String doctorName;
  String department;
  String status;
  bool isNPO;
  Timestamp? medicationTime;
  
  // [NEW] เพิ่ม 2 field นี้เข้าไป
  final String? assignedNurseId;
  final String? assignedNurseName;

  static const CollectionName = 'patients';

  Patient({
    this.id,
    required this.name,
    required this.hn,
    required this.location,
    required this.doctorName,
    required this.department,
    this.status = 'ปกติ',
    this.isNPO = false,
    this.medicationTime,
    this.assignedNurseId, // [NEW]
    this.assignedNurseName, // [NEW]
  });

  String get building => location;
  String get doctor => doctorName;

  factory Patient.fromJson(Map<String, dynamic> json, String id) {
    return Patient(
      id: id,
      name: json['name'] as String,
      hn: json['hn'] as String,
      location: json['location'] as String,
      doctorName: json['doctorName'] as String,
      department: json['department'] as String,
      status: json['status'] as String? ?? 'ปกติ',
      isNPO: json['isNPO'] as bool? ?? false,
      medicationTime: json['medicationTime'] as Timestamp?,
      // [NEW] ดึงข้อมูลใหม่จาก Firestore
      assignedNurseId: json['assignedNurseId'] as String?,
      assignedNurseName: json['assignedNurseName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hn': hn,
      'location': location,
      'doctorName': doctorName,
      'department': department,
      'status': status,
      'isNPO': isNPO,
      'medicationTime': medicationTime,
      // [NEW] เพิ่มข้อมูลใหม่ตอนบันทึก
      'assignedNurseId': assignedNurseId,
      'assignedNurseName': assignedNurseName,
    };
  }
}