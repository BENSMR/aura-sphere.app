// lib/services/notification_audit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationAuditService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream audit entries for current user UID
  Stream<List<Map<String, dynamic>>> streamAuditForUser(String uid, {int limit = 100}) {
    return _db
        .collection('notifications_audit')
        .where('targetUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              // normalize timestamp to DateTime if needed
              final ts = data['createdAt'];
              data['createdAtParsed'] = ts is Timestamp ? ts.toDate() : null;
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Optional: get last N entries once
  Future<List<Map<String, dynamic>>> fetchAuditForUser(String uid, {int limit = 200}) async {
    final snap = await _db
        .collection('notifications_audit')
        .where('targetUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      final ts = data['createdAt'];
      data['createdAtParsed'] = ts is Timestamp ? ts.toDate() : null;
      data['id'] = d.id;
      return data;
    }).toList();
  }
}
