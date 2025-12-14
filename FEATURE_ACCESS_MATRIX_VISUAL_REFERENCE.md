# 🗺️ Feature Access Matrix - Visual Reference

**Quick Visual Guide to Who Sees What**

---

## 📊 AT A GLANCE

```
┌─────────────────────────────────────────────────────────────┐
│                    OWNER vs EMPLOYEE                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  OWNER (Business Owner)          EMPLOYEE (Mobile Only)     │
│  ───────────────────────         ─────────────────────      │
│                                                             │
│  ✅ Desktop      : All features  ✅ Mobile   : 6 features   │
│  ✅ Mobile       : Main features ❌ Desktop  : NOT ALLOWED   │
│  ✅ Admin Panel  : Config mgmt   ❌ Invoices : NOT ALLOWED  │
│  ✅ All Data     : Read/Write    ❌ Finance  : NOT ALLOWED   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📱 MOBILE APPS

### Owner on Mobile
```
┌─ MOBILE OWNER DASHBOARD ─┐
│                          │
│ Bottom Navigation:       │
│ ├─ Dashboard            │
│ ├─ Clients              │
│ ├─ Invoices             │
│ ├─ Tasks                │
│ ├─ Expenses             │
│ └─ Projects             │
│                          │
│ Advanced (if expanded):  │
│ ├─ Suppliers            │
│ ├─ POs                   │
│ ├─ Inventory            │
│ ├─ Finance              │
│ ├─ Loyalty              │
│ ├─ Wallet               │
│ ├─ Anomalies            │
│ └─ Admin                │
│                          │
└──────────────────────────┘
```

### Employee on Mobile
```
┌─ MOBILE EMPLOYEE DASHBOARD ─┐
│                             │
│ Bottom Navigation:          │
│ ├─ ✅ Tasks (assigned)     │
│ ├─ ✅ Log Expense          │
│ ├─ ✅ View Clients         │
│ ├─ ✅ Complete Jobs        │
│ ├─ ✅ Profile              │
│ └─ ✅ Sync Status          │
│                             │
│ NOT AVAILABLE:              │
│ ├─ ❌ Invoices             │
│ ├─ ❌ Finance              │
│ ├─ ❌ Wallet               │
│ ├─ ❌ Suppliers            │
│ └─ ❌ Admin                │
│                             │
└─────────────────────────────┘
```

---

## 🖥️ DESKTOP APPS

### Owner on Desktop
```
┌──────────────────────────────────────────────────────┐
│                                                      │
│ SIDEBAR              MAIN CONTENT        SETTINGS    │
│ ────────────────────────────────────────────────────│
│                                                      │
│ 🏠 Dashboard      ┌──────────────────┐  👤 Profile  │
│ 👥 Clients        │   Screen Content   │  ⚙️ Settings │
│ 📄 Invoices       │   (based on       │  📲 Devices  │
│ ✅ Tasks          │    selected item)  │  🚪 Logout  │
│ 💰 Expenses       └──────────────────┘               │
│ 📊 Projects                                          │
│                                                      │
│ ▼ ADVANCED (collapsible)                             │
│ ├─ 📦 Suppliers                                      │
│ ├─ 📋 Purchase Orders                                │
│ ├─ 🏭 Inventory                                      │
│ ├─ 💹 Finance                                        │
│ ├─ 🎁 Loyalty                                        │
│ ├─ 💳 Wallet                                         │
│ ├─ ⚠️ Anomalies                                      │
│ └─ 🔧 Admin                                          │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### Employee on Desktop
```
┌──────────────────────────────────────┐
│                                      │
│   NOT AVAILABLE ON DESKTOP           │
│                                      │
│   Employees can only use mobile      │
│                                      │
│   Please access from:                │
│   📱 iPhone or Android device        │
│                                      │
│   [← Back to Mobile Login]           │
│                                      │
└──────────────────────────────────────┘
```

---

## 🎯 FEATURE VISIBILITY TABLE

