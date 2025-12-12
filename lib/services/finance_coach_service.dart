// lib/services/finance_coach_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinanceCoachService {
  final _functions = FirebaseFunctions.instance;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Fetch on-demand AI Finance Coach advice
  Future<Map<String, dynamic>?> getCoach() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final callable = _functions.httpsCallable('getFinanceCoachCallable');
      final resp = await callable.call();
      return Map<String, dynamic>.from(resp.data as Map);
    } catch (e) {
      // Fallback to last persisted coach doc
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _db.collection('users').doc(uid).collection('coach').doc('last').get();
      return doc.exists ? doc.data() : null;
    }
  }

  /// Stream the latest persisted coach document
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamLastCoach() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('coach')
        .doc('last')
        .snapshots();
  }

  /// Check cost & eligibility before calling AI (read-only, no tokens deducted)
  Future<Map<String, dynamic>?> getCoachCost() async {
    try {
      final callable = _functions.httpsCallable('getFinanceCoachCost');
      final resp = await callable.call();
      return Map<String, dynamic>.from(resp.data as Map);
    } catch (e) {
      // Silent fail → proceed without confirmation
      return null;
    }
  }
