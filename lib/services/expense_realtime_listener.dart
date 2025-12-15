import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../utils/logger.dart';

/// Real-time expense listener for alerts and notifications
class ExpenseRealtimeListener {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Listen to all user's expenses in real-time
  /// Triggers callback on new expenses, updates, and deletions
  Stream<List<Expense>> streamUserExpenses() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Expense.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  /// Listen to expenses with a callback for changes
  /// Returns unsubscribe function
  Function() onExpenseChange({
    required Function(Expense) onAdded,
    required Function(Expense) onModified,
    required Function(Expense) onRemoved,
  }) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    // Subscribe to real-time updates
    final unsubscribe = _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      // Process changes from snapshot
      for (var change in snapshot.docChanges()) {
        final expense = Expense.fromJson(change.doc.data(), change.doc.id);

        switch (change.type) {
          case DocumentChangeType.added:
            logger.info('Expense added: ${change.doc.id}');
            onAdded(expense);
            break;

          case DocumentChangeType.modified:
            logger.info('Expense modified: ${change.doc.id}');
            onModified(expense);
            break;

          case DocumentChangeType.removed:
            logger.info('Expense removed: ${change.doc.id}');
            onRemoved(expense);
            break;
        }
      }
    });

    // Return unsubscribe function
    return () {
      unsubscribe.cancel();
    };
  }

  /// Listen to alerts for new expenses
  Stream<Map<String, dynamic>> streamExpenseAlerts() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .where('type', isEqualTo: 'expense_created')
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          // Return alerts as list of maps
          return snapshot.docs.isNotEmpty
              ? snapshot.docs.first.data()
              : {};
        });
  }

  /// Listen to high-value expense notifications
  Stream<List<Map<String, dynamic>>> streamHighValueAlerts() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', isEqualTo: 'high_value_expense')
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Mark alert as read
  Future<void> markAlertAsRead(String alertId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .doc(alertId)
        .update({'read': true});
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Get user's expense statistics in real-time
  Stream<Map<String, dynamic>> streamExpenseStats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data() ?? {};
          return data['expenseStats'] ?? {};
        });
  }

  /// Get specific expense updates in real-time
  Stream<Expense?> streamExpense(String expenseId) {
    return _firestore
        .collection('expenses')
        .doc(expenseId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return Expense.fromJson(snapshot.data()!, expenseId);
        });
  }

  /// Listen to expense status changes
  Stream<List<Expense>> streamExpensesByStatus(String status) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Expense.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  /// Initialize real-time listener for new expense alerts
  /// Call this when user logs in or app starts
  void initializeExpenseAlerts({
    required Function(Map<String, dynamic>) onNewAlert,
  }) {
    streamExpenseAlerts().listen((alert) {
      if (alert.isNotEmpty) {
        logger.info('New expense alert received');
        onNewAlert(alert);
      }
    });
  }

  /// Initialize high-value expense listener
  /// Triggered for expenses > $100
  void initializeHighValueAlerts({
    required Function(List<Map<String, dynamic>>) onHighValueAlert,
  }) {
    streamHighValueAlerts().listen((alerts) {
      if (alerts.isNotEmpty) {
        logger.info('High-value expense alert received');
        onHighValueAlert(alerts);
      }
    });
  }
}
