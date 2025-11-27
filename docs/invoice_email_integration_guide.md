# Invoice Email Integration Guide

## Overview

The enhanced `InvoiceService` now includes comprehensive email and PDF functionality for professional invoice management:

- **PDF Generation**: Create professional invoices with InvoicePdfService
- **Email Sending**: Send invoices via Firebase Email Extension
- **Payment Reminders**: Automated follow-up emails for unpaid invoices
- **Audit Trail**: Track all invoice actions in Firestore

---

## Architecture

### Three-Layer Integration

```
┌─────────────────────────────────────────┐
│   UI Layer (Widgets)                    │
│   ├─ PrintInvoiceButton                 │
│   ├─ ShareInvoiceButton                 │
│   ├─ SendInvoiceEmailButton             │
│   └─ PaymentReminderButton              │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│   Service Layer (InvoiceService)        │
│   ├─ generatePdfBytes()                 │
│   ├─ savePdfToDevice()                  │
│   ├─ sendInvoiceByEmail()               │
│   └─ sendPaymentReminder()              │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│   Support Services                      │
│   ├─ InvoicePdfService (PDF gen)        │
│   ├─ InvoicePdfHandler (file ops)       │
│   ├─ EmailService (Cloud Functions)     │
│   └─ InvoiceRepository (Firestore)      │
└─────────────────────────────────────────┘
```

---

## API Reference

### PDF Methods

#### `generatePdfBytes(InvoiceModel invoice) → Future<Uint8List>`

Generate a professional PDF document as bytes.

**Parameters:**
- `invoice`: The InvoiceModel to convert to PDF

**Returns:** Uint8List (PDF file bytes)

**Throws:** Exception if PDF generation fails

**Example:**
```dart
final invoice = InvoiceModel(...);
final pdfBytes = await invoiceService.generatePdfBytes(invoice);

// Use bytes for printing, sharing, or uploading
```

---

#### `savePdfToDevice(InvoiceModel invoice) → Future<String>`

Save invoice PDF to device storage (Documents/invoices/).

**Parameters:**
- `invoice`: The InvoiceModel to save

**Returns:** String (success message with file path)

**Throws:** InvoicePdfException if file operations fail

**Example:**
```dart
final message = await invoiceService.savePdfToDevice(invoice);
// Returns: "Saved to Documents/invoices/INV-2024-001.pdf"
```

---

### Email Methods

#### `sendInvoiceByEmail(InvoiceModel invoice, {bool attachPdf = true, String? customMessage}) → Future<void>`

Send invoice to client via email with optional PDF.

**Parameters:**
- `invoice`: The InvoiceModel to send
- `attachPdf`: Include PDF file (default: true)
- `customMessage`: Custom HTML body (optional, uses default template if not provided)

**Behavior:**
- Generates professional HTML email from invoice data
- Includes itemized table with quantities and prices
- Shows subtotal, tax, and total amounts
- Auto-updates invoice status to 'sent'
- Logs email action in audit trail

**Returns:** Future<void>

**Throws:** Exception if email sending fails

**Example:**
```dart
final invoice = InvoiceModel(...);

// Simple usage with default template
await invoiceService.sendInvoiceByEmail(invoice);

// Without PDF attachment
await invoiceService.sendInvoiceByEmail(
  invoice,
  attachPdf: false,
);

// With custom message
await invoiceService.sendInvoiceByEmail(
  invoice,
  customMessage: '''
<html>
  <body>
    <p>Hello ${invoice.clientName},</p>
    <p>Your custom message here...</p>
  </body>
</html>
  ''',
);
```

---

#### `sendPaymentReminder(InvoiceModel invoice) → Future<void>`

Send payment reminder for unpaid invoice.

**Parameters:**
- `invoice`: The InvoiceModel to remind about

**Behavior:**
- Checks invoice is not already paid
- Sends friendly reminder with invoice details
- Shows amount due and due date
- Logs reminder action in audit trail

**Returns:** Future<void>

**Throws:** Exception if invoice is paid or email fails

**Example:**
```dart
final invoice = InvoiceModel(status: 'sent', ...);

await invoiceService.sendPaymentReminder(invoice);
// Sends: "Payment Reminder: Invoice INV-2024-001"
```

---

## Usage Examples

### Example 1: Send Invoice on Creation

```dart
class InvoiceDetailScreen extends StatefulWidget {
  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late InvoiceService _invoiceService;

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService();
  }

  Future<void> _sendInvoice(InvoiceModel invoice) async {
    try {
      await _invoiceService.sendInvoiceByEmail(invoice);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice sent to ${invoice.clientEmail}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice Details')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _sendInvoice(widget.invoice),
          child: Text('Send to ${widget.invoice.clientEmail}'),
        ),
      ),
    );
  }
}
```

