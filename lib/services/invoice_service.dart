import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvoiceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  /// Calls the generateNextInvoiceNumber callable function.
  /// Returns the generated invoice number string (e.g. "AURA-0101")
  Future<String?> getNextInvoiceNumber() async {
    try {
      final callable = _functions.httpsCallable('generateNextInvoiceNumber');
      final result = await callable.call();
      final data = result.data as Map<String, dynamic>?;
      if (data == null) return null;
      return data['invoiceNumber'] as String?;
    } catch (e) {
      print('getNextInvoiceNumber error: $e');
      return null;
    }
  }

  /// Mark an invoice as paid with payment method
  /// Updates status to 'paid', records paymentMethod and paidAt timestamp
  Future<void> markInvoicePaid(String invoiceId, String method) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'status': 'paid',
        'paymentMethod': method,
        'paidAt': Timestamp.now(),
        'paymentDate': Timestamp.now(), // Keep for backward compatibility
      });
    } catch (e) {
      print('markInvoicePaid error: $e');
      rethrow;
    }
  }

  /// Mark an invoice as unpaid
  /// Clears paidAt, paymentDate and paymentMethod
  Future<void> markInvoiceUnpaid(String invoiceId) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'status': 'unpaid',
        'paidAt': null,
        'paymentDate': null,
        'paymentMethod': null,
      });
    } catch (e) {
      print('markInvoiceUnpaid error: $e');
      rethrow;
    }
  }

  /// Record a partial payment for an invoice
  /// Updates status to 'partial' and records the partial amount paid
  Future<void> recordPartialPayment(String invoiceId, double amountPaid) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'status': 'partial',
        'amountPaid': amountPaid,
      });
    } catch (e) {
      print('recordPartialPayment error: $e');
      rethrow;
    }
  }

  /// Set or update the due date for an invoice
  Future<void> setInvoiceDueDate(String invoiceId, DateTime due) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'dueDate': Timestamp.fromDate(due),
      });
    } catch (e) {
      print('setInvoiceDueDate error: $e');
      rethrow;
    }
  }

  /// Set due date for an invoice (alias for setInvoiceDueDate)
  Future<void> setDueDate(String invoiceId, DateTime due) async {
    return setInvoiceDueDate(invoiceId, due);
  }

  /// Toggle payment reminders on/off for an invoice
  /// When enabled, the invoice can trigger reminder emails
  Future<void> toggleReminder(String invoiceId, bool enabled) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'reminderEnabled': enabled,
      });
    } catch (e) {
      print('toggleReminder error: $e');
      rethrow;
    }
  }

  /// Record that a reminder was sent for an invoice
  /// Updates lastReminderAt timestamp and increments reminderCount
  Future<void> recordReminderSent(String invoiceId) async {
    try {
      // Get current reminder count
      final doc = await _db.collection('invoices').doc(invoiceId).get();
      final currentCount = (doc['reminderCount'] ?? 0) as int;

      await _db.collection('invoices').doc(invoiceId).update({
        'lastReminderAt': Timestamp.now(),
        'reminderCount': currentCount + 1,
      });
    } catch (e) {
      print('recordReminderSent error: $e');
      rethrow;
    }
  }

  /// Reset reminder tracking (clear lastReminderAt and reminder count)
  /// Called when invoice is marked as paid or status changes
  Future<void> resetReminderTracking(String invoiceId) async {
    try {
      await _db.collection('invoices').doc(invoiceId).update({
        'lastReminderAt': null,
        'reminderCount': 0,
      });
    } catch (e) {
      print('resetReminderTracking error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // Invoice Statistics & Analytics
  // ============================================================================

  /// Get total amount of unpaid invoices for a user
  /// 
  /// Returns: sum of all invoice amounts with status = 'unpaid'
  /// Example: €5,400.00 if user has unpaid invoices totaling 5400
  Future<double> getTotalUnpaid(String userId) async {
    try {
      final query = await _db
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'unpaid')
          .get();

      return query.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc['amount'] as num).toDouble(),
      );
    } catch (e) {
      print('getTotalUnpaid error: $e');
      rethrow;
    }
  }

  /// Get total amount of overdue invoices for a user
  /// 
  /// Returns: sum of all invoice amounts with status = 'overdue'
  /// Example: €2,100.00 if user has overdue invoices totaling 2100
  Future<double> getTotalOverdue(String userId) async {
    try {
      final query = await _db
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'overdue')
          .get();

      return query.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc['amount'] as num).toDouble(),
      );
    } catch (e) {
      print('getTotalOverdue error: $e');
      rethrow;
    }
  }

  /// Get total amount of paid invoices in the current month
  /// 
  /// Returns: sum of all invoice amounts with status = 'paid' and paymentDate in current month
  /// Example: €8,750.00 if user received 8750 in payments this month
  Future<double> getTotalPaidThisMonth(String userId) async {
    try {
      final now = DateTime.now();
      final firstOfMonth = DateTime(now.year, now.month, 1);

      final query = await _db
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'paid')
          .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(firstOfMonth))
          .get();

      return query.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc['amount'] as num).toDouble(),
      );
    } catch (e) {
      print('getTotalPaidThisMonth error: $e');
      rethrow;
    }
  }

  /// Get total amount of paid invoices in a custom date range
  /// 
  /// Parameters:
  ///   userId: user ID
  ///   startDate: beginning of range (inclusive)
  ///   endDate: end of range (inclusive)
  /// 
  /// Example: getTotalPaidInRange(uid, DateTime(2025,1,1), DateTime(2025,12,31))
  /// Returns: total paid in year 2025
  Future<double> getTotalPaidInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _db
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'paid')
          .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('paymentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return query.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc['amount'] as num).toDouble(),
      );
    } catch (e) {
      print('getTotalPaidInRange error: $e');
      rethrow;
    }
  }

  /// Get count of unpaid invoices for a user
  /// 
  /// Returns: number of invoices with status = 'unpaid' or 'partial'
  /// Example: 5 if user has 5 unpaid/partial invoices
  Future<int> getUnpaidCount(String userId) async {
    try {
      final query = await _db
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['unpaid', 'partial'])
          .get();

      return query.docs.length;
    } catch (e) {
      print('getUnpaidCount error: $e');
      rethrow;
    }
  }

  /// Get count of overdue invoices for a user
  /// 
  /// Returns: number of invoices with status = 'overdue'
  Future<int> getOverdueCount(String userId) async {
    try {
      final query = await _db
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'overdue')
          .get();

      return query.docs.length;
    } catch (e) {
      print('getOverdueCount error: $e');
      rethrow;
    }
  }

  /// Get comprehensive invoice summary for dashboard
  /// 
  /// Returns: Map with totals and counts:
  /// {
  ///   'totalUnpaid': 5400.0,
  ///   'totalOverdue': 2100.0,
  ///   'totalPaidThisMonth': 8750.0,
  ///   'unpaidCount': 5,
  ///   'overdueCount': 2,
  /// }
  Future<Map<String, dynamic>> getInvoiceSummary(String userId) async {
    try {
      final results = await Future.wait([
        getTotalUnpaid(userId),
        getTotalOverdue(userId),
        getTotalPaidThisMonth(userId),
        getUnpaidCount(userId),
        getOverdueCount(userId),
      ]);

      return {
        'totalUnpaid': results[0] as double,
        'totalOverdue': results[1] as double,
        'totalPaidThisMonth': results[2] as double,
        'unpaidCount': results[3] as int,
        'overdueCount': results[4] as int,
      };
    } catch (e) {
      print('getInvoiceSummary error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // Invoice Creation with Client Integration
  // ============================================================================

  /// Create invoice for a client in nested invoices collection
  /// 
  /// This creates an invoice in users/{userId}/invoices/{invoiceId}
  /// which automatically triggers Cloud Functions to update client metrics
  /// 
  /// Parameters:
  ///   - clientId: Associated client ID (required for metrics)
  ///   - amountTotal: Total invoice amount (required, must be > 0)
  ///   - dueDate: Invoice due date (optional)
  ///   - status: Invoice status (default: 'draft')
  /// 
  /// Returns: Invoice ID
  Future<String> createClientInvoice({
    required String clientId,
    required double amountTotal,
    DateTime? dueDate,
    String status = 'draft',
    String? notes,
    Map<String, dynamic>? additionalData,
  }) async {
    if (clientId.isEmpty) {
      throw ArgumentError('clientId cannot be empty');
    }

    if (amountTotal <= 0) {
      throw ArgumentError('amountTotal must be greater than 0');
    }

    const validStatuses = ['draft', 'sent', 'paid', 'overdue', 'cancelled', 'refunded'];
    if (!validStatuses.contains(status)) {
      throw ArgumentError('Invalid status: $status');
    }

    try {
      final invoiceData = {
        'userId': _uid,
        'clientId': clientId,
        'amountTotal': amountTotal,
        'status': status,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
        'invoiceDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        if (notes != null) 'notes': notes,
        if (additionalData != null) ...additionalData,
      };

      // Create in nested invoices collection (triggers Cloud Function)
      final docRef = await _db
          .collection('users')
          .doc(_uid)
          .collection('invoices')
          .add(invoiceData);

      return docRef.id;
    } catch (e) {
      print('createClientInvoice error: $e');
      rethrow;
    }
  }

  /// Create invoice for client with line items
  /// 
  /// Convenience method that calculates total from items
  Future<String> createClientInvoiceWithItems({
    required String clientId,
    required List<InvoiceItem> items,
    DateTime? dueDate,
    String status = 'draft',
    String? notes,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('items cannot be empty');
    }

    final amountTotal = items.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );

    return createClientInvoice(
      clientId: clientId,
      amountTotal: amountTotal,
      dueDate: dueDate,
      status: status,
      notes: notes,
      additionalData: {
        'items': items.map((item) => item.toMap()).toList(),
      },
    );
  }

  /// Get all invoices for a specific client
  Future<List<Map<String, dynamic>>> getClientInvoices(String clientId) async {
    try {
      final query = await _db
          .collection('users')
          .doc(_uid)
          .collection('invoices')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('getClientInvoices error: $e');
      rethrow;
    }
  }

  /// Get total revenue from a client (sum of paid invoices)
  Future<double> getClientRevenue(String clientId) async {
    try {
      final query = await _db
          .collection('users')
          .doc(_uid)
          .collection('invoices')
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: 'paid')
          .get();

      return query.docs.fold<double>(
        0,
        (sum, doc) => sum + ((doc['amountTotal'] ?? 0) as num).toDouble(),
      );
    } catch (e) {
      print('getClientRevenue error: $e');
      rethrow;
    }
  }

  /// Get invoice count by status for a client
  Future<Map<String, int>> getClientInvoiceStatusCount(String clientId) async {
    try {
      final invoices = await getClientInvoices(clientId);

      final counts = <String, int>{
        'draft': 0,
        'sent': 0,
        'paid': 0,
        'overdue': 0,
        'cancelled': 0,
        'refunded': 0,
      };

      for (final invoice in invoices) {
        final status = invoice['status'] ?? 'draft';
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('getClientInvoiceStatusCount error: $e');
      rethrow;
    }
  }

  /// Get pending (unpaid) invoices for a client
  Future<double> getClientPendingAmount(String clientId) async {
    try {
      final query = await _db
          .collection('users')
          .doc(_uid)
          .collection('invoices')
          .where('clientId', isEqualTo: clientId)
          .where('status', whereIn: ['draft', 'sent', 'unpaid', 'overdue'])
          .get();

      return query.docs.fold<double>(
        0,
        (sum, doc) => sum + ((doc['amountTotal'] ?? 0) as num).toDouble(),
      );
    } catch (e) {
      print('getClientPendingAmount error: $e');
      rethrow;
    }
  }

  /// Get a single invoice by ID
  Future<Map<String, dynamic>?> getInvoiceById(String invoiceId) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .collection('invoices')
          .doc(invoiceId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      print('getInvoiceById error: $e');
      rethrow;
    }
  }

  /// Record an invoice payment
  /// Updates invoice with payment amount, method, and timestamp
  Future<void> recordInvoicePayment(
    String invoiceId,
    double amount,
    String method,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('invoices')
          .doc(invoiceId)
          .update({
        'status': 'paid',
        'paidAt': Timestamp.now(),
        'paymentAmount': amount,
        'paymentMethod': method,
      });
    } catch (e) {
      print('recordInvoicePayment error: $e');
      rethrow;
    }
  }

  /// Update invoice status
  Future<void> updateInvoiceStatus(String invoiceId, String newStatus) async {
    try {
      final Map<String, dynamic> updateData = {'status': newStatus};

      // Set timestamp based on status change
      if (newStatus == 'sent') {
        updateData['sentAt'] = Timestamp.now();
      } else if (newStatus == 'paid') {
        updateData['paidAt'] = Timestamp.now();
      }

      await _db
          .collection('users')
          .doc(_uid)
          .collection('invoices')
          .doc(invoiceId)
          .update(updateData);
    } catch (e) {
      print('updateInvoiceStatus error: $e');
      rethrow;
    }
  }

  /// Batch get invoices by ID
  Future<List<DocumentSnapshot>> batchGetInvoices(List<String> invoiceIds) async {
    if (invoiceIds.isEmpty) return [];
    final chunks = <List<String>>[];
    for (int i = 0; i < invoiceIds.length; i += 10) {
      chunks.add(invoiceIds.sublist(i, i + 10 > invoiceIds.length ? invoiceIds.length : i + 10));
    }

    final results = <DocumentSnapshot>[];
    for (final chunk in chunks) {
      final query = await _db.collection('invoices').where(FieldPath.documentId, whereIn: chunk).get();
      results.addAll(query.docs);
    }
    return results;
  }
}

/// Invoice line item helper class
class InvoiceItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double? discount; // percentage
  final double? tax; // percentage

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discount,
    this.tax,
  });

  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * ((discount ?? 0) / 100);
  double get taxAmount => (subtotal - discountAmount) * ((tax ?? 0) / 100);
  double get total => subtotal - discountAmount + taxAmount;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
      'tax': tax,
      'subtotal': subtotal,
      'total': total,
    };
  }

  static InvoiceItem fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      discount: map['discount']?.toDouble(),
      tax: map['tax']?.toDouble(),
    );
  }
}
