import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medication_model.dart';

class MedicationService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(Medication.CollectionName);

  Stream<List<Medication>> getMedications() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Medication.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> addMedication(Medication medication) async {
    await _collection.add(medication.toJson());
  }

  Future<void> updateMedication(Medication medication) async {
    if (medication.id == null) {
      throw Exception("Cannot update medication without an ID.");
    }
    await _collection.doc(medication.id).update(medication.toJson());
  }

  Future<void> deleteMedication(String medicationId) async {
    await _collection.doc(medicationId).delete();
  }

  getMedicationsByDate(DateTime day) {}
}