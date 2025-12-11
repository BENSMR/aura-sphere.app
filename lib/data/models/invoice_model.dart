import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceStatus { draft, sent, paid, unpaid, overdue, partial, cancelled }

class InvoiceItem {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final String? unit;
  final double? discount; // Optional line item discount

  InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.unit,
    this.discount,
  });

  double get total => (quantity * unitPrice) - (discount ?? 0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unit': unit,
      'discount': discount,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      unit: map['unit'],
      discount: map['discount']?.toDouble(),
    );
  }
}

class InvoiceModel {
  final String id;
  final String userId;
  final String clientId;
  final String clientName;
  final String clientEmail;

  final List<InvoiceItem> items;
  final double subtotal;
  final double tax;
  final double total;

  final String currency; // "USD", "EUR", "MAD", etc.
  final double taxRate; // 0.20 = 20%
  final String status; // unpaid | paid | overdue
  final String? invoiceNumber; // INV-2024-001
  final DateTime? dueDate;
  final DateTime? paymentDate;
  final DateTime? paidDate; // Legacy field for PDF export
  final DateTime? paidAt; // When invoice was marked as paid
  final String? pdfUrl; // Firebase Storage URL for PDF
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastReminderAt; // When last reminder was sent
  final String? projectId; // Link to project
  final List<String>? linkedExpenseIds; // Expenses linked to this invoice
  final double discount; // Absolute discount amount
  final String? notes; // Additional invoice notes
  final Map<String, dynamic>? audit; // Audit trail
  final String? paymentMethod; // Payment method used

  InvoiceModel({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.currency,
    required this.taxRate,
    required this.status,
    required this.createdAt,
    this.invoiceNumber,
    this.dueDate,
    this.paymentDate,
    this.paidDate,
    this.paidAt,
    this.pdfUrl,
    this.updatedAt,
    this.lastReminderAt,
    this.projectId,
    this.linkedExpenseIds,
    this.discount = 0,
    this.notes,
    this.audit,
    this.paymentMethod,
  });

  // Status helpers
  bool get isDraft => status == 'draft' || status == InvoiceStatus.draft.name;
  bool get isSent => status == 'sent' || status == InvoiceStatus.sent.name;
  bool get isPaid => status == 'paid' || status == InvoiceStatus.paid.name;
  bool get isUnpaid => status == 'unpaid';
  bool get isPartial => status == 'partial';
  bool get isOverdue => status == 'overdue' || status == InvoiceStatus.overdue.name;
  bool get isCanceled => status == 'cancelled' || status == 'canceled' || status == InvoiceStatus.cancelled.name;

  // Expense linking
  bool get hasLinkedExpenses => linkedExpenseIds != null && linkedExpenseIds!.isNotEmpty;
  int get linkedExpenseCount => linkedExpenseIds?.length ?? 0;

  // Check if overdue
  bool get isCurrentlyOverdue => !isPaid && dueDate != null && DateTime.now().isAfter(dueDate!);

  // Total with discount applied
  double get totalWithDiscount => total - (discount ?? 0);

