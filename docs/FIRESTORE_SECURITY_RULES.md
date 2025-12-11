# Firestore Security Rules Reference

## Overview

Complete Firestore security rules for AuraSphere Pro with comprehensive validation for the clients collection, invoices, and related data structures.

## Collections & Rules

### Users Collection (`/users/{userId}`)

**Paths**:
- `/users/{userId}` - User profile (owned)
- `/users/{userId}/clients/{clientId}` - Clients subcollection
- `/users/{userId}/invoices/{invoiceId}` - Invoices subcollection
- `/users/{userId}/tasks/{taskId}` - Tasks subcollection
- `/users/{userId}/projects/{projectId}` - Projects subcollection
- `/users/{userId}/expenses/{expenseId}` - Expenses subcollection

**Rules**:
- Only user can read/write their own documents
- Critical fields (auraTokens, roles, token_audit) cannot be modified by users
- Cloud Functions can write to audit collections

---

## Clients Collection Rules

### Create Rules

Required fields:
- `userId` (string, owned user ID)
- `name` (string, 1-255 chars) **
- `email` (string, valid email) **
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

Optional fields with validation:
- `phone` (string, ≤20 chars)
- `company` (string, ≤255 chars)
- `address` (string, ≤500 chars)
- `country` (string, ≤100 chars)
- `notes` (string, ≤5000 chars)
- `tags` (array, ≤20 items)
- `status` (string) - must be: `active | inactive | prospect | churned | lead`
- `lifetimeValue` (number, ≥0)
- `totalInvoices` (number, ≥0)
- `lastInvoiceAmount` (number, ≥0)
- `aiScore` (number, 0-100)
- `churnRisk` (number, 0-100)
- `vipStatus` (boolean)
- `sentiment` (string) - must be: `positive | neutral | negative`
- `stabilityLevel` (string) - must be: `stable | unstable | risky | unknown`
- `aiTags` (array, ≤20 items, valid tags)
- `aiSummary` (string, ≤5000 chars)
- `timeline` (array, ≤1000 items)
- `lastActivityAt` (timestamp)
- `lastInvoiceDate` (timestamp)
- `lastPaymentDate` (timestamp)

**Max fields**: 35

### Update Rules

All same validations as create, plus:
- `userId` cannot be changed (immutable)
- `createdAt` cannot be changed (immutable)
- `updatedAt` should be updated
- Partial updates allowed (fields can be null)

### Timeline Events

Each timeline event must be valid:

```dart
{
  type: string (required) - one of:
    - 'invoice_created'
    - 'payment_received'
    - 'note'
    - 'interaction'
    - 'invoice_overdue'
    - 'invoice_cancelled'
    - 'invoice_refunded'
    - 'invoice_sent'
    - 'invoice_viewed'
  createdAt: timestamp (required)
  amount: number ≥ 0 (optional)
  invoiceId: string (optional)
  message: string ≤ 500 chars (optional)
}
```

**Max timeline events**: 1000 per client

### AI Tags

Valid tags (maximum 20):
- `VIP` - VIP client status
- `AT_RISK` - Churn risk 60-90
- `DORMANT` - Inactive 90+ days
- `RETURNING` - 5+ invoices
- `NEW` - 1 invoice only
- `HIGH_VALUE` - Lifetime value ≥€5,000
- `NEGATIVE_SENTIMENT` - Negative sentiment

---

## Invoices Collection

### Paths

**Nested Invoices**:
- `/users/{userId}/invoices/{invoiceId}`

**Top-level Invoices**:
- `/invoices/{invoiceId}`

### Create Rules

Required fields:
- `userId` (string) - must be current user
- `amountTotal` (number) - must be > 0

Optional fields:
- `clientId` (string)
- `status` (string) - one of: `draft | sent | paid | overdue | cancelled | refunded`
- `invoiceDate` (timestamp)
- `dueDate` (timestamp)
- `sentAt` (timestamp)
- `viewedAt` (timestamp)
- `paidAt` (timestamp)
- `items[]` (array)

### Update Rules

Only status updates allowed on non-critical fields:
- `status` must be valid
- Cannot change `userId`, `createdAt`
- `amountTotal` must remain > 0

---

## Email Queue (`/mail/{docId}`)

- Write allowed for authenticated users (send emails)
- Read forbidden (privacy)
- Used by Firebase Email Extension

---

## Security Helpers

### Authentication
```
isAuthenticated(): request.auth != null
```

### Ownership
```
isOwner(userId): request.auth.uid == userId
```

### Admin Check
```
isAdmin(): exists(/databases/{database}/documents/admins/{request.auth.uid})
```

### Email Validation
```
isValidEmail(email): email matches regex ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
```

