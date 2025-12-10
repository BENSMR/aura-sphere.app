# Admin Management Setup Guide

## Overview

AuraSphere Pro uses a dual-layer admin system:

1. **Firestore Collection** (`/admins/{uid}`) — Firestore rules check for presence of admin document
2. **Custom Claims** (`admin: true`) — Firebase Auth token claim for fast client-side checks

When you grant admin role, both are set automatically. When you revoke, both are cleared.

## Initial Setup: Creating First Admin

### Option 1: Using Cloud Function (Recommended)

Call the `setFirstAdmin` HTTP function with a setup code:

```bash
curl -X POST https://us-central1-YOUR_PROJECT.cloudfunctions.net/setFirstAdmin \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "YOUR_USER_UID",
    "setupCode": "YOUR_SETUP_CODE"
  }'
```

**Where:**
- `YOUR_USER_UID` — User's Firebase Auth UID
- `YOUR_SETUP_CODE` — Set via environment variable `SETUP_CODE`

**Find User UID:**
1. Go to Firebase Console → Authentication
2. Click user → Copy UID

**Set Setup Code:**
1. In `.env.local` (or Cloud Functions config):
   ```
   SETUP_CODE=your_secret_setup_code_here
   ```
2. Deploy: `firebase deploy --only functions:setFirstAdmin`

### Option 2: Using Admin SDK (Direct)

From a Node.js script with admin SDK initialized:

```typescript
import * as admin from 'firebase-admin';

admin.initializeApp();

const uid = 'user_uid_here';

// Create admin doc
await admin.firestore().collection('admins').doc(uid).set({
  uid,
  grantedAt: admin.firestore.FieldValue.serverTimestamp(),
  grantedBy: 'system:setup',
});

// Set custom claim
await admin.auth().setCustomUserClaims(uid, { admin: true });

console.log('Admin created:', uid);
```

## Daily Operations

### Grant Admin Role

**From Flutter App (if user is already admin):**
```dart
final adminService = AdminService();

try {
  final success = await adminService.grantAdminRole('user_uid_here');
  if (success) {
    print('Admin role granted');
  }
} catch (e) {
  print('Error: $e');
}
```

**From CLI (using Admin SDK):**
```bash
node -e "
const admin = require('firebase-admin');
admin.initializeApp();
admin.auth().setCustomUserClaims('user_uid', { admin: true });
admin.firestore().collection('admins').doc('user_uid').set({
  uid: 'user_uid',
  grantedAt: new Date(),
  grantedBy: 'cli'
});
console.log('Admin granted');
"
```

### Revoke Admin Role

**From Flutter App:**
```dart
final adminService = AdminService();

try {
  final success = await adminService.revokeAdminRole('user_uid_here');
  if (success) {
    print('Admin role revoked');
  }
} catch (e) {
  print('Error: $e');
}
```

**Prevents self-removal** (safety check).

### List All Admins

**From Flutter App:**
```dart
final adminService = AdminService();

try {
  final admins = await adminService.listAdmins();
  for (final admin in admins) {
    print('${admin['uid']} - granted at ${admin['grantedAt']}');
  }
} catch (e) {
  print('Error: $e');
}
```

**From CLI:**
```bash
firebase auth:list --limit 100 | grep "Custom claims: {"
```

### Check Current User Admin Status

**From Flutter App:**
```dart
final adminService = AdminService();

// Fast check using custom claims
final isAdmin = await adminService.isCurrentUserAdmin();
if (isAdmin) {
  print('User is admin');
} else {
  print('User is not admin');
}
```

**Realtime Stream:**
```dart
final adminService = AdminService();

adminService.watchCurrentUserAdminStatus().listen((isAdmin) {
  print('Admin status changed: $isAdmin');
});
```

## Checking Admin Status in Code

### Flutter

**Client-side (fast):**
```dart
final user = FirebaseAuth.instance.currentUser;
final isAdmin = user?.customClaims?['admin'] == true;
```

**Fallback (if custom claims not set):**
```dart
final doc = await FirebaseFirestore.instance
    .collection('admins')
    .doc(uid)
    .get();
final isAdmin = doc.exists;
```

**Using AdminService:**
```dart
final adminService = AdminService();
final isAdmin = await adminService.isCurrentUserAdmin();
```

### Firestore Rules

Rules automatically check admin status:

```javascript
function isAdmin() {
  return exists(/databases/$(database)/documents/admins/$(request.auth.uid));
}

// Usage in rules:
if (isAdmin()) {
  allow read: true;
}
```

### Cloud Functions

