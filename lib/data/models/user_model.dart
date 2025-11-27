import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String avatarUrl;
  final int auraTokens;

  AppUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.auraTokens,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      auraTokens: data['auraTokens'] != null ? (data['auraTokens'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'auraTokens': auraTokens,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
