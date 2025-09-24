// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection(User.collectionName);

  Future<void> addUser(User user) async {
    await _collection.doc(user.id).set(user.toFirestore());
  }

  Stream<List<User>> getUsers() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => User(
                id: doc.id,
                name: doc['name'] as String,
                position: doc['position'] as String,
                email: doc['email'] as String,
              ))
          .toList();
    });
  }
}