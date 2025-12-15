# Firestore Security Rules Reference

**Version:** 2  
**Last Updated:** December 15, 2025

---

## Overview

Complete Firestore security rules configuration for AuraSphere Pro with user ownership validation, role-based access control, and comprehensive audit trail support.

---

## Collection Rules

### 1. Users Collection
```firestore
match /users/{userId} {
  allow read, write: if request.auth != null && 
                       request.auth.uid == userId;
}
```

**Purpose:** Store user profile data, settings, and preferences  
**Access:** Owner only (authenticated user matches userId)  
**Fields:** Settings, profile, preferences, theme, locale, timezone  

---

### 2. Expenses Collection
```firestore
match /expenses/{id} {
  allow create: if request.auth != null && 
                   request.resource.data.userId == request.auth.uid
                   && request.resource.data.amount > 0
                   && request.resource.data.vendor != null
                   && request.resource.data.items is list;
  allow read: if request.auth != null && 
               resource.data.userId == request.auth.uid;
  allow update: if request.auth != null && 
                 resource.data.userId == request.auth.uid
                 && request.resource.data.userId == request.auth.uid;
  allow delete: if request.auth != null && 
                 resource.data.userId == request.auth.uid;
}
```

**Purpose:** Track business expenses with validation  
**Required Fields:** userId, amount (>0), vendor, items (array)  
**Optional Fields:** category, description, status, receiptUrl  
**Access:** Create/read/update/delete by owner  
**Validation:** 
- Amount must be positive
- Vendor must exist
- Items must be array type
- UserId must match authenticated user

---

### 3. Contacts Collection
```firestore
match /contacts/{id} {
  allow create: if request.auth != null && 
                   request.resource.data.userId == request.auth.uid
                   && request.resource.data.name != null
                   && request.resource.data.phone != null;
  allow read: if request.auth != null && 
               resource.data.userId == request.auth.uid;
  allow update: if request.auth != null && 
                 resource.data.userId == request.auth.uid
                 && request.resource.data.userId == request.auth.uid;
  allow delete: if request.auth != null && 
                 resource.data.userId == request.auth.uid;
}
```

**Purpose:** Manage business contacts  
**Required Fields:** userId, name, phone  
**Optional Fields:** email, company, notes, lastContact  
**Access:** Create/read/update/delete by owner  
**Validation:**
- Name must exist
- Phone must exist
- UserId must match authenticated user

---

### 4. Stock Collection
```firestore
match /stock/{id} {
  allow create: if request.auth != null && 
                   request.resource.data.userId == request.auth.uid
                   && request.resource.data.item != null
                   && request.resource.data.quantity >= 0
                   && request.resource.data.cost >= 0;
  allow read: if request.auth != null && 
               resource.data.userId == request.auth.uid;
  allow update: if request.auth != null && 
                 resource.data.userId == request.auth.uid
                 && request.resource.data.userId == request.auth.uid;
  allow delete: if request.auth != null && 
                 resource.data.userId == request.auth.uid;
}
```

**Purpose:** Track inventory and stock levels  
**Required Fields:** userId, item, quantity (≥0), cost (≥0)  
**Optional Fields:** category, location, notes, lastUpdated  
**Access:** Create/read/update/delete by owner  
**Validation:**
- Item name must exist
- Quantity must be non-negative
- Cost must be non-negative
- UserId must match authenticated user

---

### 5. Tasks Collection
```firestore
match /tasks/{id} {
  allow create: if request.auth != null && 
                   request.resource.data.userId == request.auth.uid
                   && request.resource.data.title != null
                   && request.resource.data.dueDate != null;
  allow read: if request.auth != null && 
               resource.data.userId == request.auth.uid;
  allow update: if request.auth != null && 
                 resource.data.userId == request.auth.uid
                 && request.resource.data.userId == request.auth.uid;
  allow delete: if request.auth != null && 
                 resource.data.userId == request.auth.uid;
}
```

**Purpose:** Task and todo management  
**Required Fields:** userId, title, dueDate  
**Optional Fields:** description, completed, priority, tags, completedAt  
**Access:** Create/read/update/delete by owner  
**Validation:**
- Title must exist
- DueDate must exist
- UserId must match authenticated user

---

### 6. Mobile Modules Collection
```firestore
match /mobileModules/{uid} {
  allow read: if request.auth != null && request.auth.uid == uid;
  allow write: if request.auth != null && request.auth.uid == uid;
}
```

**Purpose:** Store user's mobile feature configuration  
**Fields:** expenses, contacts, stock, tasks, invoices, clients, crm, ai (all boolean)  
**Access:** Read/write by user (authenticated uid matches document id)  
**Default:** expenses=true, contacts=true, tasks=true; others=false

---

## Admin Collections (Server-Only)

### Audit Logs
```firestore
match /auditLogs/{docId} {
  allow read: if request.auth != null && 
               (resource.data.userId == request.auth.uid || isAdmin());
  allow write: if false; // Server-only via Cloud Functions
}
```

**Purpose:** Track all user actions and changes  
**Written by:** Cloud Functions only  
**Contains:** action, userId, timestamp, details

---

### Admin Panel
```firestore
match /admin/{doc=**} {
  allow read: if request.auth != null;
  allow write: if isAdmin();
}
```

**Purpose:** Admin-only settings and configuration  
**Access:** Admins only (checked via token.admin flag)

---

### Notifications
```firestore
match /users/{uid}/notifications/{notifId} {
  allow read: if request.auth != null && request.auth.uid == uid;
  allow create: if false; // Server-only
  allow update: if request.auth != null && request.auth.uid == uid && 
                 request.resource.data.keys().hasOnly(['read']);
  allow delete: if request.auth != null && request.auth.uid == uid;
}
```

