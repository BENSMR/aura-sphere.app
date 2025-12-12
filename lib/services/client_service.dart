import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../data/models/client_model.dart';

class ClientService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ClientService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  CollectionReference get _clientCollection =>
      _db.collection('users').doc(_uid).collection('clients');

  /// Stream all clients, ordered by last activity
  Stream<List<ClientModel>> streamClients() {
    return _clientCollection
        .orderBy('lastActivityAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ClientModel.fromDoc(doc))
            .toList());
  }

  /// Get all clients once (one-time fetch)
  Future<List<ClientModel>> getClientsOnce() async {
    final snap = await _clientCollection
        .orderBy('lastActivityAt', descending: true)
        .get();
    return snap.docs.map((d) => ClientModel.fromDoc(d)).toList();
  }

  /// Get single client by ID
  Future<ClientModel?> getClientById(String id) async {
    final doc = await _clientCollection.doc(id).get();
    if (!doc.exists) return null;
    return ClientModel.fromDoc(doc);
  }

  /// Create new client
  Future<String> createClient({
    required String name,
    required String email,
    String phone = '',
    String company = '',
    String address = '',
    String country = '',
    String notes = '',
    List<String> tags = const [],
    String status = 'lead',
  }) async {
    final now = DateTime.now();
    final docRef = await _clientCollection.add({
      'userId': _uid,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'address': address,
      'country': country,
      'notes': notes,
      'tags': tags,
      'status': status,
      'aiScore': 0,
      'aiTags': [],
      'aiSummary': '',
      'sentiment': 'neutral',
      'lifetimeValue': 0.0,
      'totalInvoices': 0,
      'lastInvoiceAmount': 0.0,
      'churnRisk': 0,
      'vipStatus': false,
      'stabilityLevel': 'unknown',
      'timeline': {'events': []},
      'lastActivityAt': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
    return docRef.id;
  }

  /// Update existing client
  Future<void> updateClient(ClientModel client) async {
    await _clientCollection.doc(client.id).update(client.toMap());
  }

  /// Delete client
  Future<void> deleteClient(String id) async {
    await _clientCollection.doc(id).delete();
  }

  /// Search clients by name or email
  Future<List<ClientModel>> searchClients(String query) async {
    if (query.isEmpty) {
      return getClientsOnce();
    }

    final lowerQuery = query.toLowerCase();
    final snap = await _clientCollection.get();

    return snap.docs
        .map((doc) => ClientModel.fromDoc(doc))
        .where((client) =>
            client.name.toLowerCase().contains(lowerQuery) ||
            client.email.toLowerCase().contains(lowerQuery) ||
            client.company.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get clients by status
  Future<List<ClientModel>> getClientsByStatus(String status) async {
    final snap = await _clientCollection
        .where('status', isEqualTo: status)
        .orderBy('lastActivityAt', descending: true)
        .get();
    return snap.docs.map((d) => ClientModel.fromDoc(d)).toList();
  }

  /// Get clients by tag
  Future<List<ClientModel>> getClientsByTag(String tag) async {
    final snap = await _clientCollection
        .where('tags', arrayContains: tag)
        .orderBy('lastActivityAt', descending: true)
        .get();
    return snap.docs.map((d) => ClientModel.fromDoc(d)).toList();
  }

  /// Add value to client (when invoice is created/paid)
  Future<void> addClientValue({
    required String clientId,
    required double amount,
  }) async {
    final ref = _clientCollection.doc(clientId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final current = (data['totalValue'] ?? 0).toDouble();
      tx.update(ref, {
        'totalValue': current + amount,
        'lastActivityAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  /// Update client status
  Future<void> updateClientStatus(String clientId, String newStatus) async {
    assert(['lead', 'active', 'vip', 'lost'].contains(newStatus),
        'Invalid status');
    await _clientCollection.doc(clientId).update({
      'status': newStatus,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Add tag to client
  Future<void> addTagToClient(String clientId, String tag) async {
    await _clientCollection.doc(clientId).update({
      'tags': FieldValue.arrayUnion([tag]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Remove tag from client
  Future<void> removeTagFromClient(String clientId, String tag) async {
    await _clientCollection.doc(clientId).update({
      'tags': FieldValue.arrayRemove([tag]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Add note to client
  Future<void> addNoteToClient(String clientId, String note) async {
    final client = await getClientById(clientId);
    if (client == null) return;

    final updated = client.notes.isEmpty
        ? note
        : '${client.notes}\n${DateTime.now().toString()}: $note';

    await _clientCollection.doc(clientId).update({
      'notes': updated,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Record activity (updates lastActivityAt)
  Future<void> recordActivity(String clientId) async {
    await _clientCollection.doc(clientId).update({
      'lastActivityAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get total value across all clients
  Future<double> getTotalClientValue() async {
    final snap = await _clientCollection.get();
    double total = 0;
    for (var doc in snap.docs) {
      final value = (doc.data() as Map<String, dynamic>)['totalValue'] ?? 0.0;
      total += (value as num).toDouble();
    }
    return total;
  }

  /// Get client count by status
  Future<Map<String, int>> getClientCountByStatus() async {
    final snap = await _clientCollection.get();
    final counts = <String, int>{
      'lead': 0,
      'active': 0,
      'vip': 0,
      'lost': 0,
    };

    for (var doc in snap.docs) {
      final status =
          (doc.data() as Map<String, dynamic>)['status'] ?? 'lead' as String;
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }
  /// Update AI score for a client
  Future<void> updateAiScore(String clientId, int score) async {
    if (score < 0 || score > 100) {
      throw ArgumentError('Score must be between 0-100');
    }
    await _clientCollection.doc(clientId).update({
      'aiScore': score,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Update AI summary and tags
  Future<void> updateAiSummary(String clientId, {
    required String summary,
    required String sentiment,
    required List<String> aiTags,
  }) async {
    await _clientCollection.doc(clientId).update({
      'aiSummary': summary,
      'sentiment': sentiment,
      'aiTags': aiTags,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Update churn risk
  Future<void> updateChurnRisk(String clientId, int risk) async {
    if (risk < 0 || risk > 100) {
      throw ArgumentError('Risk must be between 0-100');
    }
    await _clientCollection.doc(clientId).update({
      'churnRisk': risk,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Record invoice payment
  Future<void> recordInvoicePayment(String clientId, double amount, DateTime paymentDate) async {
    await _clientCollection.doc(clientId).update({
      'lastPaymentDate': Timestamp.fromDate(paymentDate),
      'lifetimeValue': FieldValue.increment(amount),
      'lastActivityAt': Timestamp.fromDate(paymentDate),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Record invoice creation
  Future<void> recordInvoiceCreation(String clientId, double amount, DateTime invoiceDate) async {
    await _clientCollection.doc(clientId).update({
      'lastInvoiceDate': Timestamp.fromDate(invoiceDate),
      'lastInvoiceAmount': amount,
      'totalInvoices': FieldValue.increment(1),
      'lastActivityAt': Timestamp.fromDate(invoiceDate),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Add timeline event
  Future<void> addTimelineEvent(String clientId, {
    required String type,
    required String message,
    required double amount,
  }) async {
    final event = {
      'type': type,
      'message': message,
      'amount': amount,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };

    await _clientCollection.doc(clientId).update({
      'timeline.events': FieldValue.arrayUnion([event]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get lifetime value (total paid invoices)
  Future<double> getTotalLifetimeValue() async {
    final snap = await _clientCollection.get();
    double total = 0;
    for (var doc in snap.docs) {
      final value = (doc.data() as Map<String, dynamic>)['lifetimeValue'] ?? 0.0;
      total += (value as num).toDouble();
    }
    return total;
  }

  /// Get clients by churn risk threshold
  Future<List<ClientModel>> getClientsByChurnRisk(int minRisk) async {
    final snap = await _clientCollection
        .where('churnRisk', isGreaterThanOrEqualTo: minRisk)
        .orderBy('churnRisk', descending: true)
        .get();
    return snap.docs.map((d) => ClientModel.fromDoc(d)).toList();
  }

  /// Get VIP clients
  Future<List<ClientModel>> getVipClients() async {
    final snap = await _clientCollection
        .where('vipStatus', isEqualTo: true)
        .orderBy('lastActivityAt', descending: true)
        .get();
    return snap.docs.map((d) => ClientModel.fromDoc(d)).toList();
  }

  /// Get clients by AI score range
  Future<List<ClientModel>> getClientsByAiScore(int minScore, int maxScore) async {
    final snap = await _clientCollection
        .where('aiScore', isGreaterThanOrEqualTo: minScore)
        .where('aiScore', isLessThanOrEqualTo: maxScore)
        .orderBy('aiScore', descending: true)
        .get();
    return snap.docs.map((d) => ClientModel.fromDoc(d)).toList();
  }

  /// Toggle VIP status
  Future<void> toggleVipStatus(String clientId) async {
    final client = await getClientById(clientId);
    if (client == null) return;
    
    await _clientCollection.doc(clientId).update({
      'vipStatus': !client.vipStatus,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Update stability level
  Future<void> updateStabilityLevel(String clientId, String level) async {
    if (!['unknown', 'stable', 'unstable', 'risky'].contains(level)) {
      throw ArgumentError('Invalid stability level');
    }
    await _clientCollection.doc(clientId).update({
      'stabilityLevel': level,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Process invoice for client - comprehensive operation
  /// Handles: fetch, update totals, add timeline, trigger AI insights
  Future<ClientModel?> processInvoiceForClient({
    required String clientId,
    required double invoiceAmount,
    required String invoiceMessage,
  }) async {
    try {
      // Step 1: Fetch current client
      final client = await getClientById(clientId);
      if (client == null) {
        throw Exception('Client not found: $clientId');
      }

      final now = DateTime.now();
      final timelineEvent = {
        'type': 'invoice_created',
        'message': invoiceMessage,
        'amount': invoiceAmount,
        'createdAt': Timestamp.fromDate(now),
      };

      // Step 2-5: Batch update all fields atomically
      await _clientCollection.doc(clientId).update({
        // Increase totalInvoices
        'totalInvoices': FieldValue.increment(1),
        // Update lastInvoiceAmount
        'lastInvoiceAmount': invoiceAmount,
        // Update lastInvoiceDate
        'lastInvoiceDate': Timestamp.fromDate(now),
        // Push timeline event
        'timeline.events': FieldValue.arrayUnion([timelineEvent]),
        // Update activity timestamp
        'lastActivityAt': Timestamp.fromDate(now),
        // Update modified timestamp
        'updatedAt': Timestamp.fromDate(now),
      });

      // Step 6: Trigger AI insight update (asynchronous, non-blocking)
      _triggerAiInsightUpdate(clientId);

      // Return updated client
      return await getClientById(clientId);
    } catch (e) {
      print('Error processing invoice for client: $e');
      rethrow;
    }
  }

  /// Trigger AI insight update (non-blocking)
  /// This would typically call a Cloud Function for AI analysis
  Future<void> _triggerAiInsightUpdate(String clientId) async {
    try {
      // Get current client for analysis
      final client = await getClientById(clientId);
      if (client == null) return;

      // Calculate basic insights synchronously
      // More advanced AI would call a Cloud Function

      // Update AI metrics based on current data
      int newChurnRisk = client.churnRisk;
      int newAiScore = client.aiScore;
      String newStability = client.stabilityLevel;

      // Simple heuristics for churn risk
      if (client.totalInvoices > 5) {
        newChurnRisk = (newChurnRisk * 0.95).toInt(); // Decrease risk with more invoices
      }

      // Increase AI score with payment activity
      if (client.lifetimeValue > 0) {
        newAiScore = (client.lifetimeValue / 1000 * 10).toInt().clamp(0, 100);
      }

      // Determine stability based on invoice frequency
      if (client.totalInvoices > 10) {
        newStability = 'stable';
      } else if (client.totalInvoices > 3) {
        newStability = 'unstable';
      }

      // Update AI fields
      await _clientCollection.doc(clientId).update({
        'churnRisk': newChurnRisk,
        'aiScore': newAiScore,
        'stabilityLevel': newStability,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating AI insights: $e');
      // Don't rethrow - this is a non-blocking operation
    }
  }

  /// Process invoice payment for client (similar to processInvoiceForClient but for payments)
  /// Handles: fetch, record payment, update lifetime value, add timeline, trigger AI insights
  Future<ClientModel?> processInvoicePaymentForClient({
    required String clientId,
    required double paymentAmount,
    required String paymentMessage,
  }) async {
    try {
      // Step 1: Fetch current client
      final client = await getClientById(clientId);
      if (client == null) {
        throw Exception('Client not found: $clientId');
      }

      final now = DateTime.now();
      final timelineEvent = {
        'type': 'invoice_paid',
        'message': paymentMessage,
        'amount': paymentAmount,
        'createdAt': Timestamp.fromDate(now),
      };

      // Step 2-5: Batch update all fields atomically
      await _clientCollection.doc(clientId).update({
        // Update lifetimeValue (cumulative)
        'lifetimeValue': FieldValue.increment(paymentAmount),
        // Update lastPaymentDate
        'lastPaymentDate': Timestamp.fromDate(now),
        // Push timeline event
        'timeline.events': FieldValue.arrayUnion([timelineEvent]),
        // Update activity timestamp
        'lastActivityAt': Timestamp.fromDate(now),
        // Update modified timestamp
        'updatedAt': Timestamp.fromDate(now),
      });

      // Step 6: Trigger AI insight update (asynchronous, non-blocking)
      _triggerAiInsightUpdateForPayment(clientId);

      // Return updated client
      return await getClientById(clientId);
    } catch (e) {
      print('Error processing payment for client: $e');
      rethrow;
    }
  }

  /// Trigger AI insight update after payment (non-blocking)
  Future<void> _triggerAiInsightUpdateForPayment(String clientId) async {
    try {
      final client = await getClientById(clientId);
      if (client == null) return;

      // Reduce churn risk after payment
      int newChurnRisk = (client.churnRisk * 0.9).toInt();

      // Increase AI score based on lifetime value
      int newAiScore = (client.lifetimeValue / 500 * 10).toInt().clamp(0, 100);

      // VIP status based on lifetime value
      bool newVipStatus = client.lifetimeValue > 10000;

      // Update AI fields after payment
      await _clientCollection.doc(clientId).update({
        'churnRisk': newChurnRisk,
        'aiScore': newAiScore,
        'vipStatus': newVipStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating AI insights after payment: $e');
      // Don't rethrow - this is a non-blocking operation
    }
  }

  /// Process payment received - comprehensive payment handling
  /// Handles: increase lifetime value, update payment date, boost relationship score,
  /// push timeline event, update AI score, and update VIP status
  Future<ClientModel?> processPaymentReceived({
    required String clientId,
    required double paymentAmount,
    String paymentNote = "Payment received",
  }) async {
    try {
      // Step 1: Fetch current client
      final client = await getClientById(clientId);
      if (client == null) {
        throw Exception('Client not found: $clientId');
      }

      final now = DateTime.now();
      
      // Calculate relationship score boost (+20 capped at 100)
      final newAiScore = (client.aiScore + 20).clamp(0, 100);
      
      // Calculate new VIP status based on lifetime value
      final newLifetimeValue = client.lifetimeValue + paymentAmount;
      final newVipStatus = newLifetimeValue > 10000;

      final timelineEvent = {
        'type': 'payment_received',
        'message': paymentNote,
        'amount': paymentAmount,
        'createdAt': Timestamp.fromDate(now),
      };

      // Batch update all fields atomically
      await _clientCollection.doc(clientId).update({
        // Increase lifetime value
        'lifetimeValue': FieldValue.increment(paymentAmount),
        // Update last payment date
        'lastPaymentDate': Timestamp.fromDate(now),
        // Boost relationship score (+20, capped at 100)
        'aiScore': newAiScore,
        // Update VIP status based on lifetime value
        'vipStatus': newVipStatus,
        // Push timeline event
        'timeline.events': FieldValue.arrayUnion([timelineEvent]),
        // Update activity timestamp
        'lastActivityAt': Timestamp.fromDate(now),
        // Update modified timestamp
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update churn risk (decrease after payment)
      await _clientCollection.doc(clientId).update({
        'churnRisk': (client.churnRisk * 0.85).toInt().clamp(0, 100),
      });

      // Return updated client
      return await getClientById(clientId);
    } catch (e) {
      print('Error processing payment: $e');
      rethrow;
    }
  }

  /// Calculate churn risk based on activity and payment history
  /// Returns risk score (0-100):
  /// - Very High Risk (80-100): No payment in 90+ days OR low lifetime value + long inactivity
  /// - High Risk (60-80): No activity in 60+ days
  /// - Medium Risk (40-60): Some engagement decline
  /// - Low Risk (0-40): Active, recent payments
  int calculateChurnRisk(ClientModel client) {
    final now = DateTime.now();
    int riskScore = 0;

    // Factor 1: Days since last activity (lastActivityAt)
    if (client.lastActivityAt != null) {
      final daysSinceActivity = now.difference(client.lastActivityAt!).inDays;

      if (daysSinceActivity > 60) {
        // High risk: No activity in 60+ days
        riskScore += 60;
      } else if (daysSinceActivity > 30) {
        // Medium risk: Activity declining
        riskScore += 30;
      } else if (daysSinceActivity > 15) {
        // Low risk: Recent activity
        riskScore += 10;
      }
    } else {
      // No activity recorded yet - neutral
      riskScore += 20;
    }

    // Factor 2: Days since last payment (lastPaymentDate)
    if (client.lastPaymentDate != null) {
      final daysSincePayment = now.difference(client.lastPaymentDate!).inDays;

      if (daysSincePayment > 90) {
        // VERY HIGH RISK: No payment in 90+ days
        riskScore += 40; // Heavy penalty
      } else if (daysSincePayment > 60) {
        // High risk: Long payment drought
        riskScore += 25;
      } else if (daysSincePayment > 30) {
        // Medium risk: Extended non-payment
        riskScore += 15;
      }
    } else {
      // Never paid - high risk
      riskScore += 35;
    }

    // Factor 3: Lifetime value threshold
    if (client.lifetimeValue < 1000) {
      // Low lifetime value = higher risk
      riskScore += 15;
    } else if (client.lifetimeValue < 5000) {
      riskScore += 10;
    } else if (client.lifetimeValue >= 10000) {
      // High lifetime value = lower risk
      riskScore = (riskScore * 0.8).toInt(); // 20% reduction for loyal customers
    }

    // Factor 4: Combined risk - low lifetime value + long inactivity
    if (client.lifetimeValue < 2000 && client.lastActivityAt != null) {
      final daysSinceActivity = now.difference(client.lastActivityAt!).inDays;
      if (daysSinceActivity > 45) {
        // Significant penalty for low-value dormant clients
        riskScore += 20;
      }
    }

    // Factor 5: VIP discount (reduce risk if VIP)
    if (client.vipStatus) {
      riskScore = (riskScore * 0.7).toInt(); // 30% risk reduction for VIPs
    }

    return riskScore.clamp(0, 100);
  }

  /// Update all clients' churn risk scores based on activity and payment history
  /// Should be called periodically (e.g., via Cloud Function daily trigger)
  Future<void> updateAllClientChurnRisks() async {
    try {
      final clients = await getClientsOnce();
      
      for (final client in clients) {
        final newChurnRisk = calculateChurnRisk(client);
        
        // Only update if risk changed significantly (>5 points)
        if ((newChurnRisk - client.churnRisk).abs() > 5) {
          await _clientCollection.doc(client.id).update({
            'churnRisk': newChurnRisk,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }
      
      print('Updated churn risk for ${clients.length} clients');
    } catch (e) {
      print('Error updating all churn risks: $e');
      rethrow;
    }
  }

  /// Get high-risk clients (churn risk > 70)
  Future<List<ClientModel>> getHighRiskClients() async {
    final now = DateTime.now();
    final clients = await getClientsOnce();
    
    final highRisk = clients.where((client) {
      final churnRisk = calculateChurnRisk(client);
      return churnRisk > 70;
    }).toList();

    // Sort by risk descending
    highRisk.sort((a, b) => 
      calculateChurnRisk(b).compareTo(calculateChurnRisk(a))
    );

    return highRisk;
  }

  /// Get clients with no payment in 90+ days
  Future<List<ClientModel>> getClientsNoPay90Days() async {
    final clients = await getClientsOnce();
    final now = DateTime.now();
    
    return clients.where((client) {
      if (client.lastPaymentDate == null) return true;
      
      final daysSincePayment = now.difference(client.lastPaymentDate!).inDays;
      return daysSincePayment > 90;
    }).toList();
  }

  /// Get inactive clients (no activity in 60+ days)
  Future<List<ClientModel>> getInactiveClients60Days() async {
    final clients = await getClientsOnce();
    final now = DateTime.now();
    
    return clients.where((client) {
      if (client.lastActivityAt == null) return true;
      
      final daysSinceActivity = now.difference(client.lastActivityAt!).inDays;
      return daysSinceActivity > 60;
    }).toList();
  }

  /// Get low-value inactive clients (lifetime < 2000 + inactive 45+ days)
  Future<List<ClientModel>> getLowValueInactiveClients() async {
    final clients = await getClientsOnce();
    final now = DateTime.now();
    
    return clients.where((client) {
      if (client.lifetimeValue >= 2000) return false;
      if (client.lastActivityAt == null) return true;
      
      final daysSinceActivity = now.difference(client.lastActivityAt!).inDays;
      return daysSinceActivity > 45;
    }).toList();
  }

  /// Trigger Cloud Function to recalculate AI score and churn risk
  /// Called automatically by Firestore trigger, but can be called manually
  Future<Map<String, dynamic>> updateClientAIScore(String clientId) async {
    try {
      final functionsInstance = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      );
      
      final result = await functionsInstance.httpsCallable(
        'calculateClientAIScore',
      ).call({
        'clientId': clientId,
        'userId': _uid,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update AI score: $e');
    }
  }

  /// Trigger Cloud Function to recalculate scores for all clients
  /// Useful for batch updates after migrations
  Future<Map<String, dynamic>> recalculateAllClientScores() async {
    try {
      final functionsInstance = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      );
      
      final result = await functionsInstance.httpsCallable(
        'recalculateAllClientScoresV2',
      ).call({});

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to recalculate scores: $e');
    }
  }
}