---

## Deployment

### Testing Rules

```bash
# Validate rules syntax
firebase validate --only firestore

# Deploy to production
firebase deploy --only firestore:rules

# Deploy with test data
firebase deploy --only firestore
```

### Emulator Testing

```bash
# Start emulator
firebase emulators:start

# Run tests
firebase test
```

---

## Best Practices

### 1. Always Validate Input

```
Validate on create:
- All required fields present
- Field types correct
- String/number ranges valid
- Email format correct
```

### 2. Protect Immutable Fields

```
Prevent updates to:
- userId
- createdAt
- id (document ID)
```

### 3. Enforce Ownership

```
All operations:
- userId matches request.auth.uid
- No cross-user data access
```

### 4. Validate Enums

```
Status values: Use explicit list
Sentiment: 'positive' | 'neutral' | 'negative'
Stability: 'stable' | 'unstable' | 'risky' | 'unknown'
```

### 5. Limit Array Sizes

```
Timeline: max 1000 events
AI Tags: max 20 tags
Field keys: max 35 fields per document
```

### 6. Timestamp Handling

```
Always use: timestamp type
Server timestamps: request.time
Client timestamps: Firestore.Timestamp.now()
```

---

## Common Scenarios

### Allow User to Read Own Data
```
match /users/{userId} {
  allow read: if request.auth.uid == userId;
}
```

### Allow Cloud Functions Only (No User Access)
```
match /users/{userId}/token_audit/{auditId} {
  allow create: if false;  // Only Cloud Functions
  allow read: if request.auth.uid == userId;
}
```

### Allow Timestamped Data (Server-controlled)
```
&& request.resource.data.createdAt is timestamp
&& request.resource.data.updatedAt is timestamp
```

### Partial Updates
```
&& (data.fieldName == null || data.fieldName is string)
```

---

## Error Messages

When validation fails, you'll get errors like:
- `Missing or invalid required field`
- `Value outside allowed range`
- `Invalid enum value`
- `Unauthorized: not document owner`
- `Type mismatch (expected number, got string)`

---

## Monitoring

### Firebase Console
- Firestore → Rules
- Verify deployments successful
- Check usage statistics

### Cloud Logging
```bash
gcloud logging read "resource.type=cloud_firestore" --limit 50
```

### Test Mode
When developing, use test mode (allows all reads/writes):
```
rules_version = '2';
service cloud.firestore {
  match /{document=**} {
    allow read, write: if request.time < timestamp.value('2025-12-31T23:59:59Z');
  }
}
```

**⚠️ IMPORTANT**: Remove test mode before production deployment!

---

## Related Resources

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/start)
- [Rules Language Reference](https://firebase.google.com/docs/reference/rules/rules.RuleContext)
- [Security Best Practices](https://firebase.google.com/docs/firestore/security/best-practices)

---

## Validation Checklist

Before deploying:

- [ ] All required fields have validation
- [ ] Immutable fields protected
- [ ] Ownership checked for all operations
- [ ] Array sizes limited
- [ ] Enum values explicit
- [ ] Email regex correct
- [ ] Timestamp handling proper
- [ ] Cloud Functions exceptions granted
- [ ] No test mode rules in production
- [ ] Rules deploy without errors

---

## Client Field Summary (30 Fields)

| Field | Type | Required | Validation |
|-------|------|----------|-----------|
| name | string | ✓ | 1-255 chars |
| email | string | ✓ | Valid email |
| phone | string | | ≤20 chars |
| company | string | | ≤255 chars |
| address | string | | ≤500 chars |
| country | string | | ≤100 chars |
| notes | string | | ≤5000 chars |
| tags | array | | ≤20 items |
| status | string | | enum: active/inactive/prospect/churned/lead |
| lifetimeValue | number | | ≥0 |
| totalInvoices | number | | ≥0 |
| lastInvoiceAmount | number | | ≥0 |
| lastActivityAt | timestamp | | valid timestamp |
| lastInvoiceDate | timestamp | | valid timestamp |
| lastPaymentDate | timestamp | | valid timestamp |
| aiScore | number | | 0-100 |
| churnRisk | number | | 0-100 |
| vipStatus | boolean | | true/false |
| sentiment | string | | enum: positive/neutral/negative |
| aiTags | array | | ≤20 valid tags |
| aiSummary | string | | ≤5000 chars |
| stabilityLevel | string | | enum: stable/unstable/risky/unknown |
| timeline | array | | ≤1000 events, valid timeline events |
| userId | string | ✓ | Current user ID (immutable) |
| createdAt | timestamp | ✓ | Server timestamp (immutable) |
| updatedAt | timestamp | ✓ | Server timestamp |

