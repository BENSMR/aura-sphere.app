# Invoice Integration: Complete Summary

**Date:** November 27, 2025  
**Status:** ✅ Model Enhanced + Integration Guide Created  

---

## What Was Done

### 1. Enhanced InvoiceModel ✅

**File:** `lib/data/models/invoice_model.dart`

**New Fields Added:**
```dart
final String? projectId;              // Link to project
final List<String>? linkedExpenseIds;  // Expenses linked to this invoice
final double discount;                // Absolute discount amount
final String? notes;                  // Additional invoice notes
final Map<String, dynamic>? audit;    // Audit trail
```

**New Helper Methods:**
```dart
bool get hasLinkedExpenses => linkedExpenseIds != null && linkedExpenseIds!.isNotEmpty;
int get linkedExpenseCount => linkedExpenseIds?.length ?? 0;
bool get isCurrentlyOverdue => !isPaid && dueDate != null && DateTime.now().isAfter(dueDate!);
double get totalWithDiscount => total - (discount ?? 0);
bool get isDraft => status == 'draft';
bool get isSent => status == 'sent';
bool get isPaid => status == 'paid';
bool get isOverdue => status == 'overdue';
bool get isCanceled => status == 'cancelled';
```

**Updated Methods:**
- `copyWith()` — Now includes all new fields
- `toMap()` — Serializes new fields
- `fromDoc()` — Deserializes new fields from Firestore
- `fromJson()` — Deserializes from JSON
- `toJson()` — Serializes to JSON

---

### 2. Created Integration Guide ✅

**File:** `docs/expense_invoice_integration.md` (500+ lines)

**Covers:**
1. **Overview** — How expenses link to invoices
2. **Data Model** — Schema and relationships
3. **Service Methods** — InvoiceService implementation guide
4. **UI Integration** — Widgets for picker and display
5. **Security Rules** — Firestore rules for invoices
6. **Workflow** — Step-by-step linking process
7. **Cloud Function** — Optional sync function
8. **Summary** — What's implemented vs. to-do
9. **Testing Checklist** — 8 test steps

---

## Integration Architecture

```
User (Employee)
  │
  ├─→ Scans Receipt
  │    └─→ ExpenseScannerScreen
  │
  ├─→ Reviews & Edits
  │    └─→ ExpenseReviewScreen
  │         ├─ TaxService (VAT)
  │         └─ InvoicePickerWidget (NEW)
  │              └─ Shows all open invoices
  │
  ├─→ Selects Invoice
  │    └─→ Saves with invoiceId
  │
  ├─→ Submits for Approval
  │    └─→ Status: pending_approval
  │
Manager (Approver)
  │
  ├─→ Views Pending Expenses
  │    └─→ ExpenseListScreen
  │
  ├─→ Approves Expense
  │    └─→ Cloud Function: onExpenseApproved
  │         ├─ Sends FCM notification
  │         ├─ Awards AuraTokens
  │         └─ Creates audit entry
  │
Accountant / Client Manager
  │
  ├─→ Views Invoice Details
  │    └─→ Sees linked expenses
  │         └─ LinkedExpensesWidget (NEW)
  │              ├─ Displays all linked expense details
  │              ├─ Shows linked expense count
  │              └─ Can unlink if needed
  │
  └─→ Generates Invoice PDF
       └─ Includes linked expense details (optional)
```

---

## Current State

### ✅ Implemented
- ExpenseModel with invoiceId field
- InvoiceModel with linkedExpenseIds field
- ExpenseService.linkToInvoice() method
- InvoiceModel enhanced with new fields

### 📋 Ready to Implement (In Guide)
- InvoiceService (full CRUD + linking)
- InvoicePickerWidget (select invoice)
- LinkedExpensesWidget (display linked expenses)
- Firestore rules for invoice security
- Cloud Function for sync (optional)

### 🔲 Not Yet Done
- InvoiceService code
- UI widget integration
- Firestore rules update
- Cloud Function (optional)

