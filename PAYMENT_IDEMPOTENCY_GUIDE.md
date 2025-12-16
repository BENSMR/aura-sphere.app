// IDEMPOTENCY KEY USAGE EXAMPLES

// ==================== CLIENT-SIDE (Flutter/Web) ====================

// Example 1: Create payment with auto-generated idempotency key
Future<void> processPayment() async {
  final paymentService = PaymentService();
  
  try {
    // Create payment - idempotency key generated automatically
    final payment = await paymentService.createPaymentIntent(
      amount: 9999, // $99.99 in cents
      currency: 'usd',
      customerId: 'cus_ABC123',
      description: 'Invoice INV-2025-001',
      metadata: {'invoiceId': 'inv_123'},
    );
    
    print('Payment created: ${payment['paymentId']}');
    print('Client secret: ${payment['clientSecret']}');
    
    // Safe to retry: same idempotency key prevents duplicate charges
    // Even if user clicks button again, same payment intent returned
  } catch (e) {
    print('Payment error: $e');
  }
}

// Example 2: Create payment with custom idempotency key
Future<void> processPaymentCustomKey() async {
  final paymentService = PaymentService();
  final userId = 'user_123';
  
  // Custom format: "user_123_1702778400000"
  final idempotencyKey = PaymentService.generateCustomIdempotencyKey(userId);
  
  final payment = await paymentService.createPaymentIntent(
    amount: 9999,
    currency: 'usd',
    customerId: 'cus_ABC123',
    idempotencyKey: idempotencyKey, // Explicit key
  );
  
  print('Idempotency key: $idempotencyKey');
}

// Example 3: Handle network retries safely
Future<void> processPaymentWithRetry() async {
  final paymentService = PaymentService();
  final idempotencyKey = PaymentService._generateIdempotencyKey();
  
  // First attempt
  try {
    final payment = await paymentService.createPaymentIntent(
      amount: 9999,
      currency: 'usd',
      customerId: 'cus_ABC123',
      idempotencyKey: idempotencyKey,
    );
    print('✅ Payment created: ${payment['paymentId']}');
  } catch (e) {
    print('❌ First attempt failed: $e');
    
    // SAFE TO RETRY: Same idempotency key ensures no duplicate charge
    print('🔄 Retrying with same key...');
    
    try {
      final payment = await paymentService.createPaymentIntent(
        amount: 9999,
        currency: 'usd',
        customerId: 'cus_ABC123',
        idempotencyKey: idempotencyKey, // Same key
      );
      print('✅ Payment created (retry): ${payment['paymentId']}');
    } catch (e2) {
      print('❌ Retry also failed: $e2');
    }
  }
}

// Example 4: Confirm payment after Stripe payment completes
Future<void> completePaymentFlow() async {
  final paymentService = PaymentService();
  
  try {
    // 1. Create payment intent
    final payment = await paymentService.createPaymentIntent(
      amount: 9999,
      currency: 'usd',
      customerId: 'cus_ABC123',
    );
    
    final paymentId = payment['paymentId'];
    final clientSecret = payment['clientSecret'];
    
    // 2. Show Stripe payment form with clientSecret
    // (Handled by Stripe Flutter plugin)
    // final result = await Stripe.instance.confirmPaymentSheetPayment();
    
    // 3. Confirm payment after user completes payment
    final confirmed = await paymentService.confirmPaymentIntent(paymentId);
    print('✅ Payment confirmed: ${confirmed['status']}');
    
  } catch (e) {
    print('❌ Payment flow failed: $e');
  }
}

// Example 5: Check payment status with polling
Future<void> pollPaymentCompletion() async {
  final paymentService = PaymentService();
  final paymentId = 'pi_123456';
  
  try {
    // Poll with exponential backoff (max 5 retries)
    final status = await paymentService.pollPaymentStatus(
      paymentId,
      maxRetries: 5,
      initialDelay: Duration(milliseconds: 500),
    );
    
    print('Payment status: ${status['status']}');
    
    if (status['status'] == 'succeeded') {
      print('✅ Payment succeeded!');
    } else if (status['status'] == 'failed') {
      print('❌ Payment failed');
    }
  } catch (e) {
    print('❌ Status check failed: $e');
  }
}

// ==================== CLOUD FUNCTION BEHAVIOR ====================

// Request Headers:
{
  'idempotency-key': '550e8400-e29b-41d4-a716-446655440000'
  // or
  'x-idempotency-key': 'user_123_1702778400000'
}

// Request Body:
{
  'amount': 9999,
  'currency': 'usd',
  'customerId': 'cus_ABC123',
  'description': 'Invoice INV-2025-001',
  'metadata': {
    'invoiceId': 'inv_123'
  }
}

// Response (Success):
{
  'success': true,
  'clientSecret': 'pi_1A2b3C4d5E6f_secret_7G8h9I0j1K2l',
  'paymentId': 'pi_1A2b3C4d5E6f',
  'status': 'requires_payment_method',
  'amount': 9999,
  'currency': 'usd',
  'message': 'Payment intent created successfully'
}

