# Firestore Schema — Suppliers Collection

## Collection Path
```
users/{uid}/suppliers/{supplierId}
```

## Document Structure

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `string` | ✅ Yes | Supplier company name |
| `email` | `string \| null` | No | Contact email address |
| `phone` | `string \| null` | No | Contact phone number |
| `contact` | `string \| null` | No | Contact person name |
| `address` | `string \| null` | No | Full address (street, city, zip) |
| `currency` | `string \| null` | No | Currency code (e.g., "USD", "EUR") |
| `paymentTerms` | `string \| null` | No | Payment terms (e.g., "Net 30", "2/10 Net 30") |
| `leadTimeDays` | `number \| null` | No | Typical lead time in days |
| `preferred` | `boolean` | No | Favorite/preferred supplier flag (default: false) |
| `createdAt` | `timestamp` | ✅ Yes | Document creation timestamp |
| `updatedAt` | `timestamp` | ✅ Yes | Last update timestamp |
| `notes` | `string \| null` | No | Internal notes about supplier |
| `tags` | `array<string>` | No | Categorization tags (e.g., ["wholesale", "electronics"]) |

---

## Example Document

```json
{
  "name": "ACME Industrial Supplies",
  "email": "sales@acme.com",
  "phone": "+1-555-0123",
  "contact": "John Smith",
  "address": "123 Commerce St, New York, NY 10001",
  "currency": "USD",
  "paymentTerms": "Net 30",
  "leadTimeDays": 5,
  "preferred": true,
  "createdAt": {
    "_seconds": 1702156800,
    "_nanoseconds": 0
  },
  "updatedAt": {
    "_seconds": 1702156800,
    "_nanoseconds": 0
  },
  "notes": "Best pricing on bulk orders. Quality is consistent.",
  "tags": ["wholesale", "electronics", "competitive-pricing"]
}
```

---

## Firestore Security Rules

```javascript
match /users/{userId}/suppliers/{supplierId} {
  allow read, write: if request.auth.uid == userId;
  allow delete: if request.auth.uid == userId;
}
```

---

## Indexing

### Recommended Indexes

1. **Name Search (case-insensitive)**
   - Collection: `suppliers`
   - Fields: `name` (Ascending)
   - Use: Full-text search, autocomplete

2. **Preferred Suppliers**
   - Collection: `suppliers`
   - Fields: `preferred` (Descending), `createdAt` (Descending)
   - Use: List favorite suppliers first

3. **Tags Filter**
   - Collection: `suppliers`
   - Fields: `tags` (Ascending), `createdAt` (Descending)
   - Use: Filter by category/tag

4. **Lead Time Sort**
   - Collection: `suppliers`
   - Fields: `leadTimeDays` (Ascending), `name` (Ascending)
   - Use: Find fast suppliers

---

## Usage Patterns

### Create Supplier
```dart
final newSupplier = {
  'name': 'Widget Co',
  'email': 'contact@widget.co',
  'phone': '+1-555-9999',
  'contact': 'Jane Doe',
  'address': '456 Supply Ave, Boston, MA',
  'currency': 'USD',
  'paymentTerms': 'Net 45',
  'leadTimeDays': 7,
  'preferred': false,
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
  'notes': 'New supplier partnership',
  'tags': ['manufacturing', 'components']
};

await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .collection('suppliers')
  .add(newSupplier);
```

### Update Supplier
```dart
await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .collection('suppliers')
  .doc(supplierId)
  .update({
    'phone': '+1-555-1111',
    'paymentTerms': 'Net 60',
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

### Query Preferred Suppliers
```dart
final snapshot = await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .collection('suppliers')
  .where('preferred', isEqualTo: true)
  .orderBy('name')
  .get();
```

### Search by Tag
```dart
final snapshot = await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .collection('suppliers')
  .where('tags', arrayContains: 'wholesale')
  .orderBy('name')
  .get();
```

### Find Fast Suppliers (< 5 days lead time)
```dart
final snapshot = await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .collection('suppliers')
  .where('leadTimeDays', isLessThan: 5)
  .orderBy('leadTimeDays')
  .get();
```

---

## Data Model (Dart)

```dart
class Supplier {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? contact;
  final String? address;
  final String? currency;
  final String? paymentTerms;
  final int? leadTimeDays;
  final bool preferred;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final List<String> tags;

  Supplier({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.contact,
    this.address,
    this.currency,
    this.paymentTerms,
    this.leadTimeDays,
    this.preferred = false,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.tags = const [],
  });

  factory Supplier.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Supplier(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'],
      phone: data['phone'],
      contact: data['contact'],
      address: data['address'],
      currency: data['currency'],
      paymentTerms: data['paymentTerms'],
      leadTimeDays: data['leadTimeDays'],
      preferred: data['preferred'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      notes: data['notes'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'phone': phone,
    'contact': contact,
    'address': address,
    'currency': currency,
    'paymentTerms': paymentTerms,
    'leadTimeDays': leadTimeDays,
    'preferred': preferred,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'notes': notes,
    'tags': tags,
  };
}
```

---

## Integration with Inventory

### Link Item to Supplier
When creating/updating inventory items, store the supplier reference:

```dart
// In InventoryItem model
{
  'name': 'Widget A',
  'supplier': 'supplierId',      // Reference to Supplier doc ID
  'supplierName': 'ACME Corp',   // Denormalized for display
  'costPrice': 1.25,
  'leadDays': 5,                 // Denormalized from supplier
  ...
}
```

### Query Items by Supplier
```dart
final items = await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .collection('inventory')
  .where('supplier', isEqualTo: supplierId)
  .get();
```

---

## Validation Rules

### Name
- Required, non-empty string
- Max 100 characters
- Unique per user (recommended to enforce in app)

### Email
- Valid email format if provided
- Optional

### Phone
- Valid phone format if provided
- Optional

### Currency
- ISO 4217 code format (e.g., "USD", "EUR")
- Optional

### Lead Time
- Non-negative integer
- Days only
- Optional

### Tags
- Array of non-empty strings
- Max 10 tags per supplier
- Lowercase recommended for consistency

---

## Performance Considerations

1. **Name Search**: Index `name` field for quick lookups
2. **Preferred Filtering**: Index `preferred` + `createdAt` for dashboard queries
3. **Tag Filtering**: Use array-contains with index for category queries
4. **Real-time Listeners**: Subscribe to changes for live supplier list updates

---

## Migration from Existing System

If migrating from existing supplier data:

1. Export supplier list with required fields
2. Map old fields to new schema
3. Backfill timestamps (use current time for `createdAt`/`updatedAt`)
4. Generate missing UUIDs or use existing IDs
5. Validate data before import
6. Test queries with new schema

---

## Notes

- All user data is isolated by UID (no cross-user data exposure)
- Timestamps are server-generated for consistency
- Optional fields allow flexible supplier information
- Tags enable powerful filtering and categorization
- Denormalization in inventory items improves read performance
