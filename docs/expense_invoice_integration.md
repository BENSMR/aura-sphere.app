# Expense ↔ Invoice Integration Guide

**Purpose:** Link expenses to invoices for complete financial reconciliation  
**Date:** November 27, 2025  
**Status:** ✅ Ready to Implement

---

## Overview

The expense system integrates bidirectionally with invoices:

```
Expense (with invoiceId)          Invoice (with linkedExpenseIds)
├─ merchant: "Supplier Inc"       ├─ items: [InvoiceItem, ...]
├─ amount: 500.00                 ├─ clientId: "client_123"
├─ category: "Supplies"           ├─ linkedExpenseIds: ["exp_1", "exp_2"]
├─ invoiceId: "INV-001" ←────────→ ├─ total: 1000.00
└─ status: approved               └─ linkedExpenseCount: 2
```

---

## Data Model Updates

### InvoiceModel Enhancements ✅

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

// Status helpers
bool get isDraft => status == 'draft';
bool get isSent => status == 'sent';
bool get isPaid => status == 'paid';
bool get isOverdue => status == 'overdue';
bool get isCanceled => status == 'cancelled';
```

### ExpenseModel Already Has:
```dart
final String? invoiceId;     // Links to invoice ID
```

---

## Firestore Schema

### Expense Document
```
users/{userId}/expenses/{expenseId}
{
  id: "exp_123",
  merchant: "Acme Corp",
  amount: 250.00,
  currency: "EUR",
  category: "Supplies",
  invoiceId: "INV-001",           ← Links to invoice
  status: "approved",
  approverId: "manager_456",
  createdAt: timestamp,
  audit: { ... }
}
```

### Invoice Document
```
users/{userId}/invoices/{invoiceId}
{
  id: "INV-001",
  invoiceNumber: "INV-2025-001",
  clientId: "client_123",
  clientName: "ABC Inc",
  items: [
    { name: "Item 1", quantity: 1, unitPrice: 500, vatRate: 0.20 },
    { name: "Item 2", quantity: 2, unitPrice: 100, vatRate: 0.20 }
  ],
  linkedExpenseIds: ["exp_1", "exp_2"],  ← Links to expenses
  total: 1000.00,
  status: "sent",
  createdAt: timestamp,
  audit: { ... }
}
```

---

## Service Methods (InvoiceService)

### Assuming you create InvoiceService, add these methods:

```dart
class InvoiceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  late CollectionReference _userInvoicesRef;

  InvoiceService() {
    if (_uid != null) {
      _userInvoicesRef = _firestore.collection('users').doc(_uid).collection('invoices');
    }
  }

  // Link expense to invoice
  Future<void> linkExpenseToInvoice(
    String invoiceId,
    String expenseId,
  ) async {
    if (_uid == null) throw Exception('User not authenticated');
    
    try {
      await _userInvoicesRef.doc(invoiceId).update({
        'linkedExpenseIds': FieldValue.arrayUnion([expenseId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create audit entry
      await _userInvoicesRef.doc(invoiceId).collection('audit').add({
        'action': 'expense_linked',
        'expenseId': expenseId,
        'actor': _uid,
        'ts': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      print('Error linking expense: $e');
      rethrow;
    }
  }

  // Unlink expense from invoice
  Future<void> unlinkExpenseFromInvoice(
    String invoiceId,
    String expenseId,
  ) async {
    if (_uid == null) throw Exception('User not authenticated');
    
    try {
      await _userInvoicesRef.doc(invoiceId).update({
        'linkedExpenseIds': FieldValue.arrayRemove([expenseId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create audit entry
      await _userInvoicesRef.doc(invoiceId).collection('audit').add({
        'action': 'expense_unlinked',
        'expenseId': expenseId,
        'actor': _uid,
        'ts': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      print('Error unlinking expense: $e');
      rethrow;
    }
  }

  // Get linked expenses for invoice
  Future<List<ExpenseModel>> getLinkedExpenses(String invoiceId) async {
    if (_uid == null) throw Exception('User not authenticated');
    
    try {
      final invoiceDoc = await _userInvoicesRef.doc(invoiceId).get();
      final invoice = InvoiceModel.fromDoc(invoiceDoc);

      if (!invoice.hasLinkedExpenses) return [];

      final expenseDocs = await Future.wait(
        invoice.linkedExpenseIds!.map(
          (expenseId) => _firestore
              .collection('users')
              .doc(_uid)
              .collection('expenses')
              .doc(expenseId)
              .get(),
        ),
      );

      return expenseDocs
          .map((doc) => ExpenseModel.fromDoc(doc))
          .toList();
    } catch (e) {
      print('Error fetching linked expenses: $e');
      rethrow;
    }
  }

  // Get invoices without expenses linked
  Stream<List<InvoiceModel>> watchOpenInvoices() {
    if (_uid == null) throw Exception('User not authenticated');
    
    return _userInvoicesRef
        .where('status', whereIn: ['draft', 'sent'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(InvoiceModel.fromDoc).toList());
  }

  // Calculate invoice total from linked expenses
  Future<double> calculateTotalFromExpenses(String invoiceId) async {
    if (_uid == null) throw Exception('User not authenticated');
    
    try {
      final expenses = await getLinkedExpenses(invoiceId);
      return expenses.fold<double>(0, (sum, exp) => sum + exp.amount);
    } catch (e) {
      print('Error calculating total: $e');
      rethrow;
    }
  }

  // Sync invoice total with linked expenses
  Future<void> syncInvoiceTotalFromExpenses(String invoiceId) async {
    if (_uid == null) throw Exception('User not authenticated');
    
    try {
      final total = await calculateTotalFromExpenses(invoiceId);
      
      await _userInvoicesRef.doc(invoiceId).update({
        'subtotal': total,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      print('Error syncing invoice total: $e');
      rethrow;
    }
  }

  // Watch linked expenses in real-time
  Stream<List<ExpenseModel>> watchLinkedExpenses(String invoiceId) async* {
    if (_uid == null) throw Exception('User not authenticated');
    
    try {
      final invoiceSnap = _userInvoicesRef.doc(invoiceId).snapshots();
      
      await for (final snap in invoiceSnap) {
        final invoice = InvoiceModel.fromDoc(snap);
        
        if (!invoice.hasLinkedExpenses) {
          yield [];
          continue;
        }

        // Watch all linked expenses
        final expenseStreams = invoice.linkedExpenseIds!.map(
          (expenseId) => _firestore
              .collection('users')
              .doc(_uid)
              .collection('expenses')
              .doc(expenseId)
              .snapshots()
              .map(ExpenseModel.fromDoc),
        );

        // Combine all streams
        yield* StreamGroup.merge(expenseStreams);
      }
    } catch (e) {
      print('Error watching linked expenses: $e');
      rethrow;
    }
  }
}
```

---

## UI Integration

### Invoice Picker Widget (For Expense Review)

```dart
// Add to ExpenseReviewScreen

class InvoicePickerWidget extends StatefulWidget {
  final String? selectedInvoiceId;
  final Function(String?) onInvoiceSelected;

  const InvoicePickerWidget({
    Key? key,
    this.selectedInvoiceId,
    required this.onInvoiceSelected,
  }) : super(key: key);

  @override
  State<InvoicePickerWidget> createState() => _InvoicePickerWidgetState();
}

class _InvoicePickerWidgetState extends State<InvoicePickerWidget> {
  late InvoiceService _invoiceService;

  @override
  void initState() {
    super.initState();
    _invoiceService = Provider.of<InvoiceService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Link to Invoice',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(height: 8),
        StreamBuilder<List<InvoiceModel>>(
          stream: _invoiceService.watchOpenInvoices(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final invoices = snapshot.data ?? [];

            return DropdownButton<String>(
              isExpanded: true,
              value: widget.selectedInvoiceId,
              hint: Text('Select an invoice...'),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('None'),
                ),
                ...invoices.map(
                  (inv) => DropdownMenuItem(
                    value: inv.id,
                    child: Text(
                      '${inv.invoiceNumber} - ${inv.clientName} (${inv.currency} ${inv.total.toStringAsFixed(2)})',
                    ),
                  ),
                ),
              ],
              onChanged: widget.onInvoiceSelected,
            );
          },
        ),
      ],
    );
  }
}
```

### Linked Expenses Display (For Invoice Detail)

```dart
// Add to invoice detail screen

class LinkedExpensesWidget extends StatelessWidget {
  final String invoiceId;

  const LinkedExpensesWidget({Key? key, required this.invoiceId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final invoiceService = Provider.of<InvoiceService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linked Expenses',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 12),
        StreamBuilder<List<ExpenseModel>>(
          stream: invoiceService.watchLinkedExpenses(invoiceId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final expenses = snapshot.data ?? [];

            if (expenses.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Text('No expenses linked'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return ListTile(
                  title: Text(expense.merchant),
                  subtitle: Text(
                    '${expense.category} • ${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Text('Unlink'),
                        onTap: () {
                          invoiceService.unlinkExpenseFromInvoice(
                            invoiceId,
                            expense.id,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
```

---

## Firestore Security Rules

### Add to firestore.rules:

```firestore
// Invoice access control
match /invoices/{invoiceId} {
  allow read: if request.auth.uid == get(/databases/$(database)/documents/users/$(request.auth.uid)/invoices/$(invoiceId)).data.userId;
  allow create: if request.auth.uid == request.resource.data.userId;
  allow update: if request.auth.uid == resource.data.userId;
  allow delete: if request.auth.uid == resource.data.userId;
  
  // Audit entries
  match /audit/{auditId} {
    allow read: if request.auth.uid == get(/databases/$(database)/documents/users/$(request.auth.uid)/invoices/$(invoiceId)).data.userId;
    allow create: if request.auth.uid == get(/databases/$(database)/documents/users/$(request.auth.uid)/invoices/$(invoiceId)).data.userId;
  }
}

// Validation when linking expenses
function isValidInvoiceUpdate(newData) {
  return newData.linkedExpenseIds.size() <= 50 // Max 50 expenses per invoice
      && newData.status in ['draft', 'sent', 'paid', 'overdue', 'cancelled'];
}
```

---

## Workflow: Link Expense to Invoice

### Step 1: User Reviews Expense
In `ExpenseReviewScreen`:
```dart
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // ... existing fields (merchant, amount, etc.)
      
      // NEW: Invoice picker
      InvoicePickerWidget(
        selectedInvoiceId: _selectedInvoiceId,
        onInvoiceSelected: (invoiceId) {
          setState(() => _selectedInvoiceId = invoiceId);
        },
      ),
      
      // Save button
      ElevatedButton(
        onPressed: _saveExpense,
        child: Text('Save Expense'),
      ),
    ],
  );
}

Future<void> _saveExpense() async {
  final expense = ExpenseModel(
    // ... fields ...
    invoiceId: _selectedInvoiceId, // Include invoice ID
  );
  
  await _expenseService.createExpenseDraft(
    // ... params ...
    invoiceId: _selectedInvoiceId,
  );
  
  // Also link to invoice
  if (_selectedInvoiceId != null) {
    await _invoiceService.linkExpenseToInvoice(
      _selectedInvoiceId!,
      expense.id,
    );
  }
}
```

### Step 2: Manager Approves Expense
When expense is approved, invoice's `linkedExpenseIds` already contains it.

### Step 3: View Linked Expenses on Invoice
In invoice detail screen:
```dart
LinkedExpensesWidget(invoiceId: invoice.id)
```

---

## Cloud Function: Sync Invoice on Expense Change

**Optional enhancement**: Auto-update invoice when linked expense changes

```typescript
// functions/src/expenses/onExpenseStatusChange.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onExpenseStatusChange = functions.firestore
  .document('users/{userId}/expenses/{expenseId}')
  .onUpdate(async (change, context) => {
    const oldData = change.before.data();
    const newData = change.after.data();
    const { userId, expenseId } = context.params;

    // Only process if expense is linked to an invoice
    if (!newData.invoiceId) return;

    try {
      // Update invoice's linked expenses metadata
      const invoiceRef = admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .doc(newData.invoiceId);

      await invoiceRef.update({
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // If status changed to rejected or deleted, unlink from invoice
      if (newData.status === 'rejected' || newData.status === 'deleted') {
        await invoiceRef.update({
          linkedExpenseIds: admin.firestore.FieldValue.arrayRemove([expenseId]),
        });
      }

      console.log(`Updated invoice ${newData.invoiceId} for expense ${expenseId}`);
    } catch (error) {
      console.error(`Error updating invoice:`, error);
      throw error;
    }
  });
```

---

## Summary of Changes

### ✅ Already Implemented
- ExpenseModel with `invoiceId` field
- InvoiceModel with `linkedExpenseIds` field
- ExpenseService.linkToInvoice() method

### 🔲 To Implement
- InvoiceService (full service)
- InvoicePickerWidget (UI for selecting invoice)
- LinkedExpensesWidget (display linked expenses)
- Update Firestore rules for invoice access
- Cloud Function for sync (optional)
- Update pubspec.yaml with new dependencies (if needed)

### 📊 Benefits
- Complete financial audit trail
- Link expenses to client invoices
- Track which expenses are invoiced
- Prevent double-invoicing
- Real-time linked expense updates
- Expense reconciliation

---

## Next Steps

1. **Create InvoiceService** (if not existing)
2. **Add InvoicePickerWidget to ExpenseReviewScreen**
3. **Add LinkedExpensesWidget to invoice detail screen**
4. **Update Firestore rules** for invoice security
5. **Test linking workflow**: Scan → Link → Approve → View
6. **(Optional) Add Cloud Function** for sync

---

## Testing Checklist

- [ ] Create invoice with multiple items
- [ ] Open expense in review screen
- [ ] Dropdown shows available invoices
- [ ] Select invoice and save expense
- [ ] Invoice shows linked expense in detail
- [ ] Unlink expense from invoice
- [ ] Linked expense count updates
- [ ] Expense status change updates invoice
- [ ] Security rules prevent unauthorized access
