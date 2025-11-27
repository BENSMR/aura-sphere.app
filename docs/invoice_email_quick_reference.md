# Invoice Email Integration - Quick Reference

## 📦 What's Included

### Enhanced InvoiceService
**File:** `/lib/services/invoice_service.dart`

**New Methods:**
```dart
// PDF Generation
Future<Uint8List> generatePdfBytes(InvoiceModel invoice)
Future<String> savePdfToDevice(InvoiceModel invoice)

// Email Sending
Future<void> sendInvoiceByEmail(InvoiceModel invoice, {
  bool attachPdf = true,
  String? customMessage,
})
Future<void> sendPaymentReminder(InvoiceModel invoice)
```

**Key Features:**
- ✅ Generates professional HTML emails with invoice details
- ✅ Auto-updates invoice status to 'sent'
- ✅ Logs all email actions in Firestore audit trail
- ✅ Integrates with InvoicePdfService for PDF generation
- ✅ Uses EmailService to send via Firebase Cloud Function
- ✅ Comprehensive error handling

### UI Widgets
**File:** `/lib/services/invoice_email_widgets.dart`

**4 Ready-to-Use Widgets:**
1. **SendInvoiceEmailButton** - Send invoice with loading state
2. **PaymentReminderButton** - Send payment reminder (disabled if paid)
3. **InvoiceActionMenu** - Dropdown menu with all actions
4. **InvoiceDetailCardWithEmail** - Complete invoice card with buttons

---

## 🚀 Quick Start

### 1. Import the Service
```dart
import 'package:flutter/material.dart';
import '../../services/invoice_service.dart';
```

### 2. Create Instance
```dart
final invoiceService = InvoiceService();
```

### 3. Send Invoice Email
```dart
try {
  await invoiceService.sendInvoiceByEmail(invoice);
  print('Invoice sent!');
} catch (e) {
  print('Error: $e');
}
```

### 4. Send Payment Reminder
```dart
try {
  await invoiceService.sendPaymentReminder(invoice);
  print('Reminder sent!');
} catch (e) {
  print('Error: $e');
}
```

### 5. Use Widget in UI
```dart
// Simple button
SendInvoiceEmailButton(invoice: invoice)

// Complete card
InvoiceDetailCardWithEmail(invoice: invoice)

// Menu with all actions
InvoiceActionMenu(invoice: invoice)
```

---

## 📧 Email Output

### Invoice Email Template
**Format:** Professional HTML

**Includes:**
- Company branding (AURASPHERE PRO)
- Invoice number, date, due date
- Itemized table (description, qty, price, total)
- Calculations (subtotal, tax, total)
- Thank you message

**Recipient:** `invoice.clientEmail`

**Subject:** `Invoice {number} - {currency} {total}`

### Payment Reminder Template
**Format:** Professional HTML

**Includes:**
- Friendly reminder tone
- Invoice details in highlighted box
- Amount due and due date
- Professional closing

**Recipient:** `invoice.clientEmail`

**Subject:** `Payment Reminder: Invoice {number}`

---

## 🔄 Integration Flow

```
┌─────────────────────────────────────┐
│   UI Layer                          │
│   ├─ SendInvoiceEmailButton         │
│   ├─ PaymentReminderButton          │
│   ├─ InvoiceActionMenu              │
│   └─ InvoiceDetailCardWithEmail     │
└────────────┬────────────────────────┘
             │ calls
┌────────────▼────────────────────────┐
│   InvoiceService (Enhanced)         │
│   ├─ generatePdfBytes()             │
│   ├─ savePdfToDevice()              │
│   ├─ sendInvoiceByEmail()           │
│   └─ sendPaymentReminder()          │
└────────────┬────────────────────────┘
             │ uses
┌────────────▼────────────────────────┐
│   Support Services                  │
│   ├─ InvoicePdfService (PDF)        │
│   ├─ EmailService (Cloud Function)  │
│   └─ InvoiceRepository (Firestore)  │
└─────────────────────────────────────┘
```

---

## 📋 Method Signatures

### `generatePdfBytes()`
```dart
Future<Uint8List> generatePdfBytes(InvoiceModel invoice)
```
- **Returns:** PDF file as bytes
- **Throws:** Exception
- **Use:** For printing, sharing, uploading

### `savePdfToDevice()`
```dart
Future<String> savePdfToDevice(InvoiceModel invoice)
```
- **Returns:** Success message with file path
- **Throws:** InvoicePdfException
- **Use:** Save PDF to Documents/invoices/

### `sendInvoiceByEmail()`
```dart
Future<void> sendInvoiceByEmail(
  InvoiceModel invoice, {
  bool attachPdf = true,
  String? customMessage,
})
```
- **Parameters:**
  - `invoice`: Invoice to send
  - `attachPdf`: Include PDF (default: true)
  - `customMessage`: Custom HTML body (optional)
- **Behavior:** Sends email, updates status to 'sent', logs action
- **Throws:** Exception

### `sendPaymentReminder()`
```dart
Future<void> sendPaymentReminder(InvoiceModel invoice)
```
- **Parameters:** `invoice` (must not be 'paid')
- **Behavior:** Sends reminder, logs action
- **Throws:** Exception

---

## 🎯 Common Usage Patterns

