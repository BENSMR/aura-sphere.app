import 'package:flutter/material.dart';

class ExpenseScannerScreen extends StatelessWidget {
  const ExpenseScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: const Center(
        child: Text('Expense Scanner - TODO: Implement camera scanning'),
      ),
    );
  }
}
