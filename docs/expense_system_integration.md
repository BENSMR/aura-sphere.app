# Expense System Integration Guide

## Overview

The expense system provides comprehensive expense management with OCR scanning, approval workflows, audit trails, and multi-system integration.

**Key Features:**
- OCR receipt scanning (Vision API)
- VAT detection (country-aware)
- Approval workflow (draft → pending → approved/rejected → reimbursed)
- AuraToken rewards
- Audit trail & version history
- Inventory tracking
- Invoice linking
- CSV import/export
- Detailed reporting

---

## Core Integration Points

### 1. **Link Expense to Invoice**

Connect an expense to an invoice for financial reconciliation.

```dart
// In ExpenseService
await expenseService.linkToInvoice(expenseId, invoiceId);
```

**Result:**
- Updates `invoiceId` field on expense document
- Sets `updatedAt` timestamp
- Creates audit trail entry

**Firestore Path:**
```
users/{userId}/expenses/{expenseId}
  invoiceId: "invoice_abc123"
```

**Use Cases:**
- Linking receipt scans to invoices
- Matching expenses to billing
- Financial reconciliation

---

### 2. **Inventory Stock Movement**

Automatically update inventory when an expense with category "Inventory" is approved.

**Cloud Function:** `onExpenseApprovedInventory`

**Trigger:**
```
Expense status changes to 'approved' AND category == 'Inventory'
```

**Actions:**
1. Create stock movement record
2. Update project inventory totals
3. Update warehouse stock balance (optional)
4. Create audit entry

**Firestore Paths Created:**
```
users/{userId}/inventory_movements/{movementId}
  - type: "purchase"
  - amount, vat, currency
  - merchant, date, projectId
  - expenseId (reference)

users/{userId}/projects/{projectId}
  - inventory.totalSpent (incremented)
  - inventory.totalVAT (incremented)

users/{userId}/warehouses/{warehouseId}/stock/{itemId}
  - quantity (incremented)
```

**Expense Fields for Inventory:**
```dart
ExpenseModel(
  category: 'Inventory',      // Triggers movement
  projectId: 'proj_123',      // Links to project
  merchant: 'Supplier Inc',   // Source
  amount: 500.0,              // Purchase cost
  vat: 100.0,                 // VAT portion
  // Optional: warehouseId, itemId, quantity for detailed tracking
)
```

**Example Workflow:**
```
1. User scans receipt from supplier
2. ExpenseParser extracts: merchant, amount, date
3. User selects category: "Inventory"
4. User approves/submits expense
5. Cloud Function: onExpenseApprovedInventory triggers
6. Stock movement created in inventory_movements
7. Project inventory.totalSpent updated
```

---

### 3. **Approval Workflow & Role-Based Access**

Implement manager approval flows using Firestore rules and user roles.

**User Roles:**
```dart
// In user profile (users/{userId}/profile)
{
  name: "John Doe",
  email: "john@example.com",
  country: "FR",
  role: "manager",              // or "employee", "accountant", "admin"
  department: "Finance",
  canApproveExpenses: true,
  approveLimitEUR: 5000.0,      // Max approval amount
}
```

**Firestore Rules:**

```firestore
match /users/{userId}/expenses/{expenseId} {
  allow read: if 
    request.auth.uid == userId ||              // Owner
    isAdmin() ||                               // Admin
    resource.data.approverId == request.auth.uid ||  // Assigned approver
    isManagerWithApprovalAccess();             // Manager role
    
  allow update: if 
    request.auth.uid == userId ||              // Owner can edit
    isAdmin() ||                               // Admin
    (isManagerWithApprovalAccess() && 
     canApproveAmount(resource.data.amount));  // Manager within limit
}

function isManagerWithApprovalAccess() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)/profile).data.role == 'manager'
         && get(/databases/$(database)/documents/users/$(request.auth.uid)/profile).data.canApproveExpenses == true;
}

function canApproveAmount(amount) {
  let profile = get(/databases/$(database)/documents/users/$(request.auth.uid)/profile).data;
  return amount <= (profile.approveLimitEUR ?? 10000.0);
}
```

**Approval Flow:**

