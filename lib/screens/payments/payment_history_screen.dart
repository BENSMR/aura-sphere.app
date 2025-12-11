import 'package:flutter/material.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('Payment History Screen'),
            SizedBox(height: 8),
            Text('This feature is under development'),
          ],
        ),
      ),
    );
  }
}

/// Payment record model
class PaymentRecord {
  final String invoiceId;
  final double amount;
  final String status;
  final DateTime timestamp;
  final String? paymentMethod;
  final String? transactionId;

  PaymentRecord({
    required this.invoiceId,
    required this.amount,
    required this.status,
    required this.timestamp,
    this.paymentMethod,
    this.transactionId,
  });
}
