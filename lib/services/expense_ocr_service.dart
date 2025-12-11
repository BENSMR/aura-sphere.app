import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_ocr_model.dart';

/// Utilities for working with Expense OCR workflow
class ExpenseOCRHelper {
  static final _firestore = FirebaseFirestore.instance;

  /// Create a new expense document from OCR results
  static Future<String> createExpenseFromOCR({
    required String userId,
    required String merchant,
    required double amount,
    required String currency,
    required String date,
    required String rawOcr,
    required ParsedOCRData? parsed,
    required String? imageStoragePath,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc();

    await docRef.set({
      'merchant': merchant,
      'totalAmount': amount,
      'currency': currency,
      'date': date,
      'status': 'draft',
      'rawOcr': rawOcr,
      'parsed': parsed?.toJson(),
      'amounts': parsed?.amounts.map((a) => a.toJson()).toList() ?? [],
      'dates': parsed?.dates ?? [],
      'attachments': imageStoragePath != null
          ? [
              {
                'path': imageStoragePath,
                'uploadedAt': FieldValue.serverTimestamp(),
                'name': imageStoragePath.split('/').last,
              }
            ]
          : [],
      'audit': [
        {
          'action': 'ocr_created',
          'at': FieldValue.serverTimestamp(),
          'by': userId,
        }
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'editedBy': null,
    });

    return docRef.id;
  }

  /// Load an expense by ID
  static Future<ExpenseOCRModel?> getExpense({
    required String userId,
    required String expenseId,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .get();

    if (!doc.exists) return null;
    return ExpenseOCRModel.fromFirestore(doc);
  }

  /// Stream an expense by ID (for real-time updates)
  static Stream<ExpenseOCRModel?> watchExpense({
    required String userId,
    required String expenseId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return ExpenseOCRModel.fromFirestore(doc);
    });
  }

  /// List all expenses for a user
  static Future<List<ExpenseOCRModel>> listExpenses({
    required String userId,
    String? status,
    int limit = 50,
  }) async {
    final collection = _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses');

    final baseQuery = collection
        .orderBy('createdAt', descending: true)
        .limit(limit);

    final query = status != null 
        ? baseQuery.where('status', isEqualTo: status)
        : baseQuery;

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ExpenseOCRModel.fromFirestore(doc))
        .toList();
  }

  /// Stream expenses (for real-time list)
  static Stream<List<ExpenseOCRModel>> watchExpenses({
    required String userId,
    String? status,
    int limit = 50,
  }) {
    final collection = _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses');

    final baseQuery = collection
        .orderBy('createdAt', descending: true)
        .limit(limit);

    final query = status != null 
        ? baseQuery.where('status', isEqualTo: status)
        : baseQuery;

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseOCRModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Update expense status
  static Future<void> updateExpenseStatus({
    required String userId,
    required String expenseId,
    required String newStatus,
    required String action,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'audit': FieldValue.arrayUnion([
        {
          'action': action,
          'at': FieldValue.serverTimestamp(),
          'by': userId,
        }
      ]),
    });
  }

  /// Update expense details
  static Future<void> updateExpenseDetails({
    required String userId,
    required String expenseId,
    required String merchant,
    required double amount,
    required String currency,
    required String date,
    String? notes,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .update({
      'merchant': merchant,
      'totalAmount': amount,
      'currency': currency,
      'date': date,
      'notes': notes,
      'status': 'pending', // Mark as pending approval after edit
      'updatedAt': FieldValue.serverTimestamp(),
      'editedBy': userId,
      'audit': FieldValue.arrayUnion([
        {
          'action': 'submitted',
          'at': FieldValue.serverTimestamp(),
          'by': userId,
        }
      ]),
    });
  }

  /// Approve an expense
  static Future<void> approveExpense({
    required String userId,
    required String expenseId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .update({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
      'audit': FieldValue.arrayUnion([
        {
          'action': 'approved',
          'at': FieldValue.serverTimestamp(),
          'by': userId,
        }
      ]),
    });
  }

  /// Reject an expense
  static Future<void> rejectExpense({
    required String userId,
    required String expenseId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
      'audit': FieldValue.arrayUnion([
        {
          'action': 'rejected',
          'at': FieldValue.serverTimestamp(),
          'by': userId,
        }
      ]),
    });
  }

  /// Delete an expense
  static Future<void> deleteExpense({
    required String userId,
    required String expenseId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  /// Get approval task for an expense
  static Future<ApprovalTask?> getApprovalTask({
    required String userId,
    required String expenseId,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .collection('approvals')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ApprovalTask.fromJson(snapshot.docs.first.data());
  }

  /// Stream approval task
  static Stream<ApprovalTask?> watchApprovalTask({
    required String userId,
    required String expenseId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .collection('approvals')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ApprovalTask.fromJson(snapshot.docs.first.data());
    });
  }

  /// Get statistics for user expenses
  static Future<ExpenseStatistics> getStatistics({
    required String userId,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .get();

    final expenses = snapshot.docs
        .map((doc) => ExpenseOCRModel.fromFirestore(doc))
        .toList();

    return ExpenseStatistics.fromList(expenses);
  }
}

/// Statistics about expenses
class ExpenseStatistics {
  final int totalCount;
  final int draftCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int paidCount;
  final double totalAmount;
  final Map<String, double> amountByStatus;
  final Map<String, int> countByStatus;

  ExpenseStatistics({
    required this.totalCount,
    required this.draftCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.paidCount,
    required this.totalAmount,
    required this.amountByStatus,
    required this.countByStatus,
  });

  /// Calculate statistics from list of expenses
  static ExpenseStatistics fromList(List<ExpenseOCRModel> expenses) {
    int draft = 0, pending = 0, approved = 0, rejected = 0, paid = 0;
    double total = 0;
    final amountByStatus = <String, double>{};
    final countByStatus = <String, int>{};

    for (final exp in expenses) {
      total += exp.totalAmount;

      // Count by status
      switch (exp.status) {
        case 'draft':
          draft++;
          break;
        case 'pending':
          pending++;
          break;
        case 'approved':
          approved++;
          break;
        case 'rejected':
          rejected++;
          break;
        case 'paid':
          paid++;
          break;
      }

      // Amount by status
      amountByStatus[exp.status] =
          (amountByStatus[exp.status] ?? 0) + exp.totalAmount;
      countByStatus[exp.status] = (countByStatus[exp.status] ?? 0) + 1;
    }

    return ExpenseStatistics(
      totalCount: expenses.length,
      draftCount: draft,
      pendingCount: pending,
      approvedCount: approved,
      rejectedCount: rejected,
      paidCount: paid,
      totalAmount: total,
      amountByStatus: amountByStatus,
      countByStatus: countByStatus,
    );
  }
}
