import 'package:cloud_firestore/cloud_firestore.dart';

class TimelineEvent {
  final String id;
  final String type; // "invoice" | "payment" | "note" | "task" | "ai" | "system"
  final String title;
  final String description;
  final double? amount;
  final String? currency;
  final String? sourceId;
  final DateTime createdAt;
  final Map<String, dynamic>? aiImpact;
  final String createdBy; // userId | "system" | "ai"

  TimelineEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.amount,
    this.currency,
    this.sourceId,
    required this.createdAt,
    this.aiImpact,
    required this.createdBy,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json, String id) {
    return TimelineEvent(
      id: id,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      currency: json['currency'] as String?,
      sourceId: json['sourceId'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      aiImpact: json['aiImpact'] as Map<String, dynamic>?,
      createdBy: json['createdBy'] as String,
    );
  }

  // Alternative factory for simpler map structure
  factory TimelineEvent.fromMap(String id, Map<String, dynamic> map) {
    return TimelineEvent(
      id: id,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : null,
      currency: map['currency'] as String?,
      sourceId: map['sourceId'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      aiImpact: map['aiImpact'] as Map<String, dynamic>?,
      createdBy: (map['createdBy'] ?? 'system') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (sourceId != null) 'sourceId': sourceId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (aiImpact != null) 'aiImpact': aiImpact,
      'createdBy': createdBy,
    };
  }

  // Helper to create AI impact map
  static Map<String, dynamic> createAiImpact({
    int relationshipDelta = 0,
    int riskDelta = 0,
    int valueDelta = 0,
  }) {
    return {
      'relationshipDelta': relationshipDelta,
      'riskDelta': riskDelta,
      'valueDelta': valueDelta,
    };
  }

  // Get icon for timeline type
  String getIcon() {
    switch (type) {
      case 'invoice':
        return '📄';
      case 'payment':
        return '💰';
      case 'note':
        return '📝';
      case 'task':
        return '✅';
      case 'ai':
        return '🤖';
      case 'system':
        return '⚙️';
      default:
        return '•';
    }
  }

  // Get color for timeline type
  String getColorHex() {
    switch (type) {
      case 'invoice':
        return '#2196F3'; // Blue
      case 'payment':
        return '#4CAF50'; // Green
      case 'note':
        return '#FF9800'; // Orange
      case 'task':
        return '#9C27B0'; // Purple
      case 'ai':
        return '#00BCD4'; // Cyan
      case 'system':
        return '#757575'; // Grey
      default:
        return '#000000';
    }
  }
}
