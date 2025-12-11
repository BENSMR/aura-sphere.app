import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnomalyInsightsWidget extends StatefulWidget {
  final int days;
  final String? filterBySeverity;

  const AnomalyInsightsWidget({
    super.key,
    this.days = 7,
    this.filterBySeverity,
  });

  @override
  State<AnomalyInsightsWidget> createState() => _AnomalyInsightsWidgetState();
}

class _AnomalyInsightsWidgetState extends State<AnomalyInsightsWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AnomalyInsight>> _fetchInsights() async {
    try {
      final snapshot = await _firestore
          .collection('analytics')
          .doc('anomaly_insights')
          .collection('daily')
          .orderBy('date', descending: true)
          .limit(widget.days)
          .get();

      List<AnomalyInsight> allInsights = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['insights'] is List) {
          for (final insight in data['insights']) {
            allInsights.add(AnomalyInsight.fromMap(insight));
          }
        }
      }

      // Filter by severity if requested
      if (widget.filterBySeverity != null) {
        allInsights = allInsights
            .where((i) => i.severity == widget.filterBySeverity)
            .toList();
      }

      // Sort by severity
      final severityOrder = {
        'critical': 0,
        'high': 1,
        'medium': 2,
        'low': 3,
      };
      allInsights.sort((a, b) =>
          (severityOrder[a.severity] ?? 99)
              .compareTo(severityOrder[b.severity] ?? 99));

      return allInsights;
    } catch (e) {
      print('Error fetching anomaly insights: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AnomalyInsight>>(
      future: _fetchInsights(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No insights yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Insights are generated daily at 6 AM UTC',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        final insights = snapshot.data!;
        return ListView.builder(
          itemCount: insights.length,
          itemBuilder: (context, index) {
            return _buildInsightCard(context, insights[index]);
          },
        );
      },
    );
  }

  Widget _buildInsightCard(BuildContext context, AnomalyInsight insight) {
    final severityColor = _getSeverityColor(insight.severity);
    final severityIcon = _getSeverityIcon(insight.severity);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with severity badge
            Row(
              children: [
                // Severity icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    severityIcon,
                    color: severityColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and severity badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: severityColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              insight.severity.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: severityColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${insight.percentage}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              insight.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            // Metadata row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Affected: ${insight.affectedCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                Text(
                  insight.timeWindow,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                ),
                Text(
                  insight.type.replaceAll('_', ' ').toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
            // Sample IDs if available
            if (insight.samplesIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample anomalies:',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: insight.samplesIds.take(3).map((id) {
                        return Chip(
                          label: Text(
                            id.substring(0, 8),
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.amber.shade700;
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.blue;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.emergency;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }
}

class AnomalyInsight {
  final String title;
  final String description;
  final String severity; // low, medium, high, critical
  final String type; // vendor_pattern, time_pattern, frequency_spike, amount_anomaly
  final String entityType;
  final int percentage;
  final String timeWindow;
  final int affectedCount;
  final List<String> samplesIds;

  AnomalyInsight({
    required this.title,
    required this.description,
    required this.severity,
    required this.type,
    required this.entityType,
    required this.percentage,
    required this.timeWindow,
    required this.affectedCount,
    required this.samplesIds,
  });

  factory AnomalyInsight.fromMap(Map<String, dynamic> map) {
    return AnomalyInsight(
      title: map['title'] as String? ?? 'Unknown',
      description: map['description'] as String? ?? '',
      severity: map['severity'] as String? ?? 'low',
      type: map['type'] as String? ?? 'unknown',
      entityType: map['entityType'] as String? ?? 'unknown',
      percentage: map['percentage'] as int? ?? 0,
      timeWindow: map['timeWindow'] as String? ?? 'this week',
      affectedCount: map['affectedCount'] as int? ?? 0,
      samplesIds: List<String>.from(map['samplesIds'] as List? ?? []),
    );
  }
}
