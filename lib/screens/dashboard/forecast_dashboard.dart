// lib/screens/dashboard/forecast_dashboard.dart
import 'package:flutter/material.dart';
import '../../services/forecast_service.dart';
import '../../core/utils/formatters.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class ForecastDashboard extends StatefulWidget {
  const ForecastDashboard({Key? key}) : super(key: key);

  @override
  State<ForecastDashboard> createState() => _ForecastDashboardState();
}

class _ForecastDashboardState extends State<ForecastDashboard> {
  final _svc = ForecastService();
  Map<String, dynamic>? _forecast;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getForecast(horizon: 90);
    setState(() {
      _forecast = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_forecast == null) {
      return const Center(child: Text('No forecast data available.'));
    }

    final dates = List<String>.from(_forecast!['dates'] ?? []);
    final dailyNet = (List<dynamic>.from(_forecast!['dailyNetForecast'] ?? []))
        .map((e) => (e as num).toDouble())
        .toList();
    final cumulative = (List<dynamic>.from(_forecast!['cumulativeBalance'] ?? []))
        .map((e) => (e as num).toDouble())
        .toList();
    final currentBalance = (_forecast!['currentBalance'] as num?)?.toDouble() ?? 0.0;
    final runwayDays = _forecast!['runwayDays'] as int?;

    final seriesList = <charts.Series<double, int>>[
      charts.Series<double, int>(
        id: 'Daily Net',
        domainFn: (_, i) => i,
        measureFn: (val, _) => val,
        data: dailyNet,
      ),
      charts.Series<double, int>(
        id: 'Cumulative Balance',
        domainFn: (_, i) => i,
        measureFn: (val, _) => val,
        data: cumulative,
      )..setAttribute(charts.rendererIdKey, 'line'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Cashflow Forecast')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: const Text('Current Balance'),
                subtitle: Text(
                  Formatters().formatCurrency(currentBalance, currencyCode: null),
                ),
                trailing: runwayDays != null
                    ? Text('Runway: ${runwayDays} days')
                    : const Text('Runway: —'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: charts.LineChart(
                seriesList,
                animate: false,
                defaultRenderer: charts.LineRendererConfig(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('Refresh Forecast'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
