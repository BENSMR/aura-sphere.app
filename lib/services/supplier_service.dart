import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/supplier.dart';
import 'dart:math';

class SupplierService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _suppliersRef(String uid) => _db.collection('users').doc(uid).collection('suppliers');

  Future<DocumentReference> createSupplier(String uid, Map<String, dynamic> payload) async {
    return await _suppliersRef(uid).add({
      ...payload,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSupplier(String uid, String supplierId, Map<String, dynamic> payload) async {
    await _suppliersRef(uid).doc(supplierId).update({
      ...payload,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSupplier(String uid, String supplierId) async {
    // optional: check references (orders/inventory) before delete
    await _suppliersRef(uid).doc(supplierId).delete();
  }

  Stream<List<Supplier>> streamSuppliers(String uid) {
    return _suppliersRef(uid).orderBy('name').snapshots().map((snap) =>
        snap.docs.map((d) => Supplier.fromDoc(d)).toList());
  }

  Future<List<Supplier>> searchSuppliers(String uid, String query, {int limit = 12}) async {
    if (query.trim().isEmpty) {
      final snap = await _suppliersRef(uid).orderBy('name').limit(limit).get();
      return snap.docs.map((d) => Supplier.fromDoc(d)).toList();
    }

    // 1) prefix search
    final lower = query.toLowerCase();
    final snap = await _suppliersRef(uid).orderBy('name').startAt([query]).endAt([query + '\uf8ff']).limit(limit).get();
    final results = snap.docs.map((d) => Supplier.fromDoc(d)).toList();
    if (results.isNotEmpty) return results;

    // 2) fallback - simple substring search (inefficient for large sets; ok for small catalogs)
    final allSnap = await _suppliersRef(uid).get();
    final list = allSnap.docs.map((d) => Supplier.fromDoc(d)).toList();
    final filtered = list.where((s) => s.name.toLowerCase().contains(lower)).toList();
    // 3) sort by closeness using simple Levenshtein-like heuristic
    filtered.sort((a, b) => _similarityScore(b.name, query).compareTo(_similarityScore(a.name, query)));
    return filtered.take(limit).toList();
  }

  // simple similarity score (bigger = better)
  double _similarityScore(String a, String b) {
    a = a.toLowerCase();
    b = b.toLowerCase();
    if (a == b) return 1.0;
    final common = <String>{};
    for (var i = 0; i < min(a.length, b.length); i++) {
      common.add(a.substring(i, i + 1));
    }
    final score = common.length / max(a.length, b.length);
    return score;
  }

  /// Try to find supplier by exact name; returns null if not found
  Future<String?> findSupplierIdByName(String uid, String name) async {
    final snap = await _suppliersRef(uid)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }
}
