import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/anomaly_analytics_model.dart';
import '../../services/anomaly_analytics_service.dart';
import '../../widgets/risk_gauge.dart';
import 'package:intl/intl.dart';

class AnomalyDashboardScreen extends StatefulWidget {
  const AnomalyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AnomalyDashboardScreen> createState() => _AnomalyDashboardScreenState();
}

class _AnomalyDashboardScreenState extends State<AnomalyDashboardScreen> {
  final AnomalyAnalyticsService _service = AnomalyAnalyticsService();
  late Future<AnalyticsSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAnalytics();
  }

  void _refresh() {
    setState(() {
      _future = _service.fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomaly Dashboard'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      body: FutureBuilder<AnalyticsSnapshot>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final data = snap.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // top row: tiles + gauge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildSummaryTiles(data)),
                    const SizedBox(width: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Text('Business Risk',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            RiskGauge(value: data.businessRiskScore, size: 140),
                            const SizedBox(height: 8),
                            Text('${data.businessRiskScore}% overall risk',
                                style: TextStyle(color: Colors.grey.shade700))
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                // trend + pie
                Row(
                  children: [
                    Expanded(
                        child: Card(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _buildTrendChart(data)))),
                    const SizedBox(width: 12),
                    SizedBox(
                        width: 360,
                        child: Card(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _buildSourcePie(data))))
                  ],
                ),
                const SizedBox(height: 12),
                // top entities + insight
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Card(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _buildTopEntities(data)))),
                    const SizedBox(width: 12),
                    SizedBox(
                        width: 360,
                        child: Card(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _buildAiInsight(data))))
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryTiles(AnalyticsSnapshot s) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryTile('Critical', s.counts.critical, Colors.redAccent),
        _summaryTile('High', s.counts.high, Colors.orangeAccent),
        _summaryTile('Medium', s.counts.medium, Colors.amber),
        _summaryTile('Low', s.counts.low, Colors.green),
        _summaryTile('Total', s.total, Colors.blueGrey),
      ],
    );
  }

  Widget _summaryTile(String title, int value, Color color) {
    return Card(
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(value.toString(),
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(AnalyticsSnapshot s) {
    final spots = <FlSpot>[];
    for (int i = 0; i < s.trend7Days.length; i++) {
      spots.add(FlSpot(i.toDouble(), s.trend7Days[i].count.toDouble()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('7-day Trend', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= s.trend7Days.length) {
                        return const SizedBox.shrink();
                      }
                      final d = s.trend7Days[idx].day;
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(DateFormat.Md().format(d),
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  color: Colors.blueAccent,
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSourcePie(AnalyticsSnapshot s) {
    final entries = s.bySource.entries.toList();
    if (entries.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Source Breakdown'),
          SizedBox(height: 8),
          Text('No data')
        ],
      );
    }
    final total = entries.fold<int>(0, (p, e) => p + e.value);
    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown
    ];
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final pct = (e.value / total) * 100;
      sections.add(PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.key}\n${pct.toStringAsFixed(0)}%',
        color: colors[i % colors.length],
        radius: 60,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Source Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(sections: sections, centerSpaceRadius: 30),
          ),
        ),
      ],
    );
  }

  Widget _buildTopEntities(AnalyticsSnapshot s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Most Affected Entities',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (s.topEntities.isEmpty) const Text('No entities'),
        ...s.topEntities.map((e) => ListTile(
          dense: true,
          title: Text('${e.entityType.toUpperCase()} • ${e.entityId}',
              overflow: TextOverflow.ellipsis),
          subtitle:
              Text('${e.severity.toUpperCase()} • Score ${e.score}'),
          trailing: ElevatedButton(
            onPressed: () {
              // TODO: navigate to entity detail screen
            },
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(72, 32)),
            child: const Text('Open'),
          ),
        ))
      ],
    );
  }

  Widget _buildAiInsight(AnalyticsSnapshot s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI Insight',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(s.aiInsight, style: TextStyle(color: Colors.grey.shade800)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: open deeper analysis modal
          },
          icon: const Icon(Icons.analytics),
          label: const Text('Run Deep Scan'),
        )
      ],
    );
  }
}
