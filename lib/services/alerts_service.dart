import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Alert severity levels
enum AlertSeverity { critical, high, medium, low }

/// Alert entity types
enum AlertEntityType { expense, invoice, inventory, audit }

/// Model for anomaly/alert
class AnomalyAlert {
  final String id;
  final String entityType;
  final String entityId;
  final String severity;
  final String message;
  final String recommendedAction;
  final DateTime createdAt;
  final bool resolved;
  final String? resolution;

  AnomalyAlert({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.severity,
    required this.message,
    required this.recommendedAction,
    required this.createdAt,
    required this.resolved,
    this.resolution,
  });

  factory AnomalyAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnomalyAlert(
      id: doc.id,
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'] ?? '',
      severity: data['severity'] ?? 'low',
      message: data['message'] ?? '',
      recommendedAction: data['recommendedAction'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolved: data['resolved'] ?? false,
      resolution: data['resolution'],
    );
  }
}

class AlertsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get unresolved alerts as a stream
  Stream<List<AnomalyAlert>> getUnresolvedAlertsStream() {
    return _db
        .collection('anomalies')
        .where('resolved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnomalyAlert.fromFirestore(doc))
          .toList();
    });
  }

  /// Get alerts filtered by entity type
  Stream<List<AnomalyAlert>> getAlertsByEntityType(String entityType) {
    return _db
        .collection('anomalies')
        .where('entityType', isEqualTo: entityType)
        .where('resolved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnomalyAlert.fromFirestore(doc))
          .toList();
    });
  }

  /// Get alerts filtered by severity
  Stream<List<AnomalyAlert>> getAlertsBySeverity(List<String> severities) {
    return _db
        .collection('anomalies')
        .where('severity', whereIn: severities)
        .where('resolved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnomalyAlert.fromFirestore(doc))
          .toList();
    });
  }

  /// Get unresolved alert count
  Future<int> getUnresolvedAlertCount() async {
    final snapshot = await _db
        .collection('anomalies')
        .where('resolved', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get critical alert count
  Future<int> getCriticalAlertCount() async {
    final snapshot = await _db
        .collection('anomalies')
        .where('severity', isEqualTo: 'critical')
        .where('resolved', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Resolve an alert (via Cloud Function)
  Future<void> resolveAlert(String anomalyId, String resolution) async {
    try {
      await _functions.httpsCallable('resolveAnomaly').call({
        'anomalyId': anomalyId,
        'resolution': resolution,
      });
    } catch (e) {
      throw Exception('Failed to resolve alert: $e');
    }
  }

  /// Query alerts with multiple filters
  Future<List<AnomalyAlert>> queryAlerts({
    String? entityType,
    String? severity,
    bool? resolved,
    int limit = 50,
  }) async {
    try {
      final result = await _functions.httpsCallable('queryAnomalies').call({
        if (entityType != null) 'entityType': entityType,
        if (severity != null) 'severity': severity,
        if (resolved != null) 'resolved': resolved,
        'limit': limit,
      });

      final data = result.data as Map<String, dynamic>;
      final anomalies = (data['anomalies'] as List)
          .map((e) => AnomalyAlert(
            id: e['id'],
            entityType: e['entityType'],
            entityId: e['entityId'],
            severity: e['severity'],
            message: e['message'],
            recommendedAction: e['recommendedAction'],
            createdAt: DateTime.parse(e['createdAt']),
            resolved: e['resolved'],
            resolution: e['resolution'],
          ))
          .toList();

      return anomalies;
    } catch (e) {
      throw Exception('Failed to query alerts: $e');
    }
  }

  /// Get alert statistics
  Future<Map<String, int>> getAlertStats() async {
    final critical = await _db
        .collection('anomalies')
        .where('severity', isEqualTo: 'critical')
        .where('resolved', isEqualTo: false)
        .count()
        .get();

    final high = await _db
        .collection('anomalies')
        .where('severity', isEqualTo: 'high')
        .where('resolved', isEqualTo: false)
        .count()
        .get();

    final medium = await _db
        .collection('anomalies')
        .where('severity', isEqualTo: 'medium')
        .where('resolved', isEqualTo: false)
        .count()
        .get();

    final low = await _db
        .collection('anomalies')
        .where('severity', isEqualTo: 'low')
        .where('resolved', isEqualTo: false)
        .count()
        .get();

    return {
      'critical': critical.count ?? 0,
      'high': high.count ?? 0,
      'medium': medium.count ?? 0,
      'low': low.count ?? 0,
    };
  }

  /// Listen to critical alerts in real-time
  Stream<List<AnomalyAlert>> watchCriticalAlerts() {
    return _db
        .collection('anomalies')
        .where('severity', isEqualTo: 'critical')
        .where('resolved', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnomalyAlert.fromFirestore(doc))
          .toList();
    });
  }
}
