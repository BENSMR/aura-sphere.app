# Invoice Creation Guide

## Overview

The enhanced `InvoiceService` provides methods for creating and managing invoices with automatic client integration. When an invoice is created for a client, Cloud Functions automatically update client metrics like lifetime value, invoice count, and AI score.

## Service Usage

### Initialization

```dart
import 'package:aura_sphere_pro/services/invoice_service.dart';

final invoiceService = InvoiceService();
```

### With Provider

```dart
final invoiceService = Provider.of<YourProvider>(context).invoiceService;
```

## Creating Invoices

### Basic Invoice Creation

Create a simple invoice for a client:

```dart
final invoiceId = await invoiceService.createClientInvoice(
  clientId: 'client123',
  amountTotal: 250.50,
  dueDate: DateTime.now().add(Duration(days: 30)),
  status: 'draft',
  notes: 'Professional services rendered',
);

print('Invoice created: $invoiceId');
```

**Parameters**:
- `clientId` (required) - Client ID from clients collection
- `amountTotal` (required) - Total invoice amount (must be > 0)
- `dueDate` (optional) - When payment is due
- `status` (optional) - Default: 'draft'
- `notes` (optional) - Additional notes
- `additionalData` (optional) - Extra fields (items, references, etc.)

**Valid Statuses**:
- `'draft'` - Not yet sent to client
- `'sent'` - Sent to client
- `'paid'` - Payment received
- `'overdue'` - Past due date without payment
- `'cancelled'` - Cancelled invoice
- `'refunded'` - Refund issued

### Invoice with Line Items

Create invoice from a list of items:

```dart
final items = [
  InvoiceItem(
    description: 'Web Development Services',
    quantity: 10,
    unitPrice: 75.00,
    discount: 10, // 10% discount
    tax: 19, // 19% VAT
  ),
  InvoiceItem(
    description: 'Hosting Setup',
    quantity: 1,
    unitPrice: 250.00,
  ),
];

final invoiceId = await invoiceService.createClientInvoiceWithItems(
  clientId: 'client123',
  items: items,
  dueDate: DateTime.now().add(Duration(days: 30)),
  notes: 'Invoice for Q1 2025 services',
);
```

**Calculation Example**:
- Item 1: 10 × €75 = €750
  - Discount: -€75 (10% of €750)
  - Tax: €128.25 (19% of €675)
  - Subtotal: €803.25
- Item 2: 1 × €250 = €250
  - Tax: €47.50 (19% of €250)
  - Subtotal: €297.50
- **Total: €1,100.75**

### Line Item Class

```dart
class InvoiceItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double? discount; // percentage (e.g., 10 = 10%)
  final double? tax; // percentage (e.g., 19 = 19%)

  // Calculated properties
  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * ((discount ?? 0) / 100);
  double get taxAmount => (subtotal - discountAmount) * ((tax ?? 0) / 100);
  double get total => subtotal - discountAmount + taxAmount;
}
```

## Managing Invoices

### Get Client Invoices

```dart
final invoices = await invoiceService.getClientInvoices('client123');
for (final invoice in invoices) {
  print('${invoice['id']}: €${invoice['amountTotal']} - ${invoice['status']}');
}
```

### Get Client Revenue (Paid Invoices Only)

```dart
final revenue = await invoiceService.getClientRevenue('client123');
print('Total paid: €${revenue.toStringAsFixed(2)}');
```

### Get Pending Amount

```dart
final pending = await invoiceService.getClientPendingAmount('client123');
print('Outstanding: €${pending.toStringAsFixed(2)}');
```

### Invoice Status Counts

```dart
final counts = await invoiceService.getClientInvoiceStatusCount('client123');
print('Draft: ${counts['draft']}, Sent: ${counts['sent']}, Paid: ${counts['paid']}');
```

## Invoice Lifecycle

### 1. Create (Draft)

```dart
final invoiceId = await invoiceService.createClientInvoice(
  clientId: 'client123',
  amountTotal: 500.00,
  status: 'draft', // Not yet sent
);
```

**What happens**:
- Invoice created in `users/{userId}/invoices/{invoiceId}`
- Cloud Function `onNestedInvoiceCreated` triggers
- Client's `totalInvoices` and `lastInvoiceAmount` updated
- Timeline event recorded: `invoice_created`

### 2. Send to Client

```dart
await invoiceService.markInvoiceAsDelivered(invoiceId);
// or manually update status
await invoiceService.markInvoiceAsSent(invoiceId);
```

**Firestore will update**:
- `status` → `'sent'`
- `sentAt` → current timestamp
- Client's `lastActivityAt` updated

