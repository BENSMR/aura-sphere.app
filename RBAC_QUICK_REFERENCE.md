# RBAC Quick Reference Card

## 🎯 Core Concepts

| Concept | Definition | Location |
|---------|-----------|----------|
| **Owner** | Full access all features | Cloud Function + Auth |
| **Employee** | 6 mobile features only | role_model.dart |
| **Role Token** | Stored in `request.auth.token.role` | Auth custom claims |
| **Feature** | Named capability (Invoices, Tasks, etc.) | Feature enum |

## 🔓 Employee Feature Access

| Feature | Create | Read | Update | Delete | Platform |
|---------|--------|------|--------|--------|----------|
| Tasks | ❌ | ✓ (assigned) | ✓ (status only) | ❌ | Mobile |
| Expenses | ✓ (own) | ✓ (own) | ✓ (own) | ❌ | Mobile |
| Clients | ❌ | ✓ (assigned) | ❌ | ❌ | Mobile |
| Jobs | ❌ | ✓ (assigned) | ✓ | ❌ | Mobile |
| Profile | ❌ | ✓ (own) | ❌ | ❌ | Mobile |
| Invoices | ❌ | ❌ | ❌ | ❌ | BLOCKED |
| Wallet | ❌ | ❌ | ❌ | ❌ | BLOCKED |
| Suppliers | ❌ | ❌ | ❌ | ❌ | BLOCKED |

## 🚀 Quick Commands

### Check User Role (Client-Side)
```dart
// In any widget
final canViewInvoices = AccessControlService.canAccessFeature(
  userRole,  // From UserProvider
  Feature.invoices,
);

if (canViewInvoices) {
  // Show invoice screen
}
```

### Guard Route Navigation
```dart
// In route.dart
final guardedRoute = MaterialPageRoute(
  builder: (context) => RoleBasedNavigator(
    initialRoute: '/invoices',
    child: InvoiceScreen(),
  ),
);
```

### Create Employee Task via Admin
```dart
// Admin calls Cloud Function
final response = await functions.httpsCallable('assignUserRole').call({
  'targetUid': 'emp@company.com',
  'role': 'employee',
});
```

### Check Firestore Permission
```dart
// Will auto-enforce in database
try {
  await firestore
    .collection('invoices')
    .add({'number': 'INV-001'});  // Fails for employee
} on FirebaseException catch (e) {
  // Shows: permission-denied
}
```

## 📋 Role Assignment Methods

### Method 1: Admin Panel
1. Owner logs in
2. Opens "Manage Team" → "Add Employee"
3. Enters email, clicks "Make Employee"
4. System calls `assignUserRole` Cloud Function
5. Employee role updated

### Method 2: API Call
```typescript
// From backend
const result = await admin.auth().setCustomUserClaims(uid, {
  role: 'employee',
  updatedAt: new Date().toISOString(),
});
```

### Method 3: Signup Flow
```dart
// Ask during registration
final role = signUpAsOwner ? 'owner' : 'employee';
// Pass to onUserCreate function
```

## 🔐 Security Layers

### Layer 1: Client-Side (UI)
```
AccessControlService.canAccessFeature()
├─ Check role
├─ Check feature.employeeAccess
└─ Return bool (show/hide UI)
```

### Layer 2: Navigation
```
RoleBasedNavigator
├─ Prevent navigation to restricted routes
├─ Show snackbar "Access denied"
└─ Redirect to employee dashboard
```

### Layer 3: Database
```
Firestore Rules
├─ Check request.auth.token.role
├─ Verify isOwner() or isEmployee()
├─ Enforce per-collection permissions
└─ Reject writes from unauthorized roles
```

## 🧪 Test Cases

### Test: Employee Cannot See Invoices
```dart
// 1. Sign in as employee
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: 'emp@company.com',
  password: 'Password123',
);

// 2. Try to read invoices (will fail)
expect(
  () => FirebaseFirestore.instance.collection('invoices').get(),
  throwsA(isA<FirebaseException>()),
);
```

### Test: Owner Can See All
```dart
// 1. Sign in as owner
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: 'owner@company.com',
  password: 'Password123',
);

// 2. Read all invoices (succeeds)
final invoices = await FirebaseFirestore.instance
  .collection('invoices')
  .get();
expect(invoices.docs.isNotEmpty, true);
```

## 📁 Key Files

| File | Purpose | Lines |
|------|---------|-------|
| role_model.dart | Role/Feature enums | 250 |
| access_control_service.dart | Permission checks | 200 |
| employee_dashboard.dart | Employee UI | 350 |
| role_based_navigator.dart | Route guards | 150 |
| firestore.rules | Database rules | 150 |
| setupUserRole.ts | Cloud Functions | 430 |

