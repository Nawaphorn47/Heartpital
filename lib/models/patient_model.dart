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
  final String createdBy; // เพิ่มบรรทัดนี้

  static const CollectionName = 'patients';

  Patient({
    this.id,
    required this.name,
    required this.hn,
    required this.location,
    required this.department,
    this.status = 'ปกติ',
    this.isNPO = false,
    this.medicationTime,
    required this.createdBy, // เพิ่มบรรทัดนี้
  });

  String get building => location;

  factory Patient.fromJson(Map<String, dynamic> json, String id) {
    return Patient(
      id: id,
      name: json['name'] as String,
      hn: json['hn'] as String,
      location: json['location'] as String,
      department: json['department'] as String,
      status: json['status'] as String? ?? 'ปกติ',
      isNPO: json['isNPO'] as bool? ?? false,
      medicationTime: json['medicationTime'] as Timestamp?,
      createdBy: json['createdBy'] as String, // เพิ่มบรรทัดนี้
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
      'createdBy': createdBy, // เพิ่มบรรทัดนี้
    };
  }
}