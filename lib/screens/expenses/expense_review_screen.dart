import 'package:flutter/material.dart';

class ExpenseReviewScreen extends StatelessWidget {
  const ExpenseReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Expense')),
      body: const Center(
        child: Text('Expense Review - TODO: Implement expense details'),
      ),
    );
  }
}
