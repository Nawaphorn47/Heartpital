// lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? id;
  final String name;
  final String position;
  final String email;

  static const collectionName = 'users';

  User({
    this.id,
    required this.name,
    required this.position,
    required this.email,
  });

  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options) {
    final data = snapshot.data();
    return User(
      id: snapshot.id,
      name: data?['name'],
      position: data?['position'],
      email: data?['email'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'position': position,
      'email': email,
    };
  }
}