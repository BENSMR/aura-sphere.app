import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // TODO: replace with your auth provider
  String get currentUserId {
    // e.g. return AuthProvider.of(context).userId;
    throw UnimplementedError('Implement currentUserId');
  }

  CollectionReference inventoryCollection(String uid) {
    return _db.collection('users').doc(uid).collection('inventory_items');
  }

  Stream<QuerySnapshot> streamItems(String uid) {
    return inventoryCollection(uid).snapshots();
  }

  Future<DocumentReference> addItem(String uid, Map<String, dynamic> item) async {
    final callable = _functions.httpsCallable('createInventoryItem');
    final res = await callable.call(item);
    final id = res.data['id'] as String;
    return inventoryCollection(uid).doc(id);
  }

  Future<void> adjustStockCallable(Map<String, dynamic> payload) async {
    final callable = _functions.httpsCallable('adjustStock');
    await callable.call(payload);
  }

  Future<void> intakeFromOCR(Map<String, dynamic> payload) async {
    final callable = _functions.httpsCallable('intakeStockFromOCR');
    await callable.call(payload);
  }

  Future<void> manualUpdateLocal(String uid, String itemId, Map<String, dynamic> updates) {
    return inventoryCollection(uid).doc(itemId).update(updates);
  }

  // simple helper to watch low-stock alerts
  Stream<DocumentSnapshot> streamInventoryAlerts(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('analytics')
        .doc('inventoryAlerts')
        .snapshots();
  }
}
