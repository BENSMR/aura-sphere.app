import 'package:cloud_firestore/cloud_firestore.dart';

/// Invoice Model for Finance Module
/// 
/// Stored at: users/{uid}/invoices/{invoiceId}
/// 
/// Represents a complete invoice with tax and currency calculations.
class Invoice {
  final String id;
  final String uid;
  final String invoiceNumber;
  final String companyId;
  final String contactId;
  final double amount;
  final String currency;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String? description;
  final List<InvoiceItem> items;
  final DateTime dueDate;
  final String status; // 'draft', 'sent', 'paid', 'overdue', 'cancelled'
  final String taxStatus; // 'calculated', 'queued', 'manual', 'error'
  final String? taxCalculatedBy;
  final String? taxCountry;
  final Map<String, dynamic>? taxBreakdown;
  final String? taxNote;
  final String? notes;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;
  final DateTime? paidAt;

  Invoice({
    required this.id,
    required this.uid,
    required this.invoiceNumber,
    required this.companyId,
    required this.contactId,
    required this.amount,
    required this.currency,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    this.description,
    this.items = const [],
    required this.dueDate,
    this.status = 'draft',
    this.taxStatus = 'queued',
    this.taxCalculatedBy,
    this.taxCountry,
    this.taxBreakdown,
    this.taxNote,
    this.notes,
    this.tags,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.sentAt,
    this.paidAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create from Firestore document
  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Invoice(
      id: doc.id,
      uid: data['uid'] ?? '',
      invoiceNumber: data['invoiceNumber'] ?? '',
      companyId: data['companyId'] ?? '',
      contactId: data['contactId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: (data['currency'] ?? 'USD').toString().toUpperCase(),
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (data['taxAmount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      description: data['description'],
      items: (data['items'] as List?)
              ?.map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      dueDate: _parseDate(data['dueDate']),
      status: data['status'] ?? 'draft',
      taxStatus: data['taxStatus'] ?? 'queued',
      taxCalculatedBy: data['taxCalculatedBy'],
      taxCountry: data['taxCountry'],
      taxBreakdown: data['taxBreakdown'],
      taxNote: data['taxNote'],
      notes: data['notes'],
      tags: (data['tags'] as List?)?.cast<String>(),
      metadata: data['metadata'],
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      sentAt: data['sentAt'] != null ? _parseTimestamp(data['sentAt']) : null,
      paidAt: data['paidAt'] != null ? _parseTimestamp(data['paidAt']) : null,
    );
  }

  /// Create from JSON
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      companyId: json['companyId'] ?? '',
      contactId: json['contactId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] ?? 'USD').toString().toUpperCase(),
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
      items: (json['items'] as List?)
              ?.map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'].toString())
          : DateTime.now().add(const Duration(days: 30)),
      status: json['status'] ?? 'draft',
      taxStatus: json['taxStatus'] ?? 'queued',
      taxCalculatedBy: json['taxCalculatedBy'],
      taxCountry: json['taxCountry'],
      taxBreakdown: json['taxBreakdown'],
      taxNote: json['taxNote'],
      notes: json['notes'],
      tags: (json['tags'] as List?)?.cast<String>(),
      metadata: json['metadata'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'].toString())
          : null,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'].toString())
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'invoiceNumber': invoiceNumber,
      'companyId': companyId,
      'contactId': contactId,
      'amount': amount,
      'currency': currency.toUpperCase(),
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'description': description,
      'items': items.map((item) => item.toMap()).toList(),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'taxStatus': taxStatus,
      'taxCalculatedBy': taxCalculatedBy,
      'taxCountry': taxCountry,
      'taxBreakdown': taxBreakdown,
      'taxNote': taxNote,
      'notes': notes,
      'tags': tags,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'invoiceNumber': invoiceNumber,
      'companyId': companyId,
      'contactId': contactId,
      'amount': amount,
      'currency': currency,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'description': description,
      'items': items.map((item) => item.toMap()).toList(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'taxStatus': taxStatus,
      'taxCalculatedBy': taxCalculatedBy,
      'taxCountry': taxCountry,
      'taxBreakdown': taxBreakdown,
      'taxNote': taxNote,
      'notes': notes,
      'tags': tags,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Invoice copyWith({
    String? id,
    String? uid,
    String? invoiceNumber,
    String? companyId,
    String? contactId,
    double? amount,
    String? currency,
    double? taxRate,
    double? taxAmount,
    double? total,
    String? description,
    List<InvoiceItem>? items,
    DateTime? dueDate,
    String? status,
    String? taxStatus,
    String? taxCalculatedBy,
    String? taxCountry,
    Map<String, dynamic>? taxBreakdown,
    String? taxNote,
    String? notes,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? sentAt,
    DateTime? paidAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      companyId: companyId ?? this.companyId,
      contactId: contactId ?? this.contactId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      description: description ?? this.description,
      items: items ?? this.items,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      taxStatus: taxStatus ?? this.taxStatus,
      taxCalculatedBy: taxCalculatedBy ?? this.taxCalculatedBy,
      taxCountry: taxCountry ?? this.taxCountry,
      taxBreakdown: taxBreakdown ?? this.taxBreakdown,
      taxNote: taxNote ?? this.taxNote,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sentAt: sentAt ?? this.sentAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Invoice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uid == other.uid;

  @override
  int get hashCode => id.hashCode ^ uid.hashCode;

  @override
  String toString() =>
      'Invoice(id: $id, invoiceNumber: $invoiceNumber, amount: $amount $currency)';
}

/// Invoice line item
class InvoiceItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final double? taxRate;
  final double? taxAmount;
  final String? notes;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    double? subtotal,
    this.taxRate,
    this.taxAmount,
    this.notes,
  }) : subtotal = subtotal ?? (quantity * unitPrice);

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble(),
      taxRate: (map['taxRate'] as num?)?.toDouble(),
      taxAmount: (map['taxAmount'] as num?)?.toDouble(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'notes': notes,
    };
  }
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

/// Helper to parse date fields
DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now().add(const Duration(days: 30));
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now().add(const Duration(days: 30));
    }
  }
  return DateTime.now().add(const Duration(days: 30));
}
