// lib/services/forecast_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForecastService {
  final _functions = FirebaseFunctions.instance;
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// Fetch forecast on-demand via callable
  Future<Map<String, dynamic>?> getForecast({int horizon = 90}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final callable = _functions.httpsCallable('getForecastCallable');
      final resp = await callable.call({'horizon': horizon});
      return Map<String, dynamic>.from(resp.data as Map);
    } catch (e) {
      // Optional: log error
      return null;
    }
  }

  /// Stream precomputed forecast document
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamForecastDoc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('forecasts')
        .doc('cashflow')
        .snapshots();
  }
}
