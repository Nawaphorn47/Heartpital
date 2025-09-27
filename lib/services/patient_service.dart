// lib/services/patient_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class PatientService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(Patient.CollectionName);

  Stream<List<Patient>> getPatients({String? building, String? department, String? searchQuery}) {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Return an empty stream if the user is not logged in.
      return Stream.value([]);
    }

    Query query = _collection.where('createdBy', isEqualTo: currentUser.uid);

    if (building != null && building != 'ทุกตึก') {
      query = query.where('location', isEqualTo: 'ตึก $building');
    }
    if (department != null && department != 'ทุกแผนก') {
      query = query.where('department', isEqualTo: department);
    }
    
    return query.snapshots().map((snapshot) {
      var patients = snapshot.docs.map((doc) => Patient.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerCaseQuery = searchQuery.toLowerCase();
        patients = patients.where((patient) {
          return patient.name.toLowerCase().contains(lowerCaseQuery) ||
                 patient.hn.toLowerCase().contains(lowerCaseQuery);
        }).toList();
      }
      
      return patients;
    });
  }

  Future<void> addPatient(Patient patient) async {
    await _collection.add(patient.toJson());
  }

  Future<void> updatePatient(Patient patient) async {
    if (patient.id == null) {
      throw Exception("Cannot update patient without an ID.");
    }
    await _collection.doc(patient.id).update(patient.toJson());
  }

  Future<void> deletePatient(String patientId) async {
    await _collection.doc(patientId).delete();
  }
}