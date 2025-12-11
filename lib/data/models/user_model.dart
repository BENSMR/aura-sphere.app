import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String avatarUrl;
  final int auraTokens;
  final String? invoiceTemplate;

  AppUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.auraTokens,
    this.invoiceTemplate,
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
      invoiceTemplate: data['invoiceTemplate'] as String?,
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    int? auraTokens,
    String? invoiceTemplate,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      auraTokens: auraTokens ?? this.auraTokens,
      invoiceTemplate: invoiceTemplate ?? this.invoiceTemplate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'auraTokens': auraTokens,
      'invoiceTemplate': invoiceTemplate,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
