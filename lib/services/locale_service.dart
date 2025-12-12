// lib/services/locale_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocaleService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection('users').doc(uid).collection('settings').doc('locale');

  Future<Map<String, dynamic>?> getLocaleDoc({String? uid}) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return null;
    final snap = await _ref(userId).get();
    return snap.exists ? snap.data() : null;
  }

  Stream<Map<String, dynamic>?> streamLocaleDoc({String? uid}) {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();
    return _ref(userId).snapshots().map((s) => s.data());
  }

  Future<void> setLocaleDoc({
    required String timezone,
    String? locale,
    String? currency,
    String? country,
    String? dateFormat,
    String? invoicePrefix,
    String? uid,
  }) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not signed in');
    await _ref(userId).set({
      'timezone': timezone,
      'locale': locale,
      'currency': currency,
      'country': country,
      'dateFormat': dateFormat,
      'invoicePrefix': invoicePrefix,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> ensureDefaults({String? uid}) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return;
    final doc = await _ref(userId).get();
    if (!doc.exists || doc.data() == null) {
      await _ref(userId).set({
        'locale': 'en-US',
        'currency': 'USD',
        'country': null,
        'invoicePrefix': 'INV-',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
