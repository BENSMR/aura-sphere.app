import 'package:flutter/material.dart';

class ExpenseHistoryScreen extends StatelessWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense History')),
      body: const Center(
        child: Text('Expense History - TODO: Implement expense list'),
      ),
    );
  }
}
