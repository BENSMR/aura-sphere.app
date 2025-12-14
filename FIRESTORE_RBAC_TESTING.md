# Role-Based Access Control Testing Guide

## Quick Start

### Step 1: Enable Firestore Emulator

```bash
# In the project root
firebase emulators:start --only firestore
```

The emulator will output:
```
⚠️  firestore: listening at 127.0.0.1:8080
```

### Step 2: Connect App to Emulator

**In `lib/main.dart` or startup code:**

```dart
// For development/testing only
if (kDebugMode && false) { // Set to true to use emulator
  FirebaseFirestore.instance.settings = const Settings(
    host: '127.0.0.1:8080',
    sslEnabled: false,
    persistenceEnabled: false,
  );
  
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
}
```

Or via environment variable in `firebase.json`:
```json
{
  "emulators": {
    "firestore": {
      "port": 8080,
      "host": "127.0.0.1"
    },
    "auth": {
      "port": 9099,
      "host": "127.0.0.1"
    }
  }
}
```

### Step 3: Test with Firebase CLI

```bash
# List test users
firebase auth:list --project=aurasphere-pro

# Export current state
firebase firestore:backup --project=aurasphere-pro backups

# Import for reset
firebase firestore:restore backups/latest --project=aurasphere-pro
```

## Manual Testing Scenarios

### Scenario 1: Employee Reads Assigned Client

**Setup:**
```bash
# Create users in emulator
firebase auth:create emp@test.com --password=Test123! --project=demo
firebase auth:create owner@test.com --password=Test123! --project=demo
```

**Steps:**
1. Sign in as `owner@test.com`
2. Create client with `assignedTo: emp@test.com`
3. Sign out and sign in as `emp@test.com`
4. Verify can read the client
5. Try to edit - should fail with "Permission denied"

**Code Test:**
```dart
// Should succeed
final doc = await FirebaseFirestore.instance
  .collection('clients')
  .doc('client-123')
  .get();
print('Success: ${doc.data()}');

// Should fail
try {
  await FirebaseFirestore.instance
    .collection('clients')
    .doc('client-123')
    .update({'name': 'Updated'});
} on FirebaseException catch (e) {
  print('Expected error: ${e.code}'); // permission-denied
}
```

### Scenario 2: Employee Cannot Read Owner's Client

**Steps:**
1. Sign in as `owner@test.com`
2. Create client with `assignedTo: owner@test.com`
3. Sign out and sign in as `emp@test.com`
4. Try to read the client - should fail

**Code Test:**
```dart
try {
  final doc = await FirebaseFirestore.instance
    .collection('clients')
    .doc('owner-client')
    .get();
  print('Unexpected success: ${doc.data()}');
} on FirebaseException catch (e) {
  expect(e.code, 'permission-denied');
  print('Success: Employee cannot read owner client');
}
```

### Scenario 3: Employee Updates Own Task Status

**Setup:**
```dart
// Owner creates task assigned to employee
await FirebaseFirestore.instance
  .collection('tasks')
  .add({
    'title': 'Design Homepage',
    'assignedTo': 'emp@test.com',
    'status': 'pending',
    'createdAt': Timestamp.now(),
  });
```

**Steps:**
1. Sign out and sign in as `emp@test.com`
2. Update task status to 'completed' - should succeed
3. Try to change title - should fail (not in allowed fields)

**Code Test:**
```dart
// Should succeed - only status allowed
await FirebaseFirestore.instance
  .collection('tasks')
  .doc('task-123')
  .update({
    'status': 'completed',
    'completedAt': Timestamp.now(),
  });
print('Success: Task updated');

// Should fail - title not in allowed list
try {
  await FirebaseFirestore.instance
    .collection('tasks')
    .doc('task-123')
    .update({'title': 'Hacked!'});
  print('Unexpected success');
} on FirebaseException catch (e) {
  expect(e.code, 'permission-denied');
  print('Success: Cannot update task title');
}
```

### Scenario 4: Employee Creates Own Expense