---

## Database Schema

### Expense Document
```
users/{userId}/expenses/{expenseId}
{
  id: "exp_123",
  merchant: "Acme Corp",
  amount: 250.00,
  invoiceId: "INV-001",  ← Links to invoice
  status: "approved",
  // ... other fields ...
}
```

### Invoice Document
```
users/{userId}/invoices/{invoiceId}
{
  id: "INV-001",
  invoiceNumber: "INV-2025-001",
  clientId: "client_123",
  items: [...],
  linkedExpenseIds: ["exp_1", "exp_2"],  ← Links to expenses
  total: 1000.00,
  status: "sent",
  // ... other fields ...
}
```

---

## Key Features

### 1. **Expense → Invoice Linking**
- Expense has `invoiceId` field
- Invoice has `linkedExpenseIds` array
- Bidirectional relationship maintained

### 2. **Open Invoice Picker**
- When reviewing expense, see all draft/sent invoices
- Select which invoice to link to
- Auto-saves with invoice ID

### 3. **Linked Expenses Display**
- Invoice detail shows all linked expenses
- Display: merchant, amount, category, status
- Can unlink individual expenses
- Shows linked expense count

### 4. **Real-Time Sync**
- Stream updates on both sides
- Status changes propagate
- Audit trail maintained

### 5. **Validation**
- Max 50 expenses per invoice
- Valid status transitions
- User ownership enforced

---

## Service Methods (To Implement)

```dart
// InvoiceService methods to add:

// Link expense to invoice
Future<void> linkExpenseToInvoice(String invoiceId, String expenseId)

// Unlink expense from invoice
Future<void> unlinkExpenseFromInvoice(String invoiceId, String expenseId)

// Get all linked expenses for invoice
Future<List<ExpenseModel>> getLinkedExpenses(String invoiceId)

// Get open invoices (draft/sent)
Stream<List<InvoiceModel>> watchOpenInvoices()

// Calculate total from linked expenses
Future<double> calculateTotalFromExpenses(String invoiceId)

// Sync invoice total with linked expenses
Future<void> syncInvoiceTotalFromExpenses(String invoiceId)

// Watch linked expenses in real-time
Stream<List<ExpenseModel>> watchLinkedExpenses(String invoiceId)
```

---

## UI Widgets (To Implement)

### InvoicePickerWidget
```dart
// Location: lib/widgets/invoice_picker_widget.dart
// Use in: ExpenseReviewScreen

Column(
  children: [
    Text('Link to Invoice'),
    DropdownButton<String>(
      items: invoices.map(...),
      onChanged: (invoiceId) { ... }
    ),
  ],
)
```

### LinkedExpensesWidget
```dart
// Location: lib/widgets/linked_expenses_widget.dart
// Use in: Invoice detail screen

Column(
  children: [
    Text('Linked Expenses'),
    ListView(
      children: [
        ListTile(merchant, amount, unlink button),
        ...
      ],
    ),
  ],
)
```

---

## Firestore Rules (To Update)

```firestore
// Add invoice rules
match /invoices/{invoiceId} {
  allow read: if request.auth.uid == get(...).data.userId;
  allow create: if request.auth.uid == request.resource.data.userId;
  allow update: if request.auth.uid == resource.data.userId;
  
  match /audit/{auditId} {
    allow read, create: if request.auth.uid == get(...).data.userId;
  }
}
```

---

## Testing Workflow

```
1. Create Invoice
   └─ INV-001, client "ABC Inc", status "draft"

2. Scan Receipt
   └─ Expense: Acme Corp, EUR 250

3. Review & Select Invoice
   └─ InvoicePickerWidget shows INV-001
   └─ Select and save

4. Verify Linking
   └─ Expense.invoiceId = "INV-001"
   └─ Invoice.linkedExpenseIds contains "exp_123"

5. Manager Approves
   └─ Expense status → approved
   └─ FCM + AuraToken awarded

6. View Invoice Details
   └─ LinkedExpensesWidget shows linked expense
   └─ Count: 1

7. Unlink Expense
   └─ Remove from linkedExpenseIds
   └─ Verify count updates to 0

8. View Expense
   └─ invoiceId still present
   └─ Can relink to different invoice
```

