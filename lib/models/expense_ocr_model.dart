import 'package:cloud_firestore/cloud_firestore.dart';

/// Expense document as stored in Firestore
/// Collection: /users/{uid}/expenses/{expenseId}
class ExpenseOCRModel {
  final String expenseId;
  final String merchant;
  final double totalAmount;
  final String currency;
  final String date; // YYYY-MM-DD
  final String status; // draft, pending, approved, rejected, paid
  final String? notes;
  final String? rawOcr;
  final ParsedOCRData? parsed;
  final List<ParsedAmount> amounts;
  final List<String> dates;
  final List<ExpenseAttachment> attachments;
  final List<ExpenseAuditEntry> audit;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? editedBy;

  ExpenseOCRModel({
    required this.expenseId,
    required this.merchant,
    required this.totalAmount,
    required this.currency,
    required this.date,
    required this.status,
    this.notes,
    this.rawOcr,
    this.parsed,
    this.amounts = const [],
    this.dates = const [],
    this.attachments = const [],
    this.audit = const [],
    required this.createdAt,
    this.updatedAt,
    this.editedBy,
  });

  /// Load from Firestore document
  static ExpenseOCRModel fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ExpenseOCRModel(
      expenseId: doc.id,
      merchant: data['merchant'] ?? 'Unknown',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      date: data['date'] ?? '',
      status: data['status'] ?? 'draft',
      notes: data['notes'],
      rawOcr: data['rawOcr'],
      parsed: data['parsed'] != null
          ? ParsedOCRData.fromJson(data['parsed'])
          : null,
      amounts: (data['amounts'] as List?)
              ?.map((a) => ParsedAmount.fromJson(a))
              .toList() ??
          [],
      dates: List<String>.from(data['dates'] ?? []),
      attachments: (data['attachments'] as List?)
              ?.map((a) => ExpenseAttachment.fromJson(a))
              .toList() ??
          [],
      audit: (data['audit'] as List?)
              ?.map((a) => ExpenseAuditEntry.fromJson(a))
              .toList() ??
          [],
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestampNullable(data['updatedAt']),
      editedBy: data['editedBy'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'merchant': merchant,
      'totalAmount': totalAmount,
      'currency': currency,
      'date': date,
      'status': status,
      'notes': notes,
      'rawOcr': rawOcr,
      'parsed': parsed?.toJson(),
      'amounts': amounts.map((a) => a.toJson()).toList(),
      'dates': dates,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'audit': audit.map((a) => a.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'editedBy': editedBy,
    };
  }

  /// Helper: is expense pending approval?
  bool get isPending => status == 'pending';

  /// Helper: is expense approved?
  bool get isApproved => status == 'approved';

  /// Helper: format amount with currency
  String get formattedAmount => '$totalAmount $currency';

  @override
  String toString() =>
      'ExpenseOCRModel(id: $expenseId, merchant: $merchant, amount: $totalAmount $currency, status: $status)';
}

/// OCR-parsed data
class ParsedOCRData {
  final String? rawText;
  final String? merchant;
  final double? total;
  final String? currency;
  final String? date;
  final List<ParsedAmount> amounts;
  final List<String> dates;

  ParsedOCRData({
    this.rawText,
    this.merchant,
    this.total,
    this.currency,
    this.date,
    this.amounts = const [],
    this.dates = const [],
  });

  static ParsedOCRData fromJson(Map<String, dynamic> json) {
    return ParsedOCRData(
      rawText: json['rawText'],
      merchant: json['merchant'],
      total: (json['total'] as num?)?.toDouble(),
      currency: json['currency'],
      date: json['date'],
      amounts: (json['amounts'] as List?)
              ?.map((a) => ParsedAmount.fromJson(a))
              .toList() ??
          [],
      dates: List<String>.from(json['dates'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rawText': rawText,
      'merchant': merchant,
      'total': total,
      'currency': currency,
      'date': date,
      'amounts': amounts.map((a) => a.toJson()).toList(),
      'dates': dates,
    };
  }
}

/// Parsed amount from OCR
class ParsedAmount {
  final String raw; // "23.50" or "23,50 EUR"
  final double value; // 23.50

  ParsedAmount({required this.raw, required this.value});

  static ParsedAmount fromJson(Map<String, dynamic> json) {
    return ParsedAmount(
      raw: json['raw'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'raw': raw, 'value': value};
  }
}

/// Expense attachment (receipt file)
class ExpenseAttachment {
  final String path; // Cloud Storage path
  final DateTime uploadedAt;
  final String? name;

  ExpenseAttachment({
    required this.path,
    required this.uploadedAt,
    this.name,
  });

  /// Get filename from path
  String get fileName => name ?? path.split('/').last;

  static ExpenseAttachment fromJson(Map<String, dynamic> json) {
    return ExpenseAttachment(
      path: json['path'] ?? '',
      uploadedAt: _parseTimestamp(json['uploadedAt']),
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'uploadedAt': uploadedAt,
      'name': name,
    };
  }
}

/// Audit trail entry
class ExpenseAuditEntry {
  final String action; // ocr_created, edited, submitted, approved, rejected, paid
  final DateTime at;
  final String? by; // User ID

  ExpenseAuditEntry({
    required this.action,
    required this.at,
    this.by,
  });

  /// Get user-friendly action label
  String get actionLabel {
    switch (action) {
      case 'ocr_created':
        return 'OCR Extracted';
      case 'created':
        return 'Created';
      case 'edited':
        return 'Edited';
      case 'submitted':
        return 'Submitted';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'paid':
        return 'Paid';
      case 'deleted':
        return 'Deleted';
      default:
        return action.replaceAll('_', ' ');
    }
  }

  static ExpenseAuditEntry fromJson(Map<String, dynamic> json) {
    return ExpenseAuditEntry(
      action: json['action'] ?? 'unknown',
      at: _parseTimestamp(json['at']),
      by: json['by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'at': at,
      'by': by,
    };
  }
}

/// Approval task subcollection
/// Path: /users/{uid}/expenses/{expenseId}/approvals/{approvalId}
class ApprovalTask {
  final String status; // pending, approved, rejected
  final double expenseAmount;
  final String merchant;
  final String expenseDate;
  final DateTime createdAt;
  final bool notified;
  final DateTime? notifiedAt;
  final String? approvedBy;
  final DateTime? approvedAt;

  ApprovalTask({
    required this.status,
    required this.expenseAmount,
    required this.merchant,
    required this.expenseDate,
    required this.createdAt,
    required this.notified,
    this.notifiedAt,
    this.approvedBy,
    this.approvedAt,
  });

  static ApprovalTask fromJson(Map<String, dynamic> json) {
    return ApprovalTask(
      status: json['status'] ?? 'pending',
      expenseAmount: (json['expenseAmount'] ?? 0).toDouble(),
      merchant: json['merchant'] ?? '',
      expenseDate: json['expenseDate'] ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      notified: json['notified'] ?? false,
      notifiedAt: _parseTimestampNullable(json['notifiedAt']),
      approvedBy: json['approvedBy'],
      approvedAt: _parseTimestampNullable(json['approvedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'expenseAmount': expenseAmount,
      'merchant': merchant,
      'expenseDate': expenseDate,
      'createdAt': createdAt,
      'notified': notified,
      'notifiedAt': notifiedAt,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt,
    };
  }
}

// Helper functions

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

DateTime? _parseTimestampNullable(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return null;
}