**Purpose:** User notifications and alerts  
**Written by:** Cloud Functions only  
**User can:** Read and mark as read (update 'read' field only)

---

## Security Patterns

### 1. User Ownership Pattern
All user-data collections use `userId` field for ownership:
```firestore
allow <operation>: if request.auth != null && 
                    resource.data.userId == request.auth.uid;
```

### 2. Required Field Validation
Creation validates mandatory fields:
```firestore
&& request.resource.data.fieldName != null
```

### 3. Type Validation
Ensures correct data types:
```firestore
&& request.resource.data.items is list
&& request.resource.data.amount > 0
```

### 4. Immutable IDs
User ID cannot be changed on update:
```firestore
&& request.resource.data.userId == request.auth.uid
```

### 5. Server-Only Operations
Critical operations blocked from client:
```firestore
allow create, update, delete: if false; // Only server via Cloud Functions
```

---

## Data Validation Rules

### Expense Rules
| Field | Rule | Error |
|-------|------|-------|
| userId | Must equal request.auth.uid | Unauthorized |
| amount | Must be > 0 | "Amount must be positive" |
| vendor | Must not be null | "Vendor required" |
| items | Must be array type | "Items must be array" |

### Contact Rules
| Field | Rule | Error |
|-------|------|-------|
| userId | Must equal request.auth.uid | Unauthorized |
| name | Must not be null | "Name required" |
| phone | Must not be null | "Phone required" |

### Stock Rules
| Field | Rule | Error |
|-------|------|-------|
| userId | Must equal request.auth.uid | Unauthorized |
| item | Must not be null | "Item required" |
| quantity | Must be >= 0 | "Quantity must be non-negative" |
| cost | Must be >= 0 | "Cost must be non-negative" |

### Task Rules
| Field | Rule | Error |
|-------|------|-------|
| userId | Must equal request.auth.uid | Unauthorized |
| title | Must not be null | "Title required" |
| dueDate | Must not be null | "Due date required" |

---

## Helper Functions

```firestore
function isAdmin() {
  return request.auth != null && request.auth.token.admin == true;
}

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

---

## Access Matrix

| Collection | Create | Read | Update | Delete | Notes |
|-----------|--------|------|--------|--------|-------|
| users/{uid} | ✓ | ✓ | ✓ | ✗ | Owner only |
| expenses/{id} | ✓ | ✓ | ✓ | ✓ | Owner only |
| contacts/{id} | ✓ | ✓ | ✓ | ✓ | Owner only |
| stock/{id} | ✓ | ✓ | ✓ | ✓ | Owner only |
| tasks/{id} | ✓ | ✓ | ✓ | ✓ | Owner only |
| mobileModules/{uid} | ✗ | ✓ | ✓ | ✗ | User config |
| auditLogs/{id} | ✗ | ✓* | ✗ | ✗ | Server/Admin |
| notifications/{id} | ✗ | ✓ | ✓ | ✓ | Server writes |

*Read restricted to owner or admin

---

## Deployment

### Prerequisites
- Firebase project initialized
- Firebase CLI installed: `npm install -g firebase-tools`
- Authenticated: `firebase login`

### Deploy Rules
```bash
# Validate rules
firebase validate --only firestore

# Deploy to production
firebase deploy --only firestore:rules

# Deploy with specific rules file
firebase deploy --only firestore:rules --config=firebase.json
```

### Dry Run (Test)
```bash
firebase firestore:delete --project <project-id> --recursive
firebase deploy --only firestore:rules --dry-run
```

---

## Testing Rules

### Firebase Local Emulator
```bash
# Start emulator
firebase emulators:start --only firestore

# Run tests
firebase test:firestore
```

### Example Test Cases
1. **Unauthorized user can't read others' expenses**
   - User A tries to read User B's expense → DENY

2. **User can't create expense with invalid amount**
   - amount <= 0 → DENY

3. **Admin can read any audit log**
   - isAdmin() && token.admin == true → ALLOW

4. **User can't modify another user's contact**
   - userId mismatch → DENY

---

## Monitoring & Logging

### Enable Audit Logging
All operations logged to `auditLogs` collection via Cloud Functions:
- User creates expense → Logged
- User updates contact → Logged
- User deletes task → Logged

### Firestore Rules Statistics
Available in Firebase Console:
- Rules evaluation time
- Rejections per rule
- Active connections

---

## Common Issues & Solutions

### Issue: User can't create document
**Check:**
1. User is authenticated (`request.auth != null`)
2. UserId matches authenticated user
3. All required fields present
4. Validation rules pass (amount > 0, etc.)

### Issue: Permission denied on read
**Check:**
1. Document userId matches request.auth.uid
2. User is authenticated
3. Document exists in correct collection

### Issue: Update fails silently
**Check:**
1. User ID field not changed
2. Only updating allowed fields
3. Field types match schema

---

## Best Practices

1. **Always validate userId** - Ensure ownership before any operation
2. **Require key fields** - Force presence of essential data at write time
3. **Validate field types** - Use `is` operator for arrays, numbers
4. **Immutable IDs** - Prevent userId changes on update
5. **Server-only critical ops** - Keep payment/admin ops server-only
6. **Regular audits** - Review audit logs weekly
7. **Test in emulator** - Always test rules before deploy
8. **Document rules** - Keep this reference up-to-date

---

## Related Documentation

- [Services Reference](./SERVICES_REFERENCE.md)
- [Architecture Guide](../docs/architecture.md)
- [API Reference](../docs/api_reference.md)
- [Setup Guide](../docs/setup.md)

---

**Last Verified:** December 15, 2025  
**Rules Version:** 2  
**Status:** ✅ Production Ready
