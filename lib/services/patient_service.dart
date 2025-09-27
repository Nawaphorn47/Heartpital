// lib/services/patient_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';

class PatientService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(Patient.CollectionName);

  // ... (โค้ดส่วนอื่นเหมือนเดิม)
  Stream<List<Patient>> getPatients({String? building, String? department, String? searchQuery}) {
    Query query = _collection;

    if (building != null && building != 'ทุกตึก') {
      query = query.where('location', isEqualTo: building);
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

  // [NEW] ฟังก์ชันสำหรับให้พยาบาลรับเคส
  Future<void> assignNurseToPatient(String patientId, String nurseId, String nurseName) async {
    await _collection.doc(patientId).update({
      'assignedNurseId': nurseId,
      'assignedNurseName': nurseName,
    });
  }
}