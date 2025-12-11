import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/timeline_event.dart';

class TimelineService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  // Stream timeline with automatic user ID
  Stream<List<TimelineEvent>> streamTimeline(String clientId) {
    final userId = _getCurrentUserId();
    return _db
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(clientId)
        .collection('timeline')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => TimelineEvent.fromMap(d.id, d.data()))
            .toList());
  }

  // Static method for custom user ID (backward compatibility)
  static Stream<List<TimelineEvent>> streamTimelineForUser(
      String userId, String clientId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(clientId)
        .collection('timeline')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => TimelineEvent.fromMap(d.id, d.data()))
            .toList());
  }

  // Add timeline event to client
  Future<String> addTimelineEvent({
    required String clientId,
    required String type,
    required String title,
    required String description,
    double? amount,
    String? currency,
    String? sourceId,
    Map<String, dynamic>? aiImpact,
    String? createdBy,
  }) async {
    final userId = _getCurrentUserId();
    final eventRef = _db
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(clientId)
        .collection('timeline')
        .doc();

    final event = TimelineEvent(
      id: eventRef.id,
      type: type,
      title: title,
      description: description,
      amount: amount,
      currency: currency,
      sourceId: sourceId,
      createdAt: DateTime.now(),
      aiImpact: aiImpact,
      createdBy: createdBy ?? userId,
    );

    await eventRef.set(event.toJson());
    return eventRef.id;
  }

  // Add invoice creation event
  Future<String> addInvoiceEvent({
    required String clientId,
    required String invoiceId,
    required String invoiceNumber,
    required double amount,
    required String currency,
  }) async {
    return addTimelineEvent(
      clientId: clientId,
      type: 'invoice',
      title: 'Invoice Created',
      description: 'Invoice $invoiceNumber for ${_formatCurrency(amount, currency)}',
      amount: amount,
      currency: currency,
      sourceId: invoiceId,
      aiImpact: TimelineEvent.createAiImpact(
        relationshipDelta: 2,
        valueDelta: 5,
      ),
      createdBy: 'system',
    );
  }

  // Add payment event
  Future<String> addPaymentEvent({
    required String clientId,
    required String invoiceId,
    required String invoiceNumber,
    required double amount,
    required String currency,
    String? paymentMethod,
  }) async {
    return addTimelineEvent(
      clientId: clientId,
      type: 'payment',
      title: 'Payment Received',
      description: 'Payment of ${_formatCurrency(amount, currency)} for Invoice $invoiceNumber${paymentMethod != null ? " via $paymentMethod" : ""}',
      amount: amount,
      currency: currency,
      sourceId: invoiceId,
      aiImpact: TimelineEvent.createAiImpact(
        relationshipDelta: 5,
        riskDelta: -5,
        valueDelta: 3,
      ),
      createdBy: 'system',
    );
  }

  // Add note event
  Future<String> addNoteEvent({
    required String clientId,
    required String noteContent,
  }) async {
    return addTimelineEvent(
      clientId: clientId,
      type: 'note',
      title: 'Note Added',
      description: noteContent,
      aiImpact: TimelineEvent.createAiImpact(relationshipDelta: 1),
    );
  }

  // Add task event
  Future<String> addTaskEvent({
    required String clientId,
    required String taskTitle,
    required String taskDescription,
  }) async {
    return addTimelineEvent(
      clientId: clientId,
      type: 'task',
      title: taskTitle,
      description: taskDescription,
      aiImpact: TimelineEvent.createAiImpact(relationshipDelta: 1),
    );
  }

  // Add AI-generated insight event
  Future<String> addAiInsightEvent({
    required String clientId,
    required String insight,
  }) async {
    return addTimelineEvent(
      clientId: clientId,
      type: 'ai',
      title: 'AI Insight Generated',
      description: insight,
      createdBy: 'ai',
    );
  }

  // Add system event
  Future<String> addSystemEvent({
    required String clientId,
    required String title,
    required String description,
    Map<String, dynamic>? aiImpact,
  }) async {
    return addTimelineEvent(
      clientId: clientId,
      type: 'system',
      title: title,
      description: description,
      aiImpact: aiImpact,
      createdBy: 'system',
    );
  }

  // Get timeline events for a client
  Stream<List<TimelineEvent>> getTimelineEvents(String clientId) {
    final userId = _getCurrentUserId();
    return _db
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(clientId)
        .collection('timeline')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TimelineEvent.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Get timeline events by type
  Stream<List<TimelineEvent>> getTimelineEventsByType(
    String clientId,
    String type,
  ) {
    final userId = _getCurrentUserId();
    return _db
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(clientId)
        .collection('timeline')
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TimelineEvent.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Get recent timeline events (last N days)
  Stream<List<TimelineEvent>> getRecentTimelineEvents(
    String clientId, {
    int days = 30,
  }) {
    final userId = _getCurrentUserId();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return _db
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(clientId)
        .collection('timeline')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffDate))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TimelineEvent.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Delete timeline event
  Future<void> deleteTimelineEvent(String clientId, String eventId) async {
    final userId = _getCurrentUserId();
    await _db
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(clientId)
        .collection('timeline')
        .doc(eventId)
        .delete();
  }

  // Update timeline event
  Future<void> updateTimelineEvent(
    String clientId,
    String eventId,
    Map<String, dynamic> updates,
  ) async {
    final userId = _getCurrentUserId();
    await _db
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(clientId)
        .collection('timeline')
        .doc(eventId)
        .update(updates);
  }

  // Get timeline stats for client
  Future<Map<String, int>> getTimelineStats(String clientId) async {
    final userId = _getCurrentUserId();
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(clientId)
        .collection('timeline')
        .get();

    final stats = <String, int>{
      'total': snapshot.docs.length,
      'invoice': 0,
      'payment': 0,
      'note': 0,
      'task': 0,
      'ai': 0,
      'system': 0,
    };

    for (final doc in snapshot.docs) {
      final type = doc.data()['type'] as String?;
      if (type != null && stats.containsKey(type)) {
        stats[type] = stats[type]! + 1;
      }
    }

    return stats;
  }

  // Helper to format currency
  String _formatCurrency(double amount, String currency) {
    return '$currency${amount.toStringAsFixed(2)}';
  }
}
