import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/supplier_service.dart';
import '../models/supplier.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierService _service = SupplierService();
  List<Supplier> suppliers = [];
  bool loading = false;

  void startListening() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    loading = true;
    notifyListeners();
    _service.streamSuppliers(uid).listen((list) {
      suppliers = list;
      loading = false;
      notifyListeners();
    });
  }

  Future<List<Supplier>> search(String query) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return await _service.searchSuppliers(uid, query);
  }

  Future<DocumentReference> add(Map<String, dynamic> payload) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return await _service.createSupplier(uid, payload);
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return await _service.updateSupplier(uid, id, payload);
  }

  Future<void> remove(String id) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return await _service.deleteSupplier(uid, id);
  }
}
