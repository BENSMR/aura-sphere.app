# 🧪 Stripe Payment Integration - Test Flow Guide

**Status:** ✅ READY TO TEST | **Date:** November 29, 2025 | **Components:** Cloud Function + Flutter + Stripe

---

## 📋 Pre-Test Checklist

Before starting tests, verify all components are in place:

- [x] Cloud Function deployed: `createCheckoutSessionBilling`
- [x] Stripe test secret configured: `sk_test_xxx`
- [x] Success URL configured: `https://yourdomain.com/success`
- [x] Cancel URL configured: `https://yourdomain.com/cancel`
- [x] Flutter dependencies installed: `cloud_functions: ^5.6.2`, `url_launcher: ^6.2.0`
- [x] `InvoiceService.createPaymentLink()` method ready
- [x] Payment button integrated in UI (or ready to add)

**Verification Command:**
```bash
firebase functions:config:get
```

Expected output:
```json
{
  "stripe": {
    "secret": "sk_test_xxx"
  },
  "app": {
    "success_url": "https://yourdomain.com/success",
    "cancel_url": "https://yourdomain.com/cancel"
  }
}
```

---

## 🎯 Test Scenarios

### Test 1: Create Invoice
**Objective:** Verify invoice creation before payment testing

**Steps:**
1. Open the app
2. Navigate to Invoices section
3. Create a new invoice with:
   - Customer: "Test Customer"
   - Amount: $100.00 USD
   - Items: At least 1 line item
4. Save the invoice

**Expected Result:**
- ✅ Invoice created successfully
- ✅ Invoice ID generated
- ✅ Status shows "draft" or "unpaid"
- ✅ Total amount displays correctly

**Test Code:**
```dart
void testCreateInvoice() async {
  final svc = InvoiceService();
  final invoice = Invoice(
    invoiceNumber: 'TEST-00001',
    customerId: 'test_customer',
    totalAmount: 100.00,
    currency: 'USD',
    items: [
      InvoiceItem(
        description: 'Test Service',
        quantity: 1,
        unitPrice: 100.00,
      ),
    ],
  );
  
  final invoiceId = await svc.createInvoiceDraft(invoice);
  expect(invoiceId, isNotEmpty);
  print('✅ Invoice created: $invoiceId');
}
```

---

### Test 2: Generate Payment Link
**Objective:** Verify Cloud Function creates valid Stripe checkout URL

**Steps:**
1. Have an unpaid invoice ready (from Test 1)
2. Call the payment link generation
3. Verify URL is returned

**Test Code:**
```dart
Future<void> testGeneratePaymentLink() async {
  final svc = InvoiceService();
  final invoiceId = 'YOUR_INVOICE_ID_HERE';
  
  try {
    final paymentUrl = await svc.createPaymentLink(
      invoiceId,
      successUrl: 'https://yourdomain.com/success',
      cancelUrl: 'https://yourdomain.com/cancel',
    );
    
    print('📍 Payment URL: $paymentUrl');
    expect(paymentUrl, isNotNull);
    expect(paymentUrl, contains('stripe.com'));
    print('✅ Payment link generated successfully');
  } catch (e) {
    print('❌ Error: $e');
    fail('Payment link generation failed');
  }
}
```

**Expected Result:**
- ✅ URL returned (typically `https://checkout.stripe.com/pay/...`)
- ✅ URL contains `stripe.com` domain
- ✅ No exceptions thrown
- ✅ Response time < 5 seconds

**If Test Fails:**
- Check Cloud Function logs: `firebase functions:log`
- Verify Stripe secret is set: `firebase functions:config:get`
- Check Firebase auth: User must be logged in
- Verify invoice exists in Firestore

---

### Test 3: Open Payment Link in Browser
**Objective:** Verify url_launcher successfully opens Stripe checkout page

**Steps:**
1. Have a valid payment URL from Test 2
2. Call url_launcher to open it
3. Verify browser opens with Stripe checkout

**Test Code:**
```dart
Future<void> testOpenPaymentLink(String paymentUrl) async {
  try {
    final uri = Uri.parse(paymentUrl);
    
    // Verify URL can be launched
    if (await canLaunchUrl(uri)) {
      print('✅ URL is launchable');
    } else {
      throw Exception('URL cannot be launched');
    }
    
    // Launch in external browser
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    
    expect(launched, true);
    print('✅ Payment page opened in browser');
  } catch (e) {
    print('❌ Error: $e');
    fail('URL launch failed');
  }
}
```

**Expected Result:**
- ✅ Browser opens automatically
- ✅ Stripe checkout page displays
- ✅ Page shows invoice amount
- ✅ Payment method inputs visible

