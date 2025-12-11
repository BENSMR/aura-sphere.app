import 'package:cloud_firestore/cloud_firestore.dart';

/// Contact Model for Finance Module
/// 
/// Stored at: users/{uid}/contacts/{contactId}
/// 
/// Represents a customer, supplier, or other business contact.
/// Used in tax and currency calculations for invoices/expenses.
class Contact {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String country;
  final String? currency;
  final bool isBusiness;
  final String? vatNumber;
  final String? taxId;
  final String? companyName;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? contactPerson;
  final String? contactPersonEmail;
  final String? contactPersonPhone;
  final String type; // 'customer', 'supplier', 'partner', 'other'
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    required this.country,
    this.currency,
    required this.isBusiness,
    this.vatNumber,
    this.taxId,
    this.companyName,
    this.address,
    this.city,
    this.postalCode,
    this.contactPerson,
    this.contactPersonEmail,
    this.contactPersonPhone,
    this.type = 'customer',
    this.isActive = true,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create from Firestore document
  factory Contact.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Contact(
      id: doc.id,
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      country: (data['country'] ?? 'US').toString().toUpperCase(),
      currency: data['currency']?.toString().toUpperCase(),
      isBusiness: data['isBusiness'] ?? false,
      vatNumber: data['vatNumber'],
      taxId: data['taxId'],
      companyName: data['companyName'],
      address: data['address'],
      city: data['city'],
      postalCode: data['postalCode'],
      contactPerson: data['contactPerson'],
      contactPersonEmail: data['contactPersonEmail'],
      contactPersonPhone: data['contactPersonPhone'],
      type: data['type'] ?? 'customer',
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'],
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Create from JSON
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      country: (json['country'] ?? 'US').toString().toUpperCase(),
      currency: json['currency']?.toString().toUpperCase(),
      isBusiness: json['isBusiness'] ?? false,
      vatNumber: json['vatNumber'],
      taxId: json['taxId'],
      companyName: json['companyName'],
      address: json['address'],
      city: json['city'],
      postalCode: json['postalCode'],
      contactPerson: json['contactPerson'],
      contactPersonEmail: json['contactPersonEmail'],
      contactPersonPhone: json['contactPersonPhone'],
      type: json['type'] ?? 'customer',
      isActive: json['isActive'] ?? true,
      metadata: json['metadata'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'country': country.toUpperCase(),
      'currency': currency?.toUpperCase(),
      'isBusiness': isBusiness,
      'vatNumber': vatNumber,
      'taxId': taxId,
      'companyName': companyName,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'contactPerson': contactPerson,
      'contactPersonEmail': contactPersonEmail,
      'contactPersonPhone': contactPersonPhone,
      'type': type,
      'isActive': isActive,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'country': country,
      'currency': currency,
      'isBusiness': isBusiness,
      'vatNumber': vatNumber,
      'taxId': taxId,
      'companyName': companyName,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'contactPerson': contactPerson,
      'contactPersonEmail': contactPersonEmail,
      'contactPersonPhone': contactPersonPhone,
      'type': type,
      'isActive': isActive,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Contact copyWith({
    String? id,
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? country,
    String? currency,
    bool? isBusiness,
    String? vatNumber,
    String? taxId,
    String? companyName,
    String? address,
    String? city,
    String? postalCode,
    String? contactPerson,
    String? contactPersonEmail,
    String? contactPersonPhone,
    String? type,
    bool? isActive,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      isBusiness: isBusiness ?? this.isBusiness,
      vatNumber: vatNumber ?? this.vatNumber,
      taxId: taxId ?? this.taxId,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPersonEmail: contactPersonEmail ?? this.contactPersonEmail,
      contactPersonPhone: contactPersonPhone ?? this.contactPersonPhone,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uid == other.uid;

  @override
  int get hashCode => id.hashCode ^ uid.hashCode;

  @override
  String toString() => 'Contact(id: $id, name: $name, country: $country)';
}

/// Helper to parse Firestore Timestamp
DateTime _parseTimestamp(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}
