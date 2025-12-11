# Tax Queue System Documentation

## Overview

The **Tax Queue** is the backbone of AuraSphere Pro's asynchronous tax calculation system. It decouples real-time entity creation from background tax processing, enabling:

- ✅ Instant invoice/expense creation (user sees result immediately)
- ✅ Batch tax calculation every 1 minute (processTaxQueue)
- ✅ Retry logic with error tracking
- ✅ Audit trail of all tax calculations
- ✅ Rate limiting and scalability

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ User creates Invoice (Flutter UI)                          │
│ POST /invoices → Firestore writes immediately              │
│ Response: {id, status: 'draft', taxStatus: 'queued'}       │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ onInvoiceCreateAutoAssign Trigger                          │
│ - Creates queue request in internal/tax_queue/requests     │
│ - Updates invoice: taxStatus = 'queued'                    │
│ - Returns to client immediately                            │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ├─ Client polls: GET /invoices/{id} (optional)
                   │  Shows: "Calculating tax..."
                   │
                   ▼
        (Wait up to 1 minute)
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ processTaxQueue Scheduled Function (every 1 minute)        │
│                                                             │
│ 1. Query: internal/tax_queue/requests WHERE processed==f   │
│ 2. Fetch up to 10 unprocessed requests                     │
│ 3. For each request:                                       │
│    a. Load entity from Firestore (invoice/expense/PO)      │
│    b. Call determineTaxLogic():                            │
│       - Load Company (companyId) → seller country/VAT      │
│       - Load Contact (contactId) → buyer country/type      │
│       - Look up config/tax_matrix/{country}                │
│       - Apply tax rule (reverse charge if B2B)             │
│    c. Update entity with:                                  │
│       { taxRate, taxAmount, total, taxCountry,             │
│         taxBreakdown, taxCalculatedBy, taxStatus }         │
│    d. Mark queue request: processed = true                 │
│    e. Log audit trail                                      │
│ 4. Return success count                                    │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ Real-time Updates (Flutter Listeners)                      │
│                                                             │
│ FinanceInvoiceProvider listens to:                         │
│   users/{uid}/invoices/{invoiceId}                         │
│                                                             │
│ Detects: taxStatus 'queued' → 'calculated'                │
│ Updates UI: Shows tax breakdown                            │
│ Calls: notifyListeners() → triggers rebuild                │
└─────────────────────────────────────────────────────────────┘
```

---

## Firestore Schema

### Queue Request Collection

**Path:** `internal/tax_queue/requests/{requestId}`

**Document Structure:**

```firestore
{
  uid: "user-123",
  entityPath: "users/user-123/invoices/inv-456",
  entityType: "invoice",
  processed: false,
  attempts: 0,
  createdAt: Timestamp(2025-12-10T14:30:00Z),
  processedAt: null,
  lastError: null,
  note: null,
  
  // Optional fields for special cases
  relatedRequestId: null,
  entityQueueRequestId: "queue-789"
}
```

### Tax Fields on Entity (Invoice/Expense/PO)

**After Tax Calculation:**

```firestore
// On users/{uid}/invoices/{invoiceId}
{
  // ... other invoice fields ...
  
  // Tax Status
  taxStatus: "calculated",  // or: "queued", "manual", "error"
  taxCalculatedBy: "server:determineTaxLogic",
  
  // Tax Amounts
  taxRate: 0.20,           // 20% VAT
  taxAmount: 200.00,       // euros
  total: 1200.00,          // amount + tax
  
  // Tax Details
  taxCountry: "FR",
  currency: "EUR",
  
  // Audit Trail
  taxBreakdown: {
    type: "vat",
    rate: 0.20,
    standard: true,
    country: "FR",
    appliedLogic: "Standard French VAT"
  },
  
  taxNote: null,
  taxQueueRequestId: "queue-789",
  taxCalculatedAt: Timestamp(2025-12-10T14:31:00Z),
  
  audit: [
    {
      action: "tax_calculation_queued",
      queueRequestId: "queue-789",
      at: Timestamp(2025-12-10T14:30:00Z)
    },
    {
      action: "tax_calculation_completed",
      queueRequestId: "queue-789",
      oldRate: null,
      newRate: 0.20,
      at: Timestamp(2025-12-10T14:31:00Z)
    }
  ]
}
```

---

## Processing Flow Details

### 1. Entity Creation (Real-time)

**Trigger:** `onInvoiceCreateAutoAssign` (and similar for expense/PO)

```typescript
// When invoice is created:
POST /invoices
{
  "companyId": "company-123",
  "contactId": "contact-456",
  "amount": 1000,
  "currency": "EUR",
  "dueDate": "2025-12-20"
}

