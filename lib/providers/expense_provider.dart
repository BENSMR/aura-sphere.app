import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/expense_model.dart';
import '../services/firestore_service.dart';

class ExpenseProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _filteredExpenses = [];
  ExpenseModel? _selectedExpense;
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;

  // Getters
  List<ExpenseModel> get expenses => _expenses;
  List<ExpenseModel> get filteredExpenses =>
      _filteredExpenses.isEmpty ? _expenses : _filteredExpenses;
  ExpenseModel? get selectedExpense => _selectedExpense;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  /// Load all expenses for current user
  Future<void> loadExpenses() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .orderBy('createdAt', descending: true)
          .get();

      _expenses = snapshot.docs.map((doc) => ExpenseModel.fromDoc(doc)).toList();
      _filteredExpenses = [];
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new expense
  Future<void> addExpense(ExpenseModel expense) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(expense.id)
          .set(expense.toMap());

      _expenses.insert(0, expense);
      _filteredExpenses = [];
    } catch (e) {
      debugPrint('Error adding expense: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update existing expense
  Future<void> updateExpense(ExpenseModel expense) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updated =
          expense.copyWith(updatedAt: DateTime.now());

      await _db
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(expense.id)
          .update(updated.toMap());

      final idx = _expenses.indexWhere((e) => e.id == expense.id);
      if (idx >= 0) {
        _expenses[idx] = updated;
      }
      _filteredExpenses = [];
      _selectedExpense = updated;
    } catch (e) {
      debugPrint('Error updating expense: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete expense
  Future<void> deleteExpense(String expenseId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(expenseId)
          .delete();

      _expenses.removeWhere((e) => e.id == expenseId);
      _filteredExpenses = [];
      if (_selectedExpense?.id == expenseId) {
        _selectedExpense = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting expense: $e');
    }
  }

  /// Select expense for viewing details
  void selectExpense(ExpenseModel expense) {
    _selectedExpense = expense;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedExpense = null;
    notifyListeners();
  }

  /// Search expenses by merchant or notes
  void searchExpenses(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredExpenses = [];
    } else {
      _filteredExpenses = _expenses
          .where((e) =>
              e.merchant.toLowerCase().contains(query.toLowerCase()) ||
              (e.notes?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    }
    notifyListeners();
  }

  /// Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    if (category == null) {
      _filteredExpenses = [];
    } else {
      _filteredExpenses = _expenses
          .where((e) => e.category?.toLowerCase() == category.toLowerCase())
          .toList();
    }
    notifyListeners();
  }

  /// Get expenses by date range
  List<ExpenseModel> getExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses.where((e) {
      if (e.date == null) return false;
      return e.date!.isAfter(start) && e.date!.isBefore(end);
    }).toList();
  }

  /// Get unlinked expenses (not attached to invoice)
  List<ExpenseModel> getUnlinkedExpenses() {
    return _expenses.where((e) => e.invoiceId == null).toList();
  }

  /// Attach expense to invoice
  Future<void> attachToInvoice(String expenseId, String invoiceId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(expenseId)
          .update({
        'invoiceId': invoiceId,
        'updatedAt': Timestamp.now(),
      });

      final idx = _expenses.indexWhere((e) => e.id == expenseId);
      if (idx >= 0) {
        _expenses[idx] =
            _expenses[idx].copyWith(invoiceId: invoiceId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error attaching expense to invoice: $e');
    }
  }

  /// Detach expense from invoice
  Future<void> detachFromInvoice(String expenseId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(expenseId)
          .update({
        'invoiceId': null,
        'updatedAt': Timestamp.now(),
      });

      final idx = _expenses.indexWhere((e) => e.id == expenseId);
      if (idx >= 0) {
        _expenses[idx] = _expenses[idx].copyWith(invoiceId: null);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error detaching expense from invoice: $e');
    }
  }

  /// Get expenses linked to specific invoice
  List<ExpenseModel> getExpensesForInvoice(String invoiceId) {
    return _expenses.where((e) => e.invoiceId == invoiceId).toList();
  }

  /// Calculate total for unlinked expenses
  double getTotalUnlinked() {
    return getUnlinkedExpenses()
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Calculate total for linked expenses
  double getTotalLinked() {
    return _expenses
        .where((e) => e.invoiceId != null)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Get all categories from expenses
  List<String> getAllCategories() {
    final categories = _expenses
        .where((e) => e.category != null)
        .map((e) => e.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
}
