// lib/services/timezone_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class TimezoneService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _ref(String uid) =>
    _db.collection('users').doc(uid).collection('settings').doc('timezone');

  /// Detect device timezone (IANA)
  Future<String> detectDeviceTimezone() async {
    try {
      final tz = await FlutterNativeTimezone.getLocalTimezone();
      return tz;
    } catch (e) {
      return 'UTC';
    }
  }

  /// Get user timezone doc
  Future<Map<String, dynamic>?> getUserTimezone({String? uid}) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return null;
    final snap = await _ref(userId).get();
    return snap.exists ? snap.data() : null;
  }

  /// Stream user timezone
  Stream<Map<String, dynamic>?> streamUserTimezone({String? uid}) {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();
    return _ref(userId).snapshots().map((s) => s.data());
  }

  /// Save / update timezone doc (merge)
  Future<void> setUserTimezone(String timezone, {String? locale, String? country, String? uid}) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not signed in');
    await _ref(userId).set({
      'timezone': timezone,
      'locale': locale,
      'country': country,
      'updatedAt': FieldValue.serverTimestamp()
    }, SetOptions(merge: true));
  }

  /// Auto-detect and set on first login if not present
  Future<void> ensureTimezone({String? uid}) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return;
    final doc = await _ref(userId).get();
    if (!doc.exists || doc.data() == null || doc.data()!['timezone'] == null) {
      final tz = await detectDeviceTimezone();
      await setUserTimezone(tz, uid: userId);
    }
  }
}
