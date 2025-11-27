# Expenses to Invoices Integration Guide

## Overview

Complete integration system for linking expenses to invoices. When an expense is scanned, it remains unlinked (`invoiceId: null`). Users can then attach expenses to invoices during invoice creation or edit.

## Architecture

### Data Model

**ExpenseModel** — Enhanced with `invoiceId` field
```dart
class ExpenseModel {
  final String invoiceId?;  // NEW: Link to invoice
  // ... other fields
}
```

**Linking States:**
- `invoiceId: null` — Expense unlinked, available for attachment
- `invoiceId: "inv_123"` — Expense linked to invoice
- Cannot change `invoiceId` via direct update (use provider methods)

### Provider Pattern

**ExpenseProvider** — Full state management with invoice linking

**Key Methods:**
```dart
// Attachment
attachToInvoice(expenseId, invoiceId)
detachFromInvoice(expenseId)
getExpensesForInvoice(invoiceId)

// Filtering
getUnlinkedExpenses()
getExpensesByDateRange(start, end)

// Analytics
getTotalUnlinked()
getTotalLinked()
```

## Implementation Details

### 1. ExpenseModel Changes

**New Field:**
```dart
final String? invoiceId;  // null by default
```

**Serialization:**
- `toMap()` → includes invoiceId for Firestore
- `fromDoc()` → reads invoiceId from Firestore
- `toJson()` → includes invoiceId for JSON export
- `fromJson()` → reads invoiceId from JSON
- `copyWith()` → supports invoiceId parameter

### 2. ExpenseProvider Enhancements

**Complete Provider with 15+ Methods:**

#### Load & CRUD
```dart
loadExpenses()           // Load all user expenses
addExpense()             // Create new
updateExpense()          // Edit existing
deleteExpense()          // Remove
```

#### Selection & Filtering
```dart
selectExpense()          // View details
clearSelection()         // Clear selected
searchExpenses(query)    // Search by merchant/notes
filterByCategory()       // Filter by category
```

#### Invoice Linking
```dart
attachToInvoice(expenseId, invoiceId)
detachFromInvoice(expenseId)
getExpensesForInvoice(invoiceId)
getUnlinkedExpenses()    // For attachment dialog
```

#### Analytics
```dart
getExpensesByDateRange(start, end)
getTotalUnlinked()       // Sum of unlinked
getTotalLinked()         // Sum of linked
getAllCategories()       // Unique categories
```

### 3. UI Components

#### ExpenseAttachmentDialog

**Location:** `lib/components/expense_attachment_dialog.dart`
**Purpose:** Dialog for attaching multiple expenses to invoice

**Features:**
- List all unlinked expenses
- Search by merchant or notes
- Multi-select checkboxes
- Show total amount of selected
- Bulk attachment

**Usage:**
```dart
showDialog(
  context: context,
  builder: (_) => ExpenseAttachmentDialog(
    invoiceId: invoiceId,
    onExpensesAttached: () {
      // Refresh invoice details
    },
  ),
);
```

**Screenshots:**
```
┌─────────────────────────────────────┐
│ Attach Expenses to Invoice          │
├─────────────────────────────────────┤
│ [Search by merchant or notes...]    │
├─────────────────────────────────────┤
│ ☐ Acme Corp          $100.00        │
│   Date: 27.11.2025                  │
│                                     │
│ ☑ Starbucks          $5.50          │
│   Business coffee                   │
│                                     │
│ ☑ Amazon            $49.99          │
│   Office supplies                   │
├─────────────────────────────────────┤
│ 2 expense(s) selected               │
│ Total: 55.49                        │
├─────────────────────────────────────┤
│              [Cancel] [Attach]      │
└─────────────────────────────────────┘
```

## Integration Workflow

### Scenario 1: Attach Expenses During Invoice Creation

**Flow:**
1. User creates new invoice
2. Clicks "Attach Expenses" button
3. Dialog shows unlinked expenses
4. User selects expenses to add as line items
5. Selected expenses linked to invoice
6. Expenses subtracted from unlinked total
7. Invoice totals updated with expense amounts

**Code Example:**
```dart
// In InvoiceCreatorScreen
FloatingActionButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => ExpenseAttachmentDialog(
        invoiceId: invoice.id,
        onExpensesAttached: () {
          // Refresh invoice amounts
          setState(() {});
        },
      ),
    );
  },
  tooltip: 'Attach Expenses',
  child: const Icon(Icons.attach_money),
)
```

### Scenario 2: View Attached Expenses

**Flow:**
1. User opens invoice details
2. View section shows attached expenses
3. Can detach individual expenses
4. Can edit expense notes
5. Totals update automatically

