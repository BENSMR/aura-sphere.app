import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../utils/logger.dart';

/// Service for monitoring specific expense document status changes
class ExpenseStatusMonitor {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Listen to a specific expense document for status changes
  /// Example: Watch for inventory_added status
  Stream<Expense?> streamExpenseStatus(String expenseId) {
    return _firestore
        .collection('expenses')
        .doc(expenseId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return Expense.fromJson(snapshot.data()!, expenseId);
        });
  }

  /// Listen to a specific expense and react to status changes
  /// Returns unsubscribe function
  Function() onExpenseStatusChanged({
    required String expenseId,
    required Function(String oldStatus, String newStatus) onStatusChange,
  }) {
    String? previousStatus;

    final unsubscribe = _firestore
        .collection('expenses')
        .doc(expenseId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final expense = Expense.fromJson(snapshot.data()!, expenseId);
      final currentStatus = expense.status;

      // Only trigger if status actually changed
      if (previousStatus != null && previousStatus != currentStatus) {
        logger.info('Expense status changed: $previousStatus → $currentStatus');
        onStatusChange(previousStatus!, currentStatus);
      }

      previousStatus = currentStatus;
    });

    // Return unsubscribe function
    return () {
      unsubscribe.cancel();
    };
  }

  /// Watch for specific status and trigger callback
  /// Example: Watch for inventory_added status
  Function() watchForStatus({
    required String expenseId,
    required String targetStatus,
    required Function(Expense) onStatusMatched,
  }) {
    return onExpenseStatusChanged(
      expenseId: expenseId,
      onStatusChange: (oldStatus, newStatus) {
        if (newStatus == targetStatus) {
          logger.info('Target status reached: $targetStatus');
          // Fetch full expense data
          _firestore
              .collection('expenses')
              .doc(expenseId)
              .get()
              .then((doc) {
            if (doc.exists) {
              final expense = Expense.fromJson(doc.data()!, expenseId);
              onStatusMatched(expense);
            }
          });
        }
      },
    );
  }

  /// Get success notification for inventory_added
  Stream<Map<String, dynamic>> streamInventorySuccessNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', isEqualTo: 'inventory_success')
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return {};
          return snapshot.docs.first.data();
        });
  }

  /// Get approval notifications
  Stream<List<Map<String, dynamic>>> streamApprovalNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', isEqualTo: 'expense_approved')
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Get rejection notifications
  Stream<List<Map<String, dynamic>>> streamRejectionNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', isEqualTo: 'expense_rejected')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Get payment notifications
  Stream<List<Map<String, dynamic>>> streamPaymentNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', isEqualTo: 'expense_paid')
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Get all status notifications (inventory, approval, rejection, payment)
  Stream<List<Map<String, dynamic>>> streamAllStatusNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', whereIn: [
          'inventory_success',
          'expense_approved',
          'expense_rejected',
          'expense_paid',
        ])
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(
    String notificationId, {
    bool isAlert = false,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    final collection = isAlert ? 'alerts' : 'notifications';

    await _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(notificationId)
        .update({'read': true});
  }

  /// Get expense by ID with real-time status updates
  Future<Expense?> getExpenseWithStatus(String expenseId) async {
    try {
      final doc = await _firestore.collection('expenses').doc(expenseId).get();
      if (!doc.exists) return null;
      return Expense.fromJson(doc.data()!, expenseId);
    } catch (e) {
      logger.error('Error fetching expense: $e');
      return null;
    }
  }

  /// Check if expense has inventory_added status
  Future<bool> isExpenseAddedToInventory(String expenseId) async {
    final expense = await getExpenseWithStatus(expenseId);
    return expense?.status == 'inventory_added';
  }

  /// Get count of expenses by status
  Future<Map<String, int>> getExpenseStatusCounts() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    final expenses = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .get();

    final counts = <String, int>{};
    for (var doc in expenses.docs) {
      final status = doc.data()['status'] as String? ?? 'pending_review';
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }
}
