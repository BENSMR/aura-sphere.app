import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/anomaly_analytics_model.dart';

class AnalyticsService {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final String summaryPath;
  final String dailyCollectionPath;

  AnalyticsService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    this.summaryPath = 'analytics/anomaly_summary/latest',
    this.dailyCollectionPath = 'analytics/anomaly_daily',
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  /// Fetch latest summary (one doc). Good for KPI tiles and risk gauge.
  Future<AnalyticsSnapshot> fetchLatestSummary() async {
    final doc = await _db.doc(summaryPath).get();
    if (!doc.exists) {
      // Return an "empty" snapshot
      return AnalyticsSnapshot(
        counts: SeverityCounts(critical: 0, high: 0, medium: 0, low: 0),
        total: 0,
        businessRiskScore: 0.0,
        trend7Days: [],
        bySource: {},
        topEntities: [],
        aiInsight: 'No data',
      );
    }

    final data = doc.data()!;
    final countsMap = Map<String, dynamic>.from(data['counts'] ?? {});
    final counts = SeverityCounts(
      critical: (countsMap['critical'] ?? 0) as int,
      high: (countsMap['high'] ?? 0) as int,
      medium: (countsMap['medium'] ?? 0) as int,
      low: (countsMap['low'] ?? 0) as int,
    );

    // topEntities is an array of maps
    final topEntitiesRaw = (data['topEntities'] as List<dynamic>?) ?? [];
    final topEntities = topEntitiesRaw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return EntityRisk(
        entityType: m['entityType']?.toString() ?? 'unknown',
        entityId: m['entityId']?.toString() ?? '',
        score: (m['score'] ?? 0) as int,
        severity: m['severity']?.toString() ?? 'low',
      );
    }).toList();

    return AnalyticsSnapshot(
      counts: counts,
      total: (data['total'] ?? 0) as int,
      businessRiskScore: (data['riskScore'] is num)
          ? (data['riskScore'] as num).toDouble()
          : 0.0,
      trend7Days: (data['trend'] as List<dynamic>?)
              ?.map((p) {
                final m = Map<String, dynamic>.from(p as Map);
                final dayStr =
                    m['day']?.toString() ?? DateTime.now().toIso8601String();
                final count = (m['count'] ?? 0) as int;
                return TrendPoint(day: DateTime.parse(dayStr), count: count);
              }).toList() ??
          [],
      bySource: Map<String, int>.from(
          (data['bySource'] ?? {}) as Map? ?? {}),
      topEntities: topEntities,
      aiInsight: data['aiInsight']?.toString() ??
          _fallbackInsight(
              counts.critical, counts.high, counts.medium, counts.low),
    );
  }

  /// Stream the latest summary doc (realtime updates in UI)
  Stream<AnalyticsSnapshot> streamLatestSummary() {
    return _db.doc(summaryPath).snapshots().map((docSnap) {
      if (!docSnap.exists) {
        return AnalyticsSnapshot(
          counts: SeverityCounts(critical: 0, high: 0, medium: 0, low: 0),
          total: 0,
          businessRiskScore: 0.0,
          trend7Days: [],
          bySource: {},
          topEntities: [],
          aiInsight: 'No data',
        );
      }
      final data = docSnap.data()!;
      final countsMap = Map<String, dynamic>.from(data['counts'] ?? {});
      final counts = SeverityCounts(
        critical: (countsMap['critical'] ?? 0) as int,
        high: (countsMap['high'] ?? 0) as int,
        medium: (countsMap['medium'] ?? 0) as int,
        low: (countsMap['low'] ?? 0) as int,
      );
      final topEntitiesRaw = (data['topEntities'] as List<dynamic>?) ?? [];
      final topEntities = topEntitiesRaw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return EntityRisk(
          entityType: m['entityType']?.toString() ?? 'unknown',
          entityId: m['entityId']?.toString() ?? '',
          score: (m['score'] ?? 0) as int,
          severity: m['severity']?.toString() ?? 'low',
        );
      }).toList();

      return AnalyticsSnapshot(
        counts: counts,
        total: (data['total'] ?? 0) as int,
        businessRiskScore: (data['riskScore'] is num)
            ? (data['riskScore'] as num).toDouble()
            : 0.0,
        trend7Days: (data['trend'] as List<dynamic>?)
                ?.map((p) {
                  final m = Map<String, dynamic>.from(p as Map);
                  final dayStr = m['day']?.toString() ??
                      DateTime.now().toIso8601String();
                  final count = (m['count'] ?? 0) as int;
                  return TrendPoint(day: DateTime.parse(dayStr), count: count);
                }).toList() ??
            [],
        bySource: Map<String, int>.from(
            (data['bySource'] ?? {}) as Map? ?? {}),
        topEntities: topEntities,
        aiInsight: data['aiInsight']?.toString() ??
            _fallbackInsight(
                counts.critical, counts.high, counts.medium, counts.low),
      );
    });
  }

  /// Fetch daily aggregate for a given dayId "YYYY-MM-DD"
  Future<AnalyticsSnapshot> fetchDaily(String dayId) async {
    final doc = await _db.collection(dailyCollectionPath).doc(dayId).get();
    if (!doc.exists) {
      throw Exception('No daily aggregate for $dayId');
    }
    final data = doc.data()!;
    final countsMap = Map<String, dynamic>.from(data['counts'] ?? {});
    final counts = SeverityCounts(
      critical: (countsMap['critical'] ?? 0) as int,
      high: (countsMap['high'] ?? 0) as int,
      medium: (countsMap['medium'] ?? 0) as int,
      low: (countsMap['low'] ?? 0) as int,
    );

    final topEntitiesRaw = (data['topEntities'] as List<dynamic>?) ?? [];
    final topEntities = topEntitiesRaw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return EntityRisk(
        entityType: m['entityType']?.toString() ?? 'unknown',
        entityId: m['entityId']?.toString() ?? '',
        score: (m['score'] ?? 0) as int,
        severity: m['severity']?.toString() ?? 'low',
      );
    }).toList();

    return AnalyticsSnapshot(
      counts: counts,
      total: (data['total'] ?? 0) as int,
      businessRiskScore: (data['riskScore'] is num)
          ? (data['riskScore'] as num).toDouble()
          : 0.0,
      trend7Days: (data['trend'] as List<dynamic>?)
              ?.map((p) {
                final m = Map<String, dynamic>.from(p as Map);
                final dayStr =
                    m['day']?.toString() ?? DateTime.now().toIso8601String();
                final count = (m['count'] ?? 0) as int;
                return TrendPoint(day: DateTime.parse(dayStr), count: count);
              }).toList() ??
          [],
      bySource: Map<String, int>.from(
          (data['bySource'] ?? {}) as Map? ?? {}),
      topEntities: topEntities,
      aiInsight: data['aiInsight']?.toString() ??
          _fallbackInsight(
              counts.critical, counts.high, counts.medium, counts.low),
    );
  }

  /// Trigger the server-side aggregation on demand (callable). Admin usage only.
  /// Returns summary: { total, riskScore }
  Future<Map<String, dynamic>> triggerServerAggregation(
      {int? windowDays, int? maxDocs}) async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('aggregateAnomaliesCallable');
      final resp = await callable.call(<String, dynamic>{
        if (windowDays != null) 'windowDays': windowDays,
        if (maxDocs != null) 'maxDocs': maxDocs,
      });
      return Map<String, dynamic>.from(resp.data as Map);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Functions error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Trigger aggregation error: $e');
      rethrow;
    }
  }

  /// Quick helper: fetch latest N daily docs (most recent first)
  Future<List<AnalyticsSnapshot>> fetchRecentDaily({int days = 7}) async {
    final now = DateTime.now().toUtc();
    final list = <AnalyticsSnapshot>[];
    for (int i = 0; i < days; i++) {
      final d = now.subtract(Duration(days: i));
      final id =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      try {
        final s = await fetchDaily(id);
        list.add(s);
      } catch (_) {
        // skip missing days
      }
    }
    return list;
  }

  String _fallbackInsight(int critical, int high, int medium, int low) {
    final total = critical + high + medium + low;
    if (total == 0) {
      return 'No anomalies detected.';
    }
    if (critical > 0) {
      return 'Critical anomalies detected — immediate review recommended.';
    }
    if (high > 0) {
      return 'High severity anomalies present — finance review advised.';
    }
    return 'Anomalies detected; monitoring recommended.';
  }
}