---

## Integration Timeline

### Phase 1: Model Enhancement ✅ DONE
- InvoiceModel fields added
- Helper methods implemented
- Serialization updated

### Phase 2: Service Layer 📋 READY
- InvoiceService methods documented
- Implementation guide provided
- Ready to code

### Phase 3: UI Implementation 📋 READY
- InvoicePickerWidget documented
- LinkedExpensesWidget documented
- Ready to code

### Phase 4: Security & Testing 📋 READY
- Firestore rules documented
- Test cases documented
- Cloud Function optional

---

## Files Modified

| File | Changes | Status |
|------|---------|--------|
| `lib/data/models/invoice_model.dart` | 5 new fields, 7 new methods | ✅ Updated |
| `docs/expense_invoice_integration.md` | Complete integration guide | ✅ Created |

---

## Files To Create (Next)

| File | Purpose | Lines |
|------|---------|-------|
| `lib/services/invoice_service.dart` | Full invoice CRUD + linking | 300-400 |
| `lib/widgets/invoice_picker_widget.dart` | Invoice selection dropdown | 80-100 |
| `lib/widgets/linked_expenses_widget.dart` | Display linked expenses | 100-120 |
| `functions/src/invoices/onExpenseStatusChange.ts` | Sync function (optional) | 50-80 |

---

## Quick Start: Link an Expense to Invoice

### In Code (Already Works):
```dart
// ExpenseService method (already exists)
await expenseService.linkToInvoice(expenseId, invoiceId);

// This updates: expense.invoiceId = invoiceId
// And creates: audit entry
```

### In UI (To Implement):
```dart
// 1. Show invoice picker (InvoicePickerWidget)
// 2. Select invoice
// 3. Save expense with invoiceId
// 4. Optionally call: invoiceService.linkExpenseToInvoice()

// Result:
// - Expense.invoiceId = selected invoice
// - Invoice.linkedExpenseIds += [expense]
```

---

## Next Steps

**To Complete Integration:**

1. **Create InvoiceService** (2-3 hours)
   - Implement 7 service methods from guide
   - Add Provider setup

2. **Add UI Widgets** (1-2 hours)
   - InvoicePickerWidget
   - LinkedExpensesWidget
   - Add to appropriate screens

3. **Update Firestore Rules** (30 minutes)
   - Add invoice access control
   - Add validation functions

4. **Test Linking** (30 minutes)
   - Manual test workflow
   - Verify bidirectional sync

5. **(Optional) Cloud Function** (1 hour)
   - Sync invoice on expense change
   - Update metadata

**Total: 4-6 hours to full integration**

---

## Summary

✅ **InvoiceModel Enhanced** with:
- projectId, linkedExpenseIds, discount, notes, audit fields
- Helper methods for status, overdue, linked expenses
- Full serialization (toMap, fromDoc, toJson, fromJson, copyWith)

✅ **Integration Guide Created** with:
- Complete service implementation
- UI widgets examples
- Security rules
- Cloud Function (optional)
- Testing checklist
- Step-by-step workflow

🚀 **Ready to Implement** — All code patterns and examples provided in guide

---

## Status

| Component | Status |
|-----------|--------|
| Model | ✅ Complete |
| Integration Guide | ✅ Complete |
| Service Methods | 📋 Documented |
| UI Widgets | 📋 Documented |
| Firestore Rules | 📋 Documented |
| Cloud Function | 📋 Optional |
| Testing | 📋 Documented |

**Overall:** 40% Complete (Model + Guide) → Ready for 60% (Code Implementation)