// Immediately returns to client:
{
  "id": "inv-789",
  "status": "draft",
  "taxStatus": "queued",      // ← Marked as queued
  "amount": 1000,
  "taxQueueRequestId": "queue-789"
}

// Simultaneously, Firestore trigger creates queue request:
// internal/tax_queue/requests/queue-789
{
  "uid": "user-123",
  "entityPath": "users/user-123/invoices/inv-789",
  "entityType": "invoice",
  "processed": false,
  "attempts": 0,
  "createdAt": serverTimestamp(),
  "processedAt": null,
  "lastError": null
}
```

### 2. Queue Processing (Scheduled 1 minute)

**Function:** `processTaxQueue`

```typescript
// Every minute, processTaxQueue:
// 1. Queries unprocessed requests
const unprocessed = await firestore
  .collection('internal/tax_queue/requests')
  .where('processed', '==', false)
  .limit(10)
  .get();

// 2. For each request, processes tax calculation
for (const doc of unprocessed.docs) {
  const req = doc.data();  // { uid, entityPath, processed, ... }
  
  try {
    // Load entity
    const entity = await firestore.doc(req.entityPath).get();
    
    // Calculate tax using determineTaxLogic
    const result = await determineTaxLogic({
      uid: req.uid,
      amount: entity.data().amount,
      fromCurrency: entity.data().currency,
      companyId: entity.data().companyId,
      contactId: entity.data().contactId,
      direction: req.entityType === 'invoice' ? 'sale' : 'purchase'
    });
    
    // Update entity with calculated fields
    await firestore.doc(req.entityPath).update({
      taxRate: result.taxRate,
      taxAmount: result.taxAmount,
      total: result.total,
      taxStatus: 'calculated',
      taxCalculatedBy: 'server:determineTaxLogic',
      taxBreakdown: result.taxBreakdown,
      taxCountry: result.country,
      currency: result.currency,
      taxCalculatedAt: serverTimestamp(),
      audit: arrayUnion({
        action: 'tax_calculation_completed',
        queueRequestId: doc.id,
        newRate: result.taxRate,
        at: serverTimestamp()
      })
    });
    
    // Mark queue request as processed
    await doc.ref.update({
      processed: true,
      processedAt: serverTimestamp()
    });
    
  } catch (error) {
    // Increment attempts, store error
    await doc.ref.update({
      attempts: increment(1),
      lastError: error.message
    });
    
    // Optionally mark as processed if max attempts exceeded
    if (attempts >= 3) {
      await doc.ref.update({
        processed: true,
        processedAt: serverTimestamp(),
        note: 'Max attempts exceeded'
      });
      
      // Update entity with error status
      await firestore.doc(req.entityPath).update({
        taxStatus: 'error',
        taxNote: `Tax calculation failed: ${error.message}`
      });
    }
  }
}
```

### 3. Real-time UI Update

**Client-side:** `FinanceInvoiceProvider` listens to invoice changes

```dart
// StreamListener on Firestore document
users/{uid}/invoices/{invoiceId}.onSnapshot((doc) {
  final invoice = Invoice.fromFirestore(doc);
  
  // Detect tax calculation completion
  if (invoice.taxStatus == 'calculated') {
    // Show tax breakdown
    updateUI({
      'taxRate': invoice.taxRate,
      'taxAmount': invoice.taxAmount,
      'total': invoice.total,
      'taxBreakdown': invoice.taxBreakdown
    });
  }
  
  if (invoice.taxStatus == 'error') {
    // Show error message
    showSnackBar('Tax calculation failed: ${invoice.taxNote}');
  }
});
```

---

## Error Handling & Retry Logic

### Attempt Counter

Queue requests track number of processing attempts:

```
Attempt 1: processTaxQueue tries, encounters error
  → lastError = "Company not found"
  → attempts = 1
  
