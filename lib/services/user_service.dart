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
}
