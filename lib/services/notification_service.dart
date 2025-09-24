import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(NotificationItem.CollectionName);

  Stream<List<NotificationItem>> getNotifications() {
    return _collection.orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => NotificationItem.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> addNotification(NotificationItem notification) async {
    await _collection.add(notification.toJson());
  }

  Future<void> deleteNotification(String notificationId) async {
    await _collection.doc(notificationId).delete();
  }
}