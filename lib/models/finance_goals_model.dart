import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceGoals {
  final double monthlyRevenueTarget;
  final double profitMarginTarget;
  final double maxExpensesThisMonth;
  final double cashRunwayTargetDays;
  final String currency;
  final DateTime? updatedAt;

  FinanceGoals({
    required this.monthlyRevenueTarget,
    required this.profitMarginTarget,
    required this.maxExpensesThisMonth,
    required this.cashRunwayTargetDays,
    required this.currency,
    this.updatedAt,
  });

  factory FinanceGoals.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FinanceGoals(
      monthlyRevenueTarget:
          (data['monthlyRevenueTarget'] ?? 0).toDouble(),
      profitMarginTarget:
          (data['profitMarginTarget'] ?? 0).toDouble(),
      maxExpensesThisMonth:
          (data['maxExpensesThisMonth'] ?? 0).toDouble(),
      cashRunwayTargetDays:
          (data['cashRunwayTargetDays'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'EUR',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
