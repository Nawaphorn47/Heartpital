// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection(User.collectionName);

  Future<void> addUser(User user) async {
    await _collection.doc(user.id).set(user.toJson());
  }

  Stream<List<User>> getUsers() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => User.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }
  
  /// ดึงข้อมูลผู้ใช้คนเดียวจาก ID
  Future<User?> getUserById(String id) async {
    final docSnapshot = await _collection.doc(id).get();
    if (docSnapshot.exists) {
      return User.fromJson(docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);
    }
    return null;
  }

  Future<void> updateUser(User user) async {
    if (user.id == null) {
      throw Exception("User ID cannot be null for updating.");
    }
    await _collection.doc(user.id).update(user.toJson());
  }
}