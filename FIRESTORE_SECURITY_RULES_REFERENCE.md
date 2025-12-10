# Firestore Security Rules Reference

## Overview

AuraSphere Pro uses Firestore security rules to enforce:
- **User isolation** — Users can only access their own data
- **Server-only writes** — Tax calculations, audit entries written by Cloud Functions only
- **Audit immutability** — Audit entries cannot be modified or deleted
- **Admin oversight** — Admins can read operational data without client visibility

## Collection Security Model

### User-Scoped Collections

```
/users/{userId}/
├── invoices/{invoiceId}          ✅ User read/write (limited fields)
├── expenses/{expenseId}          ✅ User read/write (with approval workflow)
├── purchase_orders/{poId}        ✅ User read/write
├── companies/{companyId}         ✅ User read/write
├── contacts/{contactId}          ✅ User read/write
├── wallet/{doc}                  ✅ User read-only (server updates balance)
├── token_audit/{auditId}         ✅ User read-only (server writes)
├── meta/business/                ✅ User read/write (protected fields)
└── crm/{doc=**}                  ✅ User read/write
```

**Key Protection:**
- `taxCalculatedBy` field protected (server-only)
- `invoiceCounter` field protected (server-only)
- `wallet.balance` field protected (server-only)
- `token_audit` collection server-only writes

### Server-Only Collections

```
/config/
├── fx_rates                      ❌ No client read/write (admin SDK only)
└── tax_matrix/{country}          ❌ No client read/write (admin SDK only)

/internal/
└── tax_queue/requests/{id}       ✅ Admin read only (no client writes)

/admins/{uid}                      ✅ Admin read-only (server manages)
```

### Audit Collections

```
/audit/{compositeId}/
└── entries/{entryId}             ✅ User read (owner) OR admin (all)
                                   ❌ Immutable (no client writes/updates)

/audit_index/{compositeId}        ✅ User read (owner) OR admin (all)
                                   ❌ Server-only writes
```

**CompositeId Format:** `{entityType}_{entityId}`
- `invoice_inv-001` — Invoice with ID "inv-001"
- `expense_exp-456` — Expense with ID "exp-456"
- `wallet_user123` — Wallet owned by user "user123"
- `payment_pay-789` — Payment record "pay-789"

## Security Rules

### User Authentication & Authorization

```javascript
function isAdmin() {
  return exists(/databases/$(database)/documents/admins/$(request.auth.uid));
}

function isOwnerOrAdmin(userId) {
  return request.auth != null && (request.auth.uid == userId || isAdmin());
}
```

### Audit Ownership Check

```javascript
function isAuditOwner(compositeId) {
  // Admins can read all audit entries
  if (isAdmin()) {
    return true;
  }
  
  // Parse compositeId: "entityType_entityId"
  let parts = compositeId.split('_');
  let entityType = parts[0];
  let entityId = parts[1];
  
  // User-scoped entities
  if (entityType == 'invoice' || entityType == 'expense' || entityType == 'purchase_order') {
    return exists(/databases/.../users/$(request.auth.uid)/$(entityType)s/$(entityId));
  }
  
  // Wallet entities (user owns wallet equal to their UID)
  if (entityType == 'wallet') {
    return request.auth.uid == entityId;
  }
  
  // Payment entities
  if (entityType == 'payment') {
    return request.auth.uid == entityId;
  }
  
  // Company/contact ownership
  if (entityType == 'company' || entityType == 'contact') {
    return exists(/databases/.../users/$(request.auth.uid)/$(entityType)s/$(entityId));
  }
  
  return false; // Unknown entity types denied
}
```

## Operation Security

### Invoice Operations

```
Create:    ✅ Authenticated users create in their own collection
Read:      ✅ Only invoice owner can read
Update:    ✅ Owner can update, but taxCalculatedBy field is protected
Delete:    ✅ Owner can delete (soft delete recommended in code)
```

**Protected Fields (server-only write):**
```
taxCalculatedBy    — Tax calculation owner (prevents fraud)
taxCalculationId   — Reference to tax processing
calculatedAt       — Timestamp of tax calculation
```

### Expense Operations

```
Create:    ✅ Authenticated users with valid data structure
Read:      ✅ Owner, approver, or admin
Update:    ✅ Owner/approver with approval workflow, taxCalculatedBy protected
Delete:    ❌ Forbidden (permanent audit trail)
```

### Payment Operations

```
Write:     ❌ Forbidden (Cloud Functions via Stripe webhook only)
Read:      ✅ Invoice owner can read payment sub-collection
```

**Reason:** Prevents clients from fabricating payment records.

### Tax Queue Operations

```
Read:      ✅ Admins only
Write:     ❌ Forbidden (Cloud Functions via admin SDK)
Update:    ❌ Forbidden
Delete:    ❌ Forbidden
```

**Reason:** Internal processing, not visible to clients.

### Audit Trail Operations

```
Read:      ✅ Entity owner OR admin
Create:    ❌ Forbidden (Cloud Functions via admin SDK)
Update:    ❌ Forbidden (immutable)
Delete:    ❌ Forbidden (immutable)
```

