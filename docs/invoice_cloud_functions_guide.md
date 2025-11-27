# Invoice Cloud Functions Guide

## Overview

Two production-ready Firestore triggers for invoice lifecycle management:

1. **`onInvoiceCreated`** - Triggers when invoice created, awards 8 AuraTokens
2. **`onInvoicePaid`** - Triggers when invoice marked as paid, awards 15 AuraTokens

---

## File: `/functions/src/finance/onInvoiceCreated.ts`

### Function 1: `onInvoiceCreated`

**Trigger**: `users/{userId}/invoices/{invoiceId}` → onCreate

**Purpose**: 
- Award tokens for creating invoice
- Validate invoice data
- Create audit trail
- Log metrics

**Token Award**: 8 AuraTokens

**Flow**:
```
Invoice Created → Validate Data → Award Tokens → Create Audit Entry → Log Success
```

**Validations**:
✅ userId exists (from path)
✅ invoiceData not null
✅ clientName & clientEmail present
✅ items array not empty
✅ total > 0
✅ user exists in Firestore

**Error Handling**:
- Returns `{success: false, error}` if validation fails
- Does NOT throw (allows invoice creation to succeed)
- All errors logged with full context
- Transaction ensures atomic operation

**Response**:
```dart
{
  success: true,
  invoiceId: string,
  tokensAwarded: 8,
  newBalance: number
}
```

**Audit Trail** (stored in `users/{userId}/token_audit/{docId}`):
```json
{
  "action": "create_invoice",
  "amount": 8,
  "awardedBy": "system",
  "metadata": {
    "invoiceId": "abc123",
    "invoiceNumber": "INV-2024-001",
    "clientName": "Acme Corp",
    "total": 1500.00,
    "status": "draft",
    "itemCount": 3
  },
  "createdAt": timestamp
}
```

---

### Function 2: `onInvoicePaid`

**Trigger**: `users/{userId}/invoices/{invoiceId}` → onUpdate

**Purpose**:
- Award tokens when payment received
- Track paid invoices
- Create revenue audit entry

**Token Award**: 15 AuraTokens (higher reward for payment)

**Flow**:
```
Invoice Updated → Check if status→paid → Award Tokens → Create Audit Entry → Log Success
```

**Guard Clause**:
- Only processes if status changes TO 'paid'
- Ignores status changes from 'paid' to something else
- Ignores other field updates

**Error Handling**:
- Errors logged but NOT thrown
- Payment processing still succeeds even if token award fails
- Safe to handle quota/permission errors gracefully

---

## Usage in Flutter

### 1. Invoice Creation (Auto-triggers `onInvoiceCreated`)

```dart
// This automatically triggers onInvoiceCreated in Cloud Functions
await invoiceService.createInvoice(
  clientId: 'client_123',
  clientName: 'Acme Corp',
  clientEmail: 'acme@example.com',
  items: [
    InvoiceItem(description: 'Services', quantity: 10, unitPrice: 100),
  ],
  currency: 'USD',
  taxRate: 0.20,
  dueDate: DateTime.now().add(Duration(days: 30)),
);

// Result:
// - Invoice created ✅
// - 8 AuraTokens awarded ✅
// - Audit entry created ✅
// - User balance updated ✅
```

### 2. Mark Invoice as Paid (Auto-triggers `onInvoicePaid`)

```dart
// This automatically triggers onInvoicePaid in Cloud Functions
await invoiceService.markAsPaid(invoiceId);

// OR
await invoiceService.updateInvoiceStatus(invoiceId, 'paid');

// Result:
// - Invoice status updated to 'paid' ✅
// - paidDate set to now ✅
// - 15 AuraTokens awarded ✅
// - Audit entry created ✅
// - User balance updated ✅
```

### 3. Display Token Rewards

```dart
// Listen to token balance
Future<double> getUserTokenBalance(String userId) async {
  final walletDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('wallet')
    .doc('aura')
    .get();
  
  return walletDoc.data()?['balance'] ?? 0;
}

// Listen to audit trail
Stream<List<TokenAudit>> streamTokenAudits(String userId) {
  return FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('token_audit')
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((snap) => snap.docs.map((d) => TokenAudit.fromDoc(d)).toList());
}
```

---

## Firestore Data Structure

### Wallet (After Invoice Creation)

```
users/{userId}/wallet/aura
{
  balance: 8.0,                    // Increased from creation
  updatedAt: timestamp
}
```

### Token Audit Trail

```
users/{userId}/token_audit/{docId}
{
  action: "create_invoice",
  amount: 8,
  awardedBy: "system",
  metadata: {
    invoiceId: "...",
    invoiceNumber: "INV-2024-001",
    clientName: "...",
    total: 1500.00,
    status: "draft",
    itemCount: 3
  },
  createdAt: timestamp
}

// Later, after payment:
{
  action: "invoice_paid",
  amount: 15,
  awardedBy: "system",
  metadata: {
    invoiceId: "...",
    invoiceNumber: "INV-2024-001",
    total: 1500.00
  },
  createdAt: timestamp
}
```

