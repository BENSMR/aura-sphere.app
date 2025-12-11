import 'package:flutter/material.dart';
import '../../services/finance_dashboard_service.dart';
import '../../services/functions_service.dart';
import '../../models/finance_summary_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/firebase_config.dart';
import 'widgets/finance_kpi_charts.dart';
import 'widgets/finance_ai_coach_card.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  late FinanceDashboardService _service;
  late FunctionsService _functionsService;
  String? _aiAdvice;
  bool _loadingAdvice = false;

  @override
  void initState() {
    super.initState();
    _service = FinanceDashboardService();
    _functionsService = FunctionsService();
  }

  Future<void> _fetchFinanceAdvice() async {
    if (!mounted) return;
    setState(() => _loadingAdvice = true);
    try {
      final advice = await _functionsService.fetchFinanceAdvice();
      if (mounted) {
        setState(() {
          _aiAdvice = advice;
          _loadingAdvice = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAdvice = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching advice: $e')),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    // Simulate a refresh delay
    await Future.delayed(const Duration(milliseconds: 500));
    // StreamBuilder will automatically update when data changes
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _exportCsv() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
      }
      return;
    }

    try {
      // Use the configured Cloud Functions URL
      final functionsUrl = FirebaseConfig.exportFinanceSummaryUrl(userId);

      if (await canLaunchUrl(Uri.parse(functionsUrl))) {
        await launchUrl(Uri.parse(functionsUrl),
            mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV export started')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch export URL')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export as CSV',
            onPressed: _exportCsv,
          ),
        ],
      ),
      body: StreamBuilder<FinanceSummary?>(
        stream: _service.streamSummary(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snapshot.data;
          if (s == null) {
            return const Center(child: Text('No financial data yet.'));
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // KPI Charts Widget
                FinanceKpiCharts(summary: s),
                const SizedBox(height: 16),
                // Coach advice
                FinanceAiCoachCard(advice: _aiAdvice ?? "Tap the button to get AI advice"),
                const SizedBox(height: 12),
                // Refresh AI advice button
                ElevatedButton.icon(
                  onPressed: _loadingAdvice ? null : _fetchFinanceAdvice,
                  icon: const Icon(Icons.psychology),
                  label: _loadingAdvice
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text("Refresh AI Advice"),
                ),
                if (s.updatedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Last updated: ${s.updatedAt}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

}
