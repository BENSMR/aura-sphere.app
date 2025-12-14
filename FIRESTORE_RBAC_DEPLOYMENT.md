# Firestore Role-Based Access Control (RBAC) Deployment Guide

## Overview

The Firestore security rules have been updated to enforce role-based access control based on the **Feature Access Matrix** implementation. This document guides deployment and testing.

## Architecture

### Role System
- **Owner**: Full access to all features and data
- **Employee**: Limited access (mobile-only features)
- **Role Source**: `request.auth.token.role` (set by Cloud Functions)
- **Default**: 'owner' for backward compatibility

### Helper Functions (Lines 7-19)

```firestore
function getUserRole() {
  return request.auth.token.role != null ? request.auth.token.role : 'owner';
}

function isOwner() {
  return getUserRole() == 'owner';
}

function isEmployee() {
  return getUserRole() == 'employee';
}
```

## Collection Access Rules

### Employee Features (Limited Access)

#### 1. Clients `/clients` (Read-Only, Assigned Only)
```firestore
match /clients/{clientId} {
  allow read: if isOwner() || (isEmployee() && resource.data.assignedTo == request.auth.uid);
  allow write: if isOwner();
}
```
- **Owner**: Read/write all clients
- **Employee**: Read only assigned clients (where `assignedTo == uid`)

#### 2. Tasks `/tasks` (Assigned Tasks, Limited Updates)
```firestore
match /tasks/{taskId} {
  allow read: if isOwner() || (isEmployee() && resource.data.assignedTo == request.auth.uid);
  allow write: if isOwner();
  allow update: if isEmployee() && resource.data.assignedTo == request.auth.uid
                && request.resource.data.keys().hasOnly(['status', 'completedAt', 'notes']);
}
```
- **Owner**: Full read/write access
- **Employee**: Can read assigned tasks, update only `status`, `completedAt`, `notes`

#### 3. Expenses `/expenses` (Create Own, Limited Read)
```firestore
match /expenses/{expenseId} {
  allow create: if request.auth != null && request.resource.data.createdBy == request.auth.uid;
  allow read: if isOwner() || resource.data.createdBy == request.auth.uid;
  allow update: if isOwner() || (isEmployee() && resource.data.createdBy == request.auth.uid);
  allow delete: if isOwner();
}
```
- **Owner**: Full read/write/delete access
- **Employee**: Create own expenses, read/update own expenses only

### Owner-Only Features (Blocked for Employees)

#### 4. Invoices `/invoices`
```firestore
match /invoices/{docId} {
  allow read, write: if isOwner();
}
```

#### 5. Wallet `/wallet`
```firestore
match /wallet/{doc=**} {
  allow read, write: if isOwner();
}
```

#### 6. Suppliers `/suppliers`
```firestore
match /suppliers/{doc=**} {
  allow read, write: if isOwner();
}
```

#### 7. Purchase Orders `/purchaseOrders`
```firestore
match /purchaseOrders/{doc=**} {
  allow read, write: if isOwner();
}
```

#### 8. Loyalty `/loyalty`
```firestore
match /loyalty/{doc=**} {
  allow read, write: if isOwner();
}
```

#### 9. Inventory `/inventory`
```firestore
match /inventory/{doc=**} {
  allow read, write: if isOwner();
}
```

#### 10. Settings `/settings`
```firestore
match /settings/{doc=**} {
  allow read, write: if isOwner();
}
```

## Deployment Steps

### 1. Prerequisites

Ensure your Cloud Function sets role in auth token:

```typescript
// functions/src/auth/onUserCreate.ts
import * as admin from 'firebase-admin';

export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  try {
    // Set custom claims with role
    await admin.auth().setCustomUserClaims(user.uid, {
      role: 'owner', // or 'employee'
      createdAt: new Date().toISOString(),
    });

    // Also store in Firestore
    await admin.firestore().collection('users').doc(user.uid).set(
      {
        role: 'owner',
        email: user.email,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  } catch (error) {
    console.error('Error creating user:', error);
    throw error;
  }
});
```

### 2. Test Locally

```bash
# Start Firebase emulators (includes Firestore)
firebase emulators:start

# In another terminal, run tests
firebase emulators:exec "npm test" --project demo
```

### 3. Deploy Rules

```bash
# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Or deploy everything
firebase deploy
```

### 4. Verify Deployment

```bash
# Check deployed rules
firebase rules:describe firestore:rules

# Monitor rules activity
firebase emulators:start --inspect-functions
```

## Testing Scenarios

### Test Case 1: Employee Reads Client (Assigned)

**Setup:**
- User: `emp@company.com` (role: `employee`)
- Client: `clients/client123` with `assignedTo: emp@company.com`

**Test:**
```dart
// Should succeed
final doc = await FirebaseFirestore.instance
  .collection('clients')
  .doc('client123')
  .get();
expect(doc.exists, true);
```

### Test Case 2: Employee Reads Client (Not Assigned)

**Setup:**
- User: `emp@company.com` (role: `employee`)
- Client: `clients/client456` with `assignedTo: other@company.com`

