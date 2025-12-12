import 'package:flutter/material.dart';

// Loyalty System Constants
// Add to lib/config/constants.dart or create new file

// Collection paths
const String loyaltyCollectionPath = 'loyalty';
const String loyaltyProfileDoc = 'profile';
const String tokenAuditCollectionPath = 'token_audit';
const String paymentsProcessedCollection = 'payments_processed';
const String loyaltyConfigCollection = 'loyalty_config';
const String loyaltyConfigGlobalDoc = 'global';

// Default Loyalty Configuration
class LoyaltyDefaults {
  // Daily bonus
  static const int dailyBaseReward = 50;
  static const int dailyStreakBonus = 10;
  static const int dailyMaxStreakBonus = 500;

  // Weekly bonus
  static const int weeklyThresholdDays = 7;
  static const int weeklyBonus = 500;

  // Milestones (token thresholds)
  static const int milestoneBronzeThreshold = 1000;
  static const int milestoneSilverThreshold = 5000;
  static const int milestoneGoldThreshold = 10000;
  static const int milestonePlatinumThreshold = 25000;
  static const int milestoneDiamondThreshold = 50000;

  // Milestone rewards
  static const int milestoneBronzeReward = 100;
  static const int milestoneSilverReward = 500;
  static const int milestoneGoldReward = 1000;
  static const int milestonePlatinumReward = 2500;
  static const int milestoneDiamondReward = 5000;

  // Streak freeze duration (days)
  static const int streakFreezeDurationDays = 3;

  // Special day multipliers
  static const double christmasMultiplier = 2.0;
  static const double newYearMultiplier = 1.5;
  static const double independenceDayMultiplier = 1.5;
}

// Audit Action Types
class AuditActionTypes {
  static const String dailyBonus = 'daily_bonus';
  static const String purchase = 'purchase';
  static const String badgeAwarded = 'badge_awarded';
  static const String milestoneAchieved = 'milestone_achieved';
  static const String streakFrozen = 'streak_frozen';
  static const String referralBonus = 'referral_bonus';
  static const String adminAdjustment = 'admin_adjustment';
}

// Milestone IDs & Names
class MilestoneIds {
  static const String bronze = 'bronze';
  static const String silver = 'silver';
  static const String gold = 'gold';
  static const String platinum = 'platinum';
  static const String diamond = 'diamond';

  static const Map<String, String> names = {
    bronze: 'Bronze Member',
    silver: 'Silver Member',
    gold: 'Gold Member',
    platinum: 'Platinum Member',
    diamond: 'Diamond Member',
  };

  static const Map<String, int> thresholds = {
    bronze: LoyaltyDefaults.milestoneBronzeThreshold,
    silver: LoyaltyDefaults.milestoneSilverThreshold,
    gold: LoyaltyDefaults.milestoneGoldThreshold,
    platinum: LoyaltyDefaults.milestonePlatinumThreshold,
    diamond: LoyaltyDefaults.milestoneDiamondThreshold,
  };

  static const Map<String, int> rewards = {
    bronze: LoyaltyDefaults.milestoneBronzeReward,
    silver: LoyaltyDefaults.milestoneSilverReward,
    gold: LoyaltyDefaults.milestoneGoldReward,
    platinum: LoyaltyDefaults.milestonePlatinumReward,
    diamond: LoyaltyDefaults.milestoneDiamondReward,
  };

  static String getDisplayName(String id) {
    return names[id] ?? 'Unknown';
  }

  static int getThreshold(String id) {
    return thresholds[id] ?? 0;
  }

  static int getReward(String id) {
    return rewards[id] ?? 0;
  }
}

// Badge Categories
class BadgeCategories {
  static const String achievement = 'achievement';
  static const String milestone = 'milestone';
  static const String special = 'special';
  static const String seasonal = 'seasonal';
}

