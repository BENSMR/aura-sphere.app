// lib/services/finance_dashboard_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/finance_summary_model.dart';

class FinanceDashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? getCurrentUserId() => _auth.currentUser?.uid;

  Stream<FinanceSummary?> streamSummary() {
    final uid = getCurrentUserId();
    if (uid == null) {
      return Stream.value(null);
    }

    return _db
        .collection('users')
        .doc(uid)
        .collection('analytics')
        .doc('financeSummary')
        .snapshots()
        .map((doc) => doc.exists ? FinanceSummary.fromDoc(doc) : null);
  }

  Future<FinanceSummary?> getSummary() async {
    final uid = getCurrentUserId();
    if (uid == null) return null;

    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('analytics')
        .doc('financeSummary')
        .get();

    return doc.exists ? FinanceSummary.fromDoc(doc) : null;
  }
}
