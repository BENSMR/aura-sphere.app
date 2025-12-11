# Firestore Collections Reference

**Document:** AuraSphere Pro Firestore Data Structure  
**Last Updated:** December 10, 2025  
**Status:** Production Ready

---

## Collection Hierarchy

### 1. User-Owned Collections (`users/{uid}/...`)

All user collections are scoped to `users/{uid}` and protected by authentication rules.

#### 1.1 Invoices

**Path:** `users/{uid}/invoices/{invoiceId}`

**Purpose:** Store user invoices with tax calculations and payment tracking

**Fields:**
```dart
{
  // Core fields
  id: string (invoice ID),
  userId: string (owner UID),
  
  // Financial fields
  amount: number (base amount),
  currency: string (ISO 4217 code, e.g., 'USD', 'EUR'),
  taxRate: number (calculated by server),
  taxAmount: number (calculated by server),
  total: number (amount + taxAmount, calculated by server),
  
  // Tax metadata (server-only)
  taxCalculatedBy: string (immutable, 'server:determineTaxLogic'),
  taxCalculationAt: timestamp,
  taxBreakdown: {
    type: 'vat' | 'sales_tax' | 'none',
    rate: number,
    standard: number,
    reduced: number[]
  },
  taxNote: string,
  
  // Entity references
  companyId: string (optional, seller company),
  contactId: string | clientId: string (optional, buyer),
  
  // Status
  status: 'draft' | 'sent' | 'unpaid' | 'paid' | 'overdue' | 'partial' | 'canceled',
  taxStatus: 'queued' | 'calculating' | 'calculated' | 'error',
  
  // Tax queue
  taxQueueRequestId: string (reference to internal/tax_queue/requests/{id}),
  
  // Timestamps
  createdAt: timestamp,
  updatedAt: timestamp,
  dueDate: timestamp (optional),
  paymentDate: timestamp (optional),
  
  // Audit
  audit: [{
    action: string,
    who: string,
    at: timestamp,
    ...details
  }]
}
```

**Rules:** User can create/read/update (except taxCalculatedBy), cannot delete

**Subcollections:**
- `payments/{pid}` — Payment records (server-write only)
- `paymentErrors/{eid}` — Payment errors (server-write only)
- `pdf/{pdfId}` — PDF metadata (server-write only)
- `audit/{auditId}` — Immutable audit trail (server-write only)

---

#### 1.2 Expenses

**Path:** `users/{uid}/expenses/{expenseId}`

**Purpose:** Track business expenses with OCR, tax, and approval workflow

**Fields:**
```dart
{
  // Core fields
  id: string (expense ID),
  userId: string (owner UID),
  
  // Financial fields
  amount: number (base amount),
  currency: string,
  taxRate: number (calculated),
  taxAmount: number (calculated),
  total: number (calculated),
  
  // Tax metadata (server-only)
  taxCalculatedBy: string (immutable, 'server:determineTaxLogic'),
  taxCalculationAt: timestamp,
  taxBreakdown: { ... },
  
  // Expense details
  merchant: string,
  category: string,
  paymentMethod: string,
  date: timestamp,
  
  // Project/Invoice linkage
  projectId: string (optional),
  invoiceId: string (optional),
  
  // Approval workflow
  status: 'pending' | 'approved' | 'rejected' | 'reimbursed',
  approverId: string (optional),
  approvedNote: string (optional),
  
  // OCR data
  photoUrls: string[],
  rawOcr: { ...OCR output },
  
  // Tax queue
  taxQueueRequestId: string,
  
  // Timestamps
  createdAt: timestamp,
  updatedAt: timestamp,
  
  // Audit
  audit: [{...}]
}
```

**Rules:** User can create/read/update (except taxCalculatedBy), cannot delete (permanent audit)

**Subcollections:**
- `approvals/{id}` — Approval records (server-write only)

---

#### 1.3 Companies

**Path:** `users/{uid}/companies/{companyId}`

**Purpose:** Store user's business entities (sellers in transactions)

