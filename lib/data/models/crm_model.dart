import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  final String id;
  final String userId; // owner
  final String name;
  final String email;
  final String phone;
  final String company;
  final String jobTitle;
  final String notes;
  final String status;
  final List<String> tags;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  Contact({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.jobTitle,
    required this.notes,
    required this.status,
    required this.tags,
    this.createdAt,
    this.updatedAt,
  });

  factory Contact.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return Contact(
      id: doc.id,
      userId: d['userId'] ?? '',
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      company: d['company'] ?? '',
      jobTitle: d['jobTitle'] ?? '',
      notes: d['notes'] ?? '',
      status: d['status'] ?? 'lead',
      tags: List<String>.from(d['tags'] ?? []),
      createdAt: d['createdAt'],
      updatedAt: d['updatedAt'],
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'jobTitle': jobTitle,
      'notes': notes,
      'status': status,
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'jobTitle': jobTitle,
      'notes': notes,
      'status': status,
      'tags': tags,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Contact copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? jobTitle,
    String? notes,
    String? status,
    List<String>? tags,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Legacy class for backward compatibility
class CRMContact extends Contact {
  CRMContact({
    required String id,
    required String userId,
    required String name,
    required String email,
    String phone = '',
    String company = '',
    String jobTitle = '',
    String notes = '',
    String status = '',
    List<String> tags = const [],
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          userId: userId,
          name: name,
          email: email,
          phone: phone,
          company: company,
          jobTitle: jobTitle,
          notes: notes,
          status: status,
          tags: tags,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory CRMContact.fromJson(Map<String, dynamic> json) {
    return CRMContact(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      userId: json['userId'] as String,
      phone: json['phone'] as String? ?? '',
      company: json['company'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['createdAt'] is Timestamp ? json['createdAt'] : null,
      updatedAt: json['updatedAt'] is Timestamp ? json['updatedAt'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'jobTitle': jobTitle,
      'notes': notes,
      'status': status,
      'tags': tags,
      'createdAt': createdAt?.toDate().toIso8601String(),
      'updatedAt': updatedAt?.toDate().toIso8601String(),
    };
  }
}