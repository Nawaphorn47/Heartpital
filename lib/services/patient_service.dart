import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_model.dart';

class PatientService {
  // [FIX] แก้ไขการเรียกใช้ชื่อตัวแปร
  final CollectionReference _collection = FirebaseFirestore.instance.collection(Patient.collectionName);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Patient>> getPatients({String? building, String? department, String? searchQuery}) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    Query query = _collection.where('creatorId', isEqualTo: user.uid);

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
      
      patients.sort((a, b) {
        if (a.status == 'เสร็จสิ้น' && b.status != 'เสร็จสิ้น') {
          return 1;
        }
        if (a.status != 'เสร็จสิ้น' && b.status == 'เสร็จสิ้น') {
          return -1;
        }
        final aTime = a.medicationTime ?? Timestamp(0, 0);
        final bTime = b.medicationTime ?? Timestamp(0, 0);
        return bTime.compareTo(aTime);
      });

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

  Future<void> updatePatientStatus(String patientId, String newStatus) async {
    await _collection.doc(patientId).update({'status': newStatus});
  }

  Future<void> deletePatient(String patientId) async {
    await _collection.doc(patientId).delete();
  }
}