---

### Example 2: Multi-Action Invoice Card

```dart
class InvoiceActionCard extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceActionCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final invoiceService = InvoiceService();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice ${invoice.invoiceNumber}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 12),
            Text(
              '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            // Status badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(invoice.status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                invoice.status.toUpperCase(),
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.email),
                  label: Text('Send'),
                  onPressed: () => _sendInvoice(invoiceService),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.notification_important),
                  label: Text('Remind'),
                  onPressed: invoice.status == 'paid'
                      ? null
                      : () => _sendReminder(invoiceService),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.download),
                  label: Text('Save PDF'),
                  onPressed: () => _savePdf(invoiceService),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvoice(InvoiceService service) async {
    try {
      await service.sendInvoiceByEmail(invoice);
      // Show success
    } catch (e) {
      // Show error
    }
  }

  Future<void> _sendReminder(InvoiceService service) async {
    try {
      await service.sendPaymentReminder(invoice);
      // Show success
    } catch (e) {
      // Show error
    }
  }

  Future<void> _savePdf(InvoiceService service) async {
    try {
      await service.savePdfToDevice(invoice);
      // Show success
    } catch (e) {
      // Show error
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft': return Colors.grey;
      case 'sent': return Colors.amber;
      case 'paid': return Colors.green;
      case 'overdue': return Colors.red;
      case 'cancelled': return Colors.purple;
      default: return Colors.blue;
    }
  }
}
```

---

### Example 3: Automated Reminder Flow

```dart
class InvoiceReminderScheduler {
  final InvoiceService _invoiceService;

  InvoiceReminderScheduler(this._invoiceService);

  /// Send reminders for invoices due in N days
  Future<void> sendRemindersForOverdueInvoices({int daysOverdue = 7}) async {
    try {
      final pendingInvoices = await _invoiceService.getPendingInvoices();

      for (final invoice in pendingInvoices) {
        if (invoice.dueDate != null) {
          final daysAgo = DateTime.now().difference(invoice.dueDate!).inDays;
          
          if (daysAgo >= daysOverdue && daysAgo % 7 == 0) {
            // Send reminder every 7 days after due date
            await _invoiceService.sendPaymentReminder(invoice);
            print('Reminder sent for ${invoice.invoiceNumber}');
          }
        }
      }
    } catch (e) {
      print('Error sending reminders: $e');
    }
  }
}
```

---

### Example 4: Provider Integration

```dart
class InvoiceDetailProvider extends ChangeNotifier {
  final InvoiceService _invoiceService;
  
  InvoiceModel? _selectedInvoice;
  bool _isSendingEmail = false;
  String? _sendError;

  InvoiceDetailProvider(this._invoiceService);

  InvoiceModel? get selectedInvoice => _selectedInvoice;
  bool get isSendingEmail => _isSendingEmail;
  String? get sendError => _sendError;

  Future<void> loadInvoice(String invoiceId) async {
    try {
      _selectedInvoice = await _invoiceService.getInvoice(invoiceId);
      notifyListeners();
    } catch (e) {
      _sendError = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendInvoiceEmail() async {
    if (_selectedInvoice == null) return;

    _isSendingEmail = true;
    _sendError = null;
    notifyListeners();

    try {
      await _invoiceService.sendInvoiceByEmail(_selectedInvoice!);
      _isSendingEmail = false;
      notifyListeners();
    } catch (e) {
      _sendError = e.toString();
      _isSendingEmail = false;
      notifyListeners();
    }
  }

  Future<void> sendPaymentReminder() async {
    if (_selectedInvoice == null) return;

    _isSendingEmail = true;
    _sendError = null;
    notifyListeners();

    try {
      await _invoiceService.sendPaymentReminder(_selectedInvoice!);
      _isSendingEmail = false;
      notifyListeners();
    } catch (e) {
      _sendError = e.toString();
      _isSendingEmail = false;
      notifyListeners();
    }
  }
}
```

---

## Email Templates

### Default Invoice Email

The `sendInvoiceByEmail()` method generates a professional HTML email with:

