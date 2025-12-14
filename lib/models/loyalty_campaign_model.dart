import 'package:cloud_firestore/cloud_firestore.dart';

/// Promotional campaign configuration
/// Applies bonus multipliers during specific dates/periods
class LoyaltyCampaign {
  final String id;
  final String name;
  final DateTime campaignDate; // Start date or specific date
  final DateTime? endDate; // null = single day campaign
  final double multiplier; // e.g., 2.0 for 2x rewards
  final bool active;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  LoyaltyCampaign({
    required this.id,
    required this.name,
    required this.campaignDate,
    this.endDate,
    required this.multiplier,
    required this.active,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Check if campaign is currently active (date-wise)
  bool isDateActive() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (!active) return false;

    // Single day campaign
    if (endDate == null) {
      final campaignDayStart = DateTime(
        campaignDate.year,
        campaignDate.month,
        campaignDate.day,
      );
      final campaignDayEnd = DateTime(
        campaignDate.year,
        campaignDate.month,
        campaignDate.day,
        23,
        59,
        59,
      );

      return now.isAfter(campaignDayStart) && now.isBefore(campaignDayEnd);
    }

    // Multi-day campaign
    return now.isAfter(campaignDate) && now.isBefore(endDate!);
  }

  /// Create from Firestore JSON
  factory LoyaltyCampaign.fromJson(String id, Map<String, dynamic> json) {
    return LoyaltyCampaign(
      id: id,
      name: json['name'] as String? ?? '',
      campaignDate: json['campaignDate'] is Timestamp
          ? (json['campaignDate'] as Timestamp).toDate()
          : (json['campaignDate'] as DateTime? ?? DateTime.now()),
      endDate: json['endDate'] is Timestamp
          ? (json['endDate'] as Timestamp).toDate()
          : (json['endDate'] as DateTime?),
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      active: json['active'] as bool? ?? true,
      description: json['description'] as String?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] as DateTime?),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] as DateTime?),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'name': name,
        'campaignDate': campaignDate,
        'endDate': endDate,
        'multiplier': multiplier,
        'active': active,
        'description': description,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  @override
  String toString() =>
      'LoyaltyCampaign(id: $id, name: $name, multiplier: ${multiplier}x, active: $active, dateActive: ${isDateActive()})';
}

/// Campaign application history (track when campaigns were applied to users)
class CampaignApplicationLog {
  final String id;
  final String uid;
  final String campaignId;
  final String campaignName;
  final int baseReward;
  final int multipliedReward;
  final double multiplier;
  final DateTime appliedAt;
  final String? reason; // daily_bonus, event_reward, etc.
  final Map<String, dynamic>? metadata;

  CampaignApplicationLog({
    required this.id,
    required this.uid,
    required this.campaignId,
    required this.campaignName,
    required this.baseReward,
    required this.multipliedReward,
    required this.multiplier,
    required this.appliedAt,
    this.reason,
    this.metadata,
  });

  /// Create from Firestore JSON
  factory CampaignApplicationLog.fromJson(String id, String uid, Map<String, dynamic> json) {
    return CampaignApplicationLog(
      id: id,
      uid: uid,
      campaignId: json['campaignId'] as String? ?? '',
      campaignName: json['campaignName'] as String? ?? '',
      baseReward: json['baseReward'] as int? ?? 0,
      multipliedReward: json['multipliedReward'] as int? ?? 0,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      appliedAt: json['appliedAt'] is Timestamp
          ? (json['appliedAt'] as Timestamp).toDate()
          : (json['appliedAt'] as DateTime? ?? DateTime.now()),
      reason: json['reason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'campaignName': campaignName,
        'baseReward': baseReward,
        'multipliedReward': multipliedReward,
        'multiplier': multiplier,
        'reason': reason,
        'metadata': metadata,
        'appliedAt': FieldValue.serverTimestamp(),
      };

  @override
  String toString() =>
      'CampaignApplicationLog(campaign: $campaignName, base: $baseReward, multiplied: $multipliedReward)';
}
