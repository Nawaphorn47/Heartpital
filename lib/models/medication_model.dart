import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String? id;
  final String name;
  final String patientId;
  final String status;
  final Timestamp scheduledTime;
  final Timestamp? administeredTime;

  static const CollectionName = 'medications';

  Medication({
    this.id,
    required this.name,
    required this.patientId,
    required this.status,
    required this.scheduledTime,
    this.administeredTime,
  });

  factory Medication.fromJson(Map<String, dynamic> json, String id) {
    return Medication(
      id: id,
      name: json['name'] as String,
      patientId: json['patientId'] as String,
      status: json['status'] as String,
      scheduledTime: json['scheduledTime'] as Timestamp,
      administeredTime: json['administeredTime'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'patientId': patientId,
      'status': status,
      'scheduledTime': scheduledTime,
      'administeredTime': administeredTime,
    };
  }
}