**Steps:**
1. Sign in as `emp@test.com`
2. Create expense with `createdBy: current_user_uid`
3. Verify it appears in their expense list
4. Sign in as owner and verify they can see all expenses

**Code Test:**
```dart
// Employee creates expense
final expenseRef = await FirebaseFirestore.instance
  .collection('expenses')
  .add({
    'amount': 50.00,
    'category': 'meals',
    'createdBy': FirebaseAuth.instance.currentUser!.uid,
    'createdAt': Timestamp.now(),
  });
print('Created: ${expenseRef.id}');

// Employee can read their own
final doc = await expenseRef.get();
expect(doc.exists, true);

// Owner can read all
// (Switch to owner account)
final allExpenses = await FirebaseFirestore.instance
  .collection('expenses')
  .get();
expect(allExpenses.docs.length, greaterThan(0));
```

### Scenario 5: Employee Cannot Access Invoice

**Steps:**
1. Sign in as `emp@test.com`
2. Try to create invoice - should fail
3. Try to read invoice - should fail

**Code Test:**
```dart
// Should fail - Employee role not allowed
try {
  await FirebaseFirestore.instance
    .collection('invoices')
    .add({
      'number': 'INV-001',
      'amount': 1000,
    });
  print('Unexpected success');
} on FirebaseException catch (e) {
  expect(e.code, 'permission-denied');
  print('Success: Employee cannot create invoice');
}

// Should fail - Employee cannot read
try {
  final docs = await FirebaseFirestore.instance
    .collection('invoices')
    .get();
  print('Unexpected success');
} on FirebaseException catch (e) {
  expect(e.code, 'permission-denied');
  print('Success: Employee cannot read invoices');
}
```

### Scenario 6: Owner Has Full Access

**Steps:**
1. Sign in as `owner@test.com`
2. Create invoice - should succeed
3. Read all expenses - should succeed
4. Update other user's task - should succeed
5. Access supplier list - should succeed

**Code Test:**
```dart
// Owner creates invoice
final invoiceRef = await FirebaseFirestore.instance
  .collection('invoices')
  .add({
    'number': 'INV-001',
    'amount': 1000,
    'clientId': 'client-123',
  });
expect(invoiceRef.id.isNotEmpty, true);
print('Success: Owner created invoice');

// Owner reads all expenses
final expenses = await FirebaseFirestore.instance
  .collection('expenses')
  .get();
print('Success: Owner read ${expenses.docs.length} expenses');

// Owner updates anyone's task
await FirebaseFirestore.instance
  .collection('tasks')
  .doc('task-123')
  .update({'status': 'done'});
print('Success: Owner updated any task');

// Owner accesses suppliers
final suppliers = await FirebaseFirestore.instance
  .collection('suppliers')
  .get();
print('Success: Owner accessed suppliers');
```

## Automated Testing with Firebase Test SDK

### Example: Firestore Rules Testing

Create `functions/src/__tests__/firestore.rules.test.ts`:

