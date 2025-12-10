# Admin Setup & Management

## Quick Admin Setup

### Option 1: Via Cloud Function (Recommended - Production)

Use the `setFirstAdmin` HTTP function:

```bash
curl -X POST https://us-central1-aurasphere-pro.cloudfunctions.net/setFirstAdmin \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "user-uid-here",
    "setupCode": "your_setup_code_from_.env"
  }'
```

Response:
```json
{
  "ok": true,
  "uid": "user-uid-here",
  "admin": true,
  "timestamp": "2024-12-10T10:30:00Z"
}
```

---

### Option 2: Local Admin Setup Script (Development)

For local testing or quick admin management:

```bash
# Grant admin to a user
node scripts/set-admin.js user123

# Revoke admin from a user
node scripts/set-admin.js user123 --revoke
```

**Prerequisites:**
1. Download service account key:
   ```bash
   # Go to Firebase Console → Project Settings → Service Accounts → Generate New Private Key
   # Save as: serviceAccountKey.json (or set GOOGLE_APPLICATION_CREDENTIALS env var)
   ```

2. Set your Firebase project:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json
   ```

3. Run script:
   ```bash
   node scripts/set-admin.js user123
   # ✅ Granted admin claim to user user123
   #    Current admin status: ✓ Admin
   ```

---

### Option 3: Direct Admin SDK (Node.js/Firebase CLI)

Open Node.js REPL with admin SDK initialized:

```bash
firebase functions:shell
```

Then in the shell:

```javascript
> const admin = require('firebase-admin');
> await admin.auth().setCustomUserClaims('user123', { admin: true })
> (await admin.auth().getUser('user123')).customClaims
{ admin: true }
```

---

## Verify Admin Status

Check if user has admin claim:

```bash
# Via script
node scripts/verify-admin.js user123

# Via Flutter app (if you register admin screen)
# In AdminService.getMyAdminStatus()
```

---

## Best Practices

1. **Keep setup code secret** - Only share with trusted admins
2. **Use strong setup codes** - Generate with: `openssl rand -hex 32`
3. **Log all admin changes** - All grant/revoke calls are audited
4. **Review admins regularly** - Use `listAdmins()` to audit
5. **Revoke immediately** - If admin should no longer have access

---

## Troubleshooting

**Error: "service account not found"**
- Download service account key from Firebase Console
- Set `GOOGLE_APPLICATION_CREDENTIALS` environment variable

**Error: "user not found"**
- Verify the UID is correct
- User must exist in Firebase Auth

**Admin claim not taking effect**
- Users need to refresh ID token after claim is set
- Sign out and sign back in to get new token with claim

---

## Backend Admin Functions

All admin management is exposed via Cloud Functions:

| Function | Type | Purpose |
|----------|------|---------|
| `grantAdminRole(uid)` | Callable | Grant admin to user |
| `revokeAdminRole(uid)` | Callable | Revoke admin from user |
| `listAdmins()` | Callable | List all admins with metadata |
| `getAdminStatus(uid)` | Callable | Check if user is admin |
| `getMyAdminStatus()` | Callable | Check current user admin status |
| `setFirstAdmin(uid, setupCode)` | HTTP | Bootstrap first admin (setup only) |

Use from Flutter via `AdminService`:

```dart
final adminService = AdminService();

// Grant admin
await adminService.grantAdminRole('user123');

// Check current user
final isAdmin = await adminService.getMyAdminStatus();

// List all admins
final admins = await adminService.listAdmins();
```

---

## Security Model

- All admin operations are **audited** (written to `/audit/{compositeId}/entries`)
- Admin claims are stored in **custom claims** (checked on token verification)
- Admin Firestore docs stored in **`/admins/{uid}`** (immutable, server-write only)
- Slack **notifications** sent on grant/revoke
- **Self-removal protection** - Admins cannot revoke themselves