  // Days until or since due date
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    return dueDate!.difference(now).inDays;
  }

  /// Calculate totals from items and tax rate
  static InvoiceModel calculateTotals({
    required String id,
    required String userId,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required List<InvoiceItem> items,
    required String currency,
    required double taxRate,
    required String status,
    required DateTime createdAt,
    String? invoiceNumber,
    DateTime? dueDate,
    DateTime? paymentDate,
    DateTime? paidDate,
    DateTime? paidAt,
    String? pdfUrl,
    DateTime? updatedAt,
    DateTime? lastReminderAt,
    String? projectId,
    List<String>? linkedExpenseIds,
    double discount = 0,
    String? notes,
    String? paymentMethod,
  }) {
    final itemSubtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final calculatedSubtotal = itemSubtotal - (discount ?? 0);
    final calculatedTax = calculatedSubtotal * taxRate;
    final calculatedTotal = calculatedSubtotal + calculatedTax;

    return InvoiceModel(
      id: id,
      userId: userId,
      clientId: clientId,
      clientName: clientName,
      clientEmail: clientEmail,
      items: items,
      subtotal: calculatedSubtotal,
      tax: calculatedTax,
      total: calculatedTotal,
      currency: currency,
      taxRate: taxRate,
      status: status,
      invoiceNumber: invoiceNumber,
      dueDate: dueDate,
      paymentDate: paymentDate,
      paidDate: paidDate,
      paidAt: paidAt,
      pdfUrl: pdfUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastReminderAt: lastReminderAt,
      projectId: projectId,
      linkedExpenseIds: linkedExpenseIds,
      discount: discount,
      notes: notes,
      paymentMethod: paymentMethod,
    );
  }

  /// Create a copy with modifications
  InvoiceModel copyWith({
    String? id,
    String? userId,
    String? clientId,
    String? clientName,
    String? clientEmail,
    List<InvoiceItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? currency,
    double? taxRate,
    String? status,
    String? invoiceNumber,
    DateTime? dueDate,
    DateTime? paymentDate,
    DateTime? paidDate,
    DateTime? paidAt,
    String? pdfUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastReminderAt,
    String? projectId,
    List<String>? linkedExpenseIds,
    double? discount,
    String? notes,
    Map<String, dynamic>? audit,
    String? paymentMethod,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      taxRate: taxRate ?? this.taxRate,
      status: status ?? this.status,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      dueDate: dueDate ?? this.dueDate,
      paymentDate: paymentDate ?? this.paymentDate,
      paidDate: paidDate ?? this.paidDate,
      paidAt: paidAt ?? this.paidAt,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReminderAt: lastReminderAt ?? this.lastReminderAt,
      projectId: projectId ?? this.projectId,
      linkedExpenseIds: linkedExpenseIds ?? this.linkedExpenseIds,
      discount: discount ?? this.discount,
      notes: notes ?? this.notes,
      audit: audit ?? this.audit,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'currency': currency,
      'taxRate': taxRate,
      'status': status,
      'invoiceNumber': invoiceNumber,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'pdfUrl': pdfUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastReminderAt': lastReminderAt != null ? Timestamp.fromDate(lastReminderAt!) : null,
      'projectId': projectId,
      'linkedExpenseIds': linkedExpenseIds,
      'discount': discount,
      'notes': notes,
      'paymentMethod': paymentMethod,
      'audit': audit,
    };
  }

  /// Create from Firestore document
  factory InvoiceModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceModel(
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      taxRate: (data['taxRate'] ?? 0).toDouble(),
      status: data['status'] ?? 'unpaid',
      invoiceNumber: data['invoiceNumber'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      paymentDate: (data['paymentDate'] as Timestamp?)?.toDate(),
      paidDate: (data['paidDate'] as Timestamp?)?.toDate(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      pdfUrl: data['pdfUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastReminderAt: (data['lastReminderAt'] as Timestamp?)?.toDate(),
      projectId: data['projectId'],
      linkedExpenseIds: List<String>.from(data['linkedExpenseIds'] ?? []),
      discount: (data['discount'] ?? 0).toDouble(),
      notes: data['notes'],
      paymentMethod: data['paymentMethod'],
      audit: data['audit'],
    );
  }

  /// Create from JSON
  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'] ?? '',
      clientEmail: json['clientEmail'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      taxRate: (json['taxRate'] ?? 0).toDouble(),
      status: json['status'] ?? 'unpaid',
      invoiceNumber: json['invoiceNumber'],
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] is Timestamp
              ? (json['dueDate'] as Timestamp).toDate()
              : DateTime.parse(json['dueDate'] as String))
          : null,
      paymentDate: json['paymentDate'] != null
          ? (json['paymentDate'] is Timestamp
              ? (json['paymentDate'] as Timestamp).toDate()
              : DateTime.parse(json['paymentDate'] as String))
          : null,
      paidDate: json['paidDate'] != null
          ? (json['paidDate'] is Timestamp
              ? (json['paidDate'] as Timestamp).toDate()
              : DateTime.parse(json['paidDate'] as String))
          : null,
      paidAt: json['paidAt'] != null
          ? (json['paidAt'] is Timestamp
              ? (json['paidAt'] as Timestamp).toDate()
              : DateTime.parse(json['paidAt'] as String))
          : null,
      pdfUrl: json['pdfUrl'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['updatedAt'] as String))
          : null,
      lastReminderAt: json['lastReminderAt'] != null
          ? (json['lastReminderAt'] is Timestamp
              ? (json['lastReminderAt'] as Timestamp).toDate()
              : DateTime.parse(json['lastReminderAt'] as String))
          : null,
      projectId: json['projectId'],
      linkedExpenseIds: List<String>.from(json['linkedExpenseIds'] ?? []),
      discount: (json['discount'] ?? 0).toDouble(),
      notes: json['notes'],
      paymentMethod: json['paymentMethod'],
      audit: json['audit'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'currency': currency,
      'taxRate': taxRate,
      'status': status,
      'invoiceNumber': invoiceNumber,
      'dueDate': dueDate?.toIso8601String(),
      'paymentDate': paymentDate?.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'pdfUrl': pdfUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastReminderAt': lastReminderAt?.toIso8601String(),
      'projectId': projectId,
      'linkedExpenseIds': linkedExpenseIds,
      'discount': discount,
      'notes': notes,
      'paymentMethod': paymentMethod,
    };
  }

  /// Export as map for Excel/CSV
  Map<String, dynamic> toMapForExport({
    String businessName = '',
    String businessAddress = '',
  }) {
    return {
      'businessName': businessName,
      'businessAddress': businessAddress,
      'invoiceNumber': invoiceNumber,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'amount': total,
      'currency': currency,
      'status': status,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'itemCount': items.length,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
    };
  }
}