```
┌────────────────┬────────────┬──────────────┬──────────────┬──────────┐
│    Feature     │   Route    │   Owner D    │   Owner M    │  Emp M   │
├────────────────┼────────────┼──────────────┼──────────────┼──────────┤
│ Dashboard      │ /dashboard │      ✅      │      ✅      │    ❌    │
│ CRM            │ /crm       │      ✅      │      ✅      │    ❌    │
│ Clients        │ /clients   │      ✅      │      ✅      │    ✅*   │
│ Invoices       │ /invoices  │      ✅      │      ✅      │    ❌    │
│ Tasks          │ /tasks     │      ✅      │      ✅      │    ✅*   │
│ Expenses       │ /expenses  │      ✅      │      ✅      │    ✅*   │
│ Projects       │ /projects  │      ✅      │      ✅      │    ❌    │
│ Suppliers      │ /suppliers │      ✅      │      ❌**    │    ❌    │
│ POs            │ /po/pdf    │      ✅      │      ❌**    │    ❌    │
│ Inventory      │ /inventory │      ✅      │      ❌**    │    ❌    │
│ Finance        │ /finance   │      ✅      │      ❌**    │    ❌    │
│ Loyalty        │ /loyalty   │      ✅      │      ❌**    │    ❌    │
│ Wallet         │ /billing   │      ✅      │      ❌**    │    ❌    │
│ Anomalies      │ /anomalies │      ✅      │      ❌**    │    ❌    │
│ Admin          │ /admin     │      ✅      │      ❌**    │    ❌    │
└────────────────┴────────────┴──────────────┴──────────────┴──────────┘

Legend:
  ✅    = Full access
  ✅*   = Limited access (read-only or task-specific)
  ❌    = No access
  ❌**  = Desktop only (hidden on mobile)
  
D = Desktop/Web
M = Mobile
Emp = Employee
```

---

## 🔄 NAVIGATION FLOW

### Owner Flow
```
Login/Signup
    │
    ↓
Dashboard ◄─────────────────────────────┐
    │                                    │
    ├─→ CRM ─→ Contact ─→ Details       │
    │                                    │
    ├─→ Clients ─→ Client Detail        │
    │                                    │
    ├─→ Invoices ─→ Invoice Detail      │
    │                 ├─→ PDF View      │
    │                 └─→ Email Send    │
    │                                    │
    ├─→ Tasks ─→ Task Detail            │
    │                                    │
    ├─→ Expenses ─→ Receipt Scan        │
    │               ├─→ OCR Parse       │
    │               └─→ Verify          │
    │                                    │
    ├─→ Projects ─→ Project Detail      │
    │                                    │
    ├─→ ADVANCED (collapse/expand)      │
    │   ├─→ Suppliers ─→ Add/Edit       │
    │   ├─→ POs ─→ Create ─→ Email      │
    │   ├─→ Inventory ─→ Manage Stock   │
    │   ├─→ Finance ─→ Analytics        │
    │   ├─→ Loyalty ─→ Config           │
    │   ├─→ Wallet ─→ Buy Tokens        │
    │   ├─→ Anomalies ─→ Alerts         │
    │   └─→ Admin ─→ Settings           │
    │                                    │
    └─→ Settings ────────────────────────┘
```

### Employee Flow
```
Login (Mobile Only)
    │
    ↓
Employee Dashboard (5 tabs)
    │
    ├─ Tab 1: Assigned Tasks
    │         ├─→ Task Detail
    │         └─→ Mark Complete
    │
    ├─ Tab 2: Log Expense
    │         ├─→ Camera Scan
    │         ├─→ OCR Parse
    │         └─→ Submit
    │
    ├─ Tab 3: View Clients (read-only)
    │         └─→ Client Details
    │
    ├─ Tab 4: Complete Jobs
    │         ├─→ Job Detail
    │         └─→ Add Photo + Submit
    │
    └─ Tab 5: Profile & Settings
              ├─→ View Permissions
              ├─→ Sync Status
              └─→ Logout
```

---

## 🎯 FEATURE ORGANIZATION

### Main Navigation (All Users See)
```
┌─────────────────────────────────────┐
│ Dashboard      (7)  Invoices   (10) │
│ CRM            (8)  Tasks      (5)  │
│ Clients        (6)  Expenses   (8)  │
│ Projects       (4)  Settings   (6)  │
└─────────────────────────────────────┘
                 ↓ (Desktop Only)
┌─────────────────────────────────────┐
│ ADVANCED SECTION (Owners Only)      │
├─────────────────────────────────────┤
│ Suppliers      (5)  Anomalies   (4) │
│ POs            (3)  Admin       (8) │
│ Inventory      (6)  Finance    (10) │
│ Loyalty        (7)  Wallet      (5) │
└─────────────────────────────────────┘
```

---

## 👥 PERMISSIONS SUMMARY

### Owner
```
┌──────────────────────────────────────┐
│  OWNER PERMISSIONS                   │
├──────────────────────────────────────┤
│ Desktop/Web:    All 15 features      │
│ Mobile:         7 main features      │
│ Read:           All user data        │
│ Write:          All user data        │
│ Delete:         All user data        │
│ Invite:         Add employees (later)│
│ Settings:       Change config        │
│ Admin:          Manage system        │
└──────────────────────────────────────┘
```