```typescript
async function isAdmin(uid: string): Promise<boolean> {
  const doc = await admin.firestore().collection('admins').doc(uid).get();
  return doc.exists;
}

// Usage:
if (await isAdmin(context.auth.uid)) {
  // Allow operation
}
```

## Security Considerations

### Admin Document (`/admins/{uid}`)

**What it is:**
- Simple Firestore document marking user as admin
- Checked by Firestore rules and Cloud Functions
- Accessible to anyone who knows the UID

**Security:**
- Cannot be written/modified by clients (Firestore rules: `false`)
- Only admins can call functions to modify it
- Self-removal prevented by `revokeAdminRole`

### Custom Claims (`admin: true`)

**What it is:**
- Claim embedded in Firebase Auth token
- Decoded client-side for fast UI decisions
- Does NOT control backend access (that's the Firestore doc)

**Security:**
- Requires admin SDK to set (client cannot modify)
- Token refreshes after 1 hour (picks up changes)
- Should only be used for UI/UX, not security enforcement

### Best Practices

✅ **DO:**
- Use Firestore doc for backend authorization (rules, functions)
- Use custom claims for fast client-side checks
- Keep admin list small and audited
- Regularly review who has admin access
- Log admin actions in audit trail

❌ **DON'T:**
- Trust custom claims for security (client-side only)
- Grant admin to users without explicit approval
- Share admin UID with non-admin users
- Use admin accounts for testing

## Audit Trail Integration

All admin changes are automatically logged:

**When admin granted:**
```
/audit/admin_{uid}/entries/{id}
{
  action: 'admin.role_granted',
  actor: { uid: granter_uid, role: 'admin' },
  before: { isAdmin: false },
  after: { isAdmin: true },
  meta: { grantedBy: granter_uid },
  tags: ['admin', 'security']
}
```

**When admin revoked:**
```
/audit/admin_{uid}/entries/{id}
{
  action: 'admin.role_revoked',
  actor: { uid: revoker_uid, role: 'admin' },
  before: { isAdmin: true },
  after: { isAdmin: false },
  meta: { revokedBy: revoker_uid },
  tags: ['admin', 'security']
}
```

View in AuditConsoleScreen → Filter by entity type "admin".

## Troubleshooting

### Issue: User can't see admin features

**Check:**
1. Is user in `/admins/{uid}` collection?
   ```
   firebase firestore:list /admins
   ```

2. Does auth token have custom claim?
   ```dart
   final claims = user.customClaims;
   print(claims); // Should show { admin: true }
   ```

3. Token needs refresh (custom claims cached for 1 hour)
   ```dart
   await FirebaseAuth.instance.currentUser?.reload();
   ```

**Fix:**
```dart
final adminService = AdminService();
await adminService.grantAdminRole(uid);
// User needs to sign out/in for new token
```

### Issue: Revoking admin didn't work

**Check:**
- User is signed in as an admin (who is doing the revoking)
- Target user exists in `/admins/{uid}`
- Not trying to revoke own access (blocked for safety)

**Verify Removal:**
```bash
firebase firestore:delete /admins/{uid}
```

### Issue: "Only admins can grant/revoke"

**Cause:** Caller is not an admin

**Fix:**
1. Check if caller is in `/admins/{uid}`:
   ```
   firebase firestore:list /admins
   ```

2. If not, use `setFirstAdmin` to create first admin

3. First admin can then grant others

## Monitoring

### Watch Admin Changes (Realtime)

```dart
final adminService = AdminService();

adminService.watchAdmins().listen((admins) {
  print('Admin count: ${admins.length}');
  for (final admin in admins) {
    print('  ${admin.uid} - granted at ${admin.grantedAt}');
  }
});
```

### Check Admin Audit Log

In AuditConsoleScreen:
1. Entity Type: "admin"
2. Filter Action: "role_granted" or "role_revoked"
3. View full details including who granted/revoked and when

## Examples

### Complete Setup Flow

```dart
class AdminSetupScreen extends StatelessWidget {
  const AdminSetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Management')),
      body: ListView(
        children: [
          // Check current user
          FutureBuilder<bool>(
            future: adminService.isCurrentUserAdmin(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              return ListTile(
                title: const Text('Current User Admin Status'),
                subtitle: Text(snap.data == true ? 'Admin' : 'Not Admin'),
              );
            },
          ),
          // List all admins
          FutureBuilder<List<Map<String, dynamic>>>(
            future: adminService.listAdmins(),
            builder: (context, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              return Column(
                children: snap.data!
                    .map((admin) => ListTile(
                          title: Text(admin['uid']),
                          subtitle:
                              Text('Granted by: ${admin['grantedBy']}'),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

---

**Last Updated:** December 10, 2025
**Status:** Production Ready
