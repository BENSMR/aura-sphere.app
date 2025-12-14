import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String avatarUrl;
  final int auraTokens;
  final String? invoiceTemplate;
  final String timezone;
  final String locale;
  final String? country;
  final String role; // 'owner' or 'employee'

  AppUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.auraTokens,
    this.invoiceTemplate,
    this.timezone = 'UTC',
    this.locale = 'en-US',
    this.country = 'US',
    this.role = 'owner', // Default to owner for backward compatibility
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
      timezone: data['timezone'] ?? 'UTC',
      locale: data['locale'] ?? 'en-US',
      country: data['country'] ?? 'US',
      role: data['role'] ?? 'owner',
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
    String? timezone,
    String? locale,
    String? country,
    String? role,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      auraTokens: auraTokens ?? this.auraTokens,
      invoiceTemplate: invoiceTemplate ?? this.invoiceTemplate,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      country: country ?? this.country,
      role: role ?? this.role,
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
      'timezone': timezone,
      'locale': locale,
      'country': country,
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