### 3. Client Receives Payment

```dart
await invoiceService.markInvoicePaid(invoiceId, 'stripe');
// or
await invoiceService.markInvoiceAsPaid(invoiceId);
```

**Cloud Function `onInvoicePaid` triggers**:
- `status` → `'paid'`
- `paidAt` → current timestamp
- Client's `lifetimeValue` += amount
- Client's `aiScore` += 20 points
- Client's `churnRisk` -= 15 points
- Timeline event: `payment_received`

### 4. Overdue Tracking

```dart
// Manually mark overdue (or set up scheduled Cloud Function)
await invoiceService.updateInvoiceStatus(invoiceId, 'overdue');
```

**Cloud Function `onInvoiceOverdue` triggers**:
- Client's `churnRisk` increases (1-7 days: +10, 8-30: +25, 30+: +40)
- Timeline event: `invoice_overdue`

### 5. Cancellation/Refund

```dart
// Cancel invoice
await invoiceService.updateInvoiceStatus(invoiceId, 'cancelled');

// Refund (decreases lifetime value)
await invoiceService.updateInvoiceStatus(invoiceId, 'refunded');
```

**Cloud Functions handle**:
- Remove from client revenue
- Decrease AI score (penalty)
- Update VIP status if needed
- Record timeline event

## Complete Example: Invoice Creation Form

```dart
class CreateInvoiceScreen extends StatefulWidget {
  final String clientId;
  
  const CreateInvoiceScreen({required this.clientId});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _invoiceService = InvoiceService();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime? _dueDate;
  bool _isLoading = false;

  Future<void> _createInvoice() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter invoice amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      
      final invoiceId = await _invoiceService.createClientInvoice(
        clientId: widget.clientId,
        amountTotal: amount,
        dueDate: _dueDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        status: 'draft',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice $invoiceId created')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Amount (€)',
                      hintText: '0.00',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dueDate == null
                              ? 'No due date'
                              : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _dueDate = date);
                          }
                        },
                        child: const Text('Set Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Add any additional information...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _createInvoice,
                    child: const Text('Create Invoice'),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
```

## Error Handling

Always wrap invoice operations in try/catch:

```dart
try {
  final invoiceId = await invoiceService.createClientInvoice(
    clientId: clientId,
    amountTotal: amount,
    dueDate: dueDate,
  );
  print('Invoice created: $invoiceId');
} on ArgumentError catch (e) {
  // Handle validation errors
  print('Invalid input: ${e.message}');
} catch (e) {
  // Handle other errors
  print('Error: $e');
}
```

**Common Errors**:
- `'clientId cannot be empty'` - Provide valid client ID
- `'amountTotal must be greater than 0'` - Amount must be positive
- `'Invalid status: ...'` - Use valid status value
- `'User not logged in'` - Ensure user is authenticated

## Cloud Functions Integration

When you create an invoice, these Cloud Functions automatically trigger:

### `onNestedInvoiceCreated` (onCreate trigger)
- Updates client's `totalInvoices` (+1)
- Updates client's `lastInvoiceAmount`
- Updates client's `lastInvoiceDate`
- Updates client's `lastActivityAt`
- Adds timeline event

### `onInvoicePaid` (onUpdate trigger on status → 'paid')
- Updates client's `lifetimeValue` (+amount)
- Updates client's `lastPaymentDate`
- Boosts client's `aiScore` (+20)
- Reduces client's `churnRisk` (-15)
- Evaluates client's `vipStatus` (>€5000)
- Adds timeline event

### Other Triggers
- `onInvoiceOverdue` - When invoice becomes overdue
- `onInvoiceRefunded` - When refund is issued
- `onInvoiceEngagement` - When invoice is sent/viewed

## Best Practices

1. **Always validate client exists** before creating invoice
2. **Use appropriate status** - Don't create 'paid' invoices directly
3. **Set due dates** - Helps with churn risk calculation
4. **Handle errors gracefully** - Show user-friendly messages
5. **Show loading state** - Invoice creation triggers Cloud Functions (async)
6. **Batch operations** - Create multiple invoices with delays
7. **Cache client data** - Reduce reads after invoice creation

## Testing

```bash
# Test with Firebase Emulator
firebase emulators:start

# Run unit tests
flutter test
```

## Related Documentation

- [InvoiceService Source](../lib/services/invoice_service.dart)
- [Cloud Functions - Invoice Sync](../docs/CLOUD_FUNCTIONS_GUIDE.md)
- [Client Integration](../docs/CLIENTS_INTEGRATION_GUIDE.md)
- [Firestore Security Rules](../docs/FIRESTORE_SECURITY_RULES.md)
