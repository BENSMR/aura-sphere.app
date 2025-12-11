// lib/services/deal_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/deal_model.dart';

class DealService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String getCurrentUserId() {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  CollectionReference<Map<String, dynamic>> _dealsRef(String uid) {
    return _db.collection('users').doc(uid).collection('deals');
  }

  Stream<List<DealModel>> streamDealsByStage(String stage) {
    final uid = getCurrentUserId();
    return _dealsRef(uid)
        .where('stage', isEqualTo: stage)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DealModel.fromDoc(d)).toList());
  }

  Stream<List<DealModel>> streamAllOpenDeals() {
    final uid = getCurrentUserId();
    return _dealsRef(uid)
        .where('status', isEqualTo: 'open')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DealModel.fromDoc(d)).toList());
  }

  Stream<List<DealModel>> streamDealsByClient(String clientId) {
    final uid = getCurrentUserId();
    return _dealsRef(uid)
        .where('clientId', isEqualTo: clientId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DealModel.fromDoc(d)).toList());
  }

  Future<DealModel?> getDeal(String dealId) async {
    final uid = getCurrentUserId();
    final doc = await _dealsRef(uid).doc(dealId).get();
    if (!doc.exists) return null;
    return DealModel.fromDoc(doc);
  }

  Future<String> createDeal(DealModel deal) async {
    final uid = getCurrentUserId();
    final ref = await _dealsRef(uid).add(deal.toMap());
    return ref.id;
  }

  Future<void> updateDeal(String dealId, Map<String, dynamic> updates) async {
    final uid = getCurrentUserId();
    await _dealsRef(uid).doc(dealId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDealStage(String dealId, String newStage) async {
    final uid = getCurrentUserId();
    await _dealsRef(uid).doc(dealId).update({
      'stage': newStage,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markDealWon(String dealId) async {
    final uid = getCurrentUserId();
    await _dealsRef(uid).doc(dealId).update({
      'status': 'won',
      'stage': 'won',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markDealLost(String dealId, {String? reason}) async {
    final uid = getCurrentUserId();
    await _dealsRef(uid).doc(dealId).update({
      'status': 'lost',
      'stage': 'lost',
      if (reason != null) 'lossReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDeal(String dealId) async {
    final uid = getCurrentUserId();
    await _dealsRef(uid).doc(dealId).delete();
  }

  Future<Map<String, dynamic>> getDealStats() async {
    final uid = getCurrentUserId();
    final snapshot = await _dealsRef(uid).get();
    
    double totalValue = 0;
    double wonValue = 0;
    double openValue = 0;
    int totalDeals = snapshot.docs.length;
    int wonDeals = 0;
    int lostDeals = 0;
    int openDeals = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0).toDouble();
      final status = data['status'] ?? 'open';

      totalValue += amount;
      
      if (status == 'won') {
        wonValue += amount;
        wonDeals++;
      } else if (status == 'lost') {
        lostDeals++;
      } else {
        openValue += amount;
        openDeals++;
      }
    }

    final winRate = totalDeals > 0 ? (wonDeals / totalDeals * 100) : 0.0;

    return {
      'totalDeals': totalDeals,
      'wonDeals': wonDeals,
      'lostDeals': lostDeals,
      'openDeals': openDeals,
      'totalValue': totalValue,
      'wonValue': wonValue,
      'openValue': openValue,
      'winRate': winRate,
    };
  }
}
