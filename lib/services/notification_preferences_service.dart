// lib/services/notification_preferences_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPreferencesService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _prefsRef(String uid) =>
      _db.collection('users').doc(uid).collection('settings').doc('notification_preferences');

  Future<Map<String, dynamic>> getPrefs({String? uid}) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return {};
    final snap = await _prefsRef(userId).get();
    if (!snap.exists) return {};
    return snap.data()!;
  }

  Stream<Map<String, dynamic>> streamPrefs({String? uid}) {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();
    return _prefsRef(userId).snapshots().map((snap) => snap.data() ?? {});
  }

  Future<void> updatePrefs(Map<String, dynamic> patch, {String? uid}) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not signed in');
    await _prefsRef(userId).set(patch, SetOptions(merge: true));
  }

  // Convenience: set single category enabled/disabled
  Future<void> setCategoryEnabled(String category, bool enabled, {String? uid}) => updatePrefs({
    'enabled': { category: enabled }
  }, uid: uid);

  // Convenience: set min severity for a category
  Future<void> setMinSeverity(String category, String severity, {String? uid}) => updatePrefs({
    'minSeverity': { category: severity }
  }, uid: uid);

  Future<void> setGlobalDnd(bool enabled, {String? uid}) => updatePrefs({
    'globalDnd': enabled
  }, uid: uid);
}
