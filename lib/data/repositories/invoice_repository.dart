import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';

class InvoiceRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String invoicesCollection = 'invoices';

  /// Get user's invoices collection reference
  CollectionReference _userInvoicesRef(String userId) {
    return _db.collection('users').doc(userId).collection(invoicesCollection);
  }

  /// Create a new invoice
  Future<InvoiceModel> createInvoice(String userId, InvoiceModel invoice) async {
    final docRef = _userInvoicesRef(userId).doc(invoice.id);
    await docRef.set(invoice.toMap());
    return invoice;
  }

  /// Get invoice by ID
  Future<InvoiceModel?> getInvoice(String userId, String invoiceId) async {
    try {
      final doc = await _userInvoicesRef(userId).doc(invoiceId).get();
      if (!doc.exists) return null;
      return InvoiceModel.fromDoc(doc);
    } catch (e) {
      return null;
    }
  }

  /// Get all invoices for user
  Future<List<InvoiceModel>> getInvoices(String userId) async {
    try {
      final querySnapshot = await _userInvoicesRef(userId)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => InvoiceModel.fromDoc(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream invoices for user (real-time updates)
  Stream<List<InvoiceModel>> streamInvoices(String userId) {
    return _userInvoicesRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => InvoiceModel.fromDoc(doc)).toList());
  }

  /// Get invoices by status
  Future<List<InvoiceModel>> getInvoicesByStatus(
    String userId,
    String status,
  ) async {
    try {
      final querySnapshot = await _userInvoicesRef(userId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => InvoiceModel.fromDoc(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream invoices by status
  Stream<List<InvoiceModel>> streamInvoicesByStatus(
    String userId,
    String status,
  ) {
    return _userInvoicesRef(userId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => InvoiceModel.fromDoc(doc)).toList());
  }

  /// Update invoice
  Future<void> updateInvoice(String userId, InvoiceModel invoice) async {
    await _userInvoicesRef(userId)
        .doc(invoice.id)
        .update(invoice.toMap());
  }

  /// Update invoice status
  Future<void> updateInvoiceStatus(
    String userId,
    String invoiceId,
    String newStatus,
  ) async {
    await _userInvoicesRef(userId).doc(invoiceId).update({
      'status': newStatus,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Mark invoice as paid
  Future<void> markInvoiceAsPaid(String userId, String invoiceId) async {
    await _userInvoicesRef(userId).doc(invoiceId).update({
      'status': 'paid',
      'paidDate': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete invoice
  Future<void> deleteInvoice(String userId, String invoiceId) async {
    await _userInvoicesRef(userId).doc(invoiceId).delete();
  }

  /// Get invoice count by status
  Future<int> getInvoiceCount(String userId, String status) async {
    try {
      final snapshot = await _userInvoicesRef(userId)
          .where('status', isEqualTo: status)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get total revenue
  Future<double> getTotalRevenue(String userId) async {
    try {
      final snapshot = await _userInvoicesRef(userId)
          .where('status', isEqualTo: 'paid')
          .get();
      return snapshot.docs.fold<double>(
        0,
        (sum, doc) {
          final invoice = InvoiceModel.fromDoc(doc);
          return sum + invoice.total;
        },
      );
    } catch (e) {
      return 0;
    }
  }

  /// Get pending invoices (overdue + unpaid)
  Future<List<InvoiceModel>> getPendingInvoices(String userId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _userInvoicesRef(userId)
          .where('status', whereIn: ['sent', 'overdue'])
          .orderBy('dueDate')
          .get();
      
      return querySnapshot.docs
          .map((doc) => InvoiceModel.fromDoc(doc))
          .where((invoice) => invoice.dueDate?.isAfter(now) != true)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
