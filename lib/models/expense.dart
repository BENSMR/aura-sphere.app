import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an expense in the system
class Expense {
  final String id;
  final String userId;
  final double amount;
  final String vendor;
  final List<String> items;
  final DateTime createdAt;
  final String status; // pending_review, approved, rejected
  final String? category;
  final String? description;
  final String? receiptUrl;
  final DateTime? updatedAt;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.vendor,
    required this.items,
    required this.createdAt,
    required this.status,
    this.category,
    this.description,
    this.receiptUrl,
    this.updatedAt,
  });

  /// Convert Expense to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'amount': amount,
      'vendor': vendor,
      'items': items,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'category': category,
      'description': description,
      'receiptUrl': receiptUrl,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create Expense from Firestore document
  factory Expense.fromJson(Map<String, dynamic> json, String id) {
    return Expense(
      id: id,
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      vendor: json['vendor'] ?? '',
      items: List<String>.from(json['items'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: json['status'] ?? 'pending_review',
      category: json['category'],
      description: json['description'],
      receiptUrl: json['receiptUrl'],
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create a copy with modified fields
  Expense copyWith({
    String? id,
    String? userId,
    double? amount,
    String? vendor,
    List<String>? items,
    DateTime? createdAt,
    String? status,
    String? category,
    String? description,
    String? receiptUrl,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      vendor: vendor ?? this.vendor,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      category: category ?? this.category,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
