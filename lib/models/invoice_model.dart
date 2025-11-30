import 'package:cloud_firestore/cloud_firestore.dart';
import 'invoice_item.dart';

class Invoice {
  final String id;
  final String userId;
  final String clientId;
  final String invoiceNumber;
  final double amount;
  final String currency;
  final String status;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  
  // Payment-related fields
  final String paymentStatus; // "unpaid" / "paid"
  final bool paymentVerified;
  final double? paidAmount;
  final String? paidCurrency;
  final String? lastPaymentIntentId;
  final DateTime? paidAt;

  Invoice({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.invoiceNumber,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    this.paymentStatus = 'unpaid',
    this.paymentVerified = false,
    this.paidAmount,
    this.paidCurrency,
    this.lastPaymentIntentId,
    this.paidAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      userId: json['userId'],
      clientId: json['clientId'],
      invoiceNumber: json['invoiceNumber'],
      amount: json['amount'].toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'],
      issueDate: _parseDateTime(json['issueDate']),
      dueDate: _parseDateTime(json['dueDate']),
      items: (json['items'] as List).map((i) => InvoiceItem.fromJson(i)).toList(),
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      paymentVerified: json['paymentVerified'] ?? false,
      paidAmount: json['paidAmount']?.toDouble(),
      paidCurrency: json['paidCurrency'],
      lastPaymentIntentId: json['lastPaymentIntentId'],
      paidAt: json['paidAt'] != null ? _parseDateTime(json['paidAt']) : null,
    );
  }

  // Helper method to parse DateTime from Firestore or JSON
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }
    throw ArgumentError('Invalid date format: $value');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'clientId': clientId,
      'invoiceNumber': invoiceNumber,
      'amount': amount,
      'currency': currency,
      'status': status,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'paymentStatus': paymentStatus,
      'paymentVerified': paymentVerified,
      'paidAmount': paidAmount,
      'paidCurrency': paidCurrency,
      'lastPaymentIntentId': lastPaymentIntentId,
      'paidAt': paidAt?.toIso8601String(),
    };
  }

  // Firestore serialization (handles Timestamps)
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': userId,
      'invoiceNumber': invoiceNumber,
      'total': amount,
      'currency': currency,
      'paymentStatus': paymentStatus,
      'paymentVerified': paymentVerified,
      'paidAmount': paidAmount,
      'paidCurrency': paidCurrency,
      'lastPaymentIntentId': lastPaymentIntentId,
      'paidAt': paidAt,
    };
  }

  // Factory for Firestore document reading
  factory Invoice.fromFirestore(Map<String, dynamic> data, String id) {
    return Invoice(
      id: id,
      userId: data['customerId'] ?? data['userId'] ?? '',
      clientId: data['clientId'] ?? '',
      invoiceNumber: data['invoiceNumber'] ?? '',
      amount: (data['total'] ?? data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'usd',
      status: data['status'] ?? data['paymentStatus'] ?? 'unpaid',
      issueDate: _parseDateTime(data['issueDate'] ?? DateTime.now()),
      dueDate: _parseDateTime(data['dueDate'] ?? DateTime.now()),
      items: [],
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      paymentVerified: data['paymentVerified'] ?? false,
      paidAmount: data['paidAmount']?.toDouble(),
      paidCurrency: data['paidCurrency'],
      lastPaymentIntentId: data['lastPaymentIntentId'],
      paidAt: data['paidAt'] != null ? _parseDateTime(data['paidAt']) : null,
    );
  }

  /// Copy invoice with updated fields
  Invoice copyWith({
    String? id,
    String? userId,
    String? clientId,
    String? invoiceNumber,
    double? amount,
    String? currency,
    String? status,
    DateTime? issueDate,
    DateTime? dueDate,
    List<InvoiceItem>? items,
    String? paymentStatus,
    bool? paymentVerified,
    double? paidAmount,
    String? paidCurrency,
    String? lastPaymentIntentId,
    DateTime? paidAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentVerified: paymentVerified ?? this.paymentVerified,
      paidAmount: paidAmount ?? this.paidAmount,
      paidCurrency: paidCurrency ?? this.paidCurrency,
      lastPaymentIntentId: lastPaymentIntentId ?? this.lastPaymentIntentId,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}
