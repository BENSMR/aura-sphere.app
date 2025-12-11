class SeverityCounts {
  final int critical;
  final int high;
  final int medium;
  final int low;
  SeverityCounts({
    required this.critical,
    required this.high,
    required this.medium,
    required this.low,
  });
}

class TrendPoint {
  final DateTime day;
  final int count;
  TrendPoint({required this.day, required this.count});
}

class EntityRisk {
  final String entityType;
  final String entityId;
  final int score;
  final String severity;
  EntityRisk({
    required this.entityType,
    required this.entityId,
    required this.score,
    required this.severity,
  });
}

class AnalyticsSnapshot {
  final SeverityCounts counts;
  final int total;
  final double businessRiskScore; // 0..100
  final List<TrendPoint> trend7Days;
  final Map<String,int> bySource; // entityType -> count
  final List<EntityRisk> topEntities;
  final String aiInsight;
  AnalyticsSnapshot({
    required this.counts,
    required this.total,
    required this.businessRiskScore,
    required this.trend7Days,
    required this.bySource,
    required this.topEntities,
    required this.aiInsight,
  });
}
