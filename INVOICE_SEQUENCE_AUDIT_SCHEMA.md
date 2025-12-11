# Invoice Sequence Audit Collection

## Overview
The `invoice_sequence` collection stores a complete audit trail of all invoice number allocations. Each document represents a single invoice number assignment event, enabling comprehensive tracking and compliance reporting.

## Collection Path
```
/users/{uid}/invoice_sequence/{docId}
```

## Document Schema

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `invoiceNumber` | `string` | Yes | Formatted invoice number (e.g., "AURA-2025-1001") |
| `number` | `integer` | Yes | Sequential integer allocated (e.g., 1001) |
| `allocatedAt` | `Timestamp` | Yes | Server timestamp of allocation |
| `allocatedBy` | `string` | Yes | User UID who triggered allocation |
| `invoiceId` | `string` | No | Reference to invoice doc (optional) |
| `context` | `map` | No | Arbitrary metadata (e.g., `{"source": "mobile", "projectId": "..."}`) |

## Example Document

```json
{
  "invoiceNumber": "AURA-2025-1001",
  "number": 1001,
  "allocatedAt": "2025-12-02T14:23:45.123Z",
  "allocatedBy": "user_12345",
  "invoiceId": "invoice_67890",
  "context": {
    "source": "flutter_app",
    "projectId": "proj_abc123",
    "customField": "value"
  }
}
```

## Firestore Security Rules

### Read Access
Users can only read their own audit records:
```javascript
match /users/{uid}/invoice_sequence/{document=**} {
  allow read: if request.auth.uid == uid;
}
```

### Write Access
Only Cloud Functions (via server-side logic) should write to this collection:
```javascript
match /users/{uid}/invoice_sequence/{document=**} {
  allow write: if false;  // Firestore Rules deny writes; only functions can write
}
```

## Usage Patterns

### 1. View Complete Audit Trail
```dart
final service = InvoiceAuditService();
final records = await service.getAuditHistory(userId);
```

### 2. Track Invoice Allocations by Date
```dart
final records = await service.getAuditHistoryByDateRange(
  userId,
  DateTime(2025, 1, 1),
  DateTime(2025, 12, 31),
);
```

### 3. Verify Invoice Number Assignment
```dart
final record = await service.getAuditByInvoiceNumber(userId, "AURA-2025-1001");
if (record != null) {
  print("Allocated at: ${record['allocatedAt']}");
}
```

### 4. Link Audit Record to Invoice
```dart
// When creating an invoice, pass invoiceId to Cloud Function:
final result = await FirebaseFunctions.instance.httpsCallable('generateNextInvoiceNumber').call({
  'invoiceId': 'invoice_12345',
  'context': {'source': 'mobile'}
});
```

### 5. Real-Time Monitoring
```dart
final service = InvoiceAuditService();
service.watchAuditHistory(userId).listen((records) {
  print("New audit record: ${records.first['invoiceNumber']}");
});
```

## Cloud Function Integration

### Automatic Audit Logging
The `generateNextInvoiceNumber` Cloud Function automatically:
1. Allocates a unique invoice number
2. Writes an audit record atomically in the same transaction
3. Records the current timestamp, user ID, and optional context

**Function Location**: `functions/src/invoice/generateNextInvoiceNumber.ts`

### Audit Record Creation Code
```typescript
const auditRef = db.collection('users').doc(uid).collection('invoice_sequence').doc();
const auditPayload = {
  invoiceNumber: formatted,
  number: currentNumber,
  allocatedAt: nowTs,
  allocatedBy: uid,
  context: data?.context || null,
  invoiceId: data?.invoiceId || null
};
tx.set(auditRef, auditPayload);  // Written in same transaction
```

## Queries Supported

### By Service Methods
- **Last 100 allocations** (default): `getAuditHistory(uid)`
- **Date range filter**: `getAuditHistoryByDateRange(uid, start, end)`
- **By invoice number**: `getAuditByInvoiceNumber(uid, invoiceNumber)`
- **By invoice ID**: `getAuditByInvoiceId(uid, invoiceId)`
- **Total count**: `getAuditCount(uid)`
- **Real-time stream**: `watchAuditHistory(uid)`

