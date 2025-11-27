import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseStatus { 
  draft, 
  pending_approval, 
  approved, 
  rejected, 
  reimbursed 
}

class ExpenseModel {
  final String id;
  final String userId;                    // owner (submitter)
  final String? projectId;                // optional link to project
  final String? invoiceId;                // optional link to invoice
  final String merchant;
  final DateTime? date;
  final double amount;
  final double? vat;                      // absolute VAT amount
  final double vatRate;                   // 0.20 -> 20%
  final String currency;
  final String category;
  final String paymentMethod;             // cash, card, bank
  final List<String> photoUrls;
  final ExpenseStatus status;
  final String? approverId;
  final String? approvedNote;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? rawOcr;     // raw OCR extraction data
  final Map<String, dynamic>? audit;      // minimal audit info

  ExpenseModel({
    required this.id,
    required this.userId,
    this.projectId,
    this.invoiceId,
    required this.merchant,
    this.date,
    required this.amount,
    this.vat,
    required this.vatRate,
    required this.currency,
    required this.category,
    required this.paymentMethod,
    required this.photoUrls,
    this.status = ExpenseStatus.draft,
    this.approverId,
    this.approvedNote,
    DateTime? createdAt,
    this.updatedAt,
    this.rawOcr,
    this.audit,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'projectId': projectId,
      'invoiceId': invoiceId,
      'merchant': merchant,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'amount': amount,
      'vat': vat,
      'vatRate': vatRate,
      'currency': currency,
      'category': category,
      'paymentMethod': paymentMethod,
      'photoUrls': photoUrls,
      'status': status.toString().split('.').last,
      'approverId': approverId,
      'approvedNote': approvedNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'rawOcr': rawOcr ?? {},
      'audit': audit ?? {},
    };
  }

  factory ExpenseModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    
    ExpenseStatus parseStatus(String? s) {
      if (s == null) return ExpenseStatus.draft;
      try {
        return ExpenseStatus.values.firstWhere(
          (e) => e.toString().endsWith(s),
        );
      } catch (_) {
        return ExpenseStatus.draft;
      }
    }

    return ExpenseModel(
      id: d['id'] ?? doc.id,
      userId: d['userId'] ?? '',
      projectId: d['projectId'],
      invoiceId: d['invoiceId'],
      merchant: d['merchant'] ?? '',
      date: d['date'] != null ? (d['date'] as Timestamp).toDate() : null,
      amount: (d['amount'] ?? 0).toDouble(),
      vat: d['vat'] != null ? (d['vat'] as num).toDouble() : null,
      vatRate: (d['vatRate'] ?? 0.0).toDouble(),
      currency: d['currency'] ?? 'EUR',
      category: d['category'] ?? 'General',
      paymentMethod: d['paymentMethod'] ?? 'unknown',
      photoUrls: List<String>.from(d['photoUrls'] ?? []),
      status: parseStatus(d['status']),
      approverId: d['approverId'],
      approvedNote: d['approvedNote'],
      createdAt: d['createdAt'] != null 
        ? (d['createdAt'] as Timestamp).toDate() 
        : DateTime.now(),
      updatedAt: d['updatedAt'] != null 
        ? (d['updatedAt'] as Timestamp).toDate() 
        : null,
      rawOcr: (d['rawOcr'] as Map<String, dynamic>?) ?? {},
      audit: (d['audit'] as Map<String, dynamic>?) ?? {},
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    ExpenseStatus parseStatus(String? s) {
      if (s == null) return ExpenseStatus.draft;
      try {
        return ExpenseStatus.values.firstWhere(
          (e) => e.toString().endsWith(s),
        );
      } catch (_) {
        return ExpenseStatus.draft;
      }
    }

    return ExpenseModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      projectId: json['projectId'],
      invoiceId: json['invoiceId'],
      merchant: json['merchant'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      amount: (json['amount'] ?? 0).toDouble(),
      vat: json['vat'] != null ? (json['vat'] as num).toDouble() : null,
      vatRate: (json['vatRate'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      category: json['category'] ?? 'General',
      paymentMethod: json['paymentMethod'] ?? 'unknown',
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      status: parseStatus(json['status']),
      approverId: json['approverId'],
      approvedNote: json['approvedNote'],
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : null,
      rawOcr: json['rawOcr'] as Map<String, dynamic>?,
      audit: json['audit'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'projectId': projectId,
      'invoiceId': invoiceId,
      'merchant': merchant,
      'date': date?.toIso8601String(),
      'amount': amount,
      'vat': vat,
      'vatRate': vatRate,
      'currency': currency,
      'category': category,
      'paymentMethod': paymentMethod,
      'photoUrls': photoUrls,
      'status': status.toString().split('.').last,
      'approverId': approverId,
      'approvedNote': approvedNote,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'rawOcr': rawOcr ?? {},
      'audit': audit ?? {},
    };
  }

  /// Copy with updates
  ExpenseModel copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? invoiceId,
    String? merchant,
    DateTime? date,
    double? amount,
    double? vat,
    double? vatRate,
    String? currency,
    String? category,
    String? paymentMethod,
    List<String>? photoUrls,
    ExpenseStatus? status,
    String? approverId,
    String? approvedNote,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? rawOcr,
    Map<String, dynamic>? audit,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      invoiceId: invoiceId ?? this.invoiceId,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      vat: vat ?? this.vat,
      vatRate: vatRate ?? this.vatRate,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      approverId: approverId ?? this.approverId,
      approvedNote: approvedNote ?? this.approvedNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rawOcr: rawOcr ?? this.rawOcr,
      audit: audit ?? this.audit,
    );
  }
}
