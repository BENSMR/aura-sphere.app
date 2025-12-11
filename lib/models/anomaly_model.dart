import 'package:cloud_firestore/cloud_firestore.dart';

/// Severity levels for anomalies
enum AnomalySeverity {
  low(0),
  medium(1),
  high(2),
  critical(3);

  final int score;
  const AnomalySeverity(this.score);

  static AnomalySeverity fromScore(int score) {
    if (score >= 3) return AnomalySeverity.critical;
    if (score >= 2) return AnomalySeverity.high;
    if (score >= 1) return AnomalySeverity.medium;
    return AnomalySeverity.low;
  }

  String toDisplayString() {
    switch (this) {
      case AnomalySeverity.low:
        return 'Low';
      case AnomalySeverity.medium:
        return 'Medium';
      case AnomalySeverity.high:
        return 'High';
      case AnomalySeverity.critical:
        return 'Critical';
    }
  }
}

/// Entity types that can have anomalies
enum AnomalyEntityType {
  invoice,
  expense,
  inventory,
  audit;

  static AnomalyEntityType? fromString(String? value) {
    if (value == null) return null;
    try {
      return AnomalyEntityType.values.firstWhere(
        (e) => e.toString().split('.').last == value,
      );
    } catch (e) {
      return null;
    }
  }

  String toDisplayString() {
    switch (this) {
      case AnomalyEntityType.invoice:
        return 'Invoice';
      case AnomalyEntityType.expense:
        return 'Expense';
      case AnomalyEntityType.inventory:
        return 'Inventory';
      case AnomalyEntityType.audit:
        return 'Audit';
    }
  }
}

/// Represents an anomaly detected by the scanner
class AnomalyModel {
  final String id;
  final String entityType; // 'invoice', 'expense', 'inventory', 'audit'
  final String entityId; // ID of the flagged entity
  final String? owner; // User ID or null
  final int score; // Numeric score (0-12+)
  final String severity; // 'low', 'medium', 'high', 'critical'
  final List<String> reasons; // List of human-readable reasons
  final String recommendedAction; // Suggested next step
  final Map<String, dynamic>? sample; // Sample data from entity
  final String? runId; // Scan run ID for traceability
  final DateTime detectedAt; // When anomaly was created
  final bool acknowledged; // Admin has reviewed it
  final String? resolution; // How it was resolved (if acknowledged)

  AnomalyModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.owner,
    required this.score,
    required this.severity,
    required this.reasons,
    required this.recommendedAction,
    this.sample,
    this.runId,
    required this.detectedAt,
    this.acknowledged = false,
    this.resolution,
  });

  /// Get severity as enum
  AnomalySeverity get severityEnum {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AnomalySeverity.critical;
      case 'high':
        return AnomalySeverity.high;
      case 'medium':
        return AnomalySeverity.medium;
      case 'low':
      default:
        return AnomalySeverity.low;
    }
  }

  /// Get entity type as enum
  AnomalyEntityType? get entityTypeEnum => AnomalyEntityType.fromString(entityType);

  /// Create from Firestore document
  factory AnomalyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document is empty');
    }

    return AnomalyModel(
      id: doc.id,
      entityType: data['entityType'] as String? ?? '',
      entityId: data['entityId'] as String? ?? '',
      owner: data['owner'] as String?,
      score: (data['score'] as num?)?.toInt() ?? 0,
      severity: data['severity'] as String? ?? 'low',
      reasons: List<String>.from(data['reasons'] as List<dynamic>? ?? []),
      recommendedAction: data['recommendedAction'] as String? ?? '',
      sample: data['sample'] as Map<String, dynamic>?,
      runId: data['runId'] as String?,
      detectedAt: (data['detectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acknowledged: data['acknowledged'] as bool? ?? false,
      resolution: data['resolution'] as String?,
    );
  }

  /// Create from JSON (for testing or API responses)
  factory AnomalyModel.fromJson(Map<String, dynamic> json) {
    return AnomalyModel(
      id: json['id'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as String? ?? '',
      owner: json['owner'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      severity: json['severity'] as String? ?? 'low',
      reasons: List<String>.from(json['reasons'] as List<dynamic>? ?? []),
      recommendedAction: json['recommendedAction'] as String? ?? '',
      sample: json['sample'] as Map<String, dynamic>?,
      runId: json['runId'] as String?,
      detectedAt: json['detectedAt'] is String
          ? DateTime.parse(json['detectedAt'] as String)
          : (json['detectedAt'] as DateTime?) ?? DateTime.now(),
      acknowledged: json['acknowledged'] as bool? ?? false,
      resolution: json['resolution'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'owner': owner,
      'score': score,
      'severity': severity,
      'reasons': reasons,
      'recommendedAction': recommendedAction,
      'sample': sample,
      'runId': runId,
      'detectedAt': detectedAt.toIso8601String(),
      'acknowledged': acknowledged,
      'resolution': resolution,
    };
  }

  /// Copy with modifications
  AnomalyModel copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? owner,
    int? score,
    String? severity,
    List<String>? reasons,
    String? recommendedAction,
    Map<String, dynamic>? sample,
    String? runId,
    DateTime? detectedAt,
    bool? acknowledged,
    String? resolution,
  }) {
    return AnomalyModel(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      owner: owner ?? this.owner,
      score: score ?? this.score,
      severity: severity ?? this.severity,
      reasons: reasons ?? this.reasons,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      sample: sample ?? this.sample,
      runId: runId ?? this.runId,
      detectedAt: detectedAt ?? this.detectedAt,
      acknowledged: acknowledged ?? this.acknowledged,
      resolution: resolution ?? this.resolution,
    );
  }

  @override
  String toString() {
    return 'AnomalyModel('
        'id: $id, '
        'entityType: $entityType, '
        'entityId: $entityId, '
        'severity: $severity, '
        'score: $score, '
        'acknowledged: $acknowledged'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AnomalyModel &&
        other.id == id &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        other.severity == severity &&
        other.score == score;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        entityType.hashCode ^
        entityId.hashCode ^
        severity.hashCode ^
        score.hashCode;
  }
}
