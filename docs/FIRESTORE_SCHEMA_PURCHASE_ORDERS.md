# Firestore Schema — Purchase Orders Collection

## Collection Path
```
users/{uid}/purchase_orders/{poId}
```

## Document Structure

### Root Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `supplierId` | `string` | ✅ Yes | Reference to `users/{uid}/suppliers/{supplierId}` |
| `supplierName` | `string` | ✅ Yes | Denormalized supplier name (snapshot) |
| `poNumber` | `string` | ✅ Yes | Human-friendly PO number (e.g., "PO-2025-001") |
| `status` | `string` | ✅ Yes | Status enum: `draft`, `sent`, `pending`, `partially_received`, `received`, `cancelled` |
| `createdBy` | `string` | ✅ Yes | UID of creator |
| `createdAt` | `timestamp` | ✅ Yes | Document creation timestamp (server-generated) |
| `expectedDeliveryDate` | `timestamp \| null` | No | Expected delivery date |
| `receivedAt` | `timestamp \| null` | No | Actual receipt timestamp |
| `receivedBy` | `string \| null` | No | UID of person who received (staff member) |
| `currency` | `string` | ✅ Yes | Currency code (USD, EUR, etc.) |
| `paymentTerms` | `string \| null` | No | Payment terms snapshot from supplier |
| `notes` | `string \| null` | No | Internal notes about PO |
| `subtotals` | `object` | ✅ Yes | Pricing breakdown |
| `items` | `array<object>` | ✅ Yes | Line items array (min 1 item) |
| `attachments` | `array<object>` | No | File references (PDFs, images) |
| `linkedStockMovements` | `array<object>` | No | Stock movements created on receive |

---

## Nested Objects

### Subtotals Object
```json
{
  "itemsTotal": 1250.00,
  "tax": 125.00,
  "shipping": 50.00,
  "total": 1425.00
}
```

| Field | Type | Description |
|-------|------|-------------|
| `itemsTotal` | `number` | Sum of (qty × costPrice) |
| `tax` | `number` | Tax amount |
| `shipping` | `number` | Shipping cost (default: 0) |
| `total` | `number` | Grand total (itemsTotal + tax + shipping) |