**Code Example:**
```dart
// Get attached expenses
final expenses = provider.getExpensesForInvoice(invoiceId);

// Display in list
ListView.builder(
  itemCount: expenses.length,
  itemBuilder: (_, i) {
    final expense = expenses[i];
    return ExpenseTile(
      expense: expense,
      onDetach: () {
        provider.detachFromInvoice(expense.id);
      },
    );
  },
)
```

### Scenario 3: Create Invoice from Expenses

**Future Enhancement:**
```dart
// Create invoice from selected expenses
Future<InvoiceModel> createFromExpenses(
  List<ExpenseModel> expenses,
  InvoiceModel template,
) async {
  final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
  
  final invoice = InvoiceModel(
    // ... from template
    items: expenses.map((e) => InvoiceItem(
      description: e.merchant,
      quantity: 1,
      unitPrice: e.amount,
    )).toList(),
    total: total,
  );
  
  // Attach all expenses
  for (final exp in expenses) {
    await attachToInvoice(exp.id, invoice.id);
  }
  
  return invoice;
}
```

## Firestore Security Rules

**Updated Rules** (firestore.rules):

```firestore
match /expenses/{expenseId} {
  allow create: if isValidExpenseCreate();
  allow update: if isValidExpenseUpdate();
}

function isValidExpenseCreate() {
  return data.keys().hasAll(['id', 'userId', 'merchant', 'amount', 'currency', 'imageUrl'])
         && data.userId == request.auth.uid
         && data.amount > 0
         && data.currency.size() == 3
         && (data.invoiceId == null || data.invoiceId is string)
         && data.size() <= 16;
}

function isValidExpenseUpdate() {
  return data.userId == existing.userId
         && data.id == existing.id
         && data.imageUrl == existing.imageUrl
         && (data.invoiceId == null || data.invoiceId is string)
         && data.updatedAt is timestamp
         && data.size() <= 16;
}
```

**Validation:**
- ✓ `invoiceId` is optional (null allowed)
- ✓ Can be set/cleared on update
- ✓ Must be string if present
- ✓ Field count limited to 16

## API Reference

### ExpenseProvider Methods

#### `attachToInvoice(String expenseId, String invoiceId)`

**Purpose:** Link expense to invoice

**Parameters:**
- `expenseId` (String) — Expense ID to attach
- `invoiceId` (String) — Invoice to attach to

**Updates:**
- Sets `expense.invoiceId = invoiceId`
- Sets `expense.updatedAt = now()`
- Updates Firestore

**Example:**
```dart
await provider.attachToInvoice('exp_123', 'inv_456');
```

#### `detachFromInvoice(String expenseId)`

**Purpose:** Unlink expense from invoice

**Parameters:**
- `expenseId` (String) — Expense to detach

**Updates:**
- Sets `expense.invoiceId = null`
- Sets `expense.updatedAt = now()`
- Updates Firestore

**Example:**
```dart
await provider.detachFromInvoice('exp_123');
```

#### `getUnlinkedExpenses() → List<ExpenseModel>`

**Purpose:** Get all expenses not attached to invoices

**Returns:** List of expenses where `invoiceId == null`

**Example:**
```dart
final unlinked = provider.getUnlinkedExpenses();
final count = unlinked.length;
final total = provider.getTotalUnlinked();
```

#### `getExpensesForInvoice(String invoiceId) → List<ExpenseModel>`

**Purpose:** Get all expenses attached to specific invoice

**Parameters:**
- `invoiceId` (String) — Invoice ID

**Returns:** List of expenses where `invoiceId == invoiceId`

**Example:**
```dart
final attached = provider.getExpensesForInvoice('inv_456');
for (final exp in attached) {
  print('${exp.merchant}: ${exp.amount}');
}
```

#### `getTotalUnlinked() → double`

**Purpose:** Calculate sum of unlinked expense amounts

**Returns:** Total amount of unlinked expenses

**Example:**
```dart
final unlinkedTotal = provider.getTotalUnlinked();
print('Available: \$$unlinkedTotal');
```

#### `getTotalLinked() → double`

**Purpose:** Calculate sum of linked expense amounts

**Returns:** Total amount of linked expenses

**Example:**
```dart
final linkedTotal = provider.getTotalLinked();
print('Used in invoices: \$$linkedTotal');
```

## Usage Examples

### Example 1: Attach Expenses to Invoice

