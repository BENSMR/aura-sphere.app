import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/audit_entry.dart';

/// Service for reading audit trail data
/// 
/// Provides:
/// - Fast audit index lookups (latest entry per entity)
/// - Full audit trail queries (all entries for entity)
/// - Cross-entity audit searches
class AuditService {
  final FirebaseFirestore _firestore;

  AuditService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the audit index for a specific entity
  /// 
  /// Returns latest audit action and timestamp without full history
  /// Used for quick UI displays
  Future<AuditIndexEntry?> getAuditIndex(String entityType, String entityId) async {
    final compositeId = '$entityType:$entityId';
    final doc = await _firestore.collection('audit_index').doc(compositeId).get();
    
    if (!doc.exists) return null;
    
    return AuditIndexEntry.fromJson({
      ...doc.data() ?? {},
    });
  }

  /// Watch the audit index for real-time updates
  /// 
  /// Useful for showing latest audit action in real-time
  Stream<AuditIndexEntry?> watchAuditIndex(String entityType, String entityId) {
    final compositeId = '$entityType:$entityId';
    return _firestore
        .collection('audit_index')
        .doc(compositeId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return AuditIndexEntry.fromJson({
        ...doc.data() ?? {},
      });
    });
  }

  /// Get the full audit trail for an entity
  /// 
  /// Returns all audit entries ordered by latest first
  /// Limited to specified count (default 100)
  Future<List<AuditEntry>> getAuditTrail(
    String entityType,
    String entityId, {
    int limit = 100,
  }) async {
    final compositeId = '$entityType:$entityId';
    final docs = await _firestore
        .collection('audit')
        .doc(compositeId)
        .collection('entries')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return docs.docs
        .map((doc) => AuditEntry.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// Watch the audit trail for real-time updates
  /// 
  /// Useful for showing audit history panel that updates live
  Stream<List<AuditEntry>> watchAuditTrail(
    String entityType,
    String entityId, {
    int limit = 100,
  }) {
    final compositeId = '$entityType:$entityId';
    return _firestore
        .collection('audit')
        .doc(compositeId)
        .collection('entries')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AuditEntry.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Get the latest audit entry for an entity
  /// 
  /// Retrieves the most recent action for quick inspection
  Future<AuditEntry?> getLatestAuditEntry(
    String entityType,
    String entityId,
  ) async {
    final compositeId = '$entityType:$entityId';
    final doc = await _firestore
        .collection('audit')
        .doc(compositeId)
        .collection('entries')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (doc.docs.isEmpty) return null;
    return AuditEntry.fromJson(doc.docs.first.data(), doc.docs.first.id);
  }

  /// Query audit entries by action type
  /// 
  /// Useful for finding all 'invoice.tax_applied' actions across entities
  Future<List<AuditEntry>> queryByAction(
    String action, {
    int limit = 50,
  }) async {
    final docs = await _firestore
        .collectionGroup('entries')
        .where('action', isEqualTo: action)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return docs.docs
        .map((doc) => AuditEntry.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// Query audit entries by tag
  /// 
  /// Useful for finding all 'tax', 'critical', or 'payment' entries
  Future<List<AuditEntry>> queryByTag(
    String tag, {
    int limit = 50,
  }) async {
    final docs = await _firestore
        .collectionGroup('entries')
        .where('tags', arrayContains: tag)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return docs.docs
        .map((doc) => AuditEntry.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// Get audit entries for a specific actor (user)
  /// 
  /// Useful for audit logs showing what actions a user performed
  Future<List<AuditEntry>> queryByActor(
    String uid, {
    int limit = 50,
  }) async {
    final docs = await _firestore
        .collectionGroup('entries')
        .where('actor.uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return docs.docs
        .map((doc) => AuditEntry.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// Get audit entries by source (server, webhook, client)
  /// 
  /// Useful for debugging - see which source is making changes
  Future<List<AuditEntry>> queryBySource(
    String source, {
    int limit = 50,
  }) async {
    final docs = await _firestore
        .collectionGroup('entries')
        .where('source', isEqualTo: source)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return docs.docs
        .map((doc) => AuditEntry.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// Complex audit query combining multiple filters
  /// 
  /// Example:
  /// ```
  /// final results = await auditService.queryAudit(
  ///   action: 'invoice.tax_applied',
  ///   tag: 'tax',
  ///   limit: 20
  /// );
  /// ```
  Future<List<AuditEntry>> queryAudit({
    String? entityType,
    String? action,
    String? tag,
    String? source,
    DateTime? afterDate,
    int limit = 50,
  }) async {
    var query = _firestore.collectionGroup('entries') as Query;

    if (entityType != null) {
      query = query.where('entityType', isEqualTo: entityType);
    }

    if (action != null) {
      query = query.where('action', isEqualTo: action);
    }

    if (tag != null) {
      query = query.where('tags', arrayContains: tag);
    }

    if (source != null) {
      query = query.where('source', isEqualTo: source);
    }

    if (afterDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: afterDate);
    }

    query = query.orderBy('timestamp', descending: true).limit(limit);

    final docs = await query.get();
    return docs.docs
        .map((doc) => AuditEntry.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// Check if an entity has been modified since a certain time
  /// 
  /// Useful for sync operations or change detection
  Future<bool> hasChangedSince(
    String entityType,
    String entityId,
    DateTime since,
  ) async {
    final compositeId = '$entityType:$entityId';
    final doc = await _firestore
        .collection('audit')
        .doc(compositeId)
        .collection('entries')
        .where('timestamp', isGreaterThan: since)
        .limit(1)
        .get();

    return doc.docs.isNotEmpty;
  }

  /// Get count of audit entries for an entity
  /// 
  /// Useful for showing "X changes recorded" in UI
  Future<int> getAuditEntryCount(
    String entityType,
    String entityId,
  ) async {
    final compositeId = '$entityType:$entityId';
    final docs = await _firestore
        .collection('audit')
        .doc(compositeId)
        .collection('entries')
        .count()
        .get();

    return docs.count ?? 0;
  }
}