```typescript
import * as firebase from '@firebase/rules-unit-testing';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ID = 'test-project';

beforeEach(async () => {
  await firebase.clearFirestoreData({ projectId: PROJECT_ID });
});

afterEach(async () => {
  await firebase.clearFirestoreData({ projectId: PROJECT_ID });
});

describe('Firestore RBAC Rules', () => {
  test('Owner can read all clients', async () => {
    const db = firebase
      .initializeAdminSdk({ projectId: PROJECT_ID })
      .firestore();

    const clientRef = db.collection('clients').doc('client-1');
    await clientRef.set({
      name: 'Test Client',
      assignedTo: 'owner-uid',
    });

    const ownerDb = firebase
      .initializeTestApp({
        projectId: PROJECT_ID,
        auth: { uid: 'owner-uid', role: 'owner' },
      })
      .firestore();

    const doc = await ownerDb.collection('clients').doc('client-1').get();
    expect(doc.exists).toBe(true);
  });

  test('Employee can read assigned client only', async () => {
    const db = firebase
      .initializeAdminSdk({ projectId: PROJECT_ID })
      .firestore();

    // Create client assigned to employee
    await db.collection('clients').doc('client-emp').set({
      name: 'Employee Client',
      assignedTo: 'emp-uid',
    });

    // Create client assigned to owner
    await db.collection('clients').doc('client-owner').set({
      name: 'Owner Client',
      assignedTo: 'owner-uid',
    });

    const empDb = firebase
      .initializeTestApp({
        projectId: PROJECT_ID,
        auth: { uid: 'emp-uid', role: 'employee' },
      })
      .firestore();

    // Can read assigned
    const assigned = await empDb
      .collection('clients')
      .doc('client-emp')
      .get();
    expect(assigned.exists).toBe(true);

    // Cannot read other's
    const other = empDb
      .collection('clients')
      .doc('client-owner')
      .get();
    await expect(other).rejects.toThrow('permission-denied');
  });

  test('Employee cannot create invoice', async () => {
    const empDb = firebase
      .initializeTestApp({
        projectId: PROJECT_ID,
        auth: { uid: 'emp-uid', role: 'employee' },
      })
      .firestore();

    const invoice = empDb.collection('invoices').add({
      number: 'INV-001',
      amount: 100,
    });

    await expect(invoice).rejects.toThrow('permission-denied');
  });
});
```

Run with:
```bash
npm test -- firestore.rules.test.ts
```

## Integration Testing with Flutter

### Test: Create Task and Update as Employee

```dart
void main() {
  group('RBAC Integration Tests', () {
    late FirebaseFirestore firestore;
    late FirebaseAuth auth;

    setUpAll(() async {
      // Connect to emulator
      firestore = FirebaseFirestore.instance;
      auth = FirebaseAuth.instance;
      
      // Clear data
      await firestore.clearPersistence();
    });

    test('Employee updates assigned task', () async {
      // Owner creates task
      await auth.signInWithEmailAndPassword(
        email: 'owner@test.com',
        password: 'Test123!',
      );

      final taskRef = await firestore
        .collection('tasks')
        .add({
          'title': 'Design',
          'assignedTo': 'emp-uid',
          'status': 'pending',
        });

      // Employee updates status
      await auth.signOut();
      await auth.signInWithEmailAndPassword(
        email: 'emp@test.com',
        password: 'Test123!',
      );

      await taskRef.update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
      });

      final updated = await taskRef.get();
      expect(updated['status'], 'completed');
    });

    test('Employee cannot update task title', () async {
      final taskRef = firestore.collection('tasks').doc('task-1');

      expect(
        () => taskRef.update({'title': 'Hacked'}),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('Employee cannot read invoice', () async {
      expect(
        () => firestore.collection('invoices').get(),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
```

Run with:
```bash
flutter test integration_test/rbac_test.dart
```

## Debugging Rules Violations

### Enable Firestore Logs

```bash
# Watch logs during test
firebase functions:log --project=demo --follow
```

### Check Rules Syntax

```bash
# Validate rules file
firebase firestore:indexes --import=firestore.indexes.json

# Deploy with validation
firebase deploy --only firestore:rules --debug
```

### Common Rule Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `permission-denied` | Rule condition failed | Check `allow` statement conditions |
| `mismatched-constraint` | Wildcard path mismatch | Ensure `{uid}` matches auth.uid |
| `failed-precondition` | Field validation failed | Check `request.resource.data.keys().hasOnly()` |
| `not-found` | Document doesn't exist | Create document before reading |

## Checklist Before Deployment

- [ ] Firestore emulator tests pass
- [ ] Flutter integration tests pass
- [ ] Role token claims set in Cloud Function
- [ ] All 10 owner-only collections protected
- [ ] Employee read/write limits enforced
- [ ] Rollback plan documented
- [ ] Monitoring alerts configured

## Next Steps

1. **Run emulator tests locally**
2. **Deploy to staging environment**
3. **Execute integration tests on staging**
4. **Monitor Firestore violations for 24 hours**
5. **Deploy to production with rollback ready**