### Items Array Element
```json
{
  "name": "Widget A",
  "sku": "WIDG-001",
  "qtyOrdered": 100,
  "qtyReceived": 0,
  "costPrice": 12.50,
  "unit": "pcs",
  "inventoryItemId": "inv_abc123"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `string` | ✅ Yes | Product name |
| `sku` | `string \| null` | No | Product SKU |
| `qtyOrdered` | `number` | ✅ Yes | Quantity ordered (≥ 1) |
| `qtyReceived` | `number` | ✅ Yes | Quantity received (start: 0) |
| `costPrice` | `number \| null` | No | Unit cost (used for totals) |
| `unit` | `string \| null` | No | Unit of measure (pcs, kg, L, etc.) |
| `inventoryItemId` | `string \| null` | No | Link to inventory item if exists |

### Attachments Array Element
```json
{
  "url": "gs://bucket/users/{uid}/po/{poId}/po-2025-001.pdf",
  "name": "PO-2025-001.pdf"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `url` | `string` | ✅ Yes | Firebase Storage URL |
| `name` | `string` | ✅ Yes | Display filename |

### Stock Movements Array Element
```json
{
  "movementId": "mov_xyz789",
  "itemId": "inv_abc123",
  "qty": 50,
  "createdAt": {...}
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `movementId` | `string` | ✅ Yes | Reference to `inventory/{itemId}/stock_movements/{movId}` |
| `itemId` | `string` | ✅ Yes | Inventory item ID |
| `qty` | `number` | ✅ Yes | Quantity added to stock |
| `createdAt` | `timestamp` | ✅ Yes | When stock movement was recorded |

---

## Example Document

```json
{
  "supplierId": "supp_acme123",
  "supplierName": "ACME Industrial Supplies",
  "poNumber": "PO-2025-001",
  "status": "pending",
  "createdBy": "user_123",
  "createdAt": {
    "_seconds": 1702156800,
    "_nanoseconds": 0
  },
  "expectedDeliveryDate": {
    "_seconds": 1702329600,
    "_nanoseconds": 0
  },
  "receivedAt": null,
  "receivedBy": null,
  "currency": "USD",
  "paymentTerms": "Net 30",
  "notes": "Rush order. Contact John if delays.",
  "subtotals": {
    "itemsTotal": 2500.00,
    "tax": 250.00,
    "shipping": 50.00,
    "total": 2800.00
  },
  "items": [
    {
      "name": "Widget A",
      "sku": "WIDG-001",
      "qtyOrdered": 100,
      "qtyReceived": 0,
      "costPrice": 12.50,
      "unit": "pcs",
      "inventoryItemId": "inv_abc123"
    },
    {
      "name": "Fastener Kit",
      "sku": "FAST-KIT",
      "qtyOrdered": 50,
      "qtyReceived": 0,
      "costPrice": 25.00,
      "unit": "box",
      "inventoryItemId": null
    }
  ],
  "attachments": [
    {
      "url": "gs://bucket/users/user_123/po/po_xyz789/po-2025-001.pdf",
      "name": "PO-2025-001.pdf"
    }
  ],
  "linkedStockMovements": []
}
```

---

## Firestore Security Rules

```javascript
match /users/{userId}/purchase_orders/{poId} {
  allow read: if request.auth.uid == userId;
  allow create: if request.auth.uid == userId
                && request.resource.data.createdBy == userId
                && validatePOCreate();
  allow update: if request.auth.uid == userId
                && request.resource.data.createdBy == resource.data.createdBy
                && validatePOUpdate();
  allow delete: if request.auth.uid == userId
                && resource.data.status in ['draft', 'cancelled'];
}

function validatePOCreate() {
  let data = request.resource.data;
  return data.keys().hasAll(['supplierId', 'supplierName', 'poNumber', 'status', 'createdBy', 'createdAt', 'currency', 'subtotals', 'items'])
         && data.supplierId is string && data.supplierId.size() > 0
         && data.supplierName is string && data.supplierName.size() > 0
         && data.poNumber is string && data.poNumber.size() > 0
         && data.status is string && ['draft', 'sent', 'pending', 'partially_received', 'received', 'cancelled'].hasAny([data.status])
         && data.currency is string && data.currency.size() > 0
         && data.items is list && data.items.size() > 0
         && validateSubtotals(data.subtotals)
         && data.createdAt is timestamp;
}

function validatePOUpdate() {
  let data = request.resource.data;
  let existing = resource.data;
  return data.createdBy == existing.createdBy
         && data.createdAt == existing.createdAt
         && data.poNumber == existing.poNumber
         && data.status is string && ['draft', 'sent', 'pending', 'partially_received', 'received', 'cancelled'].hasAny([data.status])
         && data.currency is string && data.currency.size() > 0
         && data.items is list && data.items.size() > 0
         && validateSubtotals(data.subtotals)
         && (data.expectedDeliveryDate == null || data.expectedDeliveryDate is timestamp)
         && (data.receivedAt == null || data.receivedAt is timestamp)
         && (data.receivedBy == null || data.receivedBy is string);
}

function validateSubtotals(subtotals) {
  return subtotals is map
         && subtotals.keys().hasAll(['itemsTotal', 'tax', 'total'])
         && subtotals.itemsTotal is number && subtotals.itemsTotal >= 0
         && subtotals.tax is number && subtotals.tax >= 0
         && subtotals.total is number && subtotals.total >= 0
         && subtotals.total == (subtotals.itemsTotal + subtotals.tax + (subtotals.shipping == null ? 0 : subtotals.shipping));
}
```

---

## Status Workflow

```
draft → sent → pending → partially_received → received
                         ↓
                    cancelled (at any point)
```

| Status | Description | Editable? | Receivable? |
|--------|-------------|-----------|------------|
| `draft` | Not sent to supplier | ✅ Yes | ❌ No |
| `sent` | Sent to supplier | ✅ Yes | ❌ No |
| `pending` | Awaiting delivery | ✅ Yes | ✅ Yes |
| `partially_received` | Some items received | ✅ Yes | ✅ Yes |
| `received` | All items received | ❌ No | ❌ No |
| `cancelled` | PO cancelled | ❌ No | ❌ No |

---

## Indexing

### Recommended Indexes

1. **Status + Created Date**
   - Collection: `purchase_orders`
   - Fields: `status` (Ascending), `createdAt` (Descending)
   - Use: Filter by status with latest first

2. **Supplier + Status**
   - Collection: `purchase_orders`
   - Fields: `supplierId` (Ascending), `status` (Ascending)
   - Use: Show supplier's pending orders

3. **Expected Delivery Date**
   - Collection: `purchase_orders`
   - Fields: `expectedDeliveryDate` (Ascending), `status` (Ascending)
   - Use: Show overdue orders

4. **Creator**
   - Collection: `purchase_orders`
   - Fields: `createdBy` (Ascending), `createdAt` (Descending)
   - Use: Show user's orders

---

## Usage Patterns

### Create Purchase Order
```dart
final newPO = {
  'supplierId': 'supp_acme123',
  'supplierName': 'ACME Corp',
  'poNumber': 'PO-2025-001',
  'status': 'draft',
  'createdBy': uid,
  'createdAt': FieldValue.serverTimestamp(),
  'currency': 'USD',
  'paymentTerms': 'Net 30',
  'notes': 'Rush delivery',
  'subtotals': {
    'itemsTotal': 1000.00,
    'tax': 100.00,
    'shipping': 0,
    'total': 1100.00,
  },
  'items': [
    {
      'name': 'Widget A',
      'sku': 'WIDG-001',
      'qtyOrdered': 100,
      'qtyReceived': 0,
      'costPrice': 10.00,
      'unit': 'pcs',
      'inventoryItemId': null,
    }
  ],
  'attachments': [],
  'linkedStockMovements': [],
};

final docRef = await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .collection('purchase_orders')
  .add(newPO);
```

### Update Status
```dart
await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .collection('purchase_orders')
  .doc(poId)
  .update({
    'status': 'sent',
  });
```

### Receive Items
```dart
await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .collection('purchase_orders')
  .doc(poId)
  .update({
    'status': 'received',
    'receivedAt': FieldValue.serverTimestamp(),
    'receivedBy': uid,
    'items': [
      // Update qtyReceived for each item
      { ...existingItem, 'qtyReceived': 100 }
    ],
    'linkedStockMovements': [
      // Add stock movement records
      { 'movementId': 'mov_123', 'itemId': 'inv_456', 'qty': 100, 'createdAt': FieldValue.serverTimestamp() }
    ],
  });
```

### Query Pending Orders
```dart
final snapshot = await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .collection('purchase_orders')
  .where('status', isEqualTo: 'pending')
  .orderBy('expectedDeliveryDate')
  .get();
```

### Query by Supplier
```dart
final snapshot = await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .collection('purchase_orders')
  .where('supplierId', isEqualTo: supplierId)
  .where('status', isNotEqualTo: 'cancelled')
  .orderBy('status')
  .orderBy('createdAt', descending: true)
  .get();
```

---

## Data Model (Dart) - PurchaseOrder

```dart
class PurchaseOrder {
  final String id;
  final String supplierId;
  final String supplierName;
  final String poNumber;
  final String status; // draft, sent, pending, partially_received, received, cancelled
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expectedDeliveryDate;
  final DateTime? receivedAt;
  final String? receivedBy;
  final String currency;
  final String? paymentTerms;
  final String? notes;
  final POSubtotals subtotals;
  final List<POItem> items;
  final List<POAttachment> attachments;
  final List<LinkedStockMovement> linkedStockMovements;

  PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.poNumber,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.expectedDeliveryDate,
    this.receivedAt,
    this.receivedBy,
    required this.currency,
    this.paymentTerms,
    this.notes,
    required this.subtotals,
    required this.items,
    List<POAttachment>? attachments,
    List<LinkedStockMovement>? linkedStockMovements,
  })  : attachments = attachments ?? [],
        linkedStockMovements = linkedStockMovements ?? [];

  factory PurchaseOrder.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchaseOrder(
      id: doc.id,
      supplierId: data['supplierId'] ?? '',
      supplierName: data['supplierName'] ?? '',
      poNumber: data['poNumber'] ?? '',
      status: data['status'] ?? 'draft',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expectedDeliveryDate: data['expectedDeliveryDate'] != null
          ? (data['expectedDeliveryDate'] as Timestamp).toDate()
          : null,
      receivedAt: data['receivedAt'] != null
          ? (data['receivedAt'] as Timestamp).toDate()
          : null,
      receivedBy: data['receivedBy'],
      currency: data['currency'] ?? 'USD',
      paymentTerms: data['paymentTerms'],
      notes: data['notes'],
      subtotals: POSubtotals.fromMap(data['subtotals'] ?? {}),
      items: ((data['items'] ?? []) as List)
          .map((i) => POItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      attachments: ((data['attachments'] ?? []) as List)
          .map((a) => POAttachment.fromMap(a as Map<String, dynamic>))
          .toList(),
      linkedStockMovements: ((data['linkedStockMovements'] ?? []) as List)
          .map((m) => LinkedStockMovement.fromMap(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMapForCreate() => {
    'supplierId': supplierId,
    'supplierName': supplierName,
    'poNumber': poNumber,
    'status': status,
    'createdBy': createdBy,
    'createdAt': FieldValue.serverTimestamp(),
    'expectedDeliveryDate': expectedDeliveryDate,
    'receivedAt': receivedAt,
    'receivedBy': receivedBy,
    'currency': currency,
    'paymentTerms': paymentTerms,
    'notes': notes,
    'subtotals': subtotals.toMap(),
    'items': items.map((i) => i.toMap()).toList(),
    'attachments': attachments.map((a) => a.toMap()).toList(),
    'linkedStockMovements': linkedStockMovements.map((m) => m.toMap()).toList(),
  };

  Map<String, dynamic> toMapForUpdate() => {
    'supplierName': supplierName,
    'status': status,
    'expectedDeliveryDate': expectedDeliveryDate,
    'receivedAt': receivedAt,
    'receivedBy': receivedBy,
    'paymentTerms': paymentTerms,
    'notes': notes,
    'subtotals': subtotals.toMap(),
    'items': items.map((i) => i.toMap()).toList(),
    'attachments': attachments.map((a) => a.toMap()).toList(),
    'linkedStockMovements': linkedStockMovements.map((m) => m.toMap()).toList(),
  };

  bool get isReceivable => ['pending', 'partially_received'].contains(status);
  bool get isEditable => ['draft', 'sent', 'pending', 'partially_received'].contains(status);
  bool get isPending => status == 'pending';
  bool get isFullyReceived => status == 'received';
}
```

### Supporting Classes

```dart
class POSubtotals {
  final double itemsTotal;
  final double tax;
  final double shipping;
  final double total;

  POSubtotals({
    required this.itemsTotal,
    required this.tax,
    required this.shipping,
    required this.total,
  });

  factory POSubtotals.fromMap(Map<String, dynamic> map) => POSubtotals(
    itemsTotal: (map['itemsTotal'] ?? 0).toDouble(),
    tax: (map['tax'] ?? 0).toDouble(),
    shipping: (map['shipping'] ?? 0).toDouble(),
    total: (map['total'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'itemsTotal': itemsTotal,
    'tax': tax,
    'shipping': shipping,
    'total': total,
  };
}

class POItem {
  final String name;
  final String? sku;
  final int qtyOrdered;
  final int qtyReceived;
  final double? costPrice;
  final String? unit;
  final String? inventoryItemId;

  POItem({
    required this.name,
    this.sku,
    required this.qtyOrdered,
    required this.qtyReceived,
    this.costPrice,
    this.unit,
    this.inventoryItemId,
  });

  factory POItem.fromMap(Map<String, dynamic> map) => POItem(
    name: map['name'] ?? '',
    sku: map['sku'],
    qtyOrdered: map['qtyOrdered'] ?? 0,
    qtyReceived: map['qtyReceived'] ?? 0,
    costPrice: map['costPrice'] != null ? (map['costPrice'] as num).toDouble() : null,
    unit: map['unit'],
    inventoryItemId: map['inventoryItemId'],
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'sku': sku,
    'qtyOrdered': qtyOrdered,
    'qtyReceived': qtyReceived,
    'costPrice': costPrice,
    'unit': unit,
    'inventoryItemId': inventoryItemId,
  };

  int get qtyPending => qtyOrdered - qtyReceived;
  bool get isFullyReceived => qtyReceived == qtyOrdered;
}

class POAttachment {
  final String url;
  final String name;

  POAttachment({required this.url, required this.name});

  factory POAttachment.fromMap(Map<String, dynamic> map) =>
      POAttachment(url: map['url'] ?? '', name: map['name'] ?? '');

  Map<String, dynamic> toMap() => {'url': url, 'name': name};
}

class LinkedStockMovement {
  final String movementId;
  final String itemId;
  final int qty;
  final DateTime createdAt;

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
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
    'movementId': movementId,
    'itemId': itemId,
    'qty': qty,
    'createdAt': createdAt,
  };
}
```

---

## Integration with Suppliers & Inventory

### Supplier Link
```dart
// When creating PO:
final supplier = suppliers.firstWhere((s) => s.id == supplierId);
final po = PurchaseOrder(
  supplierId: supplier.id,
  supplierName: supplier.name,  // Snapshot at time of creation
  paymentTerms: supplier.paymentTerms,  // Snapshot supplier terms
  // ...
);
```

### Inventory Link
```dart
// When receiving PO items:
for (final item in po.items) {
  if (item.inventoryItemId != null) {
    // Update inventory stock
    await inventoryService.addStock(
      itemId: item.inventoryItemId!,
      qty: item.qtyReceived,
      note: 'Received from PO-${po.poNumber}',
    );
    
    // Record stock movement
    final movRef = await stockMovementService.create(
      itemId: item.inventoryItemId!,
      qty: item.qtyReceived,
      type: 'inbound',
      reference: 'PO-${po.poNumber}',
    );
    
    // Link in PO
    linkedStockMovements.add(
      LinkedStockMovement(
        movementId: movRef.id,
        itemId: item.inventoryItemId!,
        qty: item.qtyReceived,
        createdAt: DateTime.now(),
      ),
    );
  }
}
```

---

## Performance Considerations

1. **Snapshot Fields** — `supplierName` is snapshotted (not joined on read)
   - Pro: Fast display, historical accuracy
   - Con: Must update when supplier name changes
   - Solution: Use Cloud Function to backfill old POs if needed

2. **Items Array** — Stored inline (not subcollection)
   - Pro: Atomic updates, all data in one fetch
   - Con: Limited to 1MB per document
   - Typical: 100-200 items per PO → Safe

3. **Stock Movements** — Linked by ID (reference only)
   - Pro: No data duplication
   - Con: Requires join to see full movement details
   - Solution: Load movement details on demand in detail screen

---

## Migration & Backfill

If migrating from existing PO system:

1. Export old POs with supplier references
2. Enrich with supplier snapshots (name, payment terms)
3. Map item SKUs to inventory IDs where applicable
4. Backfill `linkedStockMovements` from stock audit
5. Validate totals in Cloud Function before import

---

## Future Enhancements

- [ ] PO templates (recurring orders)
- [ ] Approval workflow (multi-step authorization)
- [ ] Supplier performance scoring (on-time delivery %, quality)
- [ ] Bulk receive with barcode scanning
- [ ] Email/PDF generation for supplier
- [ ] Partial returns & credit memos
- [ ] Invoice matching (3-way match: PO → Receipt → Invoice)

