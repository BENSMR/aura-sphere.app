# 🎯 Stripe Client Integration Guide

**Status:** Ready to Implement | **Date:** November 28, 2025

---

## Overview

This guide shows how to integrate Stripe payments into your Flutter screens using `StripeService`.

---

## Quick Integration (Copy-Paste Ready)

### 1. Add Payment Button to Invoice Screen

```dart
import 'package:aura_sphere_pro/services/payments/stripe_service.dart';
import 'package:aura_sphere_pro/models/invoice.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final String invoiceId;

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  Invoice? invoice;
  bool _isCreatingCheckout = false;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    // Load your invoice from Firestore
  }

  Future<void> _startPayment() async {
    if (invoice == null) return;

    setState(() => _isCreatingCheckout = true);

    try {
      final result = await StripeService.createCheckoutSession(
        invoiceId: invoice!.id,
        successUrl: 'https://yourapp.com/payment-success?session_id={CHECKOUT_SESSION_ID}',
        cancelUrl: 'https://yourapp.com/payment-cancelled',
      );

      if (result['success'] == true && result['url'] != null) {
        // Open Stripe Checkout in browser
        await StripeService.openCheckoutUrl(result['url']);
        
        // Optional: Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Redirecting to payment...')),
          );
        }
      } else {
        _showError('Failed to create checkout session');
      }
    } catch (e) {
      _showError('Payment error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isCreatingCheckout = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice Details')),
      body: invoice == null
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Invoice details...
                SizedBox(height: 20),
                if (invoice!.paymentStatus != 'paid')
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: _isCreatingCheckout ? null : _startPayment,
                      icon: _isCreatingCheckout
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Icon(Icons.payment),
                      label: Text(
                        _isCreatingCheckout
                            ? 'Creating Payment Link...'
                            : 'Pay with Stripe',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                else
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 12),
                        Text(
                          'Payment Received',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
```

---

## StripeService API Reference

### `createCheckoutSession()`

Creates a Stripe checkout session for an invoice.

**Parameters:**
```dart
String invoiceId,          // Required: Invoice document ID in Firestore
String successUrl,         // Optional: URL to redirect after payment
String cancelUrl,          // Optional: URL to redirect if cancelled
```

**Returns:**
```dart
Future<Map<String, dynamic>> {
  'success': bool,         // true if session created
  'url': String,           // Stripe Checkout URL (https://checkout.stripe.com/...)
  'sessionId': String,     // Session ID for tracking
}
```

**Example:**
```dart
try {
  final result = await StripeService.createCheckoutSession(
    invoiceId: 'inv_12345',
    successUrl: 'https://yourapp.com/success',
    cancelUrl: 'https://yourapp.com/cancel',
  );

  if (result['success'] == true) {
    print('Checkout URL: ${result['url']}');
    await StripeService.openCheckoutUrl(result['url']);
  }
} on FirebaseFunctionsException catch (e) {
  print('Error: ${e.message}');
}
```

---

### `openCheckoutUrl()`

Opens the Stripe Checkout URL in the device's default browser.

**Parameters:**
```dart
String url,  // Stripe Checkout URL from createCheckoutSession()
```

**Returns:**
```dart
Future<void>  // Completes when URL is opened (or throws if failed)
```

**Example:**
```dart
try {
  await StripeService.openCheckoutUrl('https://checkout.stripe.com/pay/cs_...');
} catch (e) {
  print('Could not open URL: $e');
}
```

---

## Error Handling

### Handle Different Error Types

```dart
Future<void> _startPayment() async {
  try {
    final result = await StripeService.createCheckoutSession(
      invoiceId: invoice!.id,
      successUrl: 'https://yourapp.com/success',
      cancelUrl: 'https://yourapp.com/cancel',
    );

    if (result['success'] == true) {
      await StripeService.openCheckoutUrl(result['url']);
    }
  } on FirebaseFunctionsException catch (e) {
    switch (e.code) {
      case 'unauthenticated':
        _showError('Please sign in to continue');
        break;
      case 'not-found':
        _showError('Invoice not found');
        break;
      case 'invalid-argument':
        _showError('Invalid invoice data');
        break;
      case 'internal':
        _showError('Payment service error. Please try again.');
        break;
      default:
        _showError('Error: ${e.message}');
    }
  } catch (e) {
    _showError('Unexpected error: ${e.toString()}');
  }
}
```

---

## Integration Patterns

### Pattern 1: Floating Action Button

```dart
FloatingActionButton(
  onPressed: invoice?.paymentStatus == 'paid' ? null : _startPayment,
  tooltip: 'Pay Invoice',
  child: Icon(Icons.payment),
  backgroundColor: Colors.blue,
)
```

### Pattern 2: Bottom Sheet Modal

```dart
void _showPaymentOptions() {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Pay with Stripe'),
            subtitle: Text('Credit/Debit Card'),
            onTap: () {
              Navigator.pop(context);
              _startPayment();
            },
          ),
          ListTile(
            leading: Icon(Icons.download),
            title: Text('Download Invoice'),
            subtitle: Text('PDF, CSV, or JSON'),
            onTap: () {
              Navigator.pop(context);
              // Show invoice download sheet
            },
          ),
        ],
      ),
    ),
  );
}
```

### Pattern 3: Inline Payment Card

