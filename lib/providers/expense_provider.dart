import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/firestore_service.dart';

class ExpenseProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;

  Future<void> loadExpenses(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.getCollection('expenses');
      _expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _firestore.setDocument('expenses', expense.id, expense.toJson());
    _expenses.add(expense);
    notifyListeners();
  }
}
