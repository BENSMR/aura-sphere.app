import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  final FirebaseDynamicLinks _dynamicLinks = FirebaseDynamicLinks.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<String?> _sessionController = StreamController.broadcast();

  Stream<String?> get onSession => _sessionController.stream;

  void init() {
    // Handle links when app is in background or closed
    _dynamicLinks.onLink.listen((PendingDynamicLinkData data) {
      _parseSessionId(data.link);
    }).onError((error) {
      debugPrint('Dynamic link error: $error');
    });

    // Handle initial link (app opened from cold start)
    _dynamicLinks.getInitialLink().then((data) {
      if (data?.link != null) _parseSessionId(data!.link);
    }).catchError((e) {
      debugPrint('Failed to get initial dynamic link: $e');
    });
  }

  void handleCustomScheme(Uri uri) {
    _parseSessionId(uri);
  }

  void _parseSessionId(Uri? uri) {
    if (uri == null) return;
    final sessionId = uri.queryParameters['session_id'] ??
        uri.queryParameters['sessionId'] ??
        uri.queryParameters['session'];
    if (sessionId != null && sessionId.isNotEmpty) {
      _sessionController.add(sessionId);
    }
  }

  /// Wait for Stripe webhook to process payment and credit tokens.
  /// Returns true if processed within timeout, false if timeout.
  Future<bool> waitForPaymentProcessed(
    String sessionId, {
    Duration timeout = const Duration(seconds: 25),
    Duration interval = const Duration(seconds: 1),
  }) async {
    final docRef = _firestore.collection('payments_processed').doc(sessionId);
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final snapshot = await docRef.get();
      if (snapshot.exists) return true;
      await Future.delayed(interval);
    }
    return false;
  }

  void dispose() {
    _sessionController.close();
  }
}