```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Status',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 12),
        if (invoice!.paymentStatus == 'paid')
          _buildPaidStatus()
        else
          ElevatedButton.icon(
            onPressed: _isCreatingCheckout ? null : _startPayment,
            icon: Icon(Icons.payment),
            label: Text('Pay Now'),
          ),
      ],
    ),
  ),
)
```

---

## Payment Status Tracking

### Listen for Payment Status Changes

```dart
// In initState or build
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('invoices')
      .doc(invoiceId)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }

    final invoice = Invoice.fromFirestore(snapshot.data!);

    return Column(
      children: [
        if (invoice.paymentStatus == 'paid')
          Container(
            color: Colors.green.shade50,
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Received',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Paid on ${invoice.paidAt?.toLocal()}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _startPayment,
            icon: Icon(Icons.payment),
            label: Text('Complete Payment'),
          ),
      ],
    );
  },
)
```

---

## Success & Cancellation Handling

### Option 1: Browser Redirect (Recommended for Mobile)

```dart
// Use platform-specific success/cancel URLs
final String appDeepLink = 'aurasphereproapp://invoice/${invoice.id}';

final result = await StripeService.createCheckoutSession(
  invoiceId: invoice.id,
  successUrl: 'https://yourapp.com/payment-success?invoiceId=${invoice.id}',
  cancelUrl: 'https://yourapp.com/payment-cancelled?invoiceId=${invoice.id}',
);

await StripeService.openCheckoutUrl(result['url']);
```

### Option 2: Poll Firestore After Payment

```dart
Future<void> _startPaymentAndWaitForStatus() async {
  try {
    final result = await StripeService.createCheckoutSession(
      invoiceId: invoice!.id,
      successUrl: 'https://yourapp.com/success',
      cancelUrl: 'https://yourapp.com/cancel',
    );

    if (result['success'] == true) {
      // Store session ID for tracking
      final sessionId = result['sessionId'];
      
      // Open checkout
      await StripeService.openCheckoutUrl(result['url']);

      // Poll for payment status (every 2 seconds for 5 minutes)
      int attempts = 0;
      while (attempts < 150) {
        await Future.delayed(Duration(seconds: 2));

        final doc = await FirebaseFirestore.instance
            .collection('invoices')
            .doc(invoice!.id)
            .get();

        final paymentStatus = doc.get('paymentStatus');
        if (paymentStatus == 'paid') {
          _showSuccess('Payment received!');
          break;
        }

        attempts++;
      }
    }
  } catch (e) {
    _showError('Payment error: ${e.toString()}');
  }
}
```

---

## Testing

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_functions/cloud_functions.dart';

void main() {
  group('StripeService', () {
    test('createCheckoutSession returns valid response', () async {
      final result = await StripeService.createCheckoutSession(
        invoiceId: 'test_invoice_123',
        successUrl: 'https://test.com/success',
        cancelUrl: 'https://test.com/cancel',
      );

      expect(result['success'], true);
      expect(result['url'], isNotNull);
      expect(result['url'], startsWith('https://checkout.stripe.com'));
      expect(result['sessionId'], isNotNull);
    });

    test('openCheckoutUrl throws for invalid URL', () async {
      expect(
        () => StripeService.openCheckoutUrl('not-a-valid-url'),
        throwsException,
      );
    });
  });
}
```

### Integration Test Example

```dart
void main() {
  group('Invoice Payment Flow', () {
    testWidgets('User can initiate payment', (tester) async {
      await tester.pumpWidget(MyApp());
      
      // Navigate to invoice screen
      await tester.tap(find.byIcon(Icons.receipt));
      await tester.pumpAndSettle();

      // Create test invoice
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill invoice details
      await tester.enterText(find.byKey(Key('itemName')), 'Consulting');
      await tester.enterText(find.byKey(Key('itemPrice')), '100');
      await tester.tap(find.byText('Save'));
      await tester.pumpAndSettle();

      // Start payment
      await tester.tap(find.byText('Pay with Stripe'));
      await tester.pumpAndSettle();

      // Verify checkout URL opened
      expect(find.byText('Redirecting to payment...'), findsOneWidget);
    });
  });
}
```

---

## Common Issues & Solutions

### Issue: "User must be authenticated"
**Cause:** User not logged in
**Solution:**
```dart
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
  return;
}
```

### Issue: "Invalid-argument: invoiceId is required"
**Cause:** invoiceId not passed correctly
**Solution:**
```dart
// ❌ Wrong
await StripeService.createCheckoutSession(
  invoiceId: null,  // Missing!
);

// ✅ Correct
await StripeService.createCheckoutSession(
  invoiceId: invoice.id,
);
```

### Issue: "Could not open checkout url"
**Cause:** url_launcher not configured, or URL invalid
**Solution:**
```dart
// Add to pubspec.yaml
dependencies:
  url_launcher: ^6.0.0

// Add to iOS Info.plist
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>https</string>
</array>

// Add to Android AndroidManifest.xml
<uses-permission android:name="android.permission.INTERNET" />
```

---

## Production Checklist

- [ ] `StripeService` imported correctly
- [ ] Error handling implemented for all cases
- [ ] Loading states shown during payment
- [ ] Success/error messages displayed to user
- [ ] Firestore rules allow reading invoices
- [ ] Cloud Functions deployed
- [ ] Stripe API keys configured in Firebase
- [ ] Webhook endpoint configured
- [ ] Payment testing completed with test cards
- [ ] Production Stripe keys in place (when ready)

---

*Last Updated: November 28, 2025*  
*Status: ✅ Ready to Integrate*
