import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceAlertItem {
  final String type;
  final String level; // success | warning | danger
  final String message;

  FinanceAlertItem({
    required this.type,
    required this.level,
    required this.message,
  });

  factory FinanceAlertItem.fromMap(Map<String, dynamic> map) {
    return FinanceAlertItem(
      type: map['type'] ?? 'generic',
      level: map['level'] ?? 'warning',
      message: map['message'] ?? '',
    );
  }
}

class FinanceAlerts {
  final String status; // ok | warning | danger
  final double revenuePctOfTarget;
  final double margin;
  final double expensesThisMonth;
  final double? runwayDaysEstimate;
  final List<FinanceAlertItem> alerts;
  final DateTime? updatedAt;

  FinanceAlerts({
    required this.status,
    required this.revenuePctOfTarget,
    required this.margin,
    required this.expensesThisMonth,
    required this.runwayDaysEstimate,
    required this.alerts,
    this.updatedAt,
  });

  factory FinanceAlerts.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawAlerts = (data['alerts'] as List<dynamic>? ?? [])
        .map((e) => FinanceAlertItem.fromMap(e as Map<String, dynamic>))
        .toList();

    return FinanceAlerts(
      status: data['status'] ?? 'ok',
      revenuePctOfTarget:
          (data['revenuePctOfTarget'] ?? 0).toDouble(),
      margin: (data['margin'] ?? 0).toDouble(),
      expensesThisMonth:
          (data['expensesThisMonth'] ?? 0).toDouble(),
      runwayDaysEstimate:
          data['runwayDaysEstimate'] != null
              ? (data['runwayDaysEstimate'] as num).toDouble()
              : null,
      alerts: rawAlerts,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
