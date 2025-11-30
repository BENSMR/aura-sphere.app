import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aurasphere_pro/models/payment_record.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
