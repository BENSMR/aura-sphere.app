import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Audit event types for notification tracking
enum NotificationAuditType {
  emailQueued,
  emailSent,
  emailFailed,
  pushQueued,
  pushSent,
  pushFailed,
  deviceRegistered,
  deviceRemoved,
  preferencesUpdated,
  notificationRead,
  notificationDeleted,
}

/// Notification audit record for compliance and debugging
class NotificationAuditRecord {
  final String auditId;
  final String actor; // uid or 'server' for Cloud Functions
  final String targetUid;
  final NotificationAuditType type;
  final String? eventId; // invoiceId, anomalyId, notificationId, deviceId
  final AuditStatus status;
  final String? error;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  NotificationAuditRecord({
    required this.auditId,
    required this.actor,
    required this.targetUid,
    required this.type,
    this.eventId,
    required this.status,
    this.error,
    required this.createdAt,
    this.metadata,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'actor': actor,
      'targetUid': targetUid,
      'type': type.name,
      'eventId': eventId,
      'status': status.name,
      'error': error,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata ?? {},
    };
  }

  /// Create from Firestore document
  factory NotificationAuditRecord.fromMap(
    String auditId,
    Map<String, dynamic> data,
  ) {
    return NotificationAuditRecord(
      auditId: auditId,
      actor: data['actor'] ?? 'unknown',
      targetUid: data['targetUid'] ?? '',
      type: NotificationAuditType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => NotificationAuditType.emailQueued,
      ),
      eventId: data['eventId'],
      status: AuditStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => AuditStatus.queued,
      ),
      error: data['error'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }
}

/// Audit status
enum AuditStatus { queued, sent, failed, processing }

/// Service for notification audit logging
class NotificationAuditService {
  final FirebaseFirestore _firestore;

  NotificationAuditService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Record an audit event
  Future<String?> recordAudit({
    required String actor,
    required String targetUid,
    required NotificationAuditType type,
    required AuditStatus status,
    String? eventId,
    String? error,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final doc = await _firestore
          .collection('notifications_audit')
          .add({
        'actor': actor,
        'targetUid': targetUid,
        'type': type.name,
        'eventId': eventId,
        'status': status.name,
        'error': error,
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });

      debugPrint('📝 Audit recorded: ${type.name} -> $status');
      return doc.id;
    } catch (e) {
      debugPrint('❌ Failed to record audit: $e');
      return null;
    }
  }

  /// Get audit records for a user
  Future<List<NotificationAuditRecord>> getAuditHistory({
    required String userId,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _firestore
          .collection('notifications_audit')
          .where('targetUid', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => NotificationAuditRecord.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get audit history: $e');
      return [];
    }
  }

  /// Stream audit records for a user (real-time)
  Stream<List<NotificationAuditRecord>> streamAuditHistory({
    required String userId,
    int limit = 50,
  }) {
    try {
      return _firestore
          .collection('notifications_audit')
          .where('targetUid', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
        (snapshot) {
          return snapshot.docs
              .map((doc) => NotificationAuditRecord.fromMap(doc.id, doc.data()))
              .toList();
        },
      ).handleError((e) {
        debugPrint('❌ Stream error: $e');
        return [];
      });
    } catch (e) {
      debugPrint('❌ Failed to stream audit history: $e');
      return Stream.value([]);
    }
  }

  /// Get audit records by type
  Future<List<NotificationAuditRecord>> getAuditByType({
    required String userId,
    required NotificationAuditType type,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('notifications_audit')
          .where('targetUid', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NotificationAuditRecord.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get audit by type: $e');
      return [];
    }
  }

  /// Get failed audit records
  Future<List<NotificationAuditRecord>> getFailedAudits({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('notifications_audit')
          .where('targetUid', isEqualTo: userId)
          .where('status', isEqualTo: AuditStatus.failed.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NotificationAuditRecord.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get failed audits: $e');
      return [];
    }
  }

  /// Get audit records for specific event
  Future<List<NotificationAuditRecord>> getAuditForEvent({
    required String userId,
    required String eventId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('notifications_audit')
          .where('targetUid', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationAuditRecord.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get audit for event: $e');
      return [];
    }
  }

  /// Stream failed audits for admin monitoring
  Stream<List<NotificationAuditRecord>> streamFailedAudits({int limit = 100}) {
    try {
      return _firestore
          .collection('notifications_audit')
          .where('status', isEqualTo: AuditStatus.failed.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
        (snapshot) {
          return snapshot.docs
              .map((doc) => NotificationAuditRecord.fromMap(doc.id, doc.data()))
              .toList();
        },
      ).handleError((e) {
        debugPrint('❌ Stream error: $e');
        return [];
      });
    } catch (e) {
      debugPrint('❌ Failed to stream failed audits: $e');
      return Stream.value([]);
    }
  }

  /// Get audit summary statistics
  Future<Map<String, dynamic>> getAuditStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _firestore
          .collection('notifications_audit')
          .where('targetUid', isEqualTo: userId);

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final records = snapshot.docs
          .map((doc) => NotificationAuditRecord.fromMap(doc.id, doc.data()))
          .toList();

      // Calculate statistics
      final stats = <String, int>{
        'total': records.length,
        'sent': 0,
        'failed': 0,
        'queued': 0,
        'emailSent': 0,
        'emailFailed': 0,
        'pushSent': 0,
        'pushFailed': 0,
      };

      for (final record in records) {
        // Count by status
        final statusKey = record.status.name;
        stats[statusKey] = (stats[statusKey] ?? 0) + 1;

        // Count by type + status
        if (record.type.name.startsWith('email')) {
          stats['email${record.status.name[0].toUpperCase()}${record.status.name.substring(1)}'] =
              (stats['email${record.status.name[0].toUpperCase()}${record.status.name.substring(1)}'] ?? 0) + 1;
        } else if (record.type.name.startsWith('push')) {
          stats['push${record.status.name[0].toUpperCase()}${record.status.name.substring(1)}'] =
              (stats['push${record.status.name[0].toUpperCase()}${record.status.name.substring(1)}'] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('❌ Failed to get audit stats: $e');
      return {};
    }
  }

  /// Update audit record status
  Future<bool> updateAuditStatus({
    required String auditId,
    required AuditStatus newStatus,
    String? error,
  }) async {
    try {
      await _firestore.collection('notifications_audit').doc(auditId).update({
        'status': newStatus.name,
        if (error != null) 'error': error,
      });

      debugPrint('📝 Audit $auditId updated to ${newStatus.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to update audit: $e');
      return false;
    }
  }

  /// Delete audit records older than specified days
  Future<int> deleteOldAudits({required int olderThanDays}) async {
    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: olderThanDays));
      final snapshot = await _firestore
          .collection('notifications_audit')
          .where('createdAt',
              isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      int deletedCount = 0;
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      debugPrint('🗑️ Deleted $deletedCount old audit records');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ Failed to delete old audits: $e');
      return 0;
    }
  }
}
