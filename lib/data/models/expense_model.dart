import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String userId;
  final String merchant;
  final DateTime? date;
  final double amount;
  final double? vat;
  final String currency;
  final String imageUrl;
  final Map<String, dynamic>? rawOcr;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? category;
  final String? notes;
  final bool? isReceipt;
  final String? invoiceId;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.merchant,
    required this.date,
    required this.amount,
    this.vat,
    required this.currency,
    required this.imageUrl,
    this.rawOcr,
    DateTime? createdAt,
    this.updatedAt,
    this.category,
    this.notes,
    this.isReceipt,
    this.invoiceId,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'merchant': merchant,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'amount': amount,
      'vat': vat,
      'currency': currency,
      'imageUrl': imageUrl,
      'rawOcr': rawOcr ?? {},
      'category': category,
      'notes': notes,
      'isReceipt': isReceipt ?? true,
      'invoiceId': invoiceId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create from Firestore DocumentSnapshot
  factory ExpenseModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: d['id'] ?? doc.id,
      userId: d['userId'] ?? '',
      merchant: d['merchant'] ?? '',
      date: d['date'] != null ? (d['date'] as Timestamp).toDate() : null,
      amount: (d['amount'] ?? 0).toDouble(),
      vat: d['vat'] != null ? (d['vat'] as num).toDouble() : null,
      currency: d['currency'] ?? 'EUR',
      imageUrl: d['imageUrl'] ?? '',
      rawOcr: d['rawOcr'] as Map<String, dynamic>?,
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: d['updatedAt'] != null
          ? (d['updatedAt'] as Timestamp).toDate()
          : null,
      category: d['category'] as String?,
      notes: d['notes'] as String?,
      isReceipt: d['isReceipt'] as bool? ?? true,
      invoiceId: d['invoiceId'] as String?,
    );
  }

  /// Create from JSON
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      merchant: json['merchant'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      vat: (json['vat'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      imageUrl: json['imageUrl'] as String? ?? '',
      rawOcr: json['rawOcr'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      category: json['category'] as String?,
      notes: json['notes'] as String?,
      isReceipt: json['isReceipt'] as bool? ?? true,
      invoiceId: json['invoiceId'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'merchant': merchant,
      'date': date?.toIso8601String(),
      'amount': amount,
      'vat': vat,
      'currency': currency,
      'imageUrl': imageUrl,
      'rawOcr': rawOcr,
      'category': category,
      'notes': notes,
      'isReceipt': isReceipt,
      'invoiceId': invoiceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Copy with modifications
  ExpenseModel copyWith({
    String? id,
    String? userId,
    String? merchant,
    DateTime? date,
    double? amount,
    double? vat,
    String? currency,
    String? imageUrl,
    Map<String, dynamic>? rawOcr,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    String? notes,
    bool? isReceipt,
    String? invoiceId,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      vat: vat ?? this.vat,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      rawOcr: rawOcr ?? this.rawOcr,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isReceipt: isReceipt ?? this.isReceipt,
      invoiceId: invoiceId ?? this.invoiceId,
    );
  }

  /// Calculate total with VAT
  double get total => amount + (vat ?? 0);

  /// Get amount without VAT
  double get subtotal => amount - (vat ?? 0);

  /// Get VAT percentage
  double? get vatPercentage {
    if (vat == null || amount == 0) return null;
    return (vat! / subtotal) * 100;
  }

  /// Check if expense is from today
  bool get isToday {
    if (date == null) return false;
    final now = DateTime.now();
    return date!.year == now.year &&
        date!.month == now.month &&
        date!.day == now.day;
  }

  /// Get age in days
  int? get ageInDays {
    if (date == null) return null;
    return DateTime.now().difference(date!).inDays;
  }

  /// Format amount as currency string
  String formatAmount() {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Format total (with VAT) as currency string
  String formatTotal() {
    return '$currency ${total.toStringAsFixed(2)}';
  }

  /// Format date as readable string
  String? formatDate() {
    if (date == null) return null;
    return '${date!.day.toString().padLeft(2, '0')}.${date!.month.toString().padLeft(2, '0')}.${date!.year}';
  }

  /// Equality check
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          merchant == other.merchant &&
          date == other.date &&
          amount == other.amount &&
          vat == other.vat &&
          currency == other.currency;

  /// Hash code
  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      merchant.hashCode ^
      date.hashCode ^
      amount.hashCode ^
      vat.hashCode ^
      currency.hashCode;

  /// String representation
  @override
  String toString() =>
      'ExpenseModel(id: $id, merchant: $merchant, amount: $amount $currency, date: $date)';
}