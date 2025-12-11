import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background handler for Firebase Cloud Messaging
/// Must be a top-level function or static method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, as time permits.
  await Firebase.initializeApp();

  debugPrint('Handling a background message: ${message.messageId}');
  // Process the message here
  // This runs in the background and can't update the UI directly
}

/// Initialize Firebase Cloud Messaging
/// Call this in your app initialization (main.dart or bootstrap)
Future<void> initializeFirebaseMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request notification permissions (iOS, Android 13+)
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    debugPrint('🔔 User granted notification permission: '
        '${settings.authorizationStatus}');

    // Get APNs token (iOS only)
    final apnsToken = await messaging.getAPNSToken();
    if (apnsToken != null) {
      debugPrint('✅ APNs token retrieved (iOS)');
    }

    // Get FCM registration token
    final fcmToken = await messaging.getToken();
    debugPrint('🔑 FCM Token: $fcmToken');

    // Handle token refresh
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      // Update token in backend when changed
      // This is typically handled by PushNotificationService
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Got a message while in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: '
            '${message.notification!.title}');
      }

      // Show a snackbar or dialog here
      // Example:
      // showDialog(
      //   context: context,
      //   builder: (context) => AlertDialog(
      //     title: Text(message.notification?.title ?? 'Notification'),
      //     content: Text(message.notification?.body ?? ''),
      //     actions: [
      //       TextButton(
      //         onPressed: () => Navigator.pop(context),
      //         child: const Text('OK'),
      //       ),
      //     ],
      //   ),
      // );
    });

    // Handle notification open (when user taps on notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🎯 A new onMessageOpenedApp event was published!');
      debugPrint('Message data: ${message.data}');

      // Navigate to relevant screen based on message data
      _handleNotificationTap(message);
    });

    // Handle initial message (app opened from notification while closed)
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🎯 App opened from notification');
      _handleNotificationTap(initialMessage);
    }

    debugPrint('✅ Firebase Cloud Messaging initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize FCM: $e');
  }
}

/// Handle notification tap and navigate accordingly
void _handleNotificationTap(RemoteMessage message) {
  final actionUrl = message.data['actionUrl'] as String?;
  final notificationType = message.data['notificationType'] as String?;

  debugPrint('🎯 Notification tapped');
  debugPrint('Type: $notificationType');
  debugPrint('Action URL: $actionUrl');

  // This would normally navigate using your router
  // Example integration with your app router:
  // 
  // if (actionUrl != null) {
  //   // Use your app's navigation/routing system
  //   // GoRouter.of(context).go(actionUrl);
  // }
}

/// Request notification permissions manually
/// Call this if you want to request permissions at a specific time
Future<NotificationSettings> requestNotificationPermissions() async {
  final messaging = FirebaseMessaging.instance;
  return messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: true,
    provisional: false,
    sound: true,
  );
}

/// Get current FCM token
Future<String?> getFCMToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    return token;
  } catch (e) {
    debugPrint('❌ Failed to get FCM token: $e');
    return null;
  }
}

/// Subscribe to notification topic
/// Useful for sending bulk notifications to groups
Future<void> subscribeToNotificationTopic(String topic) async {
  try {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('✅ Subscribed to topic: $topic');
  } catch (e) {
    debugPrint('❌ Failed to subscribe to topic: $e');
  }
}

/// Unsubscribe from notification topic
Future<void> unsubscribeFromNotificationTopic(String topic) async {
  try {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('✅ Unsubscribed from topic: $topic');
  } catch (e) {
    debugPrint('❌ Failed to unsubscribe from topic: $e');
  }
}

/// Check if notifications are enabled
Future<bool> isNotificationsEnabled() async {
  try {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  } catch (e) {
    debugPrint('❌ Failed to check notification settings: $e');
    return false;
  }
}
