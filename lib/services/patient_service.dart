import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';

class PatientService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(Patient.CollectionName);

  Stream<List<Patient>> getPatients() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Patient.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
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

  generateNewHN() {}
}