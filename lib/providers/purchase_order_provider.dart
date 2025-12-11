import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/purchase_order_service.dart';
import '../models/purchase_order.dart';

class PurchaseOrderProvider extends ChangeNotifier {
  final PurchaseOrderService _service = PurchaseOrderService();
  List<PurchaseOrder> orders = [];
  bool loading = false;
  StreamSubscription? _sub;

  void startListening() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    loading = true;
    notifyListeners();
    _sub = _service.streamPOs(uid).listen((snap) {
      orders = snap.docs.map((d) => PurchaseOrder.fromDoc(d)).toList();
      loading = false;
      notifyListeners();
    });
  }

  Future<DocumentReference> create(Map<String, dynamic> payload) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return await _service.createPO(uid, payload);
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return await _service.updatePO(uid, id, payload);
  }

  Future<dynamic> receivePO(
    String poId,
    List<Map<String, dynamic>> receivedItems, {
    String? notes,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return await _service.receivePOViaFunction(uid, poId, receivedItems, notes: notes);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
