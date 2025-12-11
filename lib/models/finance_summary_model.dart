// lib/models/finance_summary_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceSummary {
  final double revenueTotal;
  final double revenueThisMonth;
  final double revenueLast30;

  final double expensesTotal;
  final double expensesThisMonth;
  final double expensesLast30;

  final double profitThisMonth;
  final double profitLast30;

  final int unpaidInvoicesCount;
  final double unpaidInvoicesAmount;
  final int overdueInvoicesCount;
  final double overdueInvoicesAmount;

  final double taxEstimateThisMonth;
  final double profitMarginThisMonth;
  final DateTime? updatedAt;
  final String currency;

  FinanceSummary({
    required this.revenueTotal,
    required this.revenueThisMonth,
    required this.revenueLast30,
    required this.expensesTotal,
    required this.expensesThisMonth,
    required this.expensesLast30,
    required this.profitThisMonth,
    required this.profitLast30,
    required this.unpaidInvoicesCount,
    required this.unpaidInvoicesAmount,
    required this.overdueInvoicesCount,
    required this.overdueInvoicesAmount,
    required this.taxEstimateThisMonth,
    required this.profitMarginThisMonth,
    required this.currency,
    this.updatedAt,
  });

  factory FinanceSummary.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FinanceSummary(
      revenueTotal: (data['revenueTotal'] ?? 0).toDouble(),
      revenueThisMonth: (data['revenueThisMonth'] ?? 0).toDouble(),
      revenueLast30: (data['revenueLast30'] ?? 0).toDouble(),
      expensesTotal: (data['expensesTotal'] ?? 0).toDouble(),
      expensesThisMonth: (data['expensesThisMonth'] ?? 0).toDouble(),
      expensesLast30: (data['expensesLast30'] ?? 0).toDouble(),
      profitThisMonth: (data['profitThisMonth'] ?? 0).toDouble(),
      profitLast30: (data['profitLast30'] ?? 0).toDouble(),
      unpaidInvoicesCount: (data['unpaidInvoicesCount'] ?? 0).toInt(),
      unpaidInvoicesAmount:
          (data['unpaidInvoicesAmount'] ?? 0).toDouble(),
      overdueInvoicesCount: (data['overdueInvoicesCount'] ?? 0).toInt(),
      overdueInvoicesAmount:
          (data['overdueInvoicesAmount'] ?? 0).toDouble(),
      taxEstimateThisMonth:
          (data['taxEstimateThisMonth'] ?? 0).toDouble(),
      profitMarginThisMonth:
          (data['profitMarginThisMonth'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'EUR',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