**If Test Fails:**
- Check url_launcher dependency: `flutter pub get`
- Verify URL format is valid
- Check Android/iOS permission settings
- Test with simple URL first: `https://www.google.com`

---

### Test 4: Complete Payment with Test Card
**Objective:** Verify Stripe payment processing works end-to-end

**Prerequisites:**
- Have Stripe checkout page open (from Test 3)
- Have test card ready

**Test Card Details:**
| Field | Value |
|-------|-------|
| Card Number | `4242 4242 4242 4242` |
| Expiry | `12/25` (any future month/year) |
| CVC | `123` (any 3 digits) |
| Name | `Test User` |
| Email | `test@example.com` |

**Alternative Test Cards:**
```
❌ Declined Card: 4000 0000 0000 0002
⏳ Requires Auth: 4000 0025 0000 3155
🔄 3D Secure: 4000 0025 0000 3155
```

**Steps:**
1. In Stripe checkout page:
   - Enter test card: `4242 4242 4242 4242`
   - Expiry: `12/25`
   - CVC: `123`
   - Name: `Test User`
   - Email: `test@example.com`
2. Click "Pay" button
3. Wait for confirmation

**Expected Result:**
- ✅ Payment processes successfully
- ✅ Stripe returns to success URL
- ✅ App detects success
- ✅ Invoice marked as paid
- ✅ Confirmation message displayed