### Direct Firestore Queries
```dart
// Get allocations from specific date
final snapshot = await FirebaseFirestore.instance
    .collection('users').doc(uid).collection('invoice_sequence')
    .where('allocatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
    .orderBy('allocatedAt', descending: true)
    .get();
```

## Indexes Required

For optimal query performance, create these composite indexes:

### Index 1: By Date (Descending)
```
Collection: invoice_sequence
Fields:
- allocatedAt (Descending)
```

### Index 2: By Invoice ID and Date
```
Collection: invoice_sequence
Fields:
- invoiceId (Ascending)
- allocatedAt (Descending)
```

### Index 3: By Invoice Number
```
Collection: invoice_sequence
Fields:
- invoiceNumber (Ascending)
```

Firestore will prompt to create these automatically when queries are first executed.

## Data Retention & Compliance

### Recommended Policies
- **Retention**: Keep indefinitely for audit compliance
- **Archival**: Export records older than 2 years to Cloud Storage annually
- **Deletion**: Only delete upon explicit user request (GDPR/CCPA)

### Export Example
```dart
// Export all audit records as CSV
final records = await service.getAuditHistory(userId);
final csv = records.map((r) => 
  '${r['invoiceNumber']},${r['number']},${r['allocatedAt']},${r['invoiceId']}'
).join('\n');
```

## Monitoring & Alerts

### Metrics to Track
- Invoice number allocation rate (per day/week/month)
- Audit record count growth
- Successful vs. failed allocations (track retries)
- Context patterns (which sources allocate most invoices)

### Example Dashboard Query
```dart
// Get allocation statistics for the month
final allRecords = await service.getAuditHistoryByDateRange(
  userId,
  DateTime.now().subtract(Duration(days: 30)),
  DateTime.now()
);
print("Invoices allocated: ${allRecords.length}");
```

## Troubleshooting

### No Records Found
- Verify user UID is correct
- Check Firestore collection path: `/users/{uid}/invoice_sequence/`
- Confirm user is authenticated before querying
- Check Cloud Function deployment: `generateNextInvoiceNumber`

### Audit Records Not Written
- Verify Cloud Function transaction logic
- Check function logs in Firebase Console
- Ensure Firestore write quota not exceeded
- Verify security rules allow Cloud Function writes

### Query Performance Issues
- Create required composite indexes
- Limit query range (avoid scanning entire collection)
- Use date range filters for large datasets
- Archive old records if collection grows beyond 100k documents

## API Reference

### InvoiceAuditService Methods

```dart
class InvoiceAuditService {
  // Get most recent 100 records
  Future<List<Map<String, dynamic>>> getAuditHistory(String uid)

  // Filter by date range
  Future<List<Map<String, dynamic>>> getAuditHistoryByDateRange(
    String uid,
    DateTime startDate,
    DateTime endDate,
  )

  // Find by invoice number
  Future<Map<String, dynamic>?> getAuditByInvoiceNumber(
    String uid,
    String invoiceNumber,
  )

  // Find by invoice ID
  Future<List<Map<String, dynamic>>> getAuditByInvoiceId(
    String uid,
    String invoiceId,
  )

  // Get total count
  Future<int> getAuditCount(String uid)

  // Real-time stream
  Stream<List<Map<String, dynamic>>> watchAuditHistory(String uid)
}
```

## Related Collections

- **`/users/{uid}/settings/invoice_settings`** - Current numbering configuration
- **`/users/{uid}/invoices/`** - Actual invoice documents (linked via `invoiceId`)
- **`/users/{uid}/auditLog/`** - Payment audit trail (separate from allocation audit)

## Integration Checklist

- [x] Collection schema defined
- [x] Cloud Function writes audit records atomically
- [x] InvoiceAuditService created with full query API
- [x] InvoiceAuditScreen displays records
- [x] Real-time streaming support implemented
- [ ] Firestore indexes created (auto-created on first query)
- [ ] Security rules enforced
- [ ] Production monitoring configured
- [ ] Data retention policy documented
- [ ] User privacy compliance verified
