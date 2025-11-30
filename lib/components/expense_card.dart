import 'package:flutter/material.dart';
import '../models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;

  const ExpenseCard({super.key, required this.expense, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.receipt),
        title: Text(expense.merchant),
        subtitle: Text(expense.category ?? 'Uncategorized'),
        trailing: Text('\$${expense.amount.toStringAsFixed(2)}'),
        onTap: onTap,
      ),
    );
  }
}
