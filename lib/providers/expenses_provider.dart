import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

/// Provider for managing expense state
class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _service = ExpenseService();

  List<Expense> _expenses = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Expense> get expenses => _expenses;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get expenseCount => _expenses.length;
  double get totalAmount => _expenses.fold(0, (sum, e) => sum + e.amount);

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

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
