// lib/services/history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/history_model.dart';

class HistoryService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection(History.collectionName);

  // แก้ไขฟังก์ชันนี้ให้รับ userId และ optional date range
  Stream<List<History>> getHistory(String userId, {DateTime? startDate, DateTime? endDate}) {
    Query query = _collection.where('userId', isEqualTo: userId);
    
    if (startDate != null) {
      query = query.where('completedDate', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      // เพิ่มเวลาให้ถึง 23:59:59 เพื่อให้รวมข้อมูลของวันสุดท้ายด้วย
      final endOfDay = endDate.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      query = query.where('completedDate', isLessThanOrEqualTo: endOfDay);
    }
    
    query = query.orderBy('completedDate', descending: true);

    return query.snapshots().map((snapshot) {
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