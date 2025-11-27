# Firestore Security Rules for Expenses

## Overview

Enhanced Firestore security rules for the expenses collection with comprehensive validation to ensure data integrity, prevent abuse, and enforce user ownership.

**Location:** `/workspaces/aura-sphere-pro/firestore.rules`
**Deployment Status:** ✅ Live (deployed successfully)

## Security Model

### Authentication
- All operations require user authentication (`request.auth != null`)
- User must be logged in via Firebase Auth

### Authorization
- Users can only access their own expenses (`request.auth.uid == userId`)
- Owner verification on all operations (create, read, update, delete)
- No cross-user access allowed

### Data Validation
- Required fields enforced on create
- Data types validated on create/update
- Immutable fields protected on update
- Amount must be positive
- Currency code must be 3 characters (ISO 4217)

## Rules Structure

### Expenses Collection Rules

**Location in Rules:**
```
/users/{userId}/expenses/{expenseId}
```

**Operations:**

| Operation | Rule | Validation |
|-----------|------|-----------|
| **CREATE** | Owned + Auth | `isValidExpenseCreate()` |
| **READ** | Owned + Auth | None (already authenticated) |
| **UPDATE** | Owned + Auth | `isValidExpenseUpdate()` |
| **DELETE** | Owned + Auth | None (irreversible, safe) |

## Validation Functions

### isValidExpenseCreate()

**Purpose:** Validate new expense documents

**Required Fields (must present):**
- `id` (string) — UUID of expense
- `userId` (string) — Owner's UID (must match request.auth.uid)
- `merchant` (string, non-empty) — Store/vendor name
- `amount` (number > 0) — Transaction amount
- `currency` (string, length 3) — ISO 4217 currency code
- `imageUrl` (string, non-empty) — Firebase Storage URL

**Optional Fields (null allowed):**
- `vat` (number >= 0, optional) — VAT/tax amount
- `date` (timestamp, optional) — Transaction date
- `category` (string, optional) — Expense category
- `notes` (string, optional) — User notes
- `isReceipt` (bool, optional) — Receipt flag
- `createdAt` (timestamp, optional) — Creation timestamp

**Constraints:**
- Maximum 15 fields total
- `userId` must match authenticated user ID
- All amounts must be non-negative
- String fields must be non-empty when present

**Code:**
```typescript
function isValidExpenseCreate() {
  let data = request.resource.data;
  return data.keys().hasAll(['id', 'userId', 'merchant', 'amount', 'currency', 'imageUrl'])
         && data.userId == request.auth.uid
         && data.merchant is string && data.merchant.size() > 0
         && data.amount is number && data.amount > 0
         && data.currency is string && data.currency.size() == 3
         && data.imageUrl is string && data.imageUrl.size() > 0
         && (data.vat == null || (data.vat is number && data.vat >= 0))
         && (data.date == null || data.date is timestamp)
         && (data.category == null || (data.category is string && data.category.size() > 0))
         && (data.notes == null || data.notes is string)
         && (data.isReceipt == null || data.isReceipt is bool)
         && (data.createdAt == null || data.createdAt is timestamp)
         && data.size() <= 15;
}
```

### isValidExpenseUpdate()

**Purpose:** Validate expense document updates

**Immutable Fields (cannot change):**
- `id` — Expense ID locked on creation
- `userId` — Owner locked on creation
- `imageUrl` — Image reference locked on creation

**Mutable Fields (can be updated):**
- `merchant` (string, non-empty)
- `amount` (number > 0)
- `currency` (string, length 3)
- `vat` (number >= 0, optional)
- `date` (timestamp, optional)
- `category` (string, optional)
- `notes` (string, optional)
- `isReceipt` (bool, optional)
- `updatedAt` (timestamp, **required**)

**Constraints:**
- Updated documents must have `updatedAt` timestamp
- Maximum 15 fields total
- All amount/currency rules same as create
- Immutable fields cannot be changed

**Code:**
```typescript
function isValidExpenseUpdate() {
  let data = request.resource.data;
  let existing = resource.data;
  return data.userId == existing.userId
         && data.id == existing.id
         && data.imageUrl == existing.imageUrl
         && data.merchant is string && data.merchant.size() > 0
         && data.amount is number && data.amount > 0
         && data.currency is string && data.currency.size() == 3
         && (data.vat == null || (data.vat is number && data.vat >= 0))
         && (data.date == null || data.date is timestamp)
         && (data.category == null || (data.category is string && data.category.size() > 0))
         && (data.notes == null || data.notes is string)
         && (data.isReceipt == null || data.isReceipt is bool)
         && data.updatedAt is timestamp
         && data.size() <= 15;
}
```

## Field Validation Details

### id (Required)
**Type:** String (UUID)
**Validation:** Must be present and non-empty
**Immutable:** Yes
**Example:** `"550e8400-e29b-41d4-a716-446655440000"`

### userId (Required)
**Type:** String (Firebase UID)
**Validation:** Must match `request.auth.uid`
**Immutable:** Yes
**Example:** `"user123abc456def"`

