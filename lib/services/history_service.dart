import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/history_model.dart';

class HistoryService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection(History.collectionName);

  // แก้ไขฟังก์ชันนี้ให้รับ userId
  Stream<List<History>> getHistory(String userId) {
    return _collection
        .where('userId', isEqualTo: userId) // <<< เพิ่มเงื่อนไขการกรอง
        .orderBy('completedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              History.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<void> addHistory(History history) async {
    await _collection.add(history.toJson());
  }
}