(1 minute passes)

Attempt 2: processTaxQueue tries again
  → lastError = "Contact not found"
  → attempts = 2
  
(1 minute passes)

Attempt 3: processTaxQueue tries final time
  → lastError = "API rate limit exceeded"
  → attempts = 3
  → processed = true (mark as done, with error)
  → entity taxStatus = 'error'
```

### Common Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| `Company not found` | `companyId` doesn't exist | Manual company creation |
| `Contact not found` | `contactId` doesn't exist | Manual contact creation |
| `Tax matrix missing` | Country not in config/tax_matrix | Run seedTaxMatrix function |
| `API timeout` | External API (FX rates) slow | Automatic retry next minute |
| `Firestore permission denied` | Security rule issue | Check UID/path permissions |

### User Experience

Users see:
1. ✅ Invoice created → "Draft" status
2. ⏳ Tax calculating → "Calculating tax..." badge
3. ✅ Tax ready → Tax breakdown displayed
4. ❌ Tax error → "Tax calculation failed" alert + retry button

---

## Configuration & Monitoring

### Queue Processing Config

From `functions/src/finance/types/TaxQueueTypes.ts`:

```typescript
export const DEFAULT_QUEUE_CONFIG = {
  batchSize: 10,           // Process 10 at a time
  maxAttempts: 3,          // Retry max 3 times
  skipMissingEntities: true,  // Skip if invoice deleted
  calculationTimeout: 5000  // 5 second timeout per calc
};
```

### Monitoring & Alerting

**Metrics to track:**
- Queue depth: `COUNT(processed==false)`
- Processing time: `avg(processedAt - createdAt)`
- Error rate: `COUNT(lastError is not null) / COUNT(all)`
- Max attempts: `COUNT(processed==true AND attempts==3)`

**Example query:**

```firestore
// Get all failed requests (3 attempts)
internal/tax_queue/requests
  WHERE processed == true
  AND attempts == 3
  ORDER BY createdAt DESC
```

---

## Integration with Firestore Triggers

### Trigger: onInvoiceCreateAutoAssign

**Path:** `functions/src/finance/onDocumentCreateAutoAssign.ts`

**Listens to:** `users/{uid}/invoices/{invoiceId}`

**On Create:**
1. Check if invoice already has tax info (skip if cached)
2. Create queue request
3. Update invoice: `taxStatus = 'queued'`
4. Log audit trail

**Skip conditions:**
- `taxCalculatedBy` already set
- No amount in invoice
- Entity is being batch-imported

### Trigger: onExpenseCreateAutoAssign

**Path:** Same file

**Listens to:** `users/{uid}/expenses/{expenseId}`

**Differences:**
- Sets `direction='purchase'` in queue request
- Adjusts field names for expense schema

### Trigger: onPurchaseOrderCreateAutoAssign

**Path:** Same file

**Listens to:** `users/{uid}/purchaseOrders/{poId}`

**Similar to expense trigger**

---

## Best Practices

### 1. Always Provide Company & Contact IDs

```dart
// ✅ Good
await invoiceService.createInvoice(
  companyId: 'company-123',    // Seller
  contactId: 'contact-456',    // Buyer
  amount: 1000
);

// ❌ Bad - Tax calculation will fail
await invoiceService.createInvoice(
  companyId: null,
  contactId: null,
  amount: 1000
);
```

### 2. Monitor Queue Depth

```dart
// Periodically check if queue is backing up
final queueDepth = await firestore
  .collection('internal/tax_queue/requests')
  .where('processed', '==', false)
  .count()
  .get();