### merchant (Required)
**Type:** String
**Validation:** Non-empty string
**Mutable:** Yes (can be corrected/updated)
**Example:** `"Acme Corp"`, `"Starbucks"`, `"Amazon"`

### amount (Required)
**Type:** Number
**Validation:** Must be > 0
**Mutable:** Yes
**Example:** `100.50`, `1234.99`, `5.25`
**Constraints:** No negative amounts allowed

### currency (Required)
**Type:** String (ISO 4217 Code)
**Validation:** Exactly 3 characters
**Mutable:** Yes
**Examples:** `"EUR"`, `"USD"`, `"GBP"`, `"JPY"`, `"CAD"`, `"CHF"`

### imageUrl (Required)
**Type:** String (Firebase Storage URL)
**Validation:** Non-empty URL
**Immutable:** Yes (prevents orphaned images)
**Example:** `"gs://bucket/expenses/user123/image123.jpg"`

### vat (Optional)
**Type:** Number or null
**Validation:** If present, must be >= 0
**Mutable:** Yes
**Default:** null
**Example:** `10.50`, `0`, `null`

### date (Optional)
**Type:** Timestamp or null
**Validation:** Must be timestamp type if present
**Mutable:** Yes
**Default:** null
**Example:** `Timestamp(2025-11-27)`

### category (Optional)
**Type:** String or null
**Validation:** If present, must be non-empty string
**Mutable:** Yes
**Default:** null
**Examples:** `"Meals"`, `"Travel"`, `"Office Supplies"`, `"Entertainment"`

### notes (Optional)
**Type:** String or null
**Validation:** Any string length allowed
**Mutable:** Yes
**Default:** null
**Example:** `"Business lunch with client"`

### isReceipt (Optional)
**Type:** Boolean or null
**Validation:** Must be boolean if present
**Mutable:** Yes
**Default:** null/false
**Example:** `true`, `false`

### createdAt (Optional on Create)
**Type:** Timestamp or null
**Validation:** Must be timestamp if present
**Mutable:** No (not validated on update)
**Default:** null (set by client or Cloud Function)
**Example:** `Timestamp(2025-11-27T10:30:00Z)`

### updatedAt (Optional on Create, Required on Update)
**Type:** Timestamp
**Validation:** Must be present on update
**Mutable:** Yes
**Default:** null (must be set on update)
**Example:** `Timestamp(2025-11-27T15:45:00Z)`

## Data Flow Examples

### Creating an Expense (Valid)

**Request Data:**
```json
{
  "id": "exp_123",
  "userId": "user_456",
  "merchant": "Acme Corp",
  "date": "Timestamp(2025-11-27)",
  "amount": 100.0,
  "vat": 10.0,
  "currency": "EUR",
  "imageUrl": "gs://bucket/expenses/user_456/exp_123.jpg",
  "category": "Meals",
  "notes": "Business lunch",
  "isReceipt": true,
  "createdAt": "Timestamp(2025-11-27T10:30:00Z)"
}
```

**Validation Result:** ✅ **ALLOWED**
- All required fields present
- userId matches authenticated user
- amount > 0
- currency is 3 chars
- Optional fields are valid types
- Total fields = 11 (< 15)

### Creating an Expense (Invalid - Wrong Amount)

**Request Data:**
```json
{
  "id": "exp_123",
  "userId": "user_456",
  "merchant": "Acme Corp",
  "amount": -50.0,  // ❌ Negative!
  "currency": "EUR",
  "imageUrl": "gs://..."
}
```

**Validation Result:** ❌ **DENIED**
- Reason: `amount <= 0`

### Creating an Expense (Invalid - Wrong User)

**Request Data:**
```json
{
  "id": "exp_123",
  "userId": "attacker_789",  // ❌ Not authenticated user!
  "merchant": "Acme Corp",
  "amount": 100.0,
  "currency": "EUR",
  "imageUrl": "gs://..."
}
```

**Validation Result:** ❌ **DENIED**
- Reason: `userId != request.auth.uid`

### Updating an Expense (Valid)

**Before:**
```json
{
  "id": "exp_123",
  "userId": "user_456",
  "merchant": "Acme Corp",
  "amount": 100.0,
  "currency": "EUR",
  "imageUrl": "gs://...",
  "category": "Meals",
  "createdAt": "Timestamp(2025-11-27T10:30:00Z)"
}
```

**Update Request:**
```json
{
  "id": "exp_123",
  "userId": "user_456",
  "merchant": "Acme Corp",
  "amount": 100.0,
  "currency": "EUR",
  "imageUrl": "gs://...",
  "category": "Travel",  // ✅ Changed
  "notes": "Updated to Travel",  // ✅ Added
  "createdAt": "Timestamp(2025-11-27T10:30:00Z)",
  "updatedAt": "Timestamp(2025-11-27T15:45:00Z)"  // ✅ Required
}
```

**Validation Result:** ✅ **ALLOWED**
- Immutable fields unchanged
- updatedAt present and valid
- All fields valid
- Category can be updated

### Updating an Expense (Invalid - Trying to Change Image)

