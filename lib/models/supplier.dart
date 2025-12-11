import 'package:cloud_firestore/cloud_firestore.dart';

class Supplier {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? contact;
  final String? address;
  final String? currency;
  final String? paymentTerms;
  final int? leadTimeDays;
  final bool preferred;
  final String? notes;
  final List<String> tags;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Supplier({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.contact,
    this.address,
    this.currency,
    this.paymentTerms,
    this.leadTimeDays,
    this.preferred = false,
    this.notes,
    List<String>? tags,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? Timestamp.now(),
        updatedAt = updatedAt ?? Timestamp.now();

  factory Supplier.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Supplier(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'],
      phone: data['phone'],
      contact: data['contact'],
      address: data['address'],
      currency: data['currency'],
      paymentTerms: data['paymentTerms'],
      leadTimeDays: data['leadTimeDays'] != null ? (data['leadTimeDays'] as num).toInt() : null,
      preferred: data['preferred'] ?? false,
      notes: data['notes'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'contact': contact,
      'address': address,
      'currency': currency,
      'paymentTerms': paymentTerms,
      'leadTimeDays': leadTimeDays,
      'preferred': preferred,
      'notes': notes,
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
      'contact': contact,
      'address': address,
      'currency': currency,
      'paymentTerms': paymentTerms,
      'leadTimeDays': leadTimeDays,
      'preferred': preferred,
      'notes': notes,
      'tags': tags,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
