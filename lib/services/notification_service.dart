import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/logger.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permissions
    await _messaging.requestPermission();

    // Get token
    final token = await _messaging.getToken();
    Logger.info('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    Logger.info('Received message: ${message.notification?.title}');
    // TODO: Show local notification
  }
}
