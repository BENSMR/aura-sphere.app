# 🔒 Firestore Security Reference - AuraSphere Pro

**Last Updated**: December 16, 2025  
**Commit**: `8d66c4e0` - Enhanced validation rules  
**Status**: ✅ Production-Ready

---

## 📋 TABLE OF CONTENTS

1. [Security Architecture](#security-architecture)
2. [Helper Functions](#helper-functions)
3. [Collection Rules](#collection-rules)
4. [Deployment Checklist](#deployment-checklist)
5. [Testing Guide](#testing-guide)
6. [Troubleshooting](#troubleshooting)

---

## 🏛️ SECURITY ARCHITECTURE

### Multi-Layer Defense

```
Layer 1: Authentication
├─ Firebase Auth (UID ownership)
├─ Custom Claims (role: owner|employee|admin)
└─ Token validation (isAuthenticated)

Layer 2: Authorization (RBAC)
├─ Role-based access (isOwner, isEmployee, isAdmin)
├─ Document ownership (isResourceOwner)
└─ Field-level permissions (keys().hasOnly)

Layer 3: Validation
├─ Data type checking (is string, is number, is list)
├─ Format validation (email, phone, amount)
├─ Enum validation (status in [values])
└─ Range validation (quantity >= 0)

Layer 4: Audit Trail
├─ Immutable subcollections (movements, interactions, comments)
├─ Timestamp tracking (lastModified, date)
└─ User attribution (userId, assignedTo)
```

### Access Control Matrix

| Collection | Owner | Employee | Admin | Public |
|------------|-------|----------|-------|--------|
| **Users** | RW (self) | R (self) | RW | - |
| **Expenses** | CRUD | - | RW | - |
| **Contacts** | CRUD | R (assigned) | RW | - |
| **Stock** | CRUD | - | RW | - |
| **Tasks** | CRUD | RU (assigned) | RW | - |
| **Invoices** | CRUD | - | RW | - |
| **Settings** | RW (user) | - | RW | - |
| **Loyalty** | R | - | - | R (public config) |
| **Analytics** | - | - | R (analysts) | - |

**Legend**: R=Read, W=Write, U=Update, CRUD=Create/Read/Update/Delete, RU=Read+Update, - = Denied

---

## 🛠️ HELPER FUNCTIONS

### Authentication

```dart
isAuthenticated()
// Returns: true if user has valid Firebase Auth token
// Usage: Gate all user-specific operations
// Example: allow read: if isAuthenticated() && ...
```

### Role-Based

```dart
isAdmin()
// Returns: true if request.auth.token.admin == true
// Usage: Admin-only operations (analytics, configurations)
// Set via: Cloud Function onUserCreate with custom claims

isOwner()
// Returns: true if user has 'owner' role in custom claims
// Default: 'owner' (backward compatible)
// Usage: Business owner features (invoices, suppliers, billing)

isEmployee()
// Returns: true if user has 'employee' role in custom claims
// Usage: Limited-access features (read-only contacts/tasks)
```

### Ownership

```dart
isResourceOwner(userId)
// Param: userId - The document's owner UID
// Returns: true if request.auth.uid == userId
// Usage: Verify document ownership before CRUD
// Example: allow read: if isResourceOwner(uid) && ...
```

### Data Validation

#### Email

```dart
hasValidEmail(email)
// Pattern: ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
// Returns: true if valid email format
// Usage: Contacts creation, user profile updates
// Rejects: invalid domains, special chars, missing @
```

#### Phone

```dart
hasValidPhone(phone)
// Pattern: ^[+0-9 ()-]+$
// Returns: true if valid phone format
// Usage: Contact validation, SMS verification
// Allows: +, -, (), spaces, digits
// Rejects: letters, special symbols, invalid chars
```

#### Amount

```dart
hasValidAmount(amount)
// Condition: amount is number && amount > 0
// Returns: true if positive number
// Usage: Expenses, invoices, stock costs
// Rejects: zero, negative, non-numeric values
```

---

## 📚 COLLECTION RULES

### 👤 USERS COLLECTION

**Path**: `/users/{userId}`

**Purpose**: User account data (profile, settings, preferences)

**Access Rules**:
```
READ:   User can read own document only
WRITE:  User can write own document only
ADMIN:  Admins can read/write any user document
```

**Schema**:
```json
{
  "uid": "auth.uid",
  "email": "user@example.com",
  "displayName": "John Doe",
  "role": "owner|employee",
  "subscription": "free|pro|enterprise",
  "auraTokens": 1000,
  "lastLogin": timestamp,
  "createdAt": timestamp
}
```

---

### 💰 EXPENSES COLLECTION

**Path**: `/expenses/{expenseId}`

**Purpose**: Track business expenses and receipts

**Validation Rules**:

| Field | Type | Required | Validation |
|-------|------|----------|-----------|
| `userId` | string | ✅ | Must equal request.auth.uid |
| `amount` | number | ✅ | Must be > 0 |
| `vendor` | string | ✅ | Non-empty |
| `category` | string | ✅ | Valid enum |
| `items` | array | ✅ | Must have 1+ items |
| `date` | timestamp | ✅ | Valid timestamp |
| `receipt` | string | ⚪ | Storage path (optional) |
| `notes` | string | ⚪ | Max 500 chars |
| `status` | string | ⚪ | pending\|approved\|rejected |

**Access Rules**:
```
CREATE: User authenticates, userId matches auth.uid, all required fields valid
READ:   User owns expense (userId == auth.uid)
UPDATE: User owns expense, cannot change userId
DELETE: User owns expense
```

**Example**:
```dart
// Valid creation
Expense(
  userId: 'user123',
  amount: 99.99,
  vendor: 'Amazon',
  category: 'supplies',
  items: ['Monitors x2'],
  date: now,
  receipt: 'receipts/user123/exp123.pdf'
)
```

**Subcollection**: `/expenses/{id}/items`
- Detailed line item breakdown
- Inherited ownership from parent expense
- Immutable audit trail

---

### 📇 CONTACTS COLLECTION

**Path**: `/contacts/{id}`

**Purpose**: Manage clients, suppliers, and business contacts

**Validation Rules**:

| Field | Type | Required | Validation |
|-------|------|----------|-----------|
| `userId` | string | ✅ | Must equal auth.uid |
| `name` | string | ✅ | Non-empty, < 100 chars |
| `phone` | string | ✅ | Valid phone format |
| `email` | string | ⚪ | Valid email format |
| `type` | string | ✅ | client\|supplier\|other |
| `company` | string | ⚪ | Optional |
| `address` | string | ⚪ | Optional |
| `tags` | array | ⚪ | String array |

**Access Rules**:
```
CREATE: User auth, name + phone required + valid, type enum checked
READ:   User owns contact
UPDATE: User owns contact, email/phone validated if present
DELETE: User owns contact
```

**Example**:
```dart
Contact(
  userId: 'user123',
  name: 'Acme Corp',
  phone: '+1-555-123-4567',
  email: 'contact@acme.com',
  type: 'client',
  company: 'ACME Corporation',
  tags: ['priority', 'vip']
)
```

**Subcollection**: `/contacts/{id}/interactions`
- Call logs, email records, meetings
- Type: call\|email\|meeting\|note
- Immutable (no delete allowed)
- User attribution (creator) tracked

---

### 📦 STOCK COLLECTION

**Path**: `/stock/{id}`

**Purpose**: Inventory and stock management

**Validation Rules**:

| Field | Type | Required | Validation |
|-------|------|----------|-----------|
| `userId` | string | ✅ | Must equal auth.uid |
| `item` | string | ✅ | Non-empty item name |
| `quantity` | number | ✅ | >= 0 (no negative stock) |
| `cost` | number | ✅ | > 0 (positive cost) |
| `sku` | string | ✅ | Non-empty SKU |
| `category` | string | ✅ | Valid category |
| `supplier` | string | ⚪ | Optional supplier |
| `reorderLevel` | number | ⚪ | Optional threshold |

**Access Rules**:
```
CREATE: User auth, all required fields validated, quantity >= 0, cost > 0
READ:   User owns stock item
UPDATE: User owns stock, quantity >= 0, cost >= 0 (no negative updates)
DELETE: User owns stock
```

**Example**:
```dart
StockItem(
  userId: 'user123',
  item: 'USB Monitor Cable',
  quantity: 50,
  cost: 12.99,
  sku: 'MONC-USB-001',
  category: 'electronics',
  supplier: 'TechSupply Inc',
  reorderLevel: 20
)
```

**Subcollection**: `/stock/{id}/movements`
- In/Out/Adjustment movements
- Type: in\|out\|adjustment
- Immutable audit trail (delete denied)
- Timestamp and quantity tracked

---

### ✅ TASKS COLLECTION

**Path**: `/tasks/{id}`

**Purpose**: Task management and project tracking

**Validation Rules**:

| Field | Type | Required | Validation |
|-------|------|----------|-----------|
| `userId` | string | ✅ | Must equal auth.uid |
| `title` | string | ✅ | Non-empty, < 200 chars |
| `dueDate` | timestamp | ✅ | Valid future timestamp |
| `status` | string | ✅ | open\|in_progress\|completed\|cancelled |
| `description` | string | ⚪ | Optional task details |
| `priority` | string | ⚪ | low\|medium\|high |
| `assignedTo` | string | ⚪ | Employee UID |
| `completedAt` | timestamp | ⚪ | Set when completed |

**Access Rules**:

**Owners**:
```
READ:   Read all own tasks
WRITE:  Create/update/delete any task
```

**Employees**:
```
READ:   Read tasks assigned to them
UPDATE: Update only: status, completedAt, notes
```

**Example**:
```dart
Task(
  userId: 'owner123',
  title: 'Q4 Budget Review',
  dueDate: timestamp,
  status: 'in_progress',
  priority: 'high',
  assignedTo: 'employee456',
  description: 'Complete quarterly financial review'
)
```

**Subcollection**: `/tasks/{id}/comments`
- Comment threads on tasks
- Created by: user UID
- Date: timestamp
- Immutable (only creator can delete)

---

### 📄 INVOICES COLLECTION

**Path**: `/invoices/{docId}`

**Purpose**: Invoice generation and billing

**Access Rules**:
```
OWNER-ONLY: Both creation and reading restricted to isOwner() role
```

**Validation Rules**:

| Field | Type | Required | Validation |
|-------|------|----------|-----------|
| `invoiceNumber` | string | ✅ | Non-empty unique |
| `clientId` | string | ✅ | Valid client reference |
| `total` | number | ✅ | > 0 (positive amount) |
| `items` | array | ✅ | Must have 1+ items |
| `dueDate` | timestamp | ✅ | Valid timestamp |
| `status` | string | ✅ | draft\|sent\|paid\|overdue\|cancelled |

**Example**:
```dart
Invoice(
  invoiceNumber: 'INV-2025-001',
  clientId: 'client123',
  total: 1500.00,
  items: [
    {'description': 'Service', 'amount': 1500.00}
  ],
  dueDate: timestamp,
  status: 'sent',
  createdAt: timestamp,
  paidAt: null
)
```

---

### 👥 CLIENTS COLLECTION (RBAC)

**Path**: `/clients/{clientId}`

**Purpose**: Client contact management with role-based access

**Owner Access**:
```
READ:   All clients
WRITE:  Create/update/delete clients
```

**Employee Access**:
```
READ:   Clients assigned to them (assignedTo == uid)
WRITE:  DENIED
```

**Validation**:
```
- name: Non-empty string
- email: Optional but validated if present
- phone: Optional but validated if present
- assignedTo: Employee UID for assignment
```

---

### 📊 ADMIN COLLECTIONS

#### Admin Panel Data

**Path**: `/admin/{doc=**}`

**Access**:
```
READ:   Any authenticated user
WRITE:  Admins only (isAdmin())
```

#### Admin Logs

**Path**: `/admin_logs/{doc=**}`

**Access**:
```
READ:   Admins only (isAdmin())
WRITE:  Server-side only (disabled for clients)
```

---

### 💎 LOYALTY SYSTEM

#### User Wallet

**Path**: `/users/{userId}/wallet/aura`

**Access**:
```
READ:   User can read own balance
WRITE:  Server-only (Cloud Functions)
```

**Data**:
```json
{
  "balance": 1000,
  "lastUpdated": timestamp,
  "tier": "bronze|silver|gold|platinum"
}
```

#### Token Transactions

**Path**: `/users/{userId}/token_audit/{auditId}`

**Access**:
```
READ:   User can read own transactions
WRITE:  Server-only (immutable)
DELETE: Denied (audit trail)
```

---

## ✅ DEPLOYMENT CHECKLIST

### Pre-Deployment

- [ ] Review all rules in `firestore.rules`
- [ ] Run `firebase rules:test` (if test files exist)
- [ ] Verify custom claims setup in Cloud Functions
- [ ] Test authentication flows locally
- [ ] Confirm Firebase project configuration

### Deployment Steps

```bash
# 1. Validate rules syntax
firebase rules:test

# 2. Deploy rules to production
firebase deploy --only firestore:rules

# 3. Verify deployment
firebase rules:list

# 4. Monitor errors for 24 hours
# Check Firebase Console > Cloud Firestore > Rules
```

### Post-Deployment

- [ ] Monitor rule rejection rates in Cloud Logging
- [ ] Test all CRUD operations on mobile + web
- [ ] Verify employee role restrictions work
- [ ] Test offline persistence sync
- [ ] Monitor Sentry for permission errors

---

## 🧪 TESTING GUIDE

### Manual Testing

#### Test 1: User Isolation

```dart
// As User A, create expense
// Attempt: Read User B's expense (should fail)
// Expected: Permission denied error

try {
  await firestore.collection('expenses').doc(otherUserId).get();
  print('FAIL: Should not access other user data');
} catch (e) {
  print('PASS: Correctly blocked access');
}
```

#### Test 2: Email Validation

```dart
// Valid email
Contact(name: 'John', phone: '+1234567890', email: 'john@example.com')
// ✅ Passes

// Invalid email (no @)
Contact(name: 'John', phone: '+1234567890', email: 'johnexample.com')
// ❌ Rejected by rules

// Invalid email (no domain)
Contact(name: 'John', phone: '+1234567890', email: 'john@')
// ❌ Rejected by rules
```

#### Test 3: Role-Based Access (Employee)

```dart
// Setup: User A (owner), User B (employee, assigned to task)

// User B attempts to read all tasks (should fail)
await firestore.collection('tasks').get()
// ❌ Permission denied

// User B reads assigned task (should pass)
await firestore.collection('tasks')
  .where('assignedTo', isEqualTo: userB.uid).get()
// ✅ Success

// User B updates task status (should pass)
await firestore.collection('tasks').doc(taskId).update({
  'status': 'completed',
  'completedAt': FieldValue.serverTimestamp()
})
// ✅ Success

// User B tries to delete task (should fail)
await firestore.collection('tasks').doc(taskId).delete()
// ❌ Permission denied
```

#### Test 4: Admin Operations

```dart
// User without admin token tries to access analytics
await firestore.collection('analytics').get()
// ❌ Permission denied

// Admin user accesses analytics
// (token must have admin: true custom claim)
await firestore.collection('analytics').get()
// ✅ Success
```

### Automated Testing (CI/CD)

```bash
# Run Firestore rules tests
firebase emulators:start --only firestore &
npm test  # Runs test suite against emulator

# Deploy to staging first
firebase deploy --only firestore:rules --project staging

# Wait 24 hours for monitoring
# Then deploy to production
firebase deploy --only firestore:rules --project production
```

---

## 🔧 TROUBLESHOOTING

### Common Errors

#### "Missing or insufficient permissions"

**Cause**: User not authenticated or lacks role for operation

**Solution**:
```dart
// Check user authentication
if (FirebaseAuth.instance.currentUser == null) {
  // User not logged in
}

// Verify custom claims
var user = FirebaseAuth.instance.currentUser;
var claims = user?.getIdTokenResult().claims;
print('Role: ${claims?['role']}');
```

#### "Document with invalid data"

**Cause**: Data doesn't match validation rules

**Solution**:
```dart
// Check data before write
var expense = {
  'userId': uid,        // ✅ Must match
  'amount': 99.99,      // ✅ Must be > 0
  'vendor': 'Amazon',   // ✅ Non-empty
  'items': ['item1'],   // ✅ Non-empty array
  'category': 'supplies', // ✅ Valid category
  'date': FieldValue.serverTimestamp(), // ✅ Timestamp
};

await firestore.collection('expenses').add(expense);
```

#### "Operation not allowed (update)"

**Cause**: Rule doesn't allow updating certain fields

**Solution**:
```dart
// Only specific fields allowed in some rules
// Check keys().hasOnly() restrictions

// ❌ Not allowed (extra fields)
await firestore.collection('tasks').doc(id).update({
  'status': 'completed',
  'completedAt': FieldValue.serverTimestamp(),
  'userId': uid,  // ❌ Cannot change user
});

// ✅ Allowed (whitelisted fields)
await firestore.collection('tasks').doc(id).update({
  'status': 'completed',
  'completedAt': FieldValue.serverTimestamp(),
});
```

### Monitoring

**Firebase Console**:
1. Go to Cloud Firestore > Rules
2. Check "Violations" tab for denied requests
3. Click on violations to see details

**Cloud Logging**:
```bash
gcloud logging read "resource.type=cloud_firestore" \
  --limit=50 \
  --format=json
```

**Sentry Integration**:
- Permission errors are logged to Sentry
- Check dashboard for patterns
- Correlate with user feedback

---

## 🚀 DEPLOYMENT STATUS

✅ **Rules Version**: 2  
✅ **Collections Covered**: 10+  
✅ **Helper Functions**: 9  
✅ **RBAC Levels**: 3 (Owner/Employee/Admin)  
✅ **Validation Rules**: 30+  
✅ **Audit Trails**: 4 (movements, interactions, comments, logs)  

**Latest Commit**: `8d66c4e0`  
**Last Deployed**: [Set after deployment]  
**Review Date**: December 23, 2025

---

## 📞 SUPPORT

**Issues with rules?**
1. Check "Troubleshooting" section above
2. Review error message in Firebase Console
3. Verify data matches validation rules
4. Check custom claims via authentication token
5. Contact: security@aura-sphere.app
