# Firestore Security Rules Quick Reference

## Financial Collections Access Matrix

| Collection | Create | Read | Update | Delete | Notes |
|-----------|--------|------|--------|--------|-------|
| `config/fx_rates` | ❌ | ✅ All Auth | ❌ | ❌ | Server-only writes |
| `config/tax_matrix/{country}` | ❌ | ✅ All Auth | ❌ | ❌ | Server-only writes |
| `internal/tax_queue/requests/{id}` | ❌ | ✅ Owner | ❌ | ❌ | Trigger-created only |
| `users/{uid}/companies/{id}` | ✅ User | ✅ User | ✅ User* | ✅ User | Full CRUD by owner |
| `users/{uid}/contacts/{id}` | ✅ User | ✅ User | ✅ User* | ✅ User | Full CRUD by owner |
| `users/{uid}/invoices/{id}` | ✅ User | ✅ User | ✅ User* | ✅ User | Protected: `taxCalculatedBy` |
| `users/{uid}/expenses/{id}` | ✅ User | ✅ User* | ✅ User* | ❌ | Audit trail, protected tax fields |
| `users/{uid}/purchaseOrders/{id}` | ✅ User | ✅ User | ✅ User* | ✅ User | Protected: `taxCalculatedBy` |

**Notes:**
- `*` = With restrictions (field-level protection)
- ✅ All Auth = All authenticated users
- ✅ User = `request.auth.uid == userId`
- ✅ Owner = `request.auth.uid == resource.data.uid`

---

## Protected Fields (Cannot be Set by Client)

### Invoices & Purchase Orders
```
❌ taxCalculatedBy    ← Prevents fraud (server-only marker)
❌ taxRate            ← Can be updated, but not if changed with taxCalculatedBy
❌ taxAmount          ← Can be updated, but not if changed with taxCalculatedBy
❌ taxBreakdown       ← Can be updated, but not if changed with taxCalculatedBy
```

**Protection Rule:**
```firestore
allow update: if !(request.resource.data.keys().hasAny(['taxCalculatedBy']) 
                   && request.resource.data.taxCalculatedBy != resource.data.taxCalculatedBy)
```

Translation: **"Reject update if client tries to change taxCalculatedBy"**

### Expenses
Same as invoices + immutable `createdAt`

---

## Queue Request Lifecycle

```
State: processed = false, attempts = 0
Created by: onInvoiceCreateAutoAssign trigger (T+0s)
Owner: User who created invoice (uid field)

   ↓ (1 minute)

processTaxQueue picks up (T+60s)
Loads invoice, company, contact
Calls determineTaxLogic
Updates invoice with tax fields
Marks queue: processed = true, processedAt = now()

   ↓ (10 seconds)

Firestore listener on invoice fires
Detects: taxStatus 'queued' → 'calculated'
UI updates with tax breakdown
```

---

## Security Rules by Scenario

### Scenario 1: Normal User Creating Invoice
```dart
// ✅ ALLOWED
await firestore.collection('users').doc(uid)
  .collection('invoices').add({
    'amount': 1000,
    'currency': 'EUR',
    'companyId': 'company-123',
    'contactId': 'contact-456'
  });
// Creates document, triggers onInvoiceCreateAutoAssign
```

### Scenario 2: User Reading Tax Status
```dart
// ✅ ALLOWED
final invoice = await firestore.collection('users').doc(uid)
  .collection('invoices').doc(invoiceId).get();
print(invoice['taxStatus']); // 'queued' or 'calculated'
```

### Scenario 3: User Trying to Spoof Tax
```dart
// ❌ BLOCKED
await firestore.collection('users').doc(uid)
  .collection('invoices').doc(invoiceId).update({
    'taxCalculatedBy': 'server:determineTaxLogic',
    'taxRate': 0.05  // Fraudulently low!
  });
// Error: Permission denied (rule fails)
```

### Scenario 4: Server Calculating Tax
```typescript
// ✅ ALLOWED (uses service account)
await admin.firestore().collection('users').doc(uid)
  .collection('invoices').doc(invoiceId).update({
    'taxCalculatedBy': 'server:determineTaxLogic',
    'taxRate': 0.20,
    'taxAmount': 200,
    'taxStatus': 'calculated'
  });
// Admin SDK bypasses rules (service account)
```

### Scenario 5: Reading Config (All Users)
```dart
// ✅ ALLOWED - Any authenticated user
final fxRates = await firestore.collection('config')
  .doc('fx_rates').get();
print(fxRates['EUR_USD']); // 1.08

final frTax = await firestore.collection('config')
  .collection('tax_matrix').doc('FR').get();
print(frTax['vat']); // 0.20
```

---

## Validation Functions

