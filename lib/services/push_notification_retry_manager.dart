import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../utils/retry_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Push Notification Retry Manager
/// Handles failed notifications with exponential backoff and retry queue
class PushNotificationRetryManager {
  static const String _queueKey = 'push_notification_queue';
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SharedPreferences _prefs;

  PushNotificationRetryManager(this._prefs);

  /// Queue a notification for retry
  Future<void> queueNotificationForRetry(
    String userId,
    String title,
    String body, {
    Map<String, String>? data,
  }) async {
    final queue = _getQueue();
    queue.add({
      'userId': userId,
      'title': title,
      'body': body,
      'data': data ?? {},
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    });
    await _saveQueue(queue);
    debugPrint('[PushNotif] Queued notification for $userId');
  }

  /// Process queued notifications with retry logic
  Future<void> processQueuedNotifications() async {
    final queue = _getQueue();
    if (queue.isEmpty) return;

    debugPrint('[PushNotif] Processing ${queue.length} queued notifications');

    final policy = RetryPolicy(
      maxRetries: 5,
      initialDelay: const Duration(seconds: 5),
      backoffMultiplier: 1.5,
      maxDelay: const Duration(minutes: 5),
    );

    List<Map<String, dynamic>> failedNotifications = [];

    for (final notification in queue) {
      try {
        await RetryableOperation(
          operation: () => _sendNotificationToUser(
            notification['userId'],
            notification['title'],
            notification['body'],
            notification['data'],
          ),
          shouldRetry: (error) => _isRetryableError(error),
          onRetry: (attempt, error) {
            notification['retryCount'] = attempt;
            debugPrint('[PushNotif] Retry $attempt for ${notification['userId']}: $error');
          },
          policy: policy,
        ).execute();

        debugPrint('[PushNotif] ✓ Sent notification to ${notification['userId']}');
      } catch (e) {
        debugPrint('[PushNotif] ✗ Failed to send notification to ${notification['userId']}: $e');
        failedNotifications.add(notification);
      }
    }

    // Save only failed notifications back to queue
    await _saveQueue(failedNotifications);

    if (failedNotifications.isNotEmpty) {
      debugPrint('[PushNotif] ${failedNotifications.length} notifications still pending');
    }
  }

  /// Send notification to user via Cloud Function
  Future<void> _sendNotificationToUser(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    // Call your Cloud Function to send notification
    // This is a placeholder - implement your actual notification sending logic
    // Example:
    // final response = await FirebaseCloudFunctions.instance.call(
    //   'sendNotification',
    //   parameters: {
    //     'userId': userId,
    //     'title': title,
    //     'body': body,
    //     'data': data,
    //   },
    // );
  }

  /// Check if error is retryable
  bool _isRetryableError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('network') ||
           message.contains('timeout') ||
           message.contains('connection') ||
           message.contains('503') ||
           message.contains('502') ||
           message.contains('temporary');
  }

  /// Get current queue
  List<Map<String, dynamic>> _getQueue() {
    final jsonList = _prefs.getStringList(_queueKey) ?? [];
    return jsonList
        .map((json) => Map<String, dynamic>.from({
              ...json.split('|').asMap().entries.fold<Map<String, dynamic>>(
                {}, (map, entry) => map)
            }))
        .toList();
  }

  /// Save queue
  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    // Simple serialization - in production, use json_serializable
    final jsonList = queue.map((item) => item.toString()).toList();
    await _prefs.setStringList(_queueKey, jsonList);
  }
}
