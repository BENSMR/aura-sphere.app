# Email Service Flutter Integration

## Quick Start

### 1. Add Cloud Functions Dependency

Verify `cloud_functions` is in your pubspec.yaml:

```yaml
dependencies:
  cloud_functions: ^4.1.0
  flutter: sdk: flutter
```

Run `flutter pub get` to install.

### 2. Create Email Service in Flutter

Create `lib/services/email_service.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';

class EmailService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Send invoice to client via email
  static Future<Map<String, dynamic>> sendInvoiceEmail(String invoiceId) async {
    try {
      final result = await _functions
          .httpsCallable('sendInvoiceEmail')
          .call({'invoiceId': invoiceId});

      return {
        'success': true,
        'message': result.data['message'] ?? 'Email sent successfully',
        'sentAt': result.data['sentAt'],
      };
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Unknown error',
        'code': e.code,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send payment confirmation to client
  static Future<Map<String, dynamic>> sendPaymentConfirmation({
    required String invoiceId,
    required double paidAmount,
    DateTime? paymentDate,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('sendPaymentConfirmation')
          .call({
        'invoiceId': invoiceId,
        'paidAmount': paidAmount,
        'paymentDate': (paymentDate ?? DateTime.now()).toIso8601String(),
      });

      return {
        'success': true,
        'message': result.data['message'] ?? 'Confirmation sent',
      };
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Unknown error',
        'code': e.code,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send multiple invoices to different clients
  static Future<Map<String, dynamic>> sendBulkInvoices(
    List<String> invoiceIds,
  ) async {
    try {
      if (invoiceIds.isEmpty || invoiceIds.length > 50) {
        throw Exception('Must provide 1-50 invoice IDs');
      }

      final result = await _functions
          .httpsCallable('sendBulkInvoices')
          .call({'invoiceIds': invoiceIds});

      return {
        'success': result.data['success'],
        'sent': result.data['sent'] ?? 0,
        'failed': result.data['failed'] ?? 0,
        'errors': result.data['errors'],
      };
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Unknown error',
        'code': e.code,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
```

### 3. Add "Send Email" Button to Invoice Preview

Update `lib/screens/invoices/invoice_preview_screen.dart`:

```dart
import 'package:aura_sphere_pro/services/email_service.dart';

class InvoicePreviewScreen extends StatefulWidget {
  // ... existing code ...

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  bool _isSendingEmail = false;

  Future<void> _sendEmailToClient() async {
    setState(() => _isSendingEmail = true);

    try {
      final result = await EmailService.sendInvoiceEmail(widget.invoiceId);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSendingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice Preview'),
        actions: [
          // Send Email Button
          IconButton(
            icon: _isSendingEmail
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mail),
            onPressed: _isSendingEmail ? null : _sendEmailToClient,
            tooltip: 'Send via Email',
          ),
          // Existing buttons...
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) => _buildInvoicePdf(),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4. Add "Send Payment Confirmation" After Payment

Update your payment completion handler:

```dart
Future<void> _onPaymentSuccess(PaymentResult payment) async {
  // Update invoice status to "Paid"
  await FirebaseFirestore.instance
      .collection('invoices')
      .doc(invoice.id)
      .update({
        'status': 'Paid',
        'paidAt': Timestamp.now(),
        'paidAmount': payment.amount,
      });

  // Send confirmation email
  final result = await EmailService.sendPaymentConfirmation(
    invoiceId: invoice.id,
    paidAmount: payment.amount,
    paymentDate: DateTime.now(),
  );

  if (result['success']) {
    print('Payment confirmation sent to client');
  } else {
    print('Failed to send confirmation: ${result['error']}');
    // Still show success to user, but log the email failure
  }

  // Show success dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Payment Received'),
      content: const Text('Invoice marked as paid.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
```

### 5. Add Bulk Send Screen (Optional)

Create `lib/screens/invoices/bulk_email_screen.dart`:

```dart
import 'package:aura_sphere_pro/services/email_service.dart';

class BulkEmailScreen extends StatefulWidget {
  final List<String> invoiceIds;

  const BulkEmailScreen({required this.invoiceIds});

  @override
  State<BulkEmailScreen> createState() => _BulkEmailScreenState();
}

class _BulkEmailScreenState extends State<BulkEmailScreen> {
  bool _isSending = false;
  Map<String, dynamic>? _result;

  Future<void> _sendBulk() async {
    setState(() => _isSending = true);

    try {
      final result = await EmailService.sendBulkInvoices(widget.invoiceIds);
      setState(() => _result = result);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sent ${result['sent']} invoices${result['failed'] > 0 ? ', ${result['failed']} failed' : ''}',
            ),
            backgroundColor: result['failed'] == 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Invoices by Email')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ready to send ${widget.invoiceIds.length} invoices?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSending ? null : _sendBulk,
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send All'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result!['success'] ? 'Success ✓' : 'Errors Found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              _result!['success'] ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Sent: ${_result!['sent']}'),
                      Text('Failed: ${_result!['failed']}'),
                      if (_result!['errors'] != null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Errors:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ..._result!['errors'].map<Widget>(
                          (error) => Text('• $error'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 6. Add to Invoice List with Bulk Actions

Update your invoice list to support multiple selection:

```dart
class InvoiceListScreen extends StatefulWidget {
  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final Set<String> _selectedInvoices = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedInvoices.isEmpty
            ? 'Invoices'
            : '${_selectedInvoices.length} selected'),
        actions: [
          if (_selectedInvoices.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.mail),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BulkEmailScreen(
                          invoiceIds: _selectedInvoices.toList(),
                        ),
                  ),
                );
              },
              tooltip: 'Send by Email',
            ),
        ],
      ),
      body: // Your invoice list with checkbox selection
    );
  }
}
```

## Testing

### Test Locally with Firebase Emulator

```bash
# Start emulator
cd /workspaces/aura-sphere-pro
firebase emulators:start

# Run Flutter in another terminal
flutter run
```

### Manual Cloud Function Test

```bash
# Get your Firebase project URL
firebase deploy --only functions

# Test the function (replace YOUR_PROJECT_ID and YOUR_FUNCTION_URL)
curl -X POST https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/sendInvoiceEmail \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"invoiceId":"test-invoice-id"}}'
```

## Error Handling

All functions return a map with `success` boolean. Handle accordingly:

```dart
if (result['success']) {
  // Email sent successfully
  print(result['message']);
} else {
  // Error occurred
  print('Error Code: ${result['code']}');
  print('Error Message: ${result['error']}');

  // Show to user
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Email Error'),
      content: Text(result['error']),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ),
  );
}
```

## Production Checklist

- [ ] Set production email credentials (`.env.production`)
- [ ] Deploy functions: `firebase deploy --only functions`
- [ ] Test with real invoices
- [ ] Verify emails appear in client inboxes (check spam)
- [ ] Monitor function logs: `firebase functions:log`
- [ ] Set up error alerts in Firebase Console
- [ ] Document support process for email issues

## Documentation

- [Firebase Cloud Functions for Flutter](https://firebase.google.com/docs/functions/callable)
- [Cloud Functions Pricing](https://firebase.google.com/pricing#cloud-functions)
- [Email Best Practices](https://postmarkapp.com/guides/email-best-practices)

