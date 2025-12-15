import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/expense_realtime_listener.dart';
import '../services/expense_status_monitor.dart';

/// Provider for managing expense state
class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _service = ExpenseService();
  final ExpenseRealtimeListener _realtimeListener = ExpenseRealtimeListener();
  final ExpenseStatusMonitor _statusMonitor = ExpenseStatusMonitor();

  List<Expense> _expenses = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _lastAlert = {};
  List<Map<String, dynamic>> _highValueAlerts = [];
  Map<String, int> _statusCounts = {};

  // Getters
  List<Expense> get expenses => _expenses;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get expenseCount => _expenses.length;
  double get totalAmount => _expenses.fold(0, (sum, e) => sum + e.amount);
  Map<String, dynamic> get lastAlert => _lastAlert;
  List<Map<String, dynamic>> get highValueAlerts => _highValueAlerts;
  Map<String, int> get statusCounts => _statusCounts;

  /// Load all expenses for current user
  Future<void> loadExpenses({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await _service.getUserExpenses(status: status);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load expense statistics
  Future<void> loadStats() async {
    try {
      _stats = await _service.getExpenseStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Add a new expense
  Future<String?> addExpense({
    required double amount,
    required String vendor,
    required List<String> items,
    String? category,
    String? description,
    String? receiptUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final expenseId = await _service.addExpense(
        amount: amount,
        vendor: vendor,
        items: items,
        category: category,
        description: description,
        receiptUrl: receiptUrl,
      );

      // Reload expenses
      await loadExpenses();
      await loadStats();

      return expenseId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update an expense
  Future<bool> updateExpense(
    String expenseId, {
    double? amount,
    String? vendor,
    List<String>? items,
    String? category,
    String? description,
    String? receiptUrl,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateExpense(
        expenseId,
        amount: amount,
        vendor: vendor,
        items: items,
        category: category,
        description: description,
        receiptUrl: receiptUrl,
        status: status,
      );

      // Reload expenses
      await loadExpenses();
      await loadStats();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete an expense
  Future<bool> deleteExpense(String expenseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteExpense(expenseId);

      // Reload expenses
      await loadExpenses();
      await loadStats();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get expense by ID
  Future<Expense?> getExpense(String expenseId) async {
    try {
      return await _service.getExpense(expenseId);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  /// Filter expenses by status
  List<Expense> getExpensesByStatus(String status) {
    return _expenses.where((e) => e.status == status).toList();
  }

  /// Filter expenses by category
  List<Expense> getExpensesByCategory(String category) {
    return _expenses.where((e) => e.category == category).toList();
  }

  /// Search expenses
  List<Expense> searchExpenses(String query) {
    final lower = query.toLowerCase();
    return _expenses
        .where((e) =>
            e.vendor.toLowerCase().contains(lower) ||
            e.items.any((item) => item.toLowerCase().contains(lower)) ||
            e.description?.toLowerCase().contains(lower) == true)
        .toList();
  }

  /// Initialize real-time listeners for alerts and notifications
  void initializeRealtimeListeners() {
    _realtimeListener.initializeExpenseAlerts(
      onNewAlert: (alert) {
        _lastAlert = alert;
        notifyListeners();
      },
    );

    _realtimeListener.initializeHighValueAlerts(
      onHighValueAlert: (alerts) {
        _highValueAlerts = alerts;
        notifyListeners();
      },
    );
  }

  /// Stream expenses in real-time
  Stream<List<Expense>> getExpenseStream() {
    return _realtimeListener.streamUserExpenses();
  }

  /// Stream expense statistics in real-time
  Stream<Map<String, dynamic>> getStatsStream() {
    return _realtimeListener.streamExpenseStats();
  }

  /// Listen to expenses by status in real-time
  Stream<List<Expense>> getExpensesByStatusStream(String status) {
    return _realtimeListener.streamExpensesByStatus(status);
  }

  /// Watch specific expense status changes
  /// Example: Watch for inventory_added status
  Function() watchExpenseStatus(
    String expenseId, {
    required Function(String oldStatus, String newStatus) onStatusChange,
  }) {
    return _statusMonitor.onExpenseStatusChanged(
      expenseId: expenseId,
      onStatusChange: onStatusChange,
    );
  }

  /// Watch for specific status and trigger callback
  /// Example: watchForStatus('exp123', targetStatus: 'inventory_added')
  Function() watchForStatus(
    String expenseId, {
    required String targetStatus,
    required Function(Expense) onStatusMatched,
  }) {
    return _statusMonitor.watchForStatus(
      expenseId: expenseId,
      targetStatus: targetStatus,
      onStatusMatched: onStatusMatched,
    );
  }

  /// Stream inventory success notifications
  Stream<Map<String, dynamic>> streamInventorySuccessNotifications() {
    return _statusMonitor.streamInventorySuccessNotifications();
  }

  /// Stream all status notifications
  Stream<List<Map<String, dynamic>>> streamAllStatusNotifications() {
    return _statusMonitor.streamAllStatusNotifications();
  }

  /// Get expense status counts
  Future<void> loadStatusCounts() async {
    try {
      _statusCounts = await _statusMonitor.getExpenseStatusCounts();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Check if expense is in inventory
  Future<bool> isExpenseInInventory(String expenseId) async {
    return _statusMonitor.isExpenseAddedToInventory(expenseId);
  }

  /// Get high-value alerts (expenses > $100)
  List<Map<String, dynamic>> getHighValueAlerts() {
    return _highValueAlerts;
  }

  /// Get last alert received
  Map<String, dynamic> getLastAlert() {
    return _lastAlert;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

