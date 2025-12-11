import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_audit_service.dart';

enum NotificationType { anomaly, invoice, inventory, system }

enum NotificationSeverity { low, medium, high, critical }

class NotificationPayload {
  final String? invoiceId;
  final String? entityId;
  final String? deepLink;
  final Map<String, dynamic>? extra;

  NotificationPayload({
    this.invoiceId,
    this.entityId,
    this.deepLink,
    this.extra,
  });

  factory NotificationPayload.fromMap(Map<String, dynamic>? map) {
    if (map == null) return NotificationPayload();
    return NotificationPayload(
      invoiceId: map['invoiceId'],
      entityId: map['entityId'],
      deepLink: map['deepLink'],
      extra: map['extra'],
    );
  }

  Map<String, dynamic> toMap() => {
    'invoiceId': invoiceId,
    'entityId': entityId,
    'deepLink': deepLink,
    'extra': extra,
  };
}

class NotificationRecord {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final NotificationSeverity severity;
  final NotificationPayload payload;
  final bool read;
  final DateTime createdAt;
  final bool delivered;
  final Map<String, dynamic>? meta;

  NotificationRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.severity,
    required this.payload,
    required this.read,
    required this.createdAt,
    required this.delivered,
    this.meta,
  });

  factory NotificationRecord.fromMap(String id, Map<String, dynamic> map) =>
      NotificationRecord(
        id: id,
        type: NotificationType.values.byName(map['type'] ?? 'system'),
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        severity: NotificationSeverity.values.byName(
          map['severity'] ?? 'low',
        ),
        payload: NotificationPayload.fromMap(map['payload']),
        read: map['read'] ?? false,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        delivered: map['delivered'] ?? false,
        meta: map['meta'],
      );

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'title': title,
    'body': body,
    'severity': severity.name,
    'payload': payload.toMap(),
    'read': read,
    'createdAt': FieldValue.serverTimestamp(),
    'delivered': delivered,
    'meta': meta,
  };
}

class NotificationHistoryService {
  final FirebaseFirestore _firestore;

  NotificationHistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get notification history for user
  Future<List<NotificationRecord>> getNotificationHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NotificationRecord.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch notification history: $e');
      return [];
    }
  }

  /// Stream notifications (real-time)
  Stream<List<NotificationRecord>> streamNotifications({
    required String userId,
    int limit = 50,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs
                .map((doc) => NotificationRecord.fromMap(doc.id, doc.data()))
                .toList());
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Failed to get unread count: $e');
      return 0;
    }
  }

  /// Stream unread count
  Stream<int> streamUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<bool> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
            'read': true,
          });

      debugPrint('✅ Notification marked as read: $notificationId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to mark as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      
      // Log audit
      final auditService = NotificationAuditService();
      for (final doc in snapshot.docs) {
        await auditService.recordAudit(
          actor: userId,
          targetUid: userId,
          type: NotificationAuditType.notificationRead,
          status: AuditStatus.sent,
          eventId: doc.id,
        );
      }

      debugPrint('✅ All notifications marked as read');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to mark all as read: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Log audit
      final auditService = NotificationAuditService();
      await auditService.recordAudit(
        actor: userId,
        targetUid: userId,
        type: NotificationAuditType.notificationDeleted,
        status: AuditStatus.sent,
        eventId: notificationId,
      );

      debugPrint('✅ Notification deleted: $notificationId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete notification: $e');
      return false;
    }
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ All notifications deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete all notifications: $e');
      return false;
    }
  }

  /// Get notifications by type
  Future<List<NotificationRecord>> getNotificationsByType({
    required String userId,
    required NotificationType type,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('type', isEqualTo: type.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NotificationRecord.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch notifications by type: $e');
      return [];
    }
  }

  /// Get critical notifications
  Future<List<NotificationRecord>> getCriticalNotifications({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('severity', isEqualTo: 'critical')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NotificationRecord.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch critical notifications: $e');
      return [];
    }
  }

  /// Get notifications from last N days
  Future<List<NotificationRecord>> getRecentNotifications({
    required String userId,
    required int days,
    int limit = 100,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('createdAt', isGreaterThan: cutoffDate)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NotificationRecord.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch recent notifications: $e');
      return [];
    }
  }

  /// Search notifications
  Future<List<NotificationRecord>> searchNotifications({
    required String userId,
    required String query,
    int limit = 50,
  }) async {
    try {
      // Simple client-side search (Firestore doesn't support full-text search natively)
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(limit * 2) // Fetch more to filter
          .get();

      final results = snapshot.docs
          .map((doc) => NotificationRecord.fromMap(doc.id, doc.data()))
          .where((notif) =>
              notif.title.toLowerCase().contains(query.toLowerCase()) ||
              notif.body.toLowerCase().contains(query.toLowerCase()))
          .take(limit)
          .toList();

      return results;
    } catch (e) {
      debugPrint('❌ Failed to search notifications: $e');
      return [];
    }
  }

  /// Create notification record (called from Cloud Function)
  Future<String?> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    required NotificationSeverity severity,
    NotificationPayload? payload,
    bool delivered = false,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'type': type.name,
            'title': title,
            'body': body,
            'severity': severity.name,
            'payload': payload?.toMap() ?? {},
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
            'delivered': delivered,
            'meta': meta,
          });

      debugPrint('✅ Notification created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Failed to create notification: $e');
      return null;
    }
  }
}