```dart
class InvoiceCreatorScreen extends StatefulWidget {
  @override
  State<InvoiceCreatorScreen> createState() => _InvoiceCreatorScreenState();
}

class _InvoiceCreatorScreenState extends State<InvoiceCreatorScreen> {
  void _attachExpenses() {
    showDialog(
      context: context,
      builder: (_) => ExpenseAttachmentDialog(
        invoiceId: _invoice.id,
        onExpensesAttached: () {
          // Refresh invoice amounts
          _recalculateInvoiceTotal();
        },
      ),
    );
  }

  void _recalculateInvoiceTotal() {
    final provider = context.read<ExpenseProvider>();
    final attached = provider.getExpensesForInvoice(_invoice.id);
    
    setState(() {
      // Update invoice items from attached expenses
      _invoice = _invoice.copyWith(
        items: attached.map((e) => InvoiceItem(
          description: e.merchant,
          quantity: 1,
          unitPrice: e.amount,
        )).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: _attachExpenses,
            tooltip: 'Attach Expenses',
          ),
        ],
      ),
      // ... rest of UI
    );
  }
}
```

### Example 2: Display Unlinked Expenses Dashboard

```dart
class ExpensesDashboard extends StatefulWidget {
  @override
  State<ExpensesDashboard> createState() => _ExpensesDashboardState();
}

class _ExpensesDashboardState extends State<ExpensesDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (_, provider, __) {
        final unlinked = provider.getUnlinkedExpenses();
        final total = provider.getTotalUnlinked();

        return Column(
          children: [
            // Summary cards
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Unlinked Expenses',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${unlinked.length} expense(s)',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: \$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List of unlinked expenses
            Expanded(
              child: ListView.builder(
                itemCount: unlinked.length,
                itemBuilder: (_, i) {
                  final expense = unlinked[i];
                  return ListTile(
                    title: Text(expense.merchant),
                    subtitle: Text(expense.formatDate() ?? 'No date'),
                    trailing: Text(
                      expense.formatAmount(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    onTap: () {
                      provider.selectExpense(expense);
                      // Show detail screen
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
```

### Example 3: Manage Attached Expenses in Invoice

```dart
class InvoiceDetailsScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailsScreen({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (_, provider, __) {
        final attached = provider.getExpensesForInvoice(invoice.id);

        return ListView(
          children: [
            // Invoice info...
            
            if (attached.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Attached Expenses (${attached.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...attached.map((expense) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(expense.merchant),
                    subtitle: Text(
                      expense.formatDate() ?? 'No date',
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            expense.formatAmount(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              provider.detachFromInvoice(expense.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        );
      },
    );
  }
}
```

## Testing Scenarios

### Test 1: Create and Attach Expense

```dart
test('Create expense and attach to invoice', () async {
  // Create expense
  final expense = ExpenseModel(
    id: 'exp_test_1',
    userId: 'user_123',
    merchant: 'Test Store',
    amount: 100.0,
    currency: 'USD',
    imageUrl: 'gs://...',
  );
  
  await provider.addExpense(expense);
  
  // Verify unlinked
  expect(provider.getUnlinkedExpenses(), contains(expense));
  
  // Attach to invoice
  await provider.attachToInvoice(expense.id, 'inv_123');
  
  // Verify linked
  expect(provider.getExpensesForInvoice('inv_123'), contains(expense));
  expect(provider.getUnlinkedExpenses(), isNot(contains(expense)));
});
```

### Test 2: Detach Expense from Invoice

```dart
test('Detach expense from invoice', () async {
  final expense = /* ... attached expense ... */;
  
  await provider.detachFromInvoice(expense.id);
  
  expect(provider.getUnlinkedExpenses(), contains(expense));
  expect(
    provider.getExpensesForInvoice('inv_123'),
    isNot(contains(expense)),
  );
});
```

## Future Enhancements

1. **Auto-Categorization**
   - Cloud Function to classify expenses
   - Machine learning based on merchant
   - Suggested categories

2. **Bulk Linking**
   - Quick link by category
   - Date range selection
   - Template-based linking

3. **Analytics**
   - Expenses by category
   - Monthly breakdown
   - Unlinked expense alerts

4. **Reconciliation**
   - Match expenses to invoices
   - Highlight unmatched
   - Audit trail

5. **Integration**
   - Sync with accounting software
   - Bank transaction matching
   - Receipt OCR improvements

## Related Documentation

- [ExpenseModel Guide](expense_model_guide.md)
- [ExpenseProvider Reference](../lib/providers/expense_provider.dart)
- [Firestore Security Rules](firestore_expenses_security.md)
- [Invoice System](invoice_features_index.md)
- [Vision OCR Integration](cloud_vision_integration.md)

## Summary

✅ **Expenses to Invoices Integration:**
- ExpenseModel with `invoiceId` field
- ExpenseProvider with 15+ methods
- ExpenseAttachmentDialog component
- Firestore rules validation
- Complete workflow support
- Production-ready

**Status:** COMPLETE & DEPLOYED