**Fields:**
```dart
{
  id: string,
  userId: string (owner UID),
  
  // Business info
  name: string,
  country: string (ISO country code, e.g., 'US', 'DE'),
  currency: string (default currency, e.g., 'USD', 'EUR'),
  defaultCurrency: string (alias for currency),
  
  // Tax identification
  taxId: string (VAT ID, EIN, etc.),
  taxNumber: string,
  isBusiness: boolean,
  businessType: string ('sole_proprietor' | 'llc' | 'corporation' | 'partnership'),
  
  // Contact
  email: string,
  phone: string,
  website: string,
  
  // Address
  address: string,
  city: string,
  state: string,
  postalCode: string,
  
  // Branding
  logo: string (URL),
  
  // Timestamps
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Rules:** User can create/read/update/delete

---

#### 1.4 Contacts

**Path:** `users/{uid}/contacts/{contactId}`

**Purpose:** Store business contacts (customers, suppliers)

**Fields:**
```dart
{
  id: string,
  userId: string,
  
  // Contact info
  name: string,
  email: string,
  phone: string,
  
  // Business info
  company: string,
  country: string (determines tax jurisdiction),
  currency: string,
  
  // Type
  type: 'customer' | 'supplier' | 'partner',
  isBusiness: boolean (determines tax treatment),
  
  // Tax identification
  taxId: string,
  
  // Address
  address: string,
  city: string,
  state: string,
  postalCode: string,
  
  // Timestamps
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Rules:** User can create/read/update/delete

---

#### 1.5 Purchase Orders

**Path:** `users/{uid}/purchaseOrders/{poId}`

**Purpose:** Track purchase orders with tax calculations

**Fields:**
```dart
{
  // Similar to invoices
  id: string,
  userId: string,
  
  // Financial (with tax protection)
  amount: number,
  currency: string,
  taxCalculatedBy: string (immutable, server-only),
  taxRate: number,
  taxAmount: number,
  total: number,
  
  // Entity references
  supplierId: string,
  projectId: string,
  
  // Status
  status: string,
  
  // Timestamps
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Rules:** User can create/read/update (except taxCalculatedBy), cannot delete

---

### 2. Configuration Collections (`config/...`)

All config collections are read-only for authenticated users, write-only for server.

#### 2.1 FX Rates

**Path:** `config/fx_rates`

**Purpose:** Cache for foreign exchange rates (daily sync from external provider)

**Fields:**
```dart
{
  base: string ('USD', source currency),
  rates: {
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 110.5,
    ...
  },
  provider: string ('openexchangerates' | 'fixer' | 'manual'),
  updatedAt: timestamp,
  expiresAt: timestamp (TTL for cache invalidation)
}
```

**Rules:** Read all auth, write server only

**Maintained by:** `syncFxRates()` Cloud Function (scheduled daily)

---

#### 2.2 Tax Matrix

**Path:** `config/tax_matrix/{countryCode}`

**Purpose:** Tax rules per country (VAT, sales tax, special rates)

**Fields (Example - Germany):**
```dart
// config/tax_matrix/DE
{
  country: 'DE',
  countryName: 'Germany',
  region: 'EU',
  currency: 'EUR',
  
  vat: {
    standard: 0.19,
    isEu: true,
    reduced: [0.07, 0.05],
    zero: 0
  },
  
  // Optional: sales tax for US states
  sales_tax: null,
  
  // Metadata
  updatedAt: timestamp,
  source: 'official_eu_rates'
}
```

**Supported Countries:** 26+ (all EU + US + major trading partners)

**Rules:** Read all auth, write server only

**Maintained by:** `seedTaxMatrix()` Cloud Function (manual trigger + scheduled refresh)

---

### 3. Internal Collections (`internal/...`)

Administrative/system collections for server operations. **User cannot read/write.**

#### 3.1 Tax Queue

**Path:** `internal/tax_queue/requests/{requestId}`

**Purpose:** Async queue for pending tax calculations (decouple creation from calculation)

**Fields:**
```dart
{
  // Who & What
  uid: string (owner UID),
  entityPath: string (e.g., 'users/{uid}/invoices/{id}'),
  entityType: 'invoice' | 'expense' | 'po',
  
  // Status
  processed: boolean (false = pending, true = done),
  attempts: number (retry counter),
  processedAt: timestamp (when completed),
  
  // Error tracking
  lastError: string,
  lastTriedAt: timestamp,
  
  // Results
  lastResult: { ...full determineTaxLogic result },
  
  // Timestamps
  createdAt: timestamp
}
```

**Lifecycle:**
1. Created by `onInvoiceCreateAutoAssign` / `onExpenseCreateAutoAssign` / `onPurchaseOrderCreateAutoAssign`
2. Read by `processTaxQueue` (scheduled every 1 minute)
3. Updates are written by `processTaxQueue` only
4. Deleted after TTL (configurable, default: 30 days)

**Rules:** Client cannot create/read/update/delete; server only

---

#### 3.2 Tax Logs (Optional - Future Enhancement)

**Path:** `tax_logs/{entityId}/entries/{logId}`

**Purpose:** Detailed audit trail of all tax calculations for compliance

**Fields:**
```dart
{
  // Reference
  entityId: string (invoice/expense/po ID),
  entityPath: string,
  uid: string,
  
  // Calculation details
  input: { amount, currency, companyId, contactId, ... },
  output: { taxRate, taxAmount, total, country, ... },
  
  // Context
  calculatedAt: timestamp,
  calculatedBy: string ('server:determineTaxLogic'),
  fxSnapshot: { base, rates, updatedAt }, // for reproducibility
  
  // Compliance
  auditTrail: [{
    action: 'queued' | 'calculated' | 'applied',
    at: timestamp
  }]
}
```

**Status:** Currently stored inline in invoice/expense; can be extracted to separate collection for heavy compliance requirements.

---

### 4. User Subcollections (`users/{uid}/...`)

#### 4.1 Companies (Sellers)

**Path:** `users/{uid}/companies/{companyId}`

Already described above (1.3).

---

#### 4.2 Contacts (Customers/Suppliers)

**Path:** `users/{uid}/contacts/{contactId}`

Already described above (1.4).

---

## Security Model Summary

| Collection | Read | Write | Notes |
|-----------|------|-------|-------|
| `users/{uid}/invoices` | User only | User only (except tax fields) | taxCalculatedBy immutable |
| `users/{uid}/expenses` | User/Approver | User/Admin/Approver | taxCalculatedBy immutable, no delete |
| `users/{uid}/purchaseOrders` | User only | User only (except tax fields) | taxCalculatedBy immutable |
| `users/{uid}/companies` | User only | User only | Full CRUD |
| `users/{uid}/contacts` | User only | User only | Full CRUD |
| `config/fx_rates` | All auth | Server only | Daily sync |
| `config/tax_matrix/{country}` | All auth | Server only | Manual + scheduled |
| `internal/tax_queue/requests` | ❌ | Server only | Client proof |

---

## Tax Calculation Flow

```
1. User creates invoice:
   → FirebaseFirestore.instance
       .collection('users').doc(uid)
       .collection('invoices').add({amount, currency, ...})
   → Firestore trigger fires

2. onInvoiceCreateAutoAssign trigger:
   → Creates queue request in internal/tax_queue/requests
   → Sets invoice.taxStatus = 'queued'

3. processTaxQueue (every 1 minute):
   → Reads all WHERE processed == false
   → Calls determineTaxLogic(payload, uid)
   → Updates invoice with {taxRate, taxAmount, total, taxCalculatedBy, audit}
   → Marks queue request processed = true

4. Flutter UI (TaxStatusBadge):
   → Watches invoice.taxStatus
   → Shows ⏳ Calculating → ✅ Success → displays tax breakdown
```

---

## Key Design Patterns

### Pattern 1: Async Tax Calculation

**Problem:** Tax calculation is slow (Firestore reads + logic)  
**Solution:** Queue-based system with scheduled worker  
**Benefit:** Users get immediate invoice creation, tax updates automatically within 60 seconds

### Pattern 2: Server-Calculated Field Protection

**Problem:** Clients could spoof tax amounts  
**Solution:** Firestore rules protect `taxCalculatedBy` field  
**Benefit:** Fraud prevention at the database layer

### Pattern 3: FX Rate Caching

**Problem:** Real-time FX API calls are expensive  
**Solution:** Cached `config/fx_rates` document updated daily  
**Benefit:** Fast currency conversion, reduced API costs

### Pattern 4: Tax Matrix as Reference Data

**Problem:** Hard-coded tax rules don't scale  
**Solution:** `config/tax_matrix/{country}` documents  
**Benefit:** Easy to add countries, update rules without code changes

---

## Indexes Required

### Tax Queue Processing

```
Collection: internal/tax_queue/requests
Fields: processed (ASC), createdAt (ASC)
Reason: processTaxQueue queries WHERE processed==false ORDER BY createdAt
```

### Invoice Tax Status

```
Collection: users/{uid}/invoices
Fields: taxStatus (ASC), createdAt (DESC)
Reason: UI queries for pending tax calculations
```

---

## Collection Sizes & Performance

| Collection | Typical Size | Write Frequency | Read Pattern |
|-----------|--------------|-----------------|--------------|
| `invoices` | 100s-1000s | Daily | User, Filter by status |
| `expenses` | 100s-1000s | Daily | User, Filter by status |
| `companies` | 1-10 | Monthly | User |
| `contacts` | 10-100 | Monthly | User, Search |
| `config/fx_rates` | 1 | Daily | Global, All auth |
| `config/tax_matrix/*` | 26 | Monthly | Global, All auth |
| `internal/tax_queue/requests` | 10-100 | Constant | Scheduled only, Max 10/min |

---

## References

- **Tax Service:** [lib/services/tax_service.dart](lib/services/tax_service.dart) — Flutter SDK
- **Tax Logic:** [functions/src/finance/determineTaxLogic.ts](functions/src/finance/determineTaxLogic.ts) — Shared logic
- **Queue Worker:** [functions/src/finance/processTaxQueue.ts](functions/src/finance/processTaxQueue.ts) — Scheduled processor
- **Security Rules:** [firestore.rules](firestore.rules) — Complete protection model
- **Type Definitions:** [functions/src/finance/types/TaxQueueTypes.ts](functions/src/finance/types/TaxQueueTypes.ts) — TypeScript interfaces

---

## Maintenance

### Daily Tasks
- ✅ `syncFxRates` Cloud Function automatically runs daily at 00:00 UTC
- ✅ `processTaxQueue` automatically runs every 1 minute

### Monthly Tasks
- Review Firestore usage (invoices, expenses growth)
- Monitor tax matrix staleness
- Audit queue backlog (should be < 10 items)

### Quarterly Tasks
- Add new countries to tax matrix if needed
- Review security rules for any changes
- Archive old queue requests (> 30 days)