```dart
// 1. Employee submits expense
final expense = await expenseService.createExpenseDraft(
  merchant: 'Acme Corp',
  amount: 250.0,
  category: 'Supplies',
  // Status: pending_approval
);

// 2. Manager reviews and approves
await expenseService.changeStatus(
  expenseId,
  ExpenseStatus.approved,
  approverId: managerUid,
  note: 'Approved - legitimate business expense',
);
// Cloud Function: onExpenseApproved triggers
// → Notification sent to employee
// → AuraTokens awarded to employee
// → Audit entry created

// 3. Accountant processes reimbursement
await expenseService.changeStatus(
  expenseId,
  ExpenseStatus.reimbursed,
  approverId: accountantUid,
  note: 'Reimbursed via bank transfer',
);
```

**Approval Status Diagram:**

```
┌─────────────────────────────────────────────────────┐
│  draft                                              │
│  (Employee creates)                                 │
└──────────┬──────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────┐
│  pending_approval                                   │
│  (Waiting for manager review)                       │
└──────┬───────────────────────────────────┬──────────┘
       │                                   │
       │ (Manager approves)                │ (Manager rejects)
       ▼                                   ▼
   approved ──────────────────────────► rejected
   (Ready for                           (Sent back to
    reimbursement)                       employee)
       │
       │ (Accountant reimbursed)
       ▼
   reimbursed
   (Completed)
```

---

### 4. **Notification System (FCM)**

When an expense is approved, an FCM notification is sent to the submitter.

**Cloud Function:** `onExpenseApproved`

**Notification Payload:**
```dart
{
  "notification": {
    "title": "✅ Expense Approved",
    "body": "Your expense \"Acme Corp\" (EUR 250.00) was approved!"
  },
  "data": {
    "expenseId": "exp_abc123",
    "type": "expense_approved",
    "merchant": "Acme Corp"
  }
}
```

**Implementation:**
1. User device subscribes to FCM topic
2. Cloud Function sends notification
3. App receives and displays notification
4. User taps notification → opens expense details

---

### 5. **AuraToken Rewards**

Employee receives tokens when expense is approved.

**Cloud Function:** `onExpenseApproved`

**Reward Amount:** 10 AuraTokens per approved expense

**Firestore Record:**
```
users/{userId}/auraTokenTransactions/{txId}
{
  type: "reward",
  action: "expense_approved",
  expenseId: "exp_abc123",
  amount: 10,
  merchant: "Acme Corp",
  currency: "EUR",
  transactionAmount: 250.0,
  description: "Reward for approving expense from Acme Corp",
  createdAt: timestamp
}
```

**User Balance Updated:**
```
users/{userId}
{
  auraTokens: increment(10)  // Added to total
}
```

---

### 6. **Audit Trail & Version History**

All changes are logged for compliance and troubleshooting.

**Audit Trail:**
```
users/{userId}/expenses/{expenseId}/audit/{auditId}
{
  action: "approved",
  actor: "manager_uid",
  notes: "Approved - legitimate business expense",
  metadata: {
    previousStatus: "pending_approval",
    newStatus: "approved"
  },
  ts: timestamp,
  ipAddress: "192.168.1.1",
  userAgent: "flutter_app"
}
```

**Version History:**
```
users/{userId}/expenses/{expenseId}/_history/{historyId}
{
  changes: {
    status: { before: "pending_approval", after: "approved" },
    approverId: { before: null, after: "manager_uid" }
  },
  changedBy: "manager_uid",
  changedAt: timestamp,
  previousSnapshot: { /* full expense before change */ },
  newSnapshot: { /* full expense after change */ }
}
```

**Access Audit:**
```dart
// Get audit trail
final auditTrail = await expenseService.getAuditTrail(expenseId);

// Get version history
final history = await expenseService.getExpenseHistory(expenseId);

// Get audit summary
final summary = await expenseService.getAuditSummary(expenseId);
```

---

### 7. **CSV Import**

Bulk import expenses from spreadsheet.

**CSV Format:**
```csv
merchant,date,amount,currency,category,vatrate,paymentmethod
Acme Corp,2025-11-27,100.00,EUR,Supplies,0.20,card
Coffee Shop,2025-11-26,5.50,USD,Food,0.00,cash
Taxi Service,2025-11-25,25.00,EUR,Transport,0.20,card
```

**Required Columns:**
- `merchant` (string)
- `amount` (number)

**Optional Columns:**
- `date` (YYYY-MM-DD)
- `currency` (3-letter code, default: EUR)
- `category` (string, default: General)
- `vatrate` (decimal 0-1, default: 0.20)
- `paymentmethod` (string, default: unknown)

