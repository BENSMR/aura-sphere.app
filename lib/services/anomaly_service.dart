// lib/services/anomaly_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/anomaly_model.dart';

class AnomalyService {
  final CollectionReference anomaliesRef;

  AnomalyService() : anomaliesRef = FirebaseFirestore.instance.collection('anomalies');

  /// Stream anomalies with optional filters
  Stream<List<AnomalyModel>> streamAnomalies({
    String? severity,
    String? entityType,
    bool onlyUnacknowledged = false,
    int limit = 100,
  }) {
    Query q = anomaliesRef.orderBy('detectedAt', descending: true);

    if (severity != null && severity.isNotEmpty) {
      q = q.where('severity', isEqualTo: severity);
    }
    if (entityType != null && entityType.isNotEmpty) {
      q = q.where('entityType', isEqualTo: entityType);
    }
    if (onlyUnacknowledged) {
      q = q.where('acknowledged', isEqualTo: false);
    }
    q = q.limit(limit);

    return q.snapshots().map((snap) => snap.docs.map((d) => AnomalyModel.fromDoc(d)).toList());
  }

  /// Acknowledge an anomaly (set acknowledged = true, add acknowledgedBy + acknowledgedAt)
  Future<void> acknowledge(String anomalyId, {required String actorUid}) async {
    final docRef = anomaliesRef.doc(anomalyId);
    await docRef.update({
      'acknowledged': true,
      'acknowledgedBy': actorUid,
      'acknowledgedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark anomaly as resolved with a note
  Future<void> resolve(String anomalyId, {required String actorUid, String? note}) async {
    final docRef = anomaliesRef.doc(anomalyId);
    await docRef.update({
      'resolved': true,
      'resolvedBy': actorUid,
      'resolvedAt': FieldValue.serverTimestamp(),
      if (note != null) 'resolutionNote': note,
    });
  }

  /// Quick fetch by id
  Future<AnomalyModel?> fetchById(String id) async {
    final doc = await anomaliesRef.doc(id).get();
    if (!doc.exists) return null;
    return AnomalyModel.fromDoc(doc);
  }
}
