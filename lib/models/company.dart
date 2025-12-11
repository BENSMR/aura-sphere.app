import 'package:cloud_firestore/cloud_firestore.dart';

/// Company Model for Finance Module
/// 
/// Stored at: users/{uid}/companies/{companyId}
/// 
/// This represents a company/business entity used in the finance system.
/// Can be the main business or a subsidiary/branch.
class Company {
  final String id;
  final String uid;
  final String name;
  final String country;
  final String defaultCurrency;
  final bool isBusiness;
  final String? vatNumber;
  final String? taxId;
  final String? businessEmail;
  final String? businessPhone;
  final String? address;
  final String? city;
  final String? postalCode;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.uid,
    required this.name,
    required this.country,
    required this.defaultCurrency,
    required this.isBusiness,
    this.vatNumber,
    this.taxId,
    this.businessEmail,
    this.businessPhone,
    this.address,
    this.city,
    this.postalCode,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create from Firestore document
  factory Company.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Company(
      id: doc.id,
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      country: (data['country'] ?? 'US').toString().toUpperCase(),
      defaultCurrency: (data['defaultCurrency'] ?? 'USD').toString().toUpperCase(),
      isBusiness: data['isBusiness'] ?? true,
      vatNumber: data['vatNumber'],
      taxId: data['taxId'],
      businessEmail: data['businessEmail'],
      businessPhone: data['businessPhone'],
      address: data['address'],
      city: data['city'],
      postalCode: data['postalCode'],
      isDefault: data['isDefault'] ?? false,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Create from JSON (for API responses, etc.)
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      country: (json['country'] ?? 'US').toString().toUpperCase(),
      defaultCurrency: (json['defaultCurrency'] ?? 'USD').toString().toUpperCase(),
      isBusiness: json['isBusiness'] ?? true,
      vatNumber: json['vatNumber'],
      taxId: json['taxId'],
      businessEmail: json['businessEmail'],
      businessPhone: json['businessPhone'],
      address: json['address'],
      city: json['city'],
      postalCode: json['postalCode'],
      isDefault: json['isDefault'] ?? false,
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
      'country': country.toUpperCase(),
      'defaultCurrency': defaultCurrency.toUpperCase(),
      'isBusiness': isBusiness,
      'vatNumber': vatNumber,
      'taxId': taxId,
      'businessEmail': businessEmail,
      'businessPhone': businessPhone,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'isDefault': isDefault,
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
      'country': country,
      'defaultCurrency': defaultCurrency,
      'isBusiness': isBusiness,
      'vatNumber': vatNumber,
      'taxId': taxId,
      'businessEmail': businessEmail,
      'businessPhone': businessPhone,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Company copyWith({
    String? id,
    String? uid,
    String? name,
    String? country,
    String? defaultCurrency,
    bool? isBusiness,
    String? vatNumber,
    String? taxId,
    String? businessEmail,
    String? businessPhone,
    String? address,
    String? city,
    String? postalCode,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      country: country ?? this.country,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      isBusiness: isBusiness ?? this.isBusiness,
      vatNumber: vatNumber ?? this.vatNumber,
      taxId: taxId ?? this.taxId,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Company &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uid == other.uid;

  @override
  int get hashCode => id.hashCode ^ uid.hashCode;

  @override
  String toString() => 'Company(id: $id, name: $name, country: $country)';
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
