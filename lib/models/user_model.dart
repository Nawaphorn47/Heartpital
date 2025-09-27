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

  factory User.fromJson(Map<String, dynamic> json, String id) {
    return User(
      id: id,
      name: json['name'] as String,
      position: json['position'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'position': position,
      'email': email,
    };
  }
}