**Test:**
```dart
// Should fail with permission denied
expect(
  () => FirebaseFirestore.instance
    .collection('clients')
    .doc('client456')
    .get(),
  throwsA(isA<FirebaseException>()),
);
```

### Test Case 3: Employee Updates Task (Assigned)

**Setup:**
- User: `emp@company.com` (role: `employee`)
- Task: `tasks/task123` with `assignedTo: emp@company.com`

**Test:**
```dart
// Should succeed (only status/completedAt/notes)
await FirebaseFirestore.instance
  .collection('tasks')
  .doc('task123')
  .update({
    'status': 'completed',
    'completedAt': Timestamp.now(),
    'notes': 'Done!',
  });
```

### Test Case 4: Employee Tries to Create Invoice

**Setup:**
- User: `emp@company.com` (role: `employee`)

**Test:**
```dart
// Should fail with permission denied
expect(
  () => FirebaseFirestore.instance
    .collection('invoices')
    .add({
      'number': 'INV-001',
      'amount': 100,
    }),
  throwsA(isA<FirebaseException>()),
);
```

### Test Case 5: Owner Reads All Invoices

**Setup:**
- User: `owner@company.com` (role: `owner`)

**Test:**
```dart
// Should succeed
final snapshot = await FirebaseFirestore.instance
  .collection('invoices')
  .get();
expect(snapshot.docs.isNotEmpty, true);
```

## Troubleshooting

### Issue: "Permission denied" error for owner

**Cause**: Token doesn't have role claim set.

**Solution**: 
- Verify Cloud Function sets custom claims
- Clear browser cache and re-authenticate
- Check `firebase auth:export` to see custom claims

### Issue: Employee can read all clients

**Cause**: `assignedTo` field missing or different field name.

**Solution**:
- Check client document structure
- Ensure field name matches rule: `assignedTo`
- Add index if needed: `Firestore → Indexes → Add Index`

### Issue: Rules valid but access denied

**Cause**: Timestamp or data type mismatch.

**Solution**:
- Check data types match in write validation
- Ensure `createdBy` is set to `request.auth.uid` string
- Test in emulator with specific error message

## Monitoring & Audits

### Enable Rules Logging

```bash
# View logs
gcloud firestore operations list --project=YOUR_PROJECT

# Monitor rule violations
gcloud logging read \
  "resource.type=cloud_firestore_database AND severity=ERROR" \
  --project=YOUR_PROJECT \
  --limit=50
```

### Access Audit Collection

Add to rules if you want to log access:

```firestore
// After write succeeds, log to audit
match /audit/{docId} {
  allow create: if request.auth != null && request.auth.token.admin == true;
  allow read: if request.auth.token.admin == true;
}
```

## Integration with Client Code

### 1. Update UserProvider

```dart
// In your UserProvider
Future<void> loadUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Get fresh token with custom claims
    final idToken = await user.getIdTokenResult(forceRefresh: true);
    
    // Access role from token
    final role = idToken.claims?['role'] ?? 'owner';
    
    // Update user in app state
    _currentUser = AppUser(
      id: user.uid,
      email: user.email,
      role: role,
    );
    notifyListeners();
  }
}
```

### 2. Use AccessControlService (Already Implemented)

```dart
// Check before making Firestore calls
if (AccessControlService.canAccessFeature(
  _currentUser.role,
  Feature.invoices,
)) {
  final invoices = await _getInvoices();
  // Display invoices
}
```

### 3. Handle Permission Errors

```dart
try {
  await FirebaseFirestore.instance
    .collection('invoices')
    .add(newInvoice);
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    // Show: "You don't have access to invoices"
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Access denied: ${e.message}')),
    );
  }
}
```

## Migration Path (Existing Users)

For users created before role implementation:

```bash
# Create migration Cloud Function
firebase deploy --only functions:migrateUsersRole
```

```typescript
// functions/src/admin/migrateUsersRole.ts
import * as admin from 'firebase-admin';

export const migrateUsersRole = functions.https.onRequest(async (req, res) => {
  if (req.body.secret !== process.env.ADMIN_SECRET) {
    return res.status(403).json({ error: 'Unauthorized' });
  }

  const usersRef = admin.firestore().collection('users');
  const snapshot = await usersRef.where('role', '==', undefined).get();

  const batch = admin.firestore().batch();
  snapshot.docs.forEach((doc) => {
    batch.update(doc.ref, { role: 'owner' });
  });

  await batch.commit();
  res.json({ success: true, updated: snapshot.size });
});
```

## Next Steps

1. ✅ Deploy updated firestore.rules
2. ⏳ Test with employee and owner accounts
3. ⏳ Enable monitoring and audit logging
4. ⏳ Document role assignment process for admins
5. ⏳ Set up Cloud Function for role management

## References

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/start)
- [Custom Claims in Firebase Auth](https://firebase.google.com/docs/auth/admin-sdk-setup)
- [Feature Access Matrix](./FEATURE_ACCESS_MATRIX.md)
- [Access Control Service](./lib/services/access_control_service.dart)