**Stripe Dashboard Verification:**
1. Go to [Stripe Dashboard](https://dashboard.stripe.com/test/payments)
2. Filter by test mode (toggle on top left)
3. Look for payment with $100.00 amount
4. Status should show "Succeeded"

---

### Test 5: Payment Cancellation Flow
**Objective:** Verify user can cancel payment without completing

**Steps:**
1. Generate new payment link (Test 2)
2. Open in browser (Test 3)
3. Click "Cancel" or back button
4. Observe behavior

**Expected Result:**
- ✅ Browser navigates to cancel URL
- ✅ App detects cancellation
- ✅ Invoice remains unpaid
- ✅ User can retry payment
- ✅ Notification shows cancellation message

**Test Code:**
```dart
Future<void> testPaymentCancellation() async {
  final svc = InvoiceService();
  final invoiceId = 'YOUR_INVOICE_ID_HERE';
  
  // Get payment URL
  final paymentUrl = await svc.createPaymentLink(
    invoiceId,
    successUrl: 'https://yourdomain.com/success',
    cancelUrl: 'https://yourdomain.com/cancel',
  );
  
  // Verify invoice still unpaid after cancellation
  // (In real flow, user cancels in browser and returns)
  final invoice = await svc.getInvoice(invoiceId);
  expect(invoice.paymentStatus, 'unpaid');
  print('✅ Invoice remains unpaid after cancellation');
}
```

---

### Test 6: Multiple Payment Attempts
**Objective:** Verify user can retry payment after cancellation

**Steps:**
1. Cancel payment (Test 5)
2. Click "Pay" again
3. Complete payment with different amount (if supported)

**Expected Result:**
- ✅ New payment link generated
- ✅ Previous session doesn't interfere
- ✅ Payment completes successfully

---

### Test 7: Error Handling
**Objective:** Verify app handles errors gracefully

#### Test 7a: Invalid Invoice ID
```dart
Future<void> testInvalidInvoiceId() async {
  final svc = InvoiceService();
  
  try {
    final paymentUrl = await svc.createPaymentLink('INVALID_ID');
    fail('Should have thrown error');
  } catch (e) {
    expect(e.toString(), contains('not found') | contains('invalid'));
    print('✅ Proper error handling for invalid invoice');
  }
}
```

**Expected Result:**
- ✅ Error thrown (not returned silently)
- ✅ Error message is descriptive
- ✅ User sees friendly error in UI

#### Test 7b: Network Timeout
```dart
Future<void> testNetworkTimeout() async {
  // Disable network or use offline mode
  
  final svc = InvoiceService();
  
  try {
    await svc.createPaymentLink('invoiceId').timeout(
      Duration(seconds: 5),
      onTimeout: () => throw TimeoutException('Request timeout'),
    );
    fail('Should have timed out');
  } catch (e) {
    print('✅ Timeout handled: $e');
  }
}
```

**Expected Result:**
- ✅ Timeout exception caught
- ✅ User sees "Network error" message
- ✅ Can retry payment

#### Test 7c: Firebase Not Authenticated
```dart
Future<void> testUnauthenticatedUser() async {
  // Sign out user first
  await FirebaseAuth.instance.signOut();
  
  final svc = InvoiceService();
  
  try {
    await svc.createPaymentLink('invoiceId');
    fail('Should require auth');
  } catch (e) {
    expect(e.toString(), contains('auth') | contains('permission'));
    print('✅ Auth check working');
  }
}
```

**Expected Result:**
- ✅ Error when user not authenticated
- ✅ Prompts user to login

---

### Test 8: Payment Verification
**Objective:** Verify invoice is marked as paid after successful payment

**Steps:**
1. Complete payment (Test 4)
2. Check invoice status in app
3. Verify Firestore document

**Test Code:**
```dart
Future<void> testPaymentVerification(String invoiceId) async {
  final svc = InvoiceService();
  
  // Get invoice after payment
  final invoice = await svc.getInvoice(invoiceId);
  
  expect(invoice.paymentStatus, 'paid');
  expect(invoice.paidAt, isNotNull);
  expect(invoice.paymentVerified, true);
  
  print('✅ Invoice marked as paid');
  print('   Status: ${invoice.paymentStatus}');
  print('   Paid At: ${invoice.paidAt}');
  print('   Verified: ${invoice.paymentVerified}');
}
```

**Firebase Verification:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Navigate to Firestore
3. Find collection: `users > [uid] > invoices`
4. Find your test invoice
5. Check fields:
   - `paymentStatus: "paid"`
   - `paymentVerified: true`
   - `paidAt: [timestamp]`

---

## 🎬 Complete Test Flow (End-to-End)

Follow this sequence for a complete test:

```
1. Create Invoice (Test 1)
   ↓
2. Generate Payment Link (Test 2)
   ↓
3. Open in Browser (Test 3)
   ↓
4. Complete Payment with Test Card (Test 4)
   ↓
5. Verify Payment (Test 8)
   ↓
✅ PAYMENT FLOW COMPLETE

Optional:
6. Test Cancellation (Test 5)
7. Test Error Handling (Test 7)
8. Test Multiple Attempts (Test 6)
```

---

## 📊 Testing Checklist

### Pre-Flight Checks
- [ ] Cloud Function deployed
- [ ] Stripe config set
- [ ] App compiled without errors
- [ ] Dependencies installed
- [ ] Test data prepared

### Core Payment Flow
- [ ] Test 1: Create Invoice
- [ ] Test 2: Generate Payment Link
- [ ] Test 3: Open in Browser
- [ ] Test 4: Complete Payment
- [ ] Test 8: Verify Payment

### Edge Cases
- [ ] Test 5: Cancel Payment
- [ ] Test 6: Multiple Attempts
- [ ] Test 7a: Invalid Invoice
- [ ] Test 7b: Network Timeout
- [ ] Test 7c: Unauthenticated User

### Production Readiness
- [ ] All tests pass
- [ ] Error messages user-friendly
- [ ] Performance acceptable (<5s)
- [ ] Stripe Dashboard shows transactions
- [ ] Firebase Logs show no errors

---

## 🔍 Debugging Tips

### Check Cloud Function Logs
```bash
# View recent function logs
firebase functions:log

# View with filtering
firebase functions:log --limit 50

# Real-time logs
firebase functions:log --follow
```

### Common Log Patterns
```
✅ SUCCESS: "Checkout session created: cs_test_..."
❌ ERROR: "Invoice not found"
❌ ERROR: "User not authenticated"
❌ ERROR: "Stripe API error: ..."
```

### Check Firestore
1. Go to Firebase Console → Firestore
2. Find user document: `users/{uid}`
3. Check `invoices` subcollection
4. Look for:
   - Invoice created
   - `paymentStatus` field
   - `paidAt` timestamp (if paid)

### Stripe Dashboard
1. Go to [Stripe Test Dashboard](https://dashboard.stripe.com/test/payments)
2. View all test payments
3. Click on payment to see details:
   - Amount
   - Status (succeeded/failed)
   - Metadata
   - Customer email

### Flutter/Dart Errors
```bash
# Check app logs
flutter logs

# Run with verbose output
flutter run -v

# Analyze code
flutter analyze
```

---

## 🚨 Troubleshooting

### Payment Link Not Generated
**Symptoms:**
- `createPaymentLink()` returns null
- Error: "invalid response"

**Solutions:**
1. Check Cloud Function logs: `firebase functions:log`
2. Verify Stripe secret: `firebase functions:config:get`
3. Verify invoice exists in Firestore
4. Check user is authenticated
5. Verify Cloud Function is deployed: `firebase functions:list`

### Browser Doesn't Open
**Symptoms:**
- `launchUrl()` returns false
- Payment page doesn't appear

**Solutions:**
1. Verify URL is valid: Check console output
2. Check url_launcher dependency: `flutter pub get`
3. Test with simple URL first: `https://google.com`
4. Check Android/iOS permissions configured
5. Try different launch mode: `LaunchMode.inAppBrowser`

### Payment Succeeds but Invoice Not Updated
**Symptoms:**
- Stripe shows payment succeeded
- But invoice still shows "unpaid"

**Solutions:**
1. Check if success URL was called
2. Verify `markAsPaid()` is called after redirect
3. Check Firebase Logs for errors
4. Manually update invoice (debug)
5. Check Cloud Function return value includes payment ID

### Test Card Declined
**Symptoms:**
- "Your card was declined" message

**Solutions:**
1. Use correct test card: `4242 4242 4242 4242`
2. Use any future expiry: `12/25`
3. Use any 3-digit CVC: `123`
4. Try different test card from list above
5. Check Stripe account is in test mode

---

## 📈 Performance Expectations

| Operation | Expected Time | Acceptable Range |
|-----------|----------------|----|
| Generate Payment Link | 1-2 seconds | < 5 seconds |
| Open in Browser | < 500ms | < 2 seconds |
| Stripe Page Load | 2-3 seconds | < 5 seconds |
| Payment Processing | 2-5 seconds | < 10 seconds |
| Firebase Update | < 1 second | < 3 seconds |

---

## ✅ Success Criteria

Your payment integration is working when:

1. ✅ Payment link generates without errors
2. ✅ Browser opens Stripe checkout page
3. ✅ Test card payment succeeds
4. ✅ Invoice marked as paid in Firebase
5. ✅ Stripe Dashboard shows payment
6. ✅ Error handling works gracefully
7. ✅ Multiple payment attempts work
8. ✅ Performance is acceptable

---

## 🚀 Next Steps After Testing

### If Tests Pass ✅
1. Update redirect URLs to production domain
2. Add "Pay" button to invoice screens
3. Integrate with email notifications
4. Set up webhook handler (optional)
5. Deploy to production

### If Tests Fail ❌
1. Check error messages in logs
2. Verify Cloud Function is deployed
3. Verify Stripe credentials are set
4. Check Firebase auth is working
5. Review troubleshooting section above

---

## 📚 Reference Documents

- **Cloud Function:** [functions/src/billing/createCheckoutSession.ts](functions/src/billing/createCheckoutSession.ts)
- **Invoice Service:** [lib/services/invoice/invoice_service.dart](lib/services/invoice/invoice_service.dart)
- **Payment Examples:** [lib/screens/examples/stripe_payment_integration_examples.dart](lib/screens/examples/stripe_payment_integration_examples.dart)
- **Firebase Config:** Configured via `firebase functions:config:set`

---

## 🎓 Test Data

### Test Invoice Template
```dart
Invoice(
  invoiceNumber: 'TEST-00001',
  customerId: 'test_cust_123',
  customerName: 'Test Customer',
  amount: 100.00,
  tax: 0.00,
  totalAmount: 100.00,
  currency: 'USD',
  status: 'draft',
  paymentStatus: 'unpaid',
  dueDate: DateTime.now().add(Duration(days: 30)),
  items: [
    InvoiceItem(
      description: 'Consulting Services',
      quantity: 10,
      unitPrice: 100.00,
    ),
  ],
)
```

### Test Stripe Data
```
Email: test@example.com
Card: 4242 4242 4242 4242
Expiry: 12/25
CVC: 123
Name: Test User
Billing Address: 123 Test St, Test City, TS 12345
```

---

## ⏱️ Estimated Timeline

| Phase | Time | Tasks |
|-------|------|-------|
| **Setup** | 5 min | Verify dependencies, config |
| **Test 1-3** | 10 min | Create invoice, link, open |
| **Test 4-8** | 15 min | Payment, verification, errors |
| **Debugging** | 5-30 min | Fix any issues (if needed) |
| **Production** | 30 min | Update URLs, deploy, monitor |

**Total Time:** 30-60 minutes (plus debugging if needed)

---

## 📞 Support & Reference

### Documentation
- See [Copilot Instructions](/workspaces/aura-sphere-pro/.github/copilot-instructions.md)
- See [Architecture Guide](/workspaces/aura-sphere-pro/docs/architecture.md)
- See [API Reference](/workspaces/aura-sphere-pro/docs/api_reference.md)

### Quick Commands
```bash
# Check Firebase config
firebase functions:config:get

# View Cloud Function logs
firebase functions:log

# Deploy functions
firebase deploy --only functions

# Run tests
flutter test

# Analyze code
flutter analyze
```

---

*Last updated: November 29, 2025*
*Status: ✅ Ready to Test*
*Version: 1.0*