// Response (Idempotent - Same Key):
{
  'success': true,
  'clientSecret': 'pi_1A2b3C4d5E6f_secret_7G8h9I0j1K2l',
  'paymentId': 'pi_1A2b3C4d5E6f',
  'status': 'succeeded',
  'message': 'Payment already processed (idempotent)'
}

// Response (Error):
{
  'error': {
    'code': 'invalid-argument',
    'message': 'Idempotency key is required (header: idempotency-key)'
  }
}

// ==================== STRIPE WEBHOOK HANDLING ====================

// Stripe sends webhooks for payment status changes
// These are processed by handleStripeWebhook Cloud Function

// Events handled:
// 1. payment_intent.succeeded
//    → Updates payment status to 'succeeded'
//    → Triggers business logic (send receipt, create order, etc.)
//
// 2. payment_intent.payment_failed
//    → Updates payment status to 'failed'
//    → Notifies user of payment failure
//
// 3. payment_intent.canceled
//    → Updates payment status to 'canceled'
//    → Logs cancellation

// Webhook Setup in Stripe Dashboard:
// URL: https://region-project.cloudfunctions.net/handleStripeWebhook
// Events to listen for:
//   - payment_intent.succeeded
//   - payment_intent.payment_failed
//   - payment_intent.canceled

// ==================== KEY BENEFITS ====================

// PREVENTS DUPLICATE CHARGES:
// ✅ Same idempotency key = Same payment intent
// ✅ Network retry → No duplicate charge
// ✅ User clicks button twice → No duplicate charge
// ✅ Browser back button → No duplicate charge

// AUTOMATIC RETRY SAFE:
// ✅ Failed request? Retry with same key
// ✅ No risk of overcharging customer
// ✅ Transparent to user

// AUDIT TRAIL:
// ✅ Every payment logged in Firestore
// ✅ Idempotency key tracked
// ✅ Payment intent ID recorded
// ✅ Status changes timestamped

// USER EXPERIENCE:
// ✅ Instant feedback on payment creation
// ✅ Can safely retry on network failure
// ✅ Clear error messages
// ✅ Payment confirmation email sent

// ==================== FIRESTORE SCHEMA ====================

// Collection: /payments/{paymentId}
{
  'userId': 'user_123',
  'paymentId': 'pi_1A2b3C4d5E6f',
  'idempotencyKey': '550e8400-e29b-41d4-a716-446655440000',
  'amount': 9999,
  'currency': 'usd',
  'customerId': 'cus_ABC123',
  'description': 'Invoice INV-2025-001',
  'status': 'succeeded', // requires_payment_method, processing, succeeded, failed, canceled
  'clientSecret': 'pi_1A2b3C4d5E6f_secret_7G8h9I0j1K2l',
  'metadata': {
    'invoiceId': 'inv_123'
  },
  'createdAt': Timestamp,
  'updatedAt': Timestamp,
  'lastStatusChange': Timestamp
}

// ==================== ERROR HANDLING ====================

// Authentication Error:
throw new HttpsError('unauthenticated', 'User must be authenticated');

// Missing Idempotency Key:
throw new HttpsError('invalid-argument', 'Idempotency key is required (header: idempotency-key)');

// Invalid Amount:
throw new HttpsError('invalid-argument', 'Amount must be a positive number (in cents)');
throw new HttpsError('invalid-argument', 'Amount must be at least $0.50 (50 cents)');
throw new HttpsError('invalid-argument', 'Amount cannot exceed $100,000');

// Invalid Currency:
throw new HttpsError('invalid-argument', 'Currency must be one of: usd, eur, gbp, cad, aud');

// Invalid Customer:
throw new HttpsError('invalid-argument', 'Customer ID is required');

// Stripe Errors:
throw new HttpsError('invalid-argument', 'Stripe error: [error message]');
throw new HttpsError('internal', 'Payment service authentication failed');

// ==================== TESTING ====================

// Test with Stripe Test Mode:
// Test Cards: https://stripe.com/docs/testing

// Test successful payment:
// Card: 4242 4242 4242 4242
// Date: 12/25
// CVC: 123

// Test failed payment:
// Card: 4000 0000 0000 0002
// Date: 12/25
// CVC: 123

// Test idempotency:
// 1. Create payment with key: 'test_key_1'
// 2. Get paymentId: 'pi_12345'
// 3. Retry with same key: 'test_key_1'
// 4. Verify same paymentId returned

// ==================== SECURITY CONSIDERATIONS ====================

// 1. Idempotency Key Validation:
//    ✅ UUID v4 format required
//    ✅ Or custom alphanumeric format (10-100 chars)
//    ✅ Prevents malformed keys

// 2. User Ownership:
//    ✅ Payment associated with authenticated user
//    ✅ Users can only access their own payments
//    ✅ Server-side ownership validation

// 3. Amount Validation:
//    ✅ Min: $0.50 (50 cents)
//    ✅ Max: $100,000 (10000000 cents)
//    ✅ Prevents accidental large charges

// 4. Rate Limiting:
//    ✅ Cloud Functions has built-in rate limits
//    ✅ Stripe API rate limiting
//    ✅ Consider implementing client-side debouncing

// 5. Logging:
//    ✅ All payments logged for audit
//    ✅ Error tracking with details
//    ✅ Timestamp of all operations