### isValidExpenseCreate()
```firestore
Validates:
  ✓ All required fields present (id, userId, merchant, amount, etc.)
  ✓ userId == request.auth.uid (matches user)
  ✓ amount > 0
  ✓ Currency is valid string
  ✓ Max 20 fields (prevents bloat)
```

### isValidExpenseUpdate()
```firestore
Validates:
  ✓ userId/id/createdAt unchanged (immutable)
  ✓ Same field requirements as create
  ✓ Max 20 fields
```

### isValidClientCreate()
```firestore
Validates:
  ✓ Email format valid (regex)
  ✓ Name > 0 chars, < 255 chars
  ✓ Optional fields typed correctly
  ✓ Enum fields have valid values
```

---

## Common Rule Patterns

### User-Owned Resource
```firestore
match /users/{userId}/invoices/{invoiceId} {
  allow read, write: if request.auth != null 
                     && request.auth.uid == userId;
}
```

### Server-Only Write
```firestore
match /config/tax_matrix/{country} {
  allow read: if request.auth != null;
  allow write: if false;  // No client writes
}
```

### Read + Constrained Update
```firestore
match /users/{userId}/invoices/{invoiceId} {
  allow read: if request.auth.uid == userId;
  allow update: if request.auth.uid == userId
                && !(request.resource.data.keys().hasAny(['protectedField']));
}
```

### Immutable Subcollection
```firestore
match /audit/{auditId} {
  allow read: if request.auth.uid == userId;
  allow create: if request.auth.uid == userId;
  allow update, delete: if false;  // Immutable
}
```

---

## Error Messages Users See

| Scenario | Error | Cause | Solution |
|----------|-------|-------|----------|
| Cannot create invoice | `PERMISSION_DENIED` | User not authenticated | Login required |
| Tax field update rejected | `PERMISSION_DENIED` | Tried to set `taxCalculatedBy` | Cannot spoof tax |
| Cannot read other user's invoice | `PERMISSION_DENIED` | Wrong userId | Access own data only |
| Queue creation blocked | `PERMISSION_DENIED` | Tried to create queue directly | Wait for automatic queueing |
| Cannot see queue request | `PERMISSION_DENIED` | Wrong uid in request | Can only see own queue items |

---

## Testing Rules

### Emulator Mode (Development)
```bash
firebase emulators:start --only firestore
# In code:
useEmulator(host, port);
// Rules still enforced in emulator
```

### Validation Before Deploy
```bash
firebase deploy --only firestore:rules --dry-run
# Check output: "rules file compiled successfully"
```

### Production Monitoring
```bash
# View rule denials
gcloud firestore operations list

# Check access logs
gcloud logging read "resource.type=cloud_firestore"
```

---

## Firestore Rule Cheat Sheet

| Concept | Example | Meaning |
|---------|---------|---------|
| Auth check | `request.auth != null` | User is logged in |
| UID match | `request.auth.uid == userId` | User owns resource |
| Field check | `'taxCalculatedBy' in data` | Field exists |
| Has any | `data.keys().hasAny(['a','b'])` | Has at least one field |
| Has all | `data.keys().hasAll(['a','b'])` | Has all fields |
| String match | `data.email.matches('^[a-z]+@.*')` | Regex match |
| Type check | `data.amount is number` | Correct type |
| Enum | `data.status in ['paid','unpaid']` | Valid enum value |
| Negation | `!condition` | Opposite of condition |
| AND | `condition1 && condition2` | Both must be true |
| OR | `condition1 \|\| condition2` | Either must be true |

---

## Deployment Checklist

- [ ] Rules file syntax valid: `firebase deploy --dry-run`
- [ ] All finance rules added (tax queue, config, invoices, etc.)
- [ ] Protected fields enforced (taxCalculatedBy)
- [ ] Queue rules prevent client creation
- [ ] Config rules are read-only
- [ ] User scope enforced (request.auth.uid == userId)
- [ ] Audit trails immutable (no update/delete)
- [ ] Test user can create invoice
- [ ] Test user cannot spoof tax
- [ ] Test server can update tax fields
- [ ] Production deployment successful
- [ ] Monitor rule denials for 24h

---

## Resources

- **Full Security Model:** [FINANCE_MODULE_SECURITY_MODEL.md](FINANCE_MODULE_SECURITY_MODEL.md)
- **Tax Queue Details:** [TAX_QUEUE_SYSTEM_DOCUMENTATION.md](TAX_QUEUE_SYSTEM_DOCUMENTATION.md)
- **Firestore Rules Docs:** https://firebase.google.com/docs/firestore/security/rules-structure

---

**Last Updated:** December 10, 2025  
**Status:** ✅ Deployed  
**Compiler Status:** ✅ No errors
