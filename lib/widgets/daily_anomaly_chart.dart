import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DailyAnomalyCountChart extends StatefulWidget {
  final int days;
  final String? severity;

  const DailyAnomalyCountChart({
    super.key,
    this.days = 30,
    this.severity,
  });

  @override
  State<DailyAnomalyCountChart> createState() => _DailyAnomalyCountChartState();
}

class _DailyAnomalyCountChartState extends State<DailyAnomalyCountChart> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DailyAnomalyData>> _fetchDailyData() async {
    try {
      final snapshot = await _firestore
          .collection('analytics')
          .doc('anomalies_daily')
          .collection('days')
          .orderBy('date', descending: false)
          .limit(widget.days)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final count = widget.severity != null
            ? (data['severities']?[widget.severity] ?? 0) as int
            : (data['total'] ?? 0) as int;

        return DailyAnomalyData(
          date: data['date'] as String,
          count: count,
          severities: Map<String, int>.from(data['severities'] ?? {}),
          entityTypes: Map<String, int>.from(data['entityTypes'] ?? {}),
        );
      }).toList();
    } catch (e) {
      print('Error fetching daily anomaly data: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DailyAnomalyData>>(
      future: _fetchDailyData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No anomalies detected yet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final data = snapshot.data!;
        final maxY = data.map((d) => d.count.toDouble()).reduce((a, b) => a > b ? a : b);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.severity != null
                        ? 'Daily ${widget.severity?.toUpperCase()} Anomalies'
                        : 'Daily Anomaly Count (${widget.days} days)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${data.fold<int>(0, (sum, d) => sum + d.count)} anomalies',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (maxY / 5).ceil().toDouble(),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (data.length / 8).ceil().toDouble(),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= data.length) return const Text('');
                            final dateStr = data[index].date;
                            final date = DateTime.parse(dateStr);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('M/d').format(date),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    minX: 0,
                    maxX: (data.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY + 2,
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          data.length,
                          (i) => FlSpot(i.toDouble(), data[i].count.toDouble()),
                        ),
                        isCurved: true,
                        color: _getSeverityColor(widget.severity),
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: data.length <= 30,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: _getSeverityColor(widget.severity),
                              strokeWidth: 0,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: _getSeverityColor(widget.severity).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Summary stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSummaryStats(data),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryStats(List<DailyAnomalyData> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final total = data.fold<int>(0, (sum, d) => sum + d.count);
    final average = (total / data.length).toStringAsFixed(1);
    final max = data.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    final today = data.isNotEmpty ? data.last : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', total.toString(), Colors.blue),
          _buildStatItem('Average', average, Colors.orange),
          _buildStatItem('Peak', max.toString(), Colors.red),
          if (today != null) _buildStatItem('Today', today.count.toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(String? severity) {
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
}

class DailyAnomalyData {
  final String date;
  final int count;
  final Map<String, int> severities;
  final Map<String, int> entityTypes;

  DailyAnomalyData({
    required this.date,
    required this.count,
    required this.severities,
    required this.entityTypes,
  });
}
