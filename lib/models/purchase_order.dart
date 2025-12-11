import 'package:cloud_firestore/cloud_firestore.dart';

/// Purchase Order Line Item
class POItem {
  String? inventoryItemId;
  String name;
  String? sku;
  int qtyOrdered;
  int qtyReceived;
  double? costPrice;
  String? unit;

  POItem({
    this.inventoryItemId,
    required this.name,
    this.sku,
    required this.qtyOrdered,
    this.qtyReceived = 0,
    this.costPrice,
    this.unit,
  });

  factory POItem.fromMap(Map<String, dynamic> m) {
    return POItem(
      inventoryItemId: m['inventoryItemId'],
      name: m['name'] ?? '',
      sku: m['sku'],
      qtyOrdered: (m['qtyOrdered'] ?? 0),
      qtyReceived: (m['qtyReceived'] ?? 0),
      costPrice: m['costPrice'] != null ? (m['costPrice'] as num).toDouble() : null,
      unit: m['unit'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inventoryItemId': inventoryItemId,
      'name': name,
      'sku': sku,
      'qtyOrdered': qtyOrdered,
      'qtyReceived': qtyReceived,
      'costPrice': costPrice,
      'unit': unit,
    };
  }

  int get qtyPending => qtyOrdered - qtyReceived;
  bool get isFullyReceived => qtyReceived == qtyOrdered;
  double get lineTotal => (costPrice ?? 0) * qtyOrdered;
}

/// Purchase Order Document
class PurchaseOrder {
  final String id;
  final String supplierId;
  final String supplierName;
  final String poNumber;
  String status; // draft, sent, pending, partially_received, received, cancelled
  final String createdBy;
  final Timestamp createdAt;
  Timestamp? expectedDeliveryDate;
  final List<POItem> items;
  Map<String, dynamic>? subtotals;
  String? notes;

  PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.poNumber,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.items,
    this.expectedDeliveryDate,
    this.subtotals,
    this.notes,
  });

  factory PurchaseOrder.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final items = (d['items'] as List<dynamic>? ?? [])
        .map((i) => POItem.fromMap(Map<String, dynamic>.from(i)))
        .toList();
    return PurchaseOrder(
      id: doc.id,
      supplierId: d['supplierId'] ?? '',
      supplierName: d['supplierName'] ?? '',
      poNumber: d['poNumber'] ?? '',
      status: d['status'] ?? 'draft',
      createdBy: d['createdBy'] ?? '',
      createdAt: d['createdAt'] ?? Timestamp.now(),
      expectedDeliveryDate: d['expectedDeliveryDate'],
      items: items,
      subtotals: d['subtotals'],
      notes: d['notes'],
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'poNumber': poNumber,
      'status': status,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'expectedDeliveryDate': expectedDeliveryDate,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotals': subtotals,
      'notes': notes,
    };
  }

  bool get isReceivable => ['pending', 'partially_received'].contains(status);
  bool get isEditable =>
      ['draft', 'sent', 'pending', 'partially_received'].contains(status);
  bool get isPending => status == 'pending';
  bool get isFullyReceived => status == 'received';
  bool get isDraft => status == 'draft';
  bool get isCancelled => status == 'cancelled';
}

/// File attachment (PDF, image, etc.)
class POAttachment {
  final String url;
  final String name;

  POAttachment({required this.url, required this.name});

  factory POAttachment.fromMap(Map<String, dynamic> map) => POAttachment(
        url: map['url'] ?? '',
        name: map['name'] ?? '',
      );

  Map<String, dynamic> toMap() => {'url': url, 'name': name};
}

/// Link to stock movement (created when PO received)
class LinkedStockMovement {
  final String movementId;
  final String itemId;
  final int qty;
  final Timestamp createdAt;

  LinkedStockMovement({
    required this.movementId,
    required this.itemId,
    required this.qty,
    required this.createdAt,
  });

  factory LinkedStockMovement.fromMap(Map<String, dynamic> map) =>
      LinkedStockMovement(
        movementId: map['movementId'] ?? '',
        itemId: map['itemId'] ?? '',
        qty: map['qty'] ?? 0,
        createdAt: map['createdAt'] ?? Timestamp.now(),
      );

  Map<String, dynamic> toMap() => {
        'movementId': movementId,
        'itemId': itemId,
        'qty': qty,
        'createdAt': createdAt,
      };
}

/// File attachment (PDF, image, etc.)
class POAttachment {
  final String url;
  final String name;

  POAttachment({required this.url, required this.name});

  factory POAttachment.fromMap(Map<String, dynamic> map) => POAttachment(
        url: map['url'] ?? '',
        name: map['name'] ?? '',
      );

  Map<String, dynamic> toMap() => {'url': url, 'name': name};
}

/// Link to stock movement (created when PO received)
class LinkedStockMovement {
  final String movementId;
  final String itemId;
  final int qty;
  final Timestamp createdAt;

  LinkedStockMovement({
    required this.movementId,
    required this.itemId,
    required this.qty,
    required this.createdAt,
  });

  factory LinkedStockMovement.fromMap(Map<String, dynamic> map) =>
      LinkedStockMovement(
        movementId: map['movementId'] ?? '',
        itemId: map['itemId'] ?? '',
        qty: map['qty'] ?? 0,
        createdAt: map['createdAt'] ?? Timestamp.now(),
      );

  Map<String, dynamic> toMap() => {
        'movementId': movementId,
        'itemId': itemId,
        'qty': qty,
        'createdAt': createdAt,
      };
}