### Employee
```
┌──────────────────────────────────────┐
│  EMPLOYEE PERMISSIONS                │
├──────────────────────────────────────┤
│ Desktop/Web:    NOT AVAILABLE        │
│ Mobile:         6 features only      │
│ Read:           Assigned tasks       │
│ Read:           Clients (read-only)  │
│ Write:          Create expenses      │
│ Write:          Complete jobs        │
│ Delete:         Own records only     │
│ Invite:         NOT ALLOWED          │
│ Settings:       View only            │
│ Admin:          NOT AVAILABLE        │
└──────────────────────────────────────┘
```

---

## 🚦 ACCESS CONTROL DECISION TREE

```
User logs in
    │
    ├─ Check Role
    │   │
    │   ├─ Owner
    │   │   │
    │   │   ├─ On Mobile?
    │   │   │   ├─ Show: 7 main features
    │   │   │   └─ Allow: Advanced via menu
    │   │   │
    │   │   └─ On Desktop?
    │   │       ├─ Show: 7 main features
    │   │       ├─ Show: Advanced section
    │   │       └─ Allow: All routes
    │   │
    │   └─ Employee
    │       │
    │       ├─ On Mobile?
    │       │   ├─ Show: 6 features only
    │       │   └─ Allow: These 6 routes
    │       │
    │       └─ On Desktop?
    │           ├─ Deny: Not available
    │           └─ Redirect: Mobile only message
    │
    └─ Route request
        │
        ├─ Check permission
        │
        ├─ Allowed?
        │   └─ Navigate
        │
        └─ Denied?
            └─ Show error + Redirect to allowed route
```

---

## 📊 STATISTICS

### Features by Category

```
EMPLOYEE ACCESS
  ├─ Mobile: 6 features
  ├─ Desktop: 0 features
  └─ Total: 6 features

OWNER MAIN ACCESS
  ├─ Mobile: 7 features
  ├─ Desktop: 7 features
  └─ Total: 7 features

OWNER ADVANCED ACCESS (Desktop Only)
  ├─ Mobile: 0 features (hidden)
  ├─ Desktop: 8 features
  └─ Total: 8 features

OWNER TOTAL
  ├─ Mobile: 7 features
  ├─ Desktop: 15 features
  └─ Total: 15 features

SYSTEM TOTAL
  ├─ Unique routes: 20+
  ├─ Role definitions: 2
  ├─ Platform types: 4
  └─ Access rules: 30+
```

---

## 🎯 QUICK DECISION GUIDE

**Am I an Owner?**
- On Mobile? → See 7 main + access to Advanced menu
- On Desktop? → See all 15 features + Advanced section
- On Web? → See all 15 features + Advanced section

**Am I an Employee?**
- On Mobile? → See 6 features only
- On Desktop? → Not allowed (redirect to mobile)
- On Web? → Not allowed (redirect to mobile)

**Can I access [Feature X]?**
1. Check your role (Owner / Employee)
2. Check your device (Mobile / Desktop / Web)
3. Look up feature in access matrix
4. If not allowed, redirect to employee dashboard

---

## 📱 PLATFORM SUPPORT

```
┌──────────────┬────────┬────────┬────────┬────────┐
│    Device    │ Owner? │ View?  │Features│ Redirect│
├──────────────┼────────┼────────┼────────┼────────┤
│ iPhone       │  ✅    │  7+adv │  15   │   N/A  │
│ Android      │  ✅    │  7+adv │  15   │   N/A  │
│ iPad         │  ✅    │  7+adv │  15   │   N/A  │
│ Windows      │  ✅    │  all   │  15   │   N/A  │
│ macOS        │  ✅    │  all   │  15   │   N/A  │
│ Linux        │  ✅    │  all   │  15   │   N/A  │
├──────────────┼────────┼────────┼────────┼────────┤
│ iPhone       │  ❌    │   6    │   6   │   N/A  │
│ Android      │  ❌    │   6    │   6   │   N/A  │
│ iPad         │  ❌    │  block │   0   │ Mobile │
│ Windows      │  ❌    │  block │   0   │ Mobile │
│ macOS        │  ❌    │  block │   0   │ Mobile │
│ Linux        │  ❌    │  block │   0   │ Mobile │
└──────────────┴────────┴────────┴────────┴────────┘
```

---

**Visual Reference Complete!**

Use this guide as a quick reference for what each role can access on each platform.

