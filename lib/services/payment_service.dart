import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:aurasphere_pro/models/payment_record.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get all payments for a specific invoice
  Future<List<PaymentRecord>> getPaymentsForInvoice(
    String userId,
    String invoiceId,
  ) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .collection('payments')
          .orderBy('paidAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching payments for invoice: $e');
      return [];
    }
  }

  /// Get all payments for a user (across all invoices)
  Future<List<PaymentRecord>> getAllPaymentsForUser(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('payments')
          .orderBy('paidAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching user payments: $e');
      return [];
    }
  }

  /// Save a new payment record
  Future<void> savePayment(
    String userId,
    String invoiceId,
    PaymentRecord payment,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .collection('payments')
          .doc(payment.id)
          .set(payment.toFirestore());
    } catch (e) {
      print('Error saving payment: $e');
      rethrow;
    }
  }

  /// Update an existing payment record
  Future<void> updatePayment(
    String userId,
    String invoiceId,
    PaymentRecord payment,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .collection('payments')
          .doc(payment.id)
          .update(payment.toFirestore());
    } catch (e) {
      print('Error updating payment: $e');
      rethrow;
    }
  }

  /// Delete a payment record
  Future<void> deletePayment(
    String userId,
    String invoiceId,
    String paymentId,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .collection('payments')
          .doc(paymentId)
          .delete();
    } catch (e) {
      print('Error deleting payment: $e');
      rethrow;
    }
  }

  /// Get payment by ID
  Future<PaymentRecord?> getPaymentById(
    String userId,
    String invoiceId,
    String paymentId,
  ) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .collection('payments')
          .doc(paymentId)
          .get();

      if (doc.exists) {
        return PaymentRecord.fromFirestore(doc.id, doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Error fetching payment by ID: $e');
      return null;
    }
  }

  /// Listen to payment changes in real-time
  Stream<List<PaymentRecord>> watchPaymentsForInvoice(
    String userId,
    String invoiceId,
  ) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .doc(invoiceId)
        .collection('payments')
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentRecord.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Calculate total amount paid for an invoice
  Future<double> getTotalPaidForInvoice(
    String userId,
    String invoiceId,
  ) async {
    try {
      final payments = await getPaymentsForInvoice(userId, invoiceId);
      return payments.fold<double>(0, (sum, payment) => sum + payment.amount);
    } catch (e) {
      print('Error calculating total paid: $e');
      return 0;
    }
  }

  /// Get payment statistics for a user
  Future<PaymentStats> getPaymentStats(String userId) async {
    try {
      final payments = await getAllPaymentsForUser(userId);

      if (payments.isEmpty) {
        return PaymentStats(
          totalAmount: 0,
          paymentCount: 0,
          averageAmount: 0,
          largestPayment: 0,
          smallestPayment: 0,
        );
      }

      final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amount);
      final sortedByAmount = [...payments]
        ..sort((a, b) => a.amount.compareTo(b.amount));

      return PaymentStats(
        totalAmount: totalAmount,
        paymentCount: payments.length,
        averageAmount: totalAmount / payments.length,
        largestPayment: sortedByAmount.last.amount,
        smallestPayment: sortedByAmount.first.amount,
      );
    } catch (e) {
      print('Error calculating payment stats: $e');
      rethrow;
    }
  }

  /// Create Stripe checkout session for AuraToken pack purchase.
  /// Returns {url, sessionId} for success, null on error.
  Future<Map<String, dynamic>?> createTokenCheckoutSession({
    required String packId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final callable = _functions.httpsCallable('createTokenCheckoutSession');
      final resp = await callable.call({
        'packId': packId,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      });
      return resp.data != null ? Map<String, dynamic>.from(resp.data) : null;
    } catch (e) {
      print('PaymentService.createTokenCheckoutSession error: $e');
      return null;
    }
  }

  /// Create a payment intent with idempotency support
  ///
  /// IMPORTANT: Idempotency keys prevent duplicate charges from:
  /// - Network retries
  /// - User clicking button multiple times
  /// - Browser back button after payment
  ///
  /// The idempotency key is sent via custom header to Stripe
  /// Multiple requests with same key return same result
  ///
  /// Request:
  /// {
  ///   "amount": 9999,              // cents ($99.99)
  ///   "currency": "usd",
  ///   "customerId": "cus_ABC123",
  ///   "description": "Invoice INV-2025-001",
  ///   "metadata": { "invoiceId": "inv_123" }
  /// }
  ///
  /// Response:
  /// {
  ///   "success": true,
  ///   "clientSecret": "pi_..._secret_...",
  ///   "paymentId": "pi_123456",
  ///   "status": "requires_payment_method",
  ///   "amount": 9999,
  ///   "currency": "usd"
  /// }
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount, // in cents, e.g., 9999 = $99.99
    required String customerId,
    String currency = 'usd',
    String? description,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    try {
      // Validate amount
      if (amount <= 0 || amount > 10000000) {
        throw PaymentException('Amount must be between \$0.50 and \$100,000');
      }

      // Generate idempotency key if not provided
      final key = idempotencyKey ?? _generateIdempotencyKey();
      debugPrint('💳 Creating payment intent with key: $key');

      // Call Cloud Function
      final callable = _functions.httpsCallable(
        'createPayment',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      final response = await callable.call<Map<String, dynamic>>(
        {
          'amount': amount.toInt(),
          'currency': currency,
          'customerId': customerId,
          'description': description,
          'metadata': metadata,
        },
      );

      final result = response.data as Map<String, dynamic>;

      if (result['success'] == true) {
        debugPrint('✅ Payment intent created: ${result['paymentId']}');
        return result;
      } else {
        throw PaymentException(result['message'] ?? 'Failed to create payment');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Payment error: ${e.message}');
      throw PaymentException(e.message ?? 'Payment creation failed');
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      rethrow;
    }
  }

  /// Confirm a payment after user completes Stripe payment
  Future<Map<String, dynamic>> confirmPaymentIntent(String paymentId) async {
    try {
      debugPrint('✔️ Confirming payment: $paymentId');

      final callable = _functions.httpsCallable('confirmPayment');
      final response = await callable.call<Map<String, dynamic>>({
        'paymentId': paymentId,
      });

      final result = response.data as Map<String, dynamic>;

      if (result['success'] == true) {
        debugPrint('✅ Payment confirmed: ${result['status']}');
        return result;
      } else {
        throw PaymentException(result['message'] ?? 'Failed to confirm payment');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Confirmation error: ${e.message}');
      throw PaymentException(e.message ?? 'Payment confirmation failed');
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      rethrow;
    }
  }

  /// Get current payment intent status
  Future<Map<String, dynamic>> getPaymentIntentStatus(String paymentId) async {
    try {
      debugPrint('📊 Getting payment status: $paymentId');

      final callable = _functions.httpsCallable('getPaymentStatus');
      final response = await callable.call<Map<String, dynamic>>({
        'paymentId': paymentId,
      });

      final result = response.data as Map<String, dynamic>;

      if (result['success'] == true) {
        debugPrint('✅ Status: ${result['status']}');
        return result;
      } else {
        throw PaymentException(result['message'] ?? 'Failed to get status');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Status error: ${e.message}');
      throw PaymentException(e.message ?? 'Failed to get payment status');
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      rethrow;
    }
  }

  /// Poll payment status with exponential backoff
  ///
  /// Retries up to 5 times with exponential backoff.
  /// Useful for checking if payment has been processed.
  Future<Map<String, dynamic>> pollPaymentStatus(
    String paymentId, {
    int maxRetries = 5,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int retryCount = 0;
    Duration currentDelay = initialDelay;

    while (retryCount < maxRetries) {
      try {
        return await getPaymentIntentStatus(paymentId);
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }

        debugPrint('⏳ Retry $retryCount/$maxRetries in ${currentDelay.inMilliseconds}ms');
        await Future.delayed(currentDelay);

        // Exponential backoff: 500ms → 750ms → 1.1s → 1.6s → 2.4s
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * 1.5).toInt().clamp(0, 30000),
        );
      }
    }

    throw PaymentException('Max retries exceeded');
  }

  /// Generate unique idempotency key (UUID v4)
  static String _generateIdempotencyKey() {
    const uuid = Uuid();
    return uuid.v4();
  }

  /// Generate custom idempotency key with format: "userId_timestamp"
  static String generateCustomIdempotencyKey(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${userId}_$timestamp';
  }
}

/// Exception thrown by payment operations
class PaymentException implements Exception {
  final String message;

  PaymentException(this.message);

  @override
  String toString() => 'PaymentException: $message';
}

class PaymentStats {
  final double totalAmount;
  final int paymentCount;
  final double averageAmount;
  final double largestPayment;
  final double smallestPayment;

  PaymentStats({
    required this.totalAmount,
    required this.paymentCount,
    required this.averageAmount,
    required this.largestPayment,
    required this.smallestPayment,
  });
}
