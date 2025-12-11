# Tax Queue Quick Reference

## Firestore Schema Summary

### Queue Request
```
Path: internal/tax_queue/requests/{requestId}

Required Fields:
  uid: string                 (user ID)
  entityPath: string         (e.g., "users/uid/invoices/invId")
  entityType: string         ('invoice' | 'expense' | 'purchaseOrder')
  processed: boolean         (false = pending, true = done)
  attempts: number           (0, 1, 2, 3... max 3)
  createdAt: Timestamp       (when created)

Optional Fields:
  processedAt: Timestamp     (when completed)
  lastError: string          (error message if failed)
  note: string               (special handling notes)
  relatedRequestId: string   (reference to another queue item)
```

### Entity Tax Fields (Added by processTaxQueue)
```
On: users/{uid}/invoices/{invoiceId} (similar for expenses/POs)

Tax Status:
  taxStatus: 'queued' | 'calculated' | 'manual' | 'error'
  taxCalculatedBy: 'server:determineTaxLogic'
  taxQueueRequestId: string  (back-ref to queue request)

Tax Amounts:
  taxRate: number            (0.20 = 20%)
  taxAmount: number          (calculated amount)
  total: number              (amount + tax)
  currency: string           (e.g., 'EUR')
  
Tax Details:
  taxCountry: string         (ISO code)
  taxBreakdown: {            (detailed breakdown)
    type: 'vat' | 'sales_tax' | 'none'
    rate: number
    standard: boolean
    country: string
    reverseCharge?: boolean
    appliedLogic?: string
  }
  taxNote: string            (calculation notes)
  taxCalculatedAt: Timestamp

Audit:
  audit: [{                  (changes history)
    action: string
    queueRequestId: string
    newRate: number
    at: Timestamp
  }]
```

---

## Processing Lifecycle

| Step | Component | Action | Time |
|------|-----------|--------|------|
| 1 | UI/API | Create invoice | T+0s |
| 2 | Trigger | Create queue request | T+0s |
| 3 | UI | Show "Calculating tax..." | T+0s |
| 4 | processTaxQueue | Pick up request (batched) | T+60s |
| 5 | determineTaxLogic | Calculate tax | T+60-65s |
| 6 | processTaxQueue | Update entity fields | T+65s |
| 7 | Listener | Detect change, refresh UI | T+65s |
| 8 | UI | Show tax breakdown | T+65s |

---

## Usage Examples

### Create a Queue Request (Backend)
```typescript
import { createTaxQueueRequest } from './finance/types/TaxQueueTypes';

const queueReq = createTaxQueueRequest(
  uid,
  'users/uid/invoices/inv-123',
  'invoice'
);

await firestore
  .collection('internal/tax_queue/requests')
  .add(queueReq);
```

### Mark as Processed (Backend)
```typescript
import { markQueueRequestAsProcessed } from './finance/types/TaxQueueTypes';

const update = markQueueRequestAsProcessed(
  undefined,  // no error
  'Completed successfully'
);

await queueDocRef.update(update);
```

### Check Tax Status (Frontend)
```dart
// In FinanceInvoiceProvider
if (invoice.taxStatus == 'queued') {
  print('Tax is calculating...');
} else if (invoice.taxStatus == 'calculated') {
  print('Tax: ${invoice.taxRate * 100}%');
} else if (invoice.taxStatus == 'error') {
  print('Error: ${invoice.taxNote}');
}
```

### Monitor Queue Depth
```dart
final queueRef = firestore.collection('internal/tax_queue/requests');
final pending = await queueRef
  .where('processed', isEqualTo: false)
  .count()
  .get();

print('Pending tax calculations: ${pending.count}');
```

### Retry Failed Calculation
```dart
// Load the failed queue request
final queueReq = await firestore
  .collection('internal/tax_queue/requests')
  .doc(invoice.taxQueueRequestId)
  .get();

// Reset and retry
await queueReq.reference.update({
  processed: false,
  attempts: 0,
  lastError: null
});
```

---

## Configuration

### Queue Processing (in processTaxQueue)
```typescript
const BATCH_SIZE = 10;        // Process 10 per run
const MAX_ATTEMPTS = 3;       // Retry max 3 times
const SCHEDULE = 'every 1 minutes';  // Run every minute
const TIMEOUT = 5000;         // 5 sec per calculation
```

### Firestore Rules
```firestore
match /internal/tax_queue/requests/{document=**} {
  // Cloud Functions only
  allow read, write: if false;
}
```

---

## Error Codes & Messages

| Error | Cause | Fix |
|-------|-------|-----|
| Company not found | `companyId` invalid | Create company first |
| Contact not found | `contactId` invalid | Create contact first |
| Tax matrix missing | Country not seeded | Run seedTaxMatrix |
| API timeout | External API slow | Retry (automatic) |
| Firestore permission | Security rule issue | Check rules & UID |
| Invalid currency | Unknown currency code | Use valid ISO code |

---

## TypeScript Interfaces (functions/src/finance/types/TaxQueueTypes.ts)

```typescript
interface TaxQueueRequest {
  uid: string;
  entityPath: string;
  entityType: 'invoice' | 'expense' | 'purchaseOrder';
  processed: boolean;
  attempts: number;
  createdAt?: Timestamp;
  processedAt?: Timestamp;
  lastError?: string;
  note?: string;
  relatedRequestId?: string;
  entityQueueRequestId?: string;
}

interface EntityTaxFields {
  taxStatus: 'queued' | 'calculated' | 'manual' | 'error';
  taxCalculatedBy?: string;
  taxRate?: number;
  taxAmount?: number;
  total?: number;
  taxCountry?: string;
  taxBreakdown?: {...};
  taxNote?: string;
  taxQueueRequestId?: string;
  currency?: string;
  taxCalculatedAt?: Timestamp;
  audit?: Array<{...}>;
}

interface QueueProcessingConfig {
  batchSize: number;
  maxAttempts: number;
  skipMissingEntities: boolean;
  calculationTimeout: number;
}
```

---

## Related Files

| File | Purpose |
|------|---------|
| `functions/src/finance/processTaxQueue.ts` | Main queue processor (scheduled) |
| `functions/src/finance/determineTaxLogic.ts` | Core tax calculation logic |
| `functions/src/finance/onDocumentCreateAutoAssign.ts` | Firestore triggers |
| `functions/src/finance/types/TaxQueueTypes.ts` | Type definitions |
| `lib/providers/finance_invoice_provider.dart` | Flutter state management |
| `TAX_QUEUE_SYSTEM_DOCUMENTATION.md` | Full documentation |

---

**Last Updated:** December 10, 2025  
**Version:** 1.0
