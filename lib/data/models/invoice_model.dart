import 'package:cloud_firestore/cloud_firestore.dart';

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
  final double taxRate;  // 0.20 = 20%
  final String status;   // draft | sent | paid | overdue | canceled
  final String? invoiceNumber; // INV-2024-001
  final DateTime? dueDate;
  final DateTime? paidDate;
  final String? pdfUrl; // Firebase Storage URL for PDF
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final String? projectId; // Link to project
  final List<String>? linkedExpenseIds; // Expenses linked to this invoice
  final double discount; // Absolute discount amount
  final String? notes; // Additional invoice notes
  final Map<String, dynamic>? audit; // Audit trail

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
    this.paidDate,
    this.pdfUrl,
    this.updatedAt,
    this.projectId,
    this.linkedExpenseIds,
    this.discount = 0,
    this.notes,
    this.audit,
  });

  // Status helpers
  bool get isDraft => status == 'draft' || status == InvoiceStatus.draft.name;
  bool get isSent => status == 'sent' || status == InvoiceStatus.sent.name;
  bool get isPaid => status == 'paid' || status == InvoiceStatus.paid.name;
  bool get isOverdue => status == 'overdue' || status == InvoiceStatus.overdue.name;
  bool get isCanceled => status == 'cancelled' || status == InvoiceStatus.cancelled.name;

  // Expense linking
  bool get hasLinkedExpenses => linkedExpenseIds != null && linkedExpenseIds!.isNotEmpty;
  int get linkedExpenseCount => linkedExpenseIds?.length ?? 0;

  // Check if overdue
  bool get isCurrentlyOverdue => !isPaid && dueDate != null && DateTime.now().isAfter(dueDate!);

  // Total with discount applied
  double get totalWithDiscount => total - (discount ?? 0);

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
    required Timestamp createdAt,
    String? invoiceNumber,
    DateTime? dueDate,
    DateTime? paidDate,
    String? pdfUrl,
    Timestamp? updatedAt,
  }) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final tax = subtotal * taxRate;
    final total = subtotal + tax;

    return InvoiceModel(
      id: id,
      userId: userId,
      clientId: clientId,
      clientName: clientName,
      clientEmail: clientEmail,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      currency: currency,
      taxRate: taxRate,
      status: status,
      createdAt: createdAt,
      invoiceNumber: invoiceNumber,
      dueDate: dueDate,
      paidDate: paidDate,
      pdfUrl: pdfUrl,
      updatedAt: updatedAt,
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
    DateTime? paidDate,
    String? pdfUrl,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? projectId,
    List<String>? linkedExpenseIds,
    double? discount,
    String? notes,
    Map<String, dynamic>? audit,
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
      createdAt: createdAt ?? this.createdAt,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      projectId: projectId ?? this.projectId,
      linkedExpenseIds: linkedExpenseIds ?? this.linkedExpenseIds,
      discount: discount ?? this.discount,
      notes: notes ?? this.notes,
      audit: audit ?? this.audit,
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
      'dueDate': dueDate,
      'paidDate': paidDate,
      'pdfUrl': pdfUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
      'projectId': projectId,
      'linkedExpenseIds': linkedExpenseIds ?? [],
      'discount': discount,
      'notes': notes,
      'audit': audit ?? {},
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
      status: data['status'] ?? 'draft',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      invoiceNumber: data['invoiceNumber'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      paidDate: (data['paidDate'] as Timestamp?)?.toDate(),
      pdfUrl: data['pdfUrl'],
      updatedAt: data['updatedAt'],
      projectId: data['projectId'],
      linkedExpenseIds: data['linkedExpenseIds'] != null
          ? List<String>.from(data['linkedExpenseIds'] as List)
          : null,
      discount: (data['discount'] ?? 0).toDouble(),
      notes: data['notes'],
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
      status: json['status'] ?? 'draft',
      createdAt: json['createdAt'] is Timestamp
          ? json['createdAt']
          : Timestamp.fromDate(DateTime.parse(json['createdAt'] ?? DateTime.now().toString())),
      invoiceNumber: json['invoiceNumber'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      pdfUrl: json['pdfUrl'],
      updatedAt: json['updatedAt'] is Timestamp ? json['updatedAt'] : null,
      projectId: json['projectId'],
      linkedExpenseIds: json['linkedExpenseIds'] != null
          ? List<String>.from(json['linkedExpenseIds'] as List)
          : null,
      discount: (json['discount'] ?? 0).toDouble(),
      notes: json['notes'],
      audit: json['audit'],
    );
  }

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
      'paidDate': paidDate?.toIso8601String(),
      'pdfUrl': pdfUrl,
      'createdAt': createdAt.toDate().toIso8601String(),
      'updatedAt': updatedAt?.toDate().toIso8601String(),
      'projectId': projectId,
      'linkedExpenseIds': linkedExpenseIds ?? [],
      'discount': discount,
      'notes': notes,
      'audit': audit ?? {},
    };
  }

  /// Convert to map format required by Cloud Functions for export
  ///
  /// This method prepares invoice data for the exportInvoiceFormats
  /// and generateInvoicePdf Cloud Functions.
  ///
  /// Returns a map with all required fields:
  /// - invoiceNumber: Invoice identifier
  /// - createdAt: ISO8601 formatted date
  /// - dueDate: ISO8601 formatted due date
  /// - items: List of invoice items with all details
  /// - currency: Currency code (USD, EUR, etc.)
  /// - subtotal: Subtotal before tax
  /// - totalVat: Total VAT/tax amount
  /// - discount: Discount amount (if any)
  /// - total: Final total amount
  /// - businessName: Your company name
  /// - businessAddress: Your company address
  /// - clientName: Client name
  /// - clientEmail: Client email
  /// - clientAddress: Client address
  /// - notes: Invoice notes (optional)
  /// - status: Invoice status
  ///
  /// Example:
  /// ```dart
  /// final data = invoice.toMapForExport();
  /// final urls = await invoiceServiceClient.exportInvoiceAllFormats(data);
  /// ```
  Map<String, dynamic> toMapForExport({
    String businessName = 'Your Business',
    String businessAddress = '',
  }) {
    return {
      // Invoice metadata
      'invoiceNumber': invoiceNumber ?? id,
      'invoiceId': id,
      'createdAt': createdAt.toDate().toIso8601String(),
      'dueDate': (dueDate ?? DateTime.now().add(Duration(days: 30))).toIso8601String(),

      // Invoice items with full details
      'items': items
          .map((item) => {
                'id': item.toString().hashCode.toString(), // Generate ID if not present
                'name': item.description,
                'description': item.description,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'vatRate': taxRate, // Use invoice tax rate for items
                'total': item.total,
              })
          .toList(),

      // Financial details
      'currency': currency,
      'subtotal': subtotal,
      'totalVat': tax,
      'discount': discount ?? 0,
      'total': total,

      // Business information
      'businessName': businessName,
      'businessAddress': businessAddress,

      // Client information
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientAddress': '', // Not stored in current model, can be passed in

      // Additional details
      'notes': notes ?? '',
      'status': status,
      'taxRate': taxRate,
      'linkedExpenseIds': linkedExpenseIds ?? [],
    };
  }
}

/// Backward compatibility alias
typedef Invoice = InvoiceModel;


/// Individual invoice line item
class InvoiceItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  }) : total = quantity * unitPrice;

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    final qty = (map['quantity'] ?? 1).toDouble();
    final price = (map['unitPrice'] ?? 0).toDouble();
    return InvoiceItem(
      description: map['description'] ?? '',
      quantity: qty,
      unitPrice: price,
    );
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  double get price => unitPrice;
}

/// Invoice status enum
enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  cancelled;

  String get label {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  static InvoiceStatus fromString(String status) {
    return InvoiceStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => InvoiceStatus.draft,
    );
  }
}