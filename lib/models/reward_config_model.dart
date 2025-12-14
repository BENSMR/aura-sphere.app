import 'package:cloud_firestore/cloud_firestore.dart';

/// Simplified reward configuration for loyalty system
class RewardConfig {
  final double dailyReward;
  final double streakMultiplier;
  final double weeklyBonus;
  final double monthlyBonus;
  final double signupBonus;
  final bool enabled;
  final DateTime? updatedAt;

  RewardConfig({
    required this.dailyReward,
    required this.streakMultiplier,
    required this.weeklyBonus,
    required this.monthlyBonus,
    required this.signupBonus,
    required this.enabled,
    this.updatedAt,
  });

  /// Create from Firestore JSON
  factory RewardConfig.fromJson(Map<String, dynamic> json) {
    return RewardConfig(
      dailyReward: (json['dailyReward'] as num?)?.toDouble() ?? 5.0,
      streakMultiplier: (json['streakMultiplier'] as num?)?.toDouble() ?? 1.2,
      weeklyBonus: (json['weeklyBonus'] as num?)?.toDouble() ?? 25.0,
      monthlyBonus: (json['monthlyBonus'] as num?)?.toDouble() ?? 100.0,
      signupBonus: (json['signupBonus'] as num?)?.toDouble() ?? 200.0,
      enabled: json['enabled'] as bool? ?? true,
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] as DateTime?),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'dailyReward': dailyReward,
        'streakMultiplier': streakMultiplier,
        'weeklyBonus': weeklyBonus,
        'monthlyBonus': monthlyBonus,
        'signupBonus': signupBonus,
        'enabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Calculate daily reward with streak multiplier
  double calculateDailyReward(int streakDays) {
    if (!enabled) return 0;
    final streakBonus = dailyReward * (streakMultiplier * streakDays);
    return dailyReward + streakBonus;
  }

  /// Calculate weekly reward
  double getWeeklyBonus() {
    return enabled ? weeklyBonus : 0;
  }

  /// Calculate monthly reward
  double getMonthlyBonus() {
    return enabled ? monthlyBonus : 0;
  }

  /// Get signup bonus for new users
  double getSignupBonus() {
    return enabled ? signupBonus : 0;
  }

  @override
  String toString() =>
      'RewardConfig(daily: $dailyReward, multiplier: $streakMultiplier, weekly: $weeklyBonus, monthly: $monthlyBonus, signup: $signupBonus, enabled: $enabled)';
}
