import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/finance_summary_model.dart';

class FinanceKpiCharts extends StatelessWidget {
  final FinanceSummary summary;

  const FinanceKpiCharts({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _revenueExpenseChart(),
        const SizedBox(height: 16),
        _profitHealthRow(),
        const SizedBox(height: 16),
        _invoiceHealthBar(),
      ],
    );
  }

  Widget _revenueExpenseChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Revenue vs Expenses (30 Days)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(
                        toY: summary.revenueLast30,
                        color: Colors.green,
                        width: 22,
                      )
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(
                        toY: summary.expensesLast30,
                        color: Colors.red,
                        width: 22,
                      )
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _LegendDot(color: Colors.green, label: "Revenue"),
                _LegendDot(color: Colors.red, label: "Expenses"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _profitHealthRow() {
    final profit = summary.profitThisMonth;
    final isPositive = profit >= 0;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            "Profit",
            "${profit.toStringAsFixed(2)} ${summary.currency}",
            isPositive ? Colors.green : Colors.red,
            isPositive ? Icons.trending_up : Icons.trending_down,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            "Margin",
            "${summary.profitMarginThisMonth.toStringAsFixed(1)} %",
            Colors.blue,
            Icons.percent,
          ),
        ),
      ],
    );
  }

  Widget _invoiceHealthBar() {
    final unpaid = summary.unpaidInvoicesAmount;
    final overdue = summary.overdueInvoicesAmount;
    final total = unpaid + overdue;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Invoice Health",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: total == 0 ? 0 : unpaid / total,
              backgroundColor: Colors.red.shade200,
              color: Colors.orange,
              minHeight: 12,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Unpaid: ${unpaid.toStringAsFixed(2)}"),
                Text("Overdue: ${overdue.toStringAsFixed(2)}"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 6),
                Text(title),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