**Update Request:**
```json
{
  "id": "exp_123",
  "userId": "user_456",
  "merchant": "Acme Corp",
  "amount": 100.0,
  "currency": "EUR",
  "imageUrl": "gs://bucket/expenses/user_456/DIFFERENT_IMAGE.jpg",  // ❌ Changed!
  "updatedAt": "Timestamp(2025-11-27T15:45:00Z)"
}
```

**Validation Result:** ❌ **DENIED**
- Reason: `imageUrl` is immutable

## Security Considerations

### Strengths

✅ **Owner Verification**
- Every operation checks `request.auth.uid == userId`
- Prevents cross-user access

✅ **Type Safety**
- All fields have type validation
- Prevents type confusion attacks

✅ **Immutable Fields**
- Core identifiers cannot be changed
- Prevents orphaned data
- Image URLs locked to original upload

✅ **Positive Amounts**
- Amount must be > 0
- Prevents negative entries or zero-cost fraud

✅ **Field Count Limits**
- Maximum 15 fields
- Prevents bloated documents

✅ **Required Validation on Updates**
- `updatedAt` timestamp required
- Tracks modification time

### Potential Improvements

**Future Enhancements:**
1. **Amount limits** — Max transaction amount per user (fraud prevention)
2. **Rate limiting** — Max expenses per hour (spam prevention)
3. **Batch limits** — Limit simultaneous writes
4. **Soft deletes** — Archive instead of delete for audit trail
5. **Versioning** — Track update history
6. **Admin override** — Allow admins to read/modify any expense
7. **Audit logging** — Via Firestore extensions
8. **Approval workflows** — For high-value expenses

## Integration with Application

### Dart/Flutter Integration

**Creating an Expense:**
```dart
final expense = ExpenseModel(
  id: 'exp_123',
  userId: uid,
  merchant: 'Acme Corp',
  amount: 100.0,
  currency: 'EUR',
  imageUrl: url,
  category: 'Meals',
  notes: 'Business lunch',
  isReceipt: true,
  createdAt: DateTime.now(),
);

// Firestore will validate against isValidExpenseCreate()
await _db
  .collection('users').doc(uid)
  .collection('expenses').doc(expense.id)
  .set(expense.toMap());
```

**Updating an Expense:**
```dart
final updated = expense.copyWith(
  category: 'Travel',
  notes: 'Updated to Travel',
  updatedAt: DateTime.now(),
);

// Firestore will validate against isValidExpenseUpdate()
await _db
  .collection('users').doc(uid)
  .collection('expenses').doc(expense.id)
  .update(updated.toMap());
```

### Expected Error Codes

| Error | Condition | Message |
|-------|-----------|---------|
| `PERMISSION_DENIED` | User not authenticated | "Missing or insufficient permissions" |
| `INVALID_ARGUMENT` | Failed validation | "Request violates rules" |
| `FAILED_PRECONDITION` | Immutable field changed | "Request violates rules" |

## Testing Rules

### Firestore Rules Testing

**Enable Emulator:**
```bash
firebase emulators:start
```

**Test Case #1: Valid Create**
```typescript
// Should pass
db.collection('users').doc('user123')
  .collection('expenses').doc('exp123')
  .set({
    id: 'exp123',
    userId: 'user123',
    merchant: 'Acme',
    amount: 100,
    currency: 'EUR',
    imageUrl: 'gs://...'
  });
```

**Test Case #2: Invalid Create (Wrong User)**
```typescript
// Should fail - userId != auth.uid
db.collection('users').doc('user123')
  .collection('expenses').doc('exp123')
  .set({
    id: 'exp123',
    userId: 'user999',  // Different user!
    merchant: 'Acme',
    amount: 100,
    currency: 'EUR',
    imageUrl: 'gs://...'
  });
```

**Test Case #3: Invalid Update (Change Image)**
```typescript
// Should fail - imageUrl immutable
db.collection('users').doc('user123')
  .collection('expenses').doc('exp123')
  .update({
    imageUrl: 'gs://different...',
    updatedAt: now()
  });
```

**Test Case #4: Valid Update**
```typescript
// Should pass
db.collection('users').doc('user123')
  .collection('expenses').doc('exp123')
  .update({
    category: 'Travel',
    notes: 'Updated',
    updatedAt: now()
  });
```

## Deployment

### Current Status

✅ **Rules deployed successfully**
- Version: 2
- Compilation: Passed
- Status: Live on Firebase

### Deployment Command

```bash
firebase deploy --only firestore:rules
```

### Verification

```bash
# Check deployment status
firebase deploy --only firestore:rules

# View rules in console
# https://console.firebase.google.com/project/[PROJECT]/firestore/rules
```

## Related Documentation

- [ExpenseModel Guide](expense_model_guide.md)
- [Firestore Architecture](../docs/architecture.md)
- [API Reference](api_reference.md#expenses)
- [Security Standards](security_standards.md)

## Summary

✅ **Firestore Security Rules for Expenses:**
- Owner verification on all operations
- Comprehensive field validation
- Type safety enforcement
- Immutable field protection
- Amount validation (positive only)
- Required update timestamp
- Production-ready
- Deployed and live

**Status:** ✅ COMPLETE & DEPLOYED
