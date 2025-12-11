// lib/models/anomaly_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AnomalyModel {
  final String id;
  final String entityType;
  final String entityId;
  final String? owner;
  final int score;
  final String severity; // 'low'|'medium'|'high'|'critical'
  final List<dynamic> reasons;
  final String recommendedAction;
  final Map<String, dynamic>? sample;
  final Timestamp detectedAt;
  final bool acknowledged;
  final String? runId;

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
    required this.detectedAt,
    required this.acknowledged,
    this.runId,
  });

  factory AnomalyModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AnomalyModel(
      id: doc.id,
      entityType: d['entityType'] ?? 'unknown',
      entityId: d['entityId'] ?? '',
      owner: d['owner'] as String?,
      score: (d['score'] as num?)?.toInt() ?? 0,
      severity: (d['severity'] as String?) ?? 'low',
      reasons: d['reasons'] is List ? List.from(d['reasons']) : [(d['reasons'] ?? '')],
      recommendedAction: d['recommendedAction'] ?? '',
      sample: d['sample'] is Map<String, dynamic> ? Map<String, dynamic>.from(d['sample']) : null,
      detectedAt: d['detectedAt'] as Timestamp? ?? Timestamp.now(),
      acknowledged: d['acknowledged'] == true,
      runId: d['runId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entityType': entityType,
      'entityId': entityId,
      'owner': owner,
      'score': score,
      'severity': severity,
      'reasons': reasons,
      'recommendedAction': recommendedAction,
      'sample': sample,
      'detectedAt': detectedAt,
      'acknowledged': acknowledged,
      'runId': runId,
    };
  }
}