// Badge Definitions
class BadgeDefinitions {
  static const Map<String, Map<String, dynamic>> badges = {
    'first_login': {
      'name': 'Welcome',
      'category': BadgeCategories.special,
      'level': 1,
      'description': 'Earned on first login',
    },
    'streak_7': {
      'name': '7-Day Streak',
      'category': BadgeCategories.achievement,
      'level': 1,
      'description': 'Login 7 days in a row',
    },
    'streak_30': {
      'name': '30-Day Streak',
      'category': BadgeCategories.achievement,
      'level': 2,
      'description': 'Login 30 days in a row',
    },
    'streak_100': {
      'name': '100-Day Streak',
      'category': BadgeCategories.achievement,
      'level': 3,
      'description': 'Login 100 days in a row',
    },
    'spender_100': {
      'name': 'Big Spender',
      'category': BadgeCategories.achievement,
      'level': 1,
      'description': 'Spend 100 tokens',
    },
    'spender_1000': {
      'name': 'Major Spender',
      'category': BadgeCategories.achievement,
      'level': 2,
      'description': 'Spend 1000 tokens',
    },
    'holiday_christmas': {
      'name': '🎄 Holiday Cheer',
      'category': BadgeCategories.seasonal,
      'level': 1,
      'description': 'Earned during Christmas',
    },
    'milestone_bronze': {
      'name': 'Bronze Member',
      'category': BadgeCategories.milestone,
      'level': 1,
      'description': 'Reached Bronze status',
    },
    'milestone_diamond': {
      'name': '💎 Diamond Elite',
      'category': BadgeCategories.milestone,
      'level': 5,
      'description': 'Reached Diamond status',
    },
  };

  static Map<String, dynamic>? getBadge(String badgeId) {
    return badges[badgeId];
  }

  static bool badgeExists(String badgeId) {
    return badges.containsKey(badgeId);
  }
}

// Loyalty Feature Flags
class LoyaltyFeatureFlags {
  static const bool dailyBonusEnabled = true;
  static const bool weeklyBonusEnabled = true;
  static const bool milestonesEnabled = true;
  static const bool badgesEnabled = true;
  static const bool specialDayBonusEnabled = true;
  static const bool streakFreezeEnabled = true;
  static const bool auditLoggingEnabled = true;
}

// Loyalty UI Constants
class LoyaltyUIConstants {
  // Colors
  static const Color streakColor = Color(0xFFFF6B35); // Orange/fire color
  static const Color milestoneColor = Color(0xFF004E89); // Blue
  static const Color badgeColor = Color(0xFFD4A574); // Gold
  static const Color earnedColor = Color(0xFF2ECC71); // Green
  static const Color achievementColor = Color(0xFFF39C12); // Amber

  // Animation durations
  static const Duration streakAnimationDuration = Duration(milliseconds: 600);
  static const Duration bonusNotificationDuration = Duration(seconds: 3);
  static const Duration milestoneCelebrationDuration = Duration(seconds: 5);

  // Text strings
  static const String dailyBonusTitle = 'Daily Bonus';
  static const String streakTitle = 'Login Streak';
  static const String milestonesTitle = 'Milestones';
  static const String badgesTitle = 'Badges';
  static const String claimBonusButton = 'Claim Daily Bonus';
  static const String bonusClaimedToday = 'Already claimed today';
}

// Loyalty Validation Rules
class LoyaltyValidationRules {
  // Prevent claiming bonus multiple times per day
  static const Duration bonusClaimInterval = Duration(hours: 24);

  // Maximum audit log retention (auto-delete old logs)
  static const Duration auditLogRetention = Duration(days: 90);

  // Minimum tokens for meaningful transaction
  static const int minTokenAmount = 1;

  // Maximum daily bonus cap (to prevent abuse)
  static const int maxDailyBonus = 1000;

  // Streak freeze prevents earning for N days
  static const Duration streakFreezePeriod = Duration(days: 3);
}

// Firestore Index Configuration
class FirestoreIndexes {
  static const String auditLogsIndex = '''
    Collection: /users/{uid}/token_audit
    Field: createdAt (Descending)
    Status: Needed for pagination
  ''';

  static const String paymentsIndex = '''
    Collection: /payments_processed
    Field: processedAt (Descending)
    Status: Needed for payment history
  ''';
}