---

## Logging & Monitoring

### Log Examples

**Successful Creation**:
```
[INFO] Invoice created successfully and tokens awarded
userId: user_123
invoiceId: inv_456
invoiceNumber: INV-2024-001
clientName: Acme Corp
total: 1500
tokensAwarded: 8
newBalance: 108
```

**Validation Failure**:
```
[WARN] Invoice has no items
userId: user_123
invoiceId: inv_456
invoiceNumber: INV-2024-001
```

**Transaction Error**:
```
[ERROR] onInvoiceCreated function failed
userId: user_123
invoiceId: inv_456
error: Permission denied
```

### Monitoring Tokens Awarded

Query all invoices created by user:
```bash
firebase firestore:query --collection users/user_123/invoices --where status == 'draft'
```

View token audit trail:
```bash
firebase firestore:query --collection users/user_123/token_audit --order-by createdAt --limit 10
```

---

## Error Scenarios & Recovery

### Scenario 1: User Doesn't Exist
```
Error: User not found
Result: Function returns {success: false}
Invoice: Still created ✅
Tokens: NOT awarded (user missing)
Action: Check Firestore has users collection
```

### Scenario 2: Missing Invoice Items
```
Error: Invalid invoice: no items
Result: Function returns {success: false}
Invoice: Still created ✅
Tokens: NOT awarded (validation failed)
Action: Ensure UI prevents empty items before submission
```

### Scenario 3: Token Balance Already Exists
```
Result: Function updates balance via tx.update()
Tokens: Awarded successfully ✅
Recovery: Transaction is atomic, no partial state
```

### Scenario 4: Duplicate Payment (onInvoicePaid called twice)
```
First call: Status draft→paid, 15 tokens awarded ✅
Second call: Status already paid, guard clause prevents re-award ✅
Result: No double-awarding, safe idempotent
```

---

## Security & Permissions

### Firestore Rules

Ensure these rules allow document creation:

```javascript
// Users can create invoices in their subcollection
match /users/{userId}/invoices/{invoiceId} {
  allow create: if request.auth.uid == userId;
  allow update: if request.auth.uid == userId;
  allow delete: if request.auth.uid == userId;
  allow read: if request.auth.uid == userId;
}

// Cloud Functions write to wallet & token_audit with service account
match /users/{userId}/wallet/{document=**} {
  allow read: if request.auth.uid == userId;
  // write via service account only (Cloud Function)
}

match /users/{userId}/token_audit/{document=**} {
  allow read: if request.auth.uid == userId;
  // write via service account only (Cloud Function)
}
```

---

## Testing

### Local Testing with Emulator

1. Start emulators:
```bash
firebase emulators:start
```

2. Create test invoice via Firebase Emulator UI or Flutter app

3. Monitor logs:
```bash
firebase functions:log
```

4. Check Firestore in Emulator UI:
- Navigate to `users/{testUserId}/invoices/`
- Check `users/{testUserId}/wallet/aura`
- Check `users/{testUserId}/token_audit/`

### Test Cases

**Test 1: Create Valid Invoice**
- Expected: 8 tokens awarded
- Check: wallet balance increased, audit entry created

**Test 2: Create Invalid Invoice (no items)**
- Expected: validation error logged, tokens NOT awarded
- Check: invoice still exists but no audit entry

**Test 3: Mark Paid**
- Expected: 15 tokens awarded
- Check: separate audit entry with invoice_paid action

**Test 4: Mark Paid Twice**
- Expected: guard clause prevents duplicate award
- Check: second call returns early, no new audit entry

---

## Integration Checklist

- ✅ `/functions/src/finance/onInvoiceCreated.ts` created
- ✅ `onInvoiceCreated` trigger implemented with validation
- ✅ `onInvoicePaid` trigger implemented with guard clause
- ✅ Token audit trail created on award
- ✅ Comprehensive error handling & logging
- ✅ Exported in `functions/src/index.ts`
- ✅ TypeScript builds without errors
- ✅ Ready for deployment

---

## Next Steps

1. **Deploy**: `firebase deploy --only functions:onInvoiceCreated,functions:onInvoicePaid`
2. **Test**: Create invoice in app, verify tokens awarded
3. **Monitor**: Check Firebase Functions logs for errors
4. **Dashboard**: Create UI to display token balance & audit trail
5. **Rewards**: Consider additional token triggers (invoice overdue, payment received, etc.)

---

## Related Files

- `/lib/services/invoice_service.dart` - Creates invoices (triggers onCreate)
- `/lib/providers/invoice_provider.dart` - UI state management
- `/functions/src/auraToken/rewards.ts` - Token constants & logic
- `/functions/src/utils/logger.ts` - Logging utility
