import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_functions/firebase_functions.dart';
import '../models/purchase_order.dart';

class PurchaseOrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference _poRef(String uid) =>
      _db.collection('users').doc(uid).collection('purchase_orders');

  Future<DocumentReference> createPO(String uid, Map<String, dynamic> payload) {
    return _poRef(uid).add({
      ...payload,
      'createdAt': FieldValue.serverTimestamp(),
      'status': payload['status'] ?? 'draft'
    });
  }

  Future<void> updatePO(
    String uid,
    String poId,
    Map<String, dynamic> payload,
  ) async {
    await _poRef(uid).doc(poId).update({
      ...payload,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  Future<void> deletePO(String uid, String poId) async {
    await _poRef(uid).doc(poId).delete();
  }

  Stream<QuerySnapshot> streamPOs(String uid) {
    return _poRef(uid).orderBy('createdAt', descending: true).snapshots();
  }

  Future<dynamic> receivePOViaFunction(
    String uid,
    String poId,
    List<Map<String, dynamic>> receivedItems, {
    String? notes,
  }) async {
    final callable = _functions.httpsCallable('receivePurchaseOrder');
    final res = await callable.call({
      'poId': poId,
      'receivedItems': receivedItems,
      'notes': notes
    });
    return res.data;
  }
}