**Header:**
- Company branding (AURASPHERE PRO)
- Blue accent bar (#1e40af)

**Body:**
- Personalized greeting
- Invoice number, date, and due date
- Itemized table:
  - Description | Qty | Unit Price | Total
- Calculations:
  - Subtotal
  - Tax (with percentage)
  - **Total** (highlighted)

**Footer:**
- Thank you message
- Company name and contact email
- Professional signature

### Payment Reminder Email

The `sendPaymentReminder()` method generates:

**Header:**
- Subject: "Payment Reminder: Invoice [NUMBER]"

**Body:**
- Friendly reminder tone
- Invoice details in highlighted box
- Amount due and due date
- Professional closing

---

## Audit Trail

All email actions are logged in Firestore under:
```
users/{userId}/invoice_audit_log/
├─ action: "email_sent" | "reminder_sent"
├─ invoiceId: string
├─ to: email address
├─ timestamp: server timestamp
└─ details: {extra fields}
```

### Query Audit Log

```dart
final logs = await _db
    .collection('users')
    .doc(userId)
    .collection('invoice_audit_log')
    .where('action', isEqualTo: 'email_sent')
    .orderBy('timestamp', descending: true)
    .limit(50)
    .get();

for (final doc in logs.docs) {
  print('Email sent to ${doc['to']} at ${doc['timestamp']}');
}
```

---

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "User not authenticated" | No Firebase Auth session | Ensure user is logged in |
| "Failed to generate invoice PDF" | PDF service error | Check InvoicePdfService logs |
| "Failed to send invoice email" | EmailService/Cloud Function error | Check Cloud Function logs |
| "Cannot send reminder for already-paid invoice" | Status is 'paid' | Only call for unpaid invoices |

### Implementing Error Handling

```dart
Future<void> sendWithErrorHandling(InvoiceModel invoice) async {
  try {
    await invoiceService.sendInvoiceByEmail(invoice);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invoice sent successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  } on FirebaseException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Firebase error: ${e.message}'),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## Testing Checklist

- ✅ Generate PDF for invoice
- ✅ Save PDF to device
- ✅ Send invoice email to test address
- ✅ Verify invoice status updated to 'sent'
- ✅ Send payment reminder for unpaid invoice
- ✅ Verify audit log entries created
- ✅ Test with custom message parameter
- ✅ Test error handling with invalid email
- ✅ Verify email HTML renders correctly
- ✅ Check PDF attachment in email

---

## Integration Checklist

- [ ] Add InvoiceService to main.dart MultiProvider
- [ ] Import InvoiceService in detail screen
- [ ] Add "Send Invoice" button to invoice detail
- [ ] Add "Payment Reminder" button for unpaid invoices
- [ ] Create custom message input if needed
- [ ] Add email history/audit view
- [ ] Test with real Firebase project
- [ ] Set up Cloud Email Extension
- [ ] Configure sendEmail Cloud Function

---

## Related Files

- `/lib/services/invoice_service.dart` — Main service with email/PDF methods
- `/lib/services/pdf/invoice_pdf_service.dart` — PDF generation logic
- `/lib/services/pdf/invoice_pdf_handler.dart` — File operations
- `/lib/services/email_service.dart` — Firebase Cloud Function wrapper
- `/lib/data/models/invoice_model.dart` — Invoice data model
- `/lib/data/repositories/invoice_repository.dart` — Firestore access
- `/docs/invoice_pdf_generation_guide.md` — PDF system documentation

---

## Troubleshooting

### Email not sending?

1. **Check Cloud Function is deployed:**
   ```bash
   firebase functions:list
   ```
   Look for `sendTaskEmail` function

2. **Check Firebase config in web:**
   ```bash
   cat web/firebase-config.js
   ```
   Verify Cloud Functions region matches

3. **Check logs:**
   ```bash
   firebase functions:log
   ```
   Look for `sendTaskEmail` errors

4. **Test with EmailService directly:**
   ```dart
   await EmailService.sendEmail(
     to: 'test@example.com',
     subject: 'Test',
     message: 'Test message',
   );
   ```

### PDF generation failing?

1. **Check pdf package is installed:**
   ```bash
   flutter pub get
   ```

2. **Check InvoicePdfService initialization**

3. **Verify InvoiceModel fields are present:**
   - `invoiceNumber`
   - `clientName`, `clientEmail`
   - `items` (List<InvoiceItem>)
   - `subtotal`, `tax`, `total`

---

## Security Considerations

✅ **User Authentication:**
- All methods require Firebase Auth
- `currentUserId` validates authenticated session

✅ **Firestore Rules:**
- Audit logs written with `userId` field
- Follow user-scoped query pattern

✅ **Email Validation:**
- Only sends to `invoice.clientEmail` (set during creation)
- Prevents email spoofing via UI

✅ **File Storage:**
- PDFs saved to user-specific device folder
- No cloud storage of sensitive PDFs (optional)

---

## Next Steps

1. **Add UI:** Create invoice detail screen with send button
2. **Notifications:** Add push notification when email sent
3. **Scheduling:** Create Cloud Task to send reminders automatically
4. **Analytics:** Track email opens via SendGrid webhooks (if using SendGrid)
5. **Templates:** Allow custom email templates per user

