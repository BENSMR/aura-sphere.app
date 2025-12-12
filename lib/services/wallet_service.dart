import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<int> streamBalance() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.value(0);

    return _db
        .collection('users')
        .doc(uid)
        .collection('wallet')
        .doc('aura')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return 0;
      final data = snapshot.data()!;
      return (data['balance'] as num?)?.toInt() ?? 0;
    });
  }

  void refresh() {
    // Real-time stream; no-op here unless polling is added later
  }
}
