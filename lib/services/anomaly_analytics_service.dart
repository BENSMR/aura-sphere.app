import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/anomaly_analytics_model.dart';

class AnomalyAnalyticsService {
  final CollectionReference anomaliesRef;

  AnomalyAnalyticsService() : anomaliesRef = FirebaseFirestore.instance.collection('anomalies');

  /// Fetch recent anomalies (windowDays default 7). Limit total docs to avoid huge reads.
  Future<AnalyticsSnapshot> fetchAnalytics({
    int windowDays = 7,
    int maxDocs = 1000,
  }) async {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day).subtract(Duration(days: windowDays - 1));
    final cutoffTs = Timestamp.fromDate(cutoff);

    // Query recent anomalies limited to maxDocs
    final snap = await anomaliesRef
        .where('detectedAt', isGreaterThanOrEqualTo: cutoffTs)
        .orderBy('detectedAt', descending: true)
        .limit(maxDocs)
        .get();

    final docs = snap.docs;
    // compute counts by severity
    int critical = 0, high = 0, medium = 0, low = 0;
    Map<String, int> bySource = {};
    Map<String, int> dayCounts = {}; // key = yyyy-MM-dd

    List<EntityRisk> entityRisks = [];

    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final severity = (data['severity'] ?? 'low') as String;
      switch (severity) {
        case 'critical':
          critical++;
          break;
        case 'high':
          high++;
          break;
        case 'medium':
          medium++;
          break;
        default:
          low++;
          break;
      }

      final etype = (data['entityType'] ?? 'unknown') as String;
      bySource[etype] = (bySource[etype] ?? 0) + 1;

      final ts = data['detectedAt'] as Timestamp?;
      final dt = ts?.toDate() ?? DateTime.now();
      final key = DateFormat('yyyy-MM-dd').format(dt);
      dayCounts[key] = (dayCounts[key] ?? 0) + 1;

      // collect top entities by score
      final score = ((data['score'] ?? 0) as num).toInt();
      final eid = data['entityId']?.toString() ?? d.id;
      entityRisks.add(EntityRisk(
        entityType: etype,
        entityId: eid,
        score: score,
        severity: severity,
      ));
    }

    // produce last 7 days points (ordered oldest -> newest)
    final trend = <TrendPoint>[];
    for (int i = windowDays - 1; i >= 0; --i) {
      final day = DateTime.now().subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      trend.add(TrendPoint(day: day, count: dayCounts[key] ?? 0));
    }

    // compute businessRiskScore: weighted severity normalized to 0..100
    final total = critical + high + medium + low;
    double score = 0;
    if (total > 0) {
      score = ((critical * 4 + high * 3 + medium * 2 + low * 1) / (total * 4)) * 100;
    }

    // pick top 10 worst entities by score then severity weight
    entityRisks.sort((a, b) {
      final sCmp = b.score.compareTo(a.score);
      if (sCmp != 0) return sCmp;
      return severityRank(b.severity).compareTo(severityRank(a.severity));
    });
    final top = entityRisks.take(10).toList();

    // simple AI insight generation (rules-based)
    String insight = _generateInsight(critical, high, medium, low, bySource, trend);

    final snapshot = AnalyticsSnapshot(
      counts: SeverityCounts(critical: critical, high: high, medium: medium, low: low),
      total: total,
      businessRiskScore: double.parse(score.toStringAsFixed(1)),
      trend7Days: trend,
      bySource: bySource,
      topEntities: top,
      aiInsight: insight,
    );

    return snapshot;
  }

  int severityRank(String s) {
    switch (s) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }

  String _generateInsight(
    int critical,
    int high,
    int medium,
    int low,
    Map<String, int> bySource,
    List<TrendPoint> trend,
  ) {
    final total = critical + high + medium + low;
    if (total == 0) return "No anomalies detected in this period. System healthy.";

    // trend increase detection simple
    final yesterday = trend[trend.length - 2].count;
    final today = trend.last.count;
    String trendPhrase = '';
    if (yesterday == 0 && today > 0) {
      trendPhrase = "a sudden spike today";
    } else if (yesterday > 0) {
      final pct = ((today - yesterday) / (yesterday == 0 ? 1 : yesterday) * 100).round();
      if (pct > 30) {
        trendPhrase = "an increase of $pct% vs. yesterday";
      } else if (pct < -50) {
        trendPhrase = "a large decrease vs. yesterday";
      }
    }

    // largest source
    String topSource = "";
    if (bySource.isNotEmpty) {
      final sorted = bySource.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topSource = sorted.first.key;
    }

    final parts = <String>[];
    parts.add("Total anomalies: $total (critical: $critical, high: $high).");
    if (trendPhrase.isNotEmpty) parts.add("Observed $trendPhrase.");
    if (topSource.isNotEmpty) parts.add("Most affected area: $topSource.");

    // action suggestion
    if (critical > 0) {
      parts.add("Recommended: review critical items immediately and freeze related payments if needed.");
    } else if (high > 0) {
      parts.add("Recommended: have finance review high-risk items this week.");
    } else {
      parts.add("Recommended: monitor medium/low anomalies and run deeper scans if they cluster.");
    }

    return parts.join(" ");
  }
}