**Usage:**
```dart
final importer = CsvImporter();

// Pick file and import
try {
  final imported = await importer.pickAndImport();
  print('Imported ${imported.length} expenses');
} catch (e) {
  print('Import error: $e');
}

// Preview before importing
final preview = CsvImporter.previewCSV(csvContent);
print('Total rows: ${preview['totalRows']}');
print('Has errors: ${preview['hasErrors']}');
```

---

### 8. **Reporting & Analytics**

Generate monthly/yearly reports and export data.

```dart
final reportService = ReportService();

// Monthly CSV export
final csv = await reportService.exportMonthlyCsv(2025, 11);

// Yearly CSV export
final yearCsv = await reportService.exportYearlyCsv(2025);

// Statistics summary
final stats = await reportService.getStatsSummary();
// Returns: totalExpenses, totalVAT, avgExpense, topCategories, topMerchants

// Status breakdown
final statusReport = await reportService.getStatusReport();
// Returns: count and total by status (draft, pending, approved, etc.)

// Category analysis
final categoryReport = await reportService.getCategoryReport();
// Returns: per-category totals, averages, approval counts
```

---

## Security Considerations

### 1. **User Isolation**
- All expenses stored under `users/{userId}/*`
- Firestore rules enforce `request.auth.uid == userId`
- Cross-user access only for managers/admins

### 2. **Sensitive Data**
- No personal credit card info stored
- OCR extracts only merchant/amount/date
- Photos deleted after processing (optional)

### 3. **Approval Authorization**
- Managers can only approve within their approval limit
- Two-factor approval required for large expenses (custom)
- Audit trail tracks all approvals

### 4. **Immutable Audit Trail**
- Audit entries cannot be deleted or modified
- Historical snapshots preserved
- Tampering detection possible via versioning

---

## Deployment

### Deploy Cloud Functions:
```bash
firebase deploy --only functions
```

### Deploy Firestore Rules:
```bash
firebase deploy --only firestore:rules
```

### Full Deployment:
```bash
firebase deploy
```

---

## Testing Integration

### Test Expense Creation:
```dart
final service = ExpenseService();
final expense = await service.createExpenseDraft(
  merchant: 'Test Corp',
  amount: 100.0,
  currency: 'EUR',
  category: 'Supplies',
);
print('Created: ${expense.id}');
```

### Test Approval Flow:
```dart
await service.changeStatus(
  expense.id,
  ExpenseStatus.approved,
  approverId: 'manager_123',
  note: 'Test approval',
);
```

### Test CSV Import:
```dart
final csv = 'merchant,amount\nTest,100.0\nTest2,50.0';
final imported = await service.importCsvRows(csv);
print('Imported: ${imported.length}');
```

---

## Common Use Cases

### Use Case 1: Employee Submits Receipt
1. Employee launches app
2. Taps "Scan Receipt" button
3. Takes photo of receipt
4. ExpenseParser extracts: merchant, amount, date, VAT
5. ExpenseReviewScreen displays for confirmation
6. Employee modifies if needed
7. Expense saved as "pending_approval"
8. Manager receives notification

### Use Case 2: Manager Approves Multiple Expenses
1. Manager opens ExpenseListScreen
2. Filters by "Pending Approval"
3. Reviews each expense details
4. Taps "Approve" or "Reject"
5. System creates audit entry
6. Employee receives FCM notification
7. Employee receives AuraTokens (if approved)

### Use Case 3: Inventory Purchase
1. Employee scans receipt from supplier
2. Selects category: "Inventory"
3. Sets projectId: "warehouse_project"
4. Manager approves
5. Cloud Function: onExpenseApprovedInventory triggers
6. Stock movement created
7. Project inventory totals updated

### Use Case 4: Monthly Reconciliation
1. Accountant navigates to Reports
2. Selects "Export Monthly Report"
3. Generates CSV with summary and breakdown
4. Downloads and imports to accounting system
5. Verifies against bank statements

---

## Troubleshooting

### Cloud Function Not Triggering
- Check Cloud Functions logs: `gcloud functions log`
- Verify Firestore rule allows write
- Check function deployment status

### Audit Entries Not Created
- Verify user has write access to audit subcollection
- Check Firestore rules for audit permission
- Review function error logs

### Inventory Not Updating
- Verify expense category is exactly "Inventory"
- Check if projectId exists
- Review onExpenseApprovedInventory logs

### CSV Import Failing
- Verify headers match expected format
- Check date format (YYYY-MM-DD)
- Ensure amount and merchant columns present

---

## API Reference

See [API Reference](./api_reference.md) for detailed method signatures and return types.
