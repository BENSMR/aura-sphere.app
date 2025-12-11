import 'package:cloud_firestore/cloud_firestore.dart';

class Supplier {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;

  final Timestamp createdAt;
  final Timestamp updatedAt;

  Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // 🔄 Create empty supplier (for UI)
  factory Supplier.empty() {
    return Supplier(
      id: '',
      name: '',
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
  }

  // 🔥 Firestore → Model
  factory Supplier.fromJson(Map<String, dynamic> json, String id) {
    return Supplier(
      id: id,
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      notes: json['notes'],
      createdAt: json['createdAt'] ?? Timestamp.now(),
      updatedAt: json['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Model → Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Clone with modifications
  Supplier copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: Timestamp.now(),
    );
  }

  // Check if supplier has contact info
  bool get hasContactInfo => phone != null || email != null || address != null;

  // Get initials for avatar
  String get initials {
    final parts = name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
