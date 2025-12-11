import 'package:flutter/material.dart';

class FinanceAiCoachCard extends StatelessWidget {
  final String advice;

  const FinanceAiCoachCard({super.key, required this.advice});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.indigo),
                SizedBox(width: 6),
                Text(
                  "AI Financial Coach",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(advice),
          ],
        ),
      ),
    );
  }
}