if (queueDepth.count > 100) {
  // Warn user: "Tax calculations delayed"
  // Consider increasing processTaxQueue frequency
}
```

### 3. Retry Failed Calculations

```dart
// If user gets "Tax calculation failed", provide retry button
Future<void> retryTaxCalculation(String invoiceId) async {
  // Create a new queue request
  final queueRef = firestore
    .collection('internal/tax_queue/requests')
    .doc();
  
  await queueRef.set({
    uid: currentUser.uid,
    entityPath: 'users/${currentUser.uid}/invoices/$invoiceId',
    entityType: 'invoice',
    processed: false,
    attempts: 0,
    createdAt: serverTimestamp()
  });
  
  // Update invoice
  await firestore
    .collection('users')
    .doc(currentUser.uid)
    .collection('invoices')
    .doc(invoiceId)
    .update({
      taxStatus: 'queued',
      taxQueueRequestId: queueRef.id
    });
}
```

### 4. Handle Offline Scenarios

```dart
// If tax not calculated and user needs to send invoice:
if (invoice.taxStatus == 'queued') {
  // Show warning, allow manual tax entry
  showDialog(
    title: 'Tax Still Calculating',
    message: 'You can manually enter tax or wait 1-2 minutes',
    actions: [
      'Wait', // Re-check in 10 seconds
      'Enter Manually' // Open tax form
    ]
  );
}
```

---

## Firestore Rules for Queue

```firestore
match /internal/tax_queue/requests/{document=**} {
  // Only Cloud Functions can read/write
  allow read, write: if request.auth == null && request.service == 'cloud.firestore';
  
  // Fallback: deny all direct access
  allow read, write: if false;
}

// Or more permissively (if not using service account):
match /internal/tax_queue/requests/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == get(/databases/$(database)/documents/users/$(request.auth.uid)).uid;
}
```

---

## Troubleshooting

### Queue Not Processing

**Problem:** Queue requests stuck with `processed==false` for > 5 minutes

**Diagnosis:**
```firestore
// Check if processTaxQueue function is active
internal/tax_queue/requests
  WHERE createdAt > now() - 5 minutes
  AND processed == false
```

**Solutions:**
1. Verify `processTaxQueue` is deployed: `firebase functions:list`
2. Check Cloud Functions logs: `firebase functions:log`
3. Check if scheduler job is running: Cloud Scheduler UI
4. Manually trigger: `firebase functions:shell` → `processTaxQueue()`

### Tax Calculation Failing (Repeated Errors)

**Problem:** Queue requests have `attempts==3` and `taxStatus=='error'`

**Check:**
1. Do companies exist? `GET /companies/{companyId}`
2. Do contacts exist? `GET /contacts/{contactId}`
3. Is tax matrix seeded? `GET /config/tax_matrix/FR`
4. Check function logs for error message

### Slow Tax Calculation (> 1 minute)

**Problem:** Queued invoices take 2-3 minutes to calculate

**Likely Causes:**
- Queue backlog: `COUNT(processed==false) > 50`
- API timeouts: Check `lastError` messages
- Firestore slowness: Monitor latency in Cloud Console

**Solutions:**
- Increase `batchSize` in processTaxQueue (10 → 20)
- Decrease schedule interval (every 1 minute → every 30 seconds)
- Cache FX rates more aggressively

---

## TypeScript Types Reference

See `functions/src/finance/types/TaxQueueTypes.ts` for:
- `TaxQueueRequest` interface
- `EntityTaxFields` interface
- `QueueProcessingConfig` interface
- Helper functions: `createTaxQueueRequest()`, `markQueueRequestAsProcessed()`, `incrementQueueAttempts()`

---

**Last Updated:** December 10, 2025  
**Status:** ✅ Production Ready  
**Part of:** Finance Module Integration