## 🎨 Feature Visibility Flow

```
User Logs In
    ↓
[Get User Role from Auth]
    ↓
[Check if Owner or Employee]
    ↓
┌─────────────────┬─────────────────┐
│                 │                 │
Owner          Employee
    │                 │
[Full Sidebar]    [Employee Dashboard]
├─ Dashboard       ├─ Tasks
├─ CRM             ├─ Expenses
├─ Clients         ├─ Clients
├─ Invoices        ├─ Jobs
├─ Tasks           ├─ Profile
├─ Expenses        └─ Sync
├─ Projects
└─ Advanced        [Mobile Only]
   (Suppliers,
    POs, Inventory,
    Finance, Loyalty,
    Wallet, Anomalies,
    Admin)
```

## 🔄 Role Change Flow

```
[Admin calls assignUserRole]
    ↓
[Update Auth custom claims]
    ↓
[Update Firestore user doc]
    ↓
[Log to audit_logs]
    ↓
[Employee must re-login]
    ↓
[New role in effect]
```

## ⚙️ Firestore Rules Patterns

### Pattern 1: Owner Full, Employee Own
```firestore
allow read: if isOwner() || resource.data.createdBy == request.auth.uid;
allow write: if isOwner() || resource.data.createdBy == request.auth.uid;
```

### Pattern 2: Owner Full, Employee Assigned
```firestore
allow read: if isOwner() || 
  (isEmployee() && resource.data.assignedTo == request.auth.uid);
allow update: if isEmployee() && 
  resource.data.assignedTo == request.auth.uid &&
  request.resource.data.keys().hasOnly(['status', 'notes']);
```

### Pattern 3: Owner Only
```firestore
allow read, write: if isOwner();
```

## 📊 Collection Permissions Matrix

```
┌────────────────┬──────────────┬──────────────┐
│  Collection    │    Owner     │   Employee   │
├────────────────┼──────────────┼──────────────┤
│ /clients       │ Full         │ Assigned RO  │
│ /tasks         │ Full         │ Assigned RU* │
│ /expenses      │ Full         │ Own CRU      │
│ /invoices      │ Full         │ BLOCKED      │
│ /wallet        │ Full         │ BLOCKED      │
│ /suppliers     │ Full         │ BLOCKED      │
│ /purchaseOrders│ Full         │ BLOCKED      │
│ /loyalty       │ Full         │ BLOCKED      │
│ /inventory     │ Full         │ BLOCKED      │
│ /settings      │ Full         │ BLOCKED      │
└────────────────┴──────────────┴──────────────┘

Legend:
RO  = Read Only
RU* = Read + Update (status/notes only)
CRU = Create + Read + Update own
```

## 🚨 Common Mistakes

| Mistake | Fix |
|---------|-----|
| Checking role only on client | Add Firestore rules to enforce |
| Forgetting to refresh token | Call `getIdTokenResult(forceRefresh: true)` |
| Missing `assignedTo` field | Add field to document before checking |
| Hardcoding permissions | Use Feature enum from role_model.dart |
| Not testing with employee | Test both roles locally |
| Deploying without rules | Deploy rules BEFORE removing client checks |

## 🎯 Success Criteria

- [x] Owner can access all 15 features
- [x] Employee can access only 6 mobile features
- [x] Employee cannot see invoices, wallet, suppliers
- [x] Employee cannot create/edit other users' data
- [x] Firestore rules block unauthorized access
- [x] Role token required for all database access
- [x] Documentation is complete
- [x] Tests pass for both roles
- [x] Zero compilation errors
- [x] Ready for production

## 📞 Getting Help

| Question | Answer | Docs |
|----------|--------|------|
| How do features work? | See Feature enum | role_model.dart |
| How to check permission? | Use AccessControlService | access_control_service.dart |
| How to build employee UI? | Copy employee_dashboard.dart | employee_dashboard.dart |
| How to protect routes? | Wrap with RoleBasedNavigator | role_based_navigator.dart |
| How to test database access? | See test scenarios | FIRESTORE_RBAC_TESTING.md |
| How to assign roles? | Call assignUserRole function | setupUserRole.ts |
| How to deploy? | Follow 4-step process | FIRESTORE_RBAC_DEPLOYMENT.md |

---

**Version:** 1.0  
**Status:** ✅ Production Ready  
**Last Updated:** 2024  
**Maintainer:** AuraSphere Pro Team
