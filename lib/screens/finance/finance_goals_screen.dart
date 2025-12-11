import 'package:flutter/material.dart';
import '../../services/finance_goals_service.dart';
import '../../models/finance_goals_model.dart';
import '../../models/finance_alerts_model.dart';

class FinanceGoalsScreen extends StatefulWidget {
  const FinanceGoalsScreen({super.key});

  @override
  State<FinanceGoalsScreen> createState() => _FinanceGoalsScreenState();
}

class _FinanceGoalsScreenState extends State<FinanceGoalsScreen> {
  final _service = FinanceGoalsService();

  final _revCtrl = TextEditingController();
  final _marginCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _runwayCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _revCtrl.dispose();
    _marginCtrl.dispose();
    _expCtrl.dispose();
    _runwayCtrl.dispose();
    super.dispose();
  }

  void _fillFromGoals(FinanceGoals g) {
    _revCtrl.text = g.monthlyRevenueTarget.toStringAsFixed(0);
    _marginCtrl.text = g.profitMarginTarget.toStringAsFixed(1);
    _expCtrl.text = g.maxExpensesThisMonth.toStringAsFixed(0);
    _runwayCtrl.text = g.cashRunwayTargetDays.toStringAsFixed(0);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.saveGoals(
        monthlyRevenueTarget: double.tryParse(_revCtrl.text) ?? 0,
        profitMarginTarget: double.tryParse(_marginCtrl.text) ?? 0,
        maxExpensesThisMonth: double.tryParse(_expCtrl.text) ?? 0,
        cashRunwayTargetDays: double.tryParse(_runwayCtrl.text) ?? 0,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goals updated ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goals: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Goals & Alerts'),
      ),
      body: StreamBuilder<FinanceGoals?>(
        stream: _service.streamGoals(),
        builder: (context, goalsSnap) {
          final goals = goalsSnap.data;
          if (goals != null && _revCtrl.text.isEmpty) {
            // first time load
            _fillFromGoals(goals);
          }

          return StreamBuilder<FinanceAlerts?>(
            stream: _service.streamAlerts(),
            builder: (context, alertsSnap) {
              final alerts = alertsSnap.data;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (goals != null)
                    Text(
                      "Base currency: ${goals.currency}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildGoalsForm(goals),
                  const SizedBox(height: 20),
                  if (alerts != null) _buildAlertsSection(alerts),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        label: _saving
            ? const Text('Saving...')
            : const Text('Save Goals'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  Widget _buildGoalsForm(FinanceGoals? g) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Finance Goals",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _field("Monthly Revenue Target", _revCtrl,
                suffix: g?.currency ?? 'EUR'),
            const SizedBox(height: 10),
            _field("Profit Margin Target (%)", _marginCtrl, suffix: "%"),
            const SizedBox(height: 10),
            _field("Max Expenses (This Month)", _expCtrl,
                suffix: g?.currency ?? 'EUR'),
            const SizedBox(height: 10),
            _field("Cash Runway Target (Days)", _runwayCtrl),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? suffix}) {
    return TextField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildAlertsSection(FinanceAlerts alerts) {
    Color statusColor;
    String statusText;
    switch (alerts.status) {
      case 'danger':
        statusColor = Colors.red;
        statusText = "High Risk";
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusText = "Needs Attention";
        break;
      default:
        statusColor = Colors.green;
        statusText = "Healthy";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: Icon(Icons.shield, color: statusColor),
            title: Text(
              "Status: $statusText",
              style: TextStyle(
                  color: statusColor, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
                "Revenue vs target: ${alerts.revenuePctOfTarget.toStringAsFixed(1)}%\nProfit margin: ${alerts.margin.toStringAsFixed(1)}%"),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Alerts",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (alerts.alerts.isEmpty)
          const Text(
            "No alerts. You're on track ✅",
            style: TextStyle(color: Colors.green),
          )
        else
          ...alerts.alerts.map(
            (a) => Card(
              color: a.level == 'danger'
                  ? Colors.red.shade50
                  : a.level == 'warning'
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
              child: ListTile(
                leading: Icon(
                  a.level == 'danger'
                      ? Icons.warning_amber
                      : a.level == 'warning'
                          ? Icons.info
                          : Icons.check_circle,
                  color: a.level == 'danger'
                      ? Colors.red
                      : a.level == 'warning'
                          ? Colors.orange
                          : Colors.green,
                ),
                title: Text(a.message),
              ),
            ),
          ),
      ],
    );
  }
}
