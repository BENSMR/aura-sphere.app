import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    // Local notifications init
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    await _local.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (payload) {
        // handle tap
      },
    );

    // Request permissions for iOS
    if (Platform.isIOS) {
      await _fm.requestPermission(alert: true, badge: true, sound: true);
    }

    // Get token and save
    final token = await _fm.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        _showLocalNotification(notif.title ?? '', notif.body ?? '', message.data);
      }
    });

    // Background/terminated message tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageNavigation(message.data);
    });

    // Optional: handle token refresh
    _fm.onTokenRefresh.listen((t) => _saveTokenToFirestore(t));
  }

  Future<void> _saveTokenToFirestore(String token) async {
    // current user required
    // ensure you have auth currentUser; do not store tokens for anonymous sessions
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final docId = token.hashCode.toString();
    final doc = _db.collection('users').doc(uid).collection('devices').doc(docId);
    await doc.set({
      'token': token,
      'platform': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'web',
      'lastSeen': FieldValue.serverTimestamp(),
      'prefs': {'anomalies': true, 'invoices': true, 'inventory': true}
    }, SetOptions(merge: true));
  }

  Future<void> _showLocalNotification(String title, String body, Map<String, dynamic>? data) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'aura_channel', 'Aura Notifications', channelDescription: 'Alerts from AuraSphere',
      importance: Importance.max, priority: Priority.high);
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _local.show(0, title, body, details, payload: data?.toString());
  }

  void _handleMessageNavigation(Map<String, dynamic>? data) {
    if (data == null) return;
    // Example: open invoice screen
    if (data['type'] == 'invoice' && data['invoiceId'] != null) {
      final invoiceId = data['invoiceId'];
      // Navigator.pushNamed(context, '/invoice', arguments: invoiceId);
      debugPrint('Navigate to invoice $invoiceId');
    }
    // Add other deep links
  }

  Future<void> unregisterToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final tokens = await _db.collection('users').doc(uid).collection('devices').get();
    for (final doc in tokens.docs) {
      await doc.reference.delete();
    }
    await _fm.deleteToken();
  }
}
