import 'package:cloud_firestore/cloud_firestore.dart';

/// Event-based reward trigger configuration
/// Rewards users for completing specific actions like creating invoices, etc.
class EventReward {
  final String id;
  final String title;
  final String condition; // e.g., "invoice_created", "expense_logged", "client_added"
  final int reward; // tokens to award
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? description;
  final int? maxRewardsPerDay; // null = unlimited
  final Map<String, dynamic>? metadata;

  EventReward({
    required this.id,
    required this.title,
    required this.condition,
    required this.reward,
    required this.active,
    this.createdAt,
    this.updatedAt,
    this.description,
    this.maxRewardsPerDay,
    this.metadata,
  });

  /// Create from Firestore JSON
  factory EventReward.fromJson(String id, Map<String, dynamic> json) {
    return EventReward(
      id: id,
      title: json['title'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      reward: json['reward'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] as DateTime?),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] as DateTime?),
      description: json['description'] as String?,
      maxRewardsPerDay: json['maxRewardsPerDay'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'title': title,
        'condition': condition,
        'reward': reward,
        'active': active,
        'description': description,
        'maxRewardsPerDay': maxRewardsPerDay,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  @override
  String toString() =>
      'EventReward(id: $id, title: $title, condition: $condition, reward: $reward, active: $active)';
}

/// Event reward claim record (tracks when users earned event rewards)
class EventRewardClaim {
  final String id;
  final String uid;
  final String eventRewardId;
  final String condition;
  final int tokensEarned;
  final DateTime claimedAt;
  final Map<String, dynamic>? metadata;

  EventRewardClaim({
    required this.id,
    required this.uid,
    required this.eventRewardId,
    required this.condition,
    required this.tokensEarned,
    required this.claimedAt,
    this.metadata,
  });

  /// Create from Firestore JSON
  factory EventRewardClaim.fromJson(String id, String uid, Map<String, dynamic> json) {
    return EventRewardClaim(
      id: id,
      uid: uid,
      eventRewardId: json['eventRewardId'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      tokensEarned: json['tokensEarned'] as int? ?? 0,
      claimedAt: json['claimedAt'] is Timestamp
          ? (json['claimedAt'] as Timestamp).toDate()
          : (json['claimedAt'] as DateTime? ?? DateTime.now()),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'eventRewardId': eventRewardId,
        'condition': condition,
        'tokensEarned': tokensEarned,
        'metadata': metadata,
        'claimedAt': FieldValue.serverTimestamp(),
      };

  @override
  String toString() =>
      'EventRewardClaim(uid: $uid, condition: $condition, tokens: $tokensEarned)';
}
