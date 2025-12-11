// lib/models/deal_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DealModel {
  final String id;
  final String clientId;        // Link to CRM client
  final String title;           // e.g. "Website redesign for ACME"
  final double amount;          // Total deal value
  final String currency;        // e.g. "EUR"
  final String stage;           // "lead", "contacted", "proposal", "negotiation", "won", "lost"
  final double winProbability;  // 0–100
  final String status;          // "open", "won", "lost"
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expectedCloseDate;
  final String? source;         // "referral", "website", "cold_email", etc.
  final String? ownerId;        // user/team member who owns the deal
  final String? notes;
  final List<String> tags;      // ["high_priority", "upsell"]
  final Map<String, dynamic>? ai; // ai.score, ai.nextStep, ai.summary etc.

  DealModel({
    required this.id,
    required this.clientId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.stage,
    required this.winProbability,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.expectedCloseDate,
    this.source,
    this.ownerId,
    this.notes,
    this.tags = const [],
    this.ai,
  });

  factory DealModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DealModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'EUR',
      stage: data['stage'] ?? 'lead',
      winProbability: (data['winProbability'] ?? 0).toDouble(),
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedCloseDate:
          (data['expectedCloseDate'] as Timestamp?)?.toDate(),
      source: data['source'],
      ownerId: data['ownerId'],
      notes: data['notes'],
      tags: (data['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      ai: data['ai'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'title': title,
      'amount': amount,
      'currency': currency,
      'stage': stage,
      'winProbability': winProbability,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (expectedCloseDate != null)
        'expectedCloseDate': expectedCloseDate,
      if (source != null) 'source': source,
      if (ownerId != null) 'ownerId': ownerId,
      if (notes != null) 'notes': notes,
      'tags': tags,
      if (ai != null) 'ai': ai,
    };
  }
}