**Reason:** Compliance requirement — audit must never be modified.

## Enforcement Points

### Client-Side Attempt → Rejected

```
❌ User tries to update invoice.taxCalculatedBy
   → Rule blocks (server-only field)

❌ User tries to edit audit entry
   → Rule blocks (immutable collection)

❌ User tries to set wallet.balance
   → Rule blocks (server-only field)

❌ User tries to read other user's invoices
   → Rule blocks (different userId path)

❌ User tries to read tax_queue
   → Rule blocks (admin-only collection)
```

### Server-Side Operations → Allowed

```
✅ Cloud Function (admin SDK) creates audit entry
   → Bypasses rules (admin SDK != request.auth)

✅ Cloud Function (admin SDK) updates wallet.balance
   → Bypasses rules (admin SDK)

✅ processTaxQueue function writes to tax_queue
   → Bypasses rules (admin SDK)

✅ determineTaxAndCurrency sets invoice.taxCalculatedBy
   → Bypasses rules (admin SDK)
```

## Deployment

### Deploy Rules

```bash
firebase deploy --only firestore:rules
```

### Validate Rules (Local Emulator)

```bash
firebase emulators:start --import=./data
# Tests run against emulated rules
```

### Testing Checklist

- [ ] User can read own invoice
- [ ] User cannot read other user's invoice
- [ ] User cannot update invoice.taxCalculatedBy
- [ ] User cannot modify audit entries
- [ ] Admin can read all audit entries
- [ ] Admin can read tax_queue
- [ ] Cloud Function can write audit entries
- [ ] Client cannot write audit entries

## Practical Examples

### Example 1: Tax Calculation Flow

1. User creates invoice → Firestore trigger fires
2. Cloud Function reads invoice (admin SDK, bypasses rules)
3. Cloud Function calls `determineTaxAndCurrency()`
4. Cloud Function updates `invoice.taxCalculatedBy` (admin SDK)
5. Cloud Function writes audit entry (admin SDK)
6. User reads audit trail (request.auth, passes `isAuditOwner()` check)

**Rules Enforced:**
- User cannot create invoices with pre-filled `taxCalculatedBy` ✅
- User cannot modify `taxCalculatedBy` after creation ✅
- Audit entry immutable once written ✅

### Example 2: Token Award (Admin)

1. Admin calls `rewardUser(userId, 'welcome_bonus')`
2. Cloud Function checks `isAdmin()` (admin SDK)
3. Cloud Function updates `wallet.balance` (admin SDK)
4. Cloud Function writes audit entry to `/audit/wallet_{userId}/entries/{id}`
5. User reads audit in FinanceDebugScreen → Passes `isAuditOwner()` check

**Rules Enforced:**
- User cannot adjust own wallet balance ✅
- Admin can read all wallet audit entries ✅
- Audit shows who awarded tokens and when ✅

### Example 3: Expense Approval Workflow

1. User creates expense (approval pending)
2. Approver reads expense (approver listed in rule)
3. Approver updates status → Firestore trigger writes audit
4. Audit entry shows before/after values
5. Both user and approver can read audit trail

**Rules Enforced:**
- Only user or approver can update expense ✅
- `taxCalculatedBy` protected from both user and approver ✅
- Audit trail captures all changes ✅

## Maintenance

### Adding New Entity Type to Audit

1. Update `isAuditOwner()` function in firestore.rules
2. Add entity type case (e.g., `if (entityType == 'newtype')`)
3. Define ownership check (usually check if user owns the document)
4. Deploy rules: `firebase deploy --only firestore:rules`

### Granting Admin Access

1. Create document at `/admins/{uid}`
2. Existing checks will automatically grant admin permissions
3. No rule redeploy needed

### Protecting New Fields

1. Add field name to protected array in update rule:
   ```
   && !request.resource.data.keys().hasAny(['newField', 'anotherField'])
   ```
2. Deploy rules: `firebase deploy --only firestore:rules`

## Troubleshooting

### User Cannot Read Their Own Audit

**Check:**
1. Composite ID format is correct: `{entityType}_{entityId}`
2. Entity exists in user's collection
3. User is authenticated (not anonymous)

**Debug:**
```javascript
// In FinanceDebugScreen
final index = await getAuditIndex('invoice', 'inv-001');
// If null → either audit doesn't exist or rule blocked read
```

### Admin Cannot Read All Audits

**Check:**
1. User's UID exists in `/admins/{uid}` collection
2. Firestore rules deployed successfully
3. User is signed in with correct UID

**Fix:**
```javascript
// Create admin doc
admin.firestore().collection('admins').doc(adminUid).set({ role: 'admin' });
```

### Cloud Function Cannot Write Audit

**Check:**
1. Cloud Function uses admin SDK (not request.auth)
2. Function is authenticated via service account
3. Firestore rules allow `false` for client creates (correct)

**Debug:**
```typescript
// In Cloud Function
console.log('[admin-sdk]', admin.app().name); // Should be 'default'
```

---

**Last Updated:** December 10, 2025
**Version:** 1.0
**Status:** Production Ready
