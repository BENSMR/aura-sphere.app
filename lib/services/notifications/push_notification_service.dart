import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

enum NotificationType { anomaly, invoice, expense, payment, system }

enum NotificationSeverity { critical, high, medium, low }

class PushNotificationPayload {
  final String userId;
  final String title;
  final String body;
  final NotificationType notificationType;
  final NotificationSeverity severity;
  final String? actionUrl;
  final Map<String, String>? data;

  PushNotificationPayload({
    required this.userId,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.severity,
    this.actionUrl,
    this.data,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'body': body,
    'notificationType': notificationType.name,
    'severity': severity.name,
    'actionUrl': actionUrl,
    'data': data,
  };
}

class PushNotificationRecord {
  final String title;
  final String body;
  final NotificationType notificationType;
  final NotificationSeverity severity;
  final DateTime sentAt;
  final String status;

  PushNotificationRecord({
    required this.title,
    required this.body,
    required this.notificationType,
    required this.severity,
    required this.sentAt,
    required this.status,
  });

  factory PushNotificationRecord.fromMap(Map<String, dynamic> map) =>
      PushNotificationRecord(
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        notificationType: NotificationType.values
            .byName(map['notificationType'] ?? 'system'),
        severity:
            NotificationSeverity.values.byName(map['severity'] ?? 'low'),
        sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: map['status'] ?? 'sent',
      );
}

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore;

  PushNotificationService({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initialize push notifications
  /// Call this in main.dart or when user logs in
  Future<void> initialize({
    required String userId,
    VoidCallback? onTokenRefreshed,
  }) async {
    try {
      // Request permission (iOS only, Android is automatic)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 Notification permissions: ${settings.authorizationStatus}');

      // Get initial FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await registerFCMToken(userId, token);
      }

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        await registerFCMToken(userId, newToken);
        onTokenRefreshed?.call();
      });

      // Handle foreground messages (app open)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background/terminated message taps
      _messaging.getInitialMessage().then((message) {
        if (message != null) {
          _handleMessageTap(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      debugPrint('✅ Push notifications initialized for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to initialize push notifications: $e');
    }
  }

  /// Register FCM token with backend
  Future<bool> registerFCMToken(String userId, String token) async {
    try {
      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) return false;

      // Register device in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(fcmToken)
          .set({
        'token': fcmToken,
        'platform': defaultTargetPlatform.name,
        'lastSeen': FieldValue.serverTimestamp(),
        'prefs': {
          'anomalies': true,
          'invoices': true,
          'inventory': true,
          'all': true,
        },
      }, SetOptions(merge: true));

      debugPrint('✅ FCM token registered');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to register FCM token: $e');
      return false;
    }
  }

  /// Remove FCM token when user logs out
  Future<bool> removeFCMToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return true;

      // Remove device from Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(token)
          .delete();

      debugPrint('✅ FCM token removed');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to remove FCM token: $e');
      return false;
    }
  }

  /// Send push notification via Cloud Function
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType notificationType,
    required NotificationSeverity severity,
    String? actionUrl,
    Map<String, String>? data,
  }) async {
    try {
      // Store notification in Firestore - Cloud Function will process via trigger
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': notificationType.name,
        'title': title,
        'body': body,
        'severity': severity.name,
        'payload': {
          'actionUrl': actionUrl,
          'data': data ?? {},
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'delivered': false,
        'meta': {},
      });

      debugPrint('✅ Push notification queued: $title');
      return true;
    } catch (e) {
      debugPrint('❌ Push notification error: $e');
      return false;
    }
  }

  /// Send anomaly alert
  Future<bool> sendAnomalyNotification({
    required String userId,
    required String entityType,
    required String description,
    required NotificationSeverity severity,
    String? anomalyId,
  }) async {
    return sendNotification(
      userId: userId,
      title: '🚨 ${entityType.toUpperCase()} Anomaly',
      body: description,
      notificationType: NotificationType.anomaly,
      severity: severity,
      actionUrl: anomalyId != null ? '/anomalies/$anomalyId' : '/anomalies',
      data: {
        'entityType': entityType,
        'anomalyId': anomalyId ?? '',
      },
    );
  }

  /// Send invoice notification
  Future<bool> sendInvoiceNotification({
    required String userId,
    required String invoiceNumber,
    required String message,
    String? invoiceId,
  }) async {
    return sendNotification(
      userId: userId,
      title: 'Invoice #$invoiceNumber',
      body: message,
      notificationType: NotificationType.invoice,
      severity: NotificationSeverity.medium,
      actionUrl: invoiceId != null ? '/invoices/$invoiceId' : '/invoices',
      data: {
        'invoiceNumber': invoiceNumber,
        'invoiceId': invoiceId ?? '',
      },
    );
  }

  /// Send payment notification
  Future<bool> sendPaymentNotification({
    required String userId,
    required String message,
    required String amount,
    String? invoiceId,
  }) async {
    return sendNotification(
      userId: userId,
      title: '💰 Payment Received',
      body: message,
      notificationType: NotificationType.payment,
      severity: NotificationSeverity.medium,
      actionUrl: invoiceId != null ? '/invoices/$invoiceId' : '/payments',
      data: {
        'amount': amount,
        'invoiceId': invoiceId ?? '',
      },
    );
  }

  /// Send critical system alert
  Future<bool> sendCriticalAlert({
    required String userId,
    required String title,
    required String body,
    String? actionUrl,
  }) async {
    return sendNotification(
      userId: userId,
      title: title,
      body: body,
      notificationType: NotificationType.system,
      severity: NotificationSeverity.critical,
      actionUrl: actionUrl,
    );
  }

  /// Get notification history
  Future<List<PushNotificationRecord>> getNotificationHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('pushNotifications')
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PushNotificationRecord.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch notification history: $e');
      return [];
    }
  }

  /// Subscribe to topic for bulk notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic: $e');
    }
  }

  /// Disable notification type
  Future<bool> disableNotificationType({
    required String userId,
    required NotificationType notificationType,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .update({
            'disabledNotifications': FieldValue.arrayUnion([notificationType.name]),
          });
      return true;
    } catch (e) {
      debugPrint('❌ Failed to disable notification type: $e');
      return false;
    }
  }

  /// Enable notification type
  Future<bool> enableNotificationType({
    required String userId,
    required NotificationType notificationType,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .update({
            'disabledNotifications': FieldValue.arrayRemove([notificationType.name]),
          });
      return true;
    } catch (e) {
      debugPrint('❌ Failed to enable notification type: $e');
      return false;
    }
  }

  /// Stream notification preferences
  Stream<Map<String, dynamic>> streamNotificationPreferences(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('notifications')
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground notification: ${message.notification?.title}');
    // This can trigger a local overlay or update UI
    // Typically, show a snackbar or dialog
  }

  /// Handle notification tap
  void _handleMessageTap(RemoteMessage message) {
    final actionUrl = message.data['actionUrl'] as String?;
    debugPrint('🎯 Notification tapped, navigating to: $actionUrl');
    
    // Navigate to the action URL
    // You'll need to integrate this with your router
    // This is a placeholder - implement based on your routing setup
  }
}
