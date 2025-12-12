// lib/screens/ai/finance_coach_screen.dart
import 'package:flutter/material.dart';
import '../../services/finance_coach_service.dart';
import '../../components/ai/ai_cost_confirmation_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinanceCoachScreen extends StatefulWidget {
  const FinanceCoachScreen({Key? key}) : super(key: key);

  @override
  State<FinanceCoachScreen> createState() => _FinanceCoachScreenState();
}

class _FinanceCoachScreenState extends State<FinanceCoachScreen> {
  final _svc = FinanceCoachService();
  Map<String, dynamic>? _coach;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  void _subscribe() {
    _svc.streamLastCoach().listen((snap) {
      if (snap.exists) {
        setState(() => _coach = snap.data());
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getCoach();
    setState(() {
      _coach = data;
      _loading = false;
    });
  }

  /// Shows cost preview and asks for confirmation before running AI.
  Future<void> _askAndRunCoach() async {
    final costInfo = await _svc.getCoachCost();

    // If cost lookup fails, fall back to direct call
    if (costInfo == null) {
      await _load();
      return;
    }

    final cost = costInfo['cost'] as int? ?? 5;
    final balance = costInfo['balance'] as int? ?? 0;
    final plan = costInfo['plan'] as String? ?? 'free';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AICostConfirmationDialog(
        cost: cost,
        balance: balance,
        plan: plan,
      ),
    );

    if (confirmed == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Finance Coach')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_coach == null) {
      return const Center(child: Text('No coach data yet. Tap refresh.'));
    }

    final summary = _coach!['summary'] as Map<String, dynamic>?;
    final deterministic = _coach!['deterministic'] as Map<String, dynamic>?;
    final ai = _coach!['aiNarrative'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView(
        children: [
          Card(
            child: ListTile(
              title: Text('Current balance: \$${(summary?['currentBalance'] ?? 0).toStringAsFixed(2)}'),
              subtitle: Text('Runway: ${summary?['runwayDays'] ?? '—'} days'),
            ),
          ),
          const SizedBox(height: 12),
          if (ai != null && ai['headline'] != null)
            Card(
              child: ListTile(
                title: Text(ai['headline'] as String),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...List<String>.from(deterministic?['advice'] ?? []).map((a) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Text('• $a'),
                    );
                  }),
                  const Divider(),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List<Map<String, dynamic>>.from(deterministic?['actions'] ?? [])
                        .map<Widget>((act) {
                      return ElevatedButton(
                        onPressed: () => _handleAction(act['action'] as String?),
                        child: Text(act['label'] as String? ?? act['action'] as String? ?? 'Action'),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Coach'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _askAndRunCoach,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Run AI Coach (Preview cost)'),
          ),
        ],
      ),
    );
  }

  void _handleAction(String? action) {
    if (action == null) return;
    if (action == 'send_reminder') {
      Navigator.pushNamed(context, '/invoices');
    } else if (action == 'review_expenses') {
      Navigator.pushNamed(context, '/expenses');
    } else if (action == 'explore_finance') {
      Navigator.pushNamed(context, '/billing');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action triggered: $action')),
      );
    }
  }
}
