import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';

/// Service for managing expenses in Supabase
class ExpenseService {
  final _supabase = Supabase.instance.client;

  /// Get single expense by ID
  Future<Expense> getExpense(String expenseId) async {
    final data = await _supabase
        .from('expenses')
        .select()
        .eq('id', expenseId)
        .single();

    return Expense.fromJson(data);
  }

  /// Get all expenses for a user
  Future<List<Expense>> getUserExpenses(String userId) async {
    final data = await _supabase
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => Expense.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Watch expenses in real-time
  Stream<List<Expense>> watchExpenses(String userId) {
    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((list) => list
            .map((json) => Expense.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  /// Get expenses by status
  Future<List<Expense>> getExpensesByStatus(String userId, String status) async {
    final data = await _supabase
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .eq('status', status)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => Expense.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get expenses by category
  Future<List<Expense>> getExpensesByCategory(
    String userId,
    String category,
  ) async {
    final data = await _supabase
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .eq('category', category)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => Expense.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create new expense
  Future<Expense> createExpense({
    required String userId,
    required double amount,
    required String vendor,
    required List<String> items,
    required String currency,
    String? category,
    String? description,
    String? receiptUrl,
  }) async {
    if (amount <= 0 || amount > 100000) {
      throw Exception('Amount must be between $0.01 and $100,000');
    }
    if (vendor.length < 2 || vendor.length > 100) {
      throw Exception('Vendor name must be 2-100 characters');
    }
    if (items.isEmpty || items.length > 20) {
      throw Exception('Items must be 1-20');
    }

    final expenseData = {
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'vendor': vendor,
      'category': category,
      'description': description,
      'receipt_url': receiptUrl,
      'items': items, // PostgreSQL array type
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final result =
        await _supabase.from('expenses').insert(expenseData).select().single();

    return Expense.fromJson(result);
  }

  /// Update expense
  Future<void> updateExpense({
    required String expenseId,
    double? amount,
    String? vendor,
    List<String>? items,
    String? category,
    String? description,
    String? receiptUrl,
    String? notes,
  }) async {
    final update = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (amount != null) update['amount'] = amount;
    if (vendor != null) update['vendor'] = vendor;
    if (items != null) update['items'] = items;
    if (category != null) update['category'] = category;
    if (description != null) update['description'] = description;
    if (receiptUrl != null) update['receipt_url'] = receiptUrl;
    if (notes != null) update['notes'] = notes;

    await _supabase
        .from('expenses')
        .update(update)
        .eq('id', expenseId);
  }

  /// Approve expense
  Future<void> approveExpense(String expenseId) async {
    await _supabase
        .from('expenses')
        .update({
          'status': 'approved',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', expenseId);
  }

  /// Reject expense
  Future<void> rejectExpense(String expenseId) async {
    await _supabase
        .from('expenses')
        .update({
          'status': 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', expenseId);
  }

  /// Mark expense as reimbursed
  Future<void> markAsReimbursed(String expenseId) async {
    await _supabase
        .from('expenses')
        .update({
          'status': 'reimbursed',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', expenseId);
  }

  /// Delete expense
  Future<void> deleteExpense(String expenseId) async {
    await _supabase
        .from('expenses')
        .delete()
        .eq('id', expenseId);
  }

  /// Get total expenses for a period
  Future<double> getTotalExpensesForPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? category,
  }) async {
    final start = startDate.toIso8601String();
    final end = endDate.toIso8601String();

    var query = _supabase
        .from('expenses')
        .select('amount')
        .eq('user_id', userId)
        .eq('status', 'approved')
        .gte('created_at', start)
        .lte('created_at', end);

    if (category != null) {
      query = query.eq('category', category);
    }

    final data = await query;
    final total = (data as List).fold<double>(
      0.0,
      (sum, json) => sum + (json['amount'] as num).toDouble(),
    );

    return total;
  }

  /// Get expenses pending approval
  Future<List<Expense>> getPendingExpenses(String userId) async {
    final data = await _supabase
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: true);

    return (data as List)
        .map((json) => Expense.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get category breakdown
  Future<Map<String, double>> getExpensesByCategory(String userId) async {
    final data = await _supabase
        .from('expenses')
        .select('category, amount')
        .eq('user_id', userId)
        .eq('status', 'approved');

    final breakdown = <String, double>{};
    for (final expense in data as List) {
      final category = expense['category'] as String? ?? 'other';
      final amount = (expense['amount'] as num).toDouble();
      breakdown[category] = (breakdown[category] ?? 0) + amount;
    }

    return breakdown;
  }
}
