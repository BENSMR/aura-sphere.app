import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../utils/logger.dart';

/// Service for managing expenses in Firestore
class ExpenseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new expense to Firestore
  Future<String> addExpense({
    required double amount,
    required String vendor,
    required List<String> items,
    String? category,
    String? description,
    String? receiptUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final docRef = await _firestore.collection('expenses').add({
        'userId': user.uid,
        'amount': amount,
        'vendor': vendor,
        'items': items,
        'category': category,
        'description': description,
        'receiptUrl': receiptUrl,
        'status': 'pending_review',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.info('Expense added', {
        'userId': user.uid,
        'expenseId': docRef.id,
        'amount': amount,
      });

      return docRef.id;
    } catch (e) {
      logger.error('Error adding expense', {'error': e.toString()});
      rethrow;
    }
  }

  /// Get all expenses for current user
  Future<List<Expense>> getUserExpenses({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      var query = _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map((doc) => Expense.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      logger.error('Error fetching expenses', {'error': e.toString()});
      return [];
    }
  }

  /// Get a single expense by ID
  Future<Expense?> getExpense(String expenseId) async {
    try {
      final doc = await _firestore.collection('expenses').doc(expenseId).get();

      if (!doc.exists) return null;

      return Expense.fromJson(doc.data()!, expenseId);
    } catch (e) {
      logger.error('Error fetching expense', {
        'expenseId': expenseId,
        'error': e.toString(),
      });
      return null;
    }
  }

  /// Update an expense
  Future<void> updateExpense(
    String expenseId, {
    double? amount,
    String? vendor,
    List<String>? items,
    String? category,
    String? description,
    String? receiptUrl,
    String? status,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify ownership
      final doc = await _firestore.collection('expenses').doc(expenseId).get();
      if (doc.data()?['userId'] != user.uid) {
        throw Exception('Unauthorized: Not your expense');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (amount != null) updateData['amount'] = amount;
      if (vendor != null) updateData['vendor'] = vendor;
      if (items != null) updateData['items'] = items;
      if (category != null) updateData['category'] = category;
      if (description != null) updateData['description'] = description;
      if (receiptUrl != null) updateData['receiptUrl'] = receiptUrl;
      if (status != null) updateData['status'] = status;

      await _firestore
          .collection('expenses')
          .doc(expenseId)
          .update(updateData);

      logger.info('Expense updated', {'expenseId': expenseId});
    } catch (e) {
      logger.error('Error updating expense', {
        'expenseId': expenseId,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify ownership
      final doc = await _firestore.collection('expenses').doc(expenseId).get();
      if (doc.data()?['userId'] != user.uid) {
        throw Exception('Unauthorized: Not your expense');
      }

      await _firestore.collection('expenses').doc(expenseId).delete();

      logger.info('Expense deleted', {'expenseId': expenseId});
    } catch (e) {
      logger.error('Error deleting expense', {
        'expenseId': expenseId,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Get total expenses for user (optional: filtered by status and date)
  Future<double> getTotalExpenses({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final expenses =
          await getUserExpenses(status: status, startDate: startDate, endDate: endDate);
      double total = 0.0;
      for (final expense in expenses) {
        total += expense.amount;
      }
      return total;
    } catch (e) {
      logger.error('Error calculating total', {'error': e.toString()});
      return 0.0;
    }
  }

  /// Get expense statistics
  Future<Map<String, dynamic>> getExpenseStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final expenses = await getUserExpenses();

      final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final approved =
          expenses.where((e) => e.status == 'approved').fold(0.0, (sum, e) => sum + e.amount);
      final pending = expenses.where((e) => e.status == 'pending_review').length;
      final byCategory = <String, double>{};

      for (final expense in expenses) {
        final category = expense.category ?? 'uncategorized';
        byCategory[category] = (byCategory[category] ?? 0) + expense.amount;
      }

      return {
        'total': total,
        'approved': approved,
        'pending': pending,
        'count': expenses.length,
        'byCategory': byCategory,
      };
    } catch (e) {
      logger.error('Error getting stats', {'error': e.toString()});
      return {};
    }
  }

  /// Stream expenses for real-time updates
  Stream<List<Expense>> streamUserExpenses() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromJson(doc.data(), doc.id))
            .toList())
        .handleError((e) {
          logger.error('Error streaming expenses', {'error': e.toString()});
          return <Expense>[];
        });
  }
}