### Pattern 1: Simple Send
```dart
ElevatedButton(
  onPressed: () async {
    try {
      await invoiceService.sendInvoiceByEmail(invoice);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
  child: Text('Send Invoice'),
)
```

### Pattern 2: With Provider
```dart
Consumer<InvoiceProvider>(
  builder: (context, provider, _) {
    return SendInvoiceEmailButton(
      invoice: provider.selectedInvoice!,
      onSuccess: () => provider.loadInvoice(invoiceId),
      onError: (err) => print('Error: $err'),
    );
  },
)
```

### Pattern 3: Complete Card
```dart
InvoiceDetailCardWithEmail(invoice: invoice)
```

---

## 📊 State Management Example

```dart
class InvoiceEmailProvider extends ChangeNotifier {
  bool _isSending = false;
  String? _error;

  bool get isSending => _isSending;
  String? get error => _error;

  Future<void> sendInvoice(InvoiceService service, InvoiceModel invoice) async {
    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      await service.sendInvoiceByEmail(invoice);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
```

---

## 🔐 Security Features

✅ **Authentication:** All methods require Firebase Auth  
✅ **User-Scoped:** Only sends to current user's invoices  
✅ **Audit Trail:** All emails logged in Firestore  
✅ **Error Isolation:** Email failure doesn't crash app  
✅ **Validation:** Status checks before sending reminders  

---

## 🧪 Testing Checklist

- [ ] Generate PDF bytes successfully
- [ ] Save PDF to device storage
- [ ] Send invoice email to test address
- [ ] Verify invoice status updated to 'sent'
- [ ] Verify email received with invoice details
- [ ] Send payment reminder for unpaid invoice
- [ ] Verify reminder not sent for paid invoices
- [ ] Check audit log entries created
- [ ] Test custom message parameter
- [ ] Test error handling with invalid email
- [ ] Verify email HTML renders correctly in email client
- [ ] Check PDF attachment appears in email (if enabled)
- [ ] Test with multiple invoices simultaneously
- [ ] Verify loading states work correctly
- [ ] Test error messages appear to user

---

## 🐛 Troubleshooting

### Email Not Sending?

1. **Check Cloud Function deployed:**
   ```bash
   firebase functions:list
   ```

2. **Check Firebase config:**
   ```bash
   firebase functions:config:get
   ```

3. **Check logs:**
   ```bash
   firebase functions:log
   ```

### PDF Not Generating?

1. **Verify pdf package:**
   ```bash
   flutter pub get
   ```

2. **Check InvoiceModel fields are complete:**
   - `invoiceNumber`
   - `clientName`, `clientEmail`
   - `items` (List<InvoiceItem>)
   - `subtotal`, `tax`, `total`

### Widget Not Showing?

1. **Check imports are correct**
2. **Verify InvoiceModel is valid**
3. **Check Flutter hot reload/restart**

---

## 📚 Related Documentation

- 📖 **Full Guide:** `/docs/invoice_email_integration_guide.md`
- 📖 **PDF Guide:** `/docs/invoice_pdf_generation_guide.md`
- 🔧 **Service Code:** `/lib/services/invoice_service.dart`
- 🎨 **Widgets:** `/lib/services/invoice_email_widgets.dart`
- 📊 **Models:** `/lib/data/models/invoice_model.dart`

---

## ✨ Key Improvements Over Original

| Feature | Original | Enhanced |
|---------|----------|----------|
| Email Template | Plain text | Professional HTML |
| Status Update | Manual | Automatic |
| Audit Trail | None | Full logging |
| Error Handling | Basic | Comprehensive |
| UI Components | None | 4 ready widgets |
| PDF Integration | Basic | Full integration |
| Payment Reminders | Not available | Full support |
| Type Safety | Partial | Full typing |

---

## 🚀 Next Steps

1. **Integrate InvoiceService into main.dart**
2. **Add InvoiceProvider to MultiProvider**
3. **Create invoice detail screen with action buttons**
4. **Add email history view to dashboard**
5. **Implement scheduled reminders (Cloud Tasks)**
6. **Add email templates configuration**
7. **Track email opens/clicks (SendGrid webhooks)**

---

## 📝 Code Generation Example

```dart
// Create invoice with service
final invoice = await invoiceService.createInvoice(
  clientId: 'client_123',
  clientName: 'Acme Corp',
  clientEmail: 'contact@acme.com',
  items: [
    InvoiceItem(
      description: 'Web Development',
      quantity: 40,
      unitPrice: 150,
    ),
  ],
  currency: 'USD',
  taxRate: 0.20,
);

// Generate and save PDF
final pdfBytes = await invoiceService.generatePdfBytes(invoice);
await invoiceService.savePdfToDevice(invoice);

// Send via email
await invoiceService.sendInvoiceByEmail(invoice);

// Later: Send payment reminder
await invoiceService.sendPaymentReminder(invoice);
```

---

## 💡 Pro Tips

1. **Custom Messages:** Override default template with `customMessage` parameter
2. **Testing:** Use test email addresses from Firebase test environment
3. **Audit Trail:** Query `invoice_audit_log` for email history
4. **Error Context:** Always catch and display errors to user
5. **Loading States:** Use `isSending` flag in providers for UI feedback
6. **Batching:** Send multiple reminder emails via scheduled Cloud Function

---

