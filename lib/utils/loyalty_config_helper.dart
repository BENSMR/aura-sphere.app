import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loyalty_config_model.dart';
import '../models/reward_config_model.dart';

/// Loyalty configuration utility helper
/// Provides static methods to fetch reward settings
class LoyaltyConfigHelper {
  static final _firestore = FirebaseFirestore.instance;

  // Cache for config to avoid excessive reads
  static LoyaltyConfig? _cachedConfig;
  static DateTime? _configCacheTime;
  static const _cacheExpiry = Duration(minutes: 10);

  static RewardConfig? _cachedRewardConfig;
  static DateTime? _rewardCacheTime;

  /// Get daily reward amount from config
  static Future<int> getDailyReward() async {
    try {
      final config = await getLoyaltyConfig();
      return config?.daily.baseReward ?? 50;
    } catch (e) {
      print('Error getting daily reward: $e');
      return 50; // fallback
    }
  }

  /// Get streak bonus multiplier
  static Future<int> getStreakBonus() async {
    try {
      final config = await getLoyaltyConfig();
      return config?.daily.streakBonus ?? 10;
    } catch (e) {
      print('Error getting streak bonus: $e');
      return 10; // fallback
    }
  }

  /// Get max streak bonus cap
  static Future<int> getMaxStreakBonus() async {
    try {
      final config = await getLoyaltyConfig();
      return config?.daily.maxStreakBonus ?? 500;
    } catch (e) {
      print('Error getting max streak bonus: $e');
      return 500; // fallback
    }
  }

  /// Get weekly bonus amount
  static Future<int> getWeeklyBonus() async {
    try {
      final config = await getLoyaltyConfig();
      return config?.weekly.bonus ?? 500;
    } catch (e) {
      print('Error getting weekly bonus: $e');
      return 500; // fallback
    }
  }

  /// Get weekly threshold (days)
  static Future<int> getWeeklyThreshold() async {
    try {
      final config = await getLoyaltyConfig();
      return config?.weekly.thresholdDays ?? 7;
    } catch (e) {
      print('Error getting weekly threshold: $e');
      return 7; // fallback
    }
  }

  /// Get simplified reward daily amount
  static Future<double> getRewardDaily() async {
    try {
      final config = await getRewardConfig();
      return config?.dailyReward ?? 5.0;
    } catch (e) {
      print('Error getting reward daily: $e');
      return 5.0; // fallback
    }
  }

  /// Get streak multiplier
  static Future<double> getStreakMultiplier() async {
    try {
      final config = await getRewardConfig();
      return config?.streakMultiplier ?? 1.2;
    } catch (e) {
      print('Error getting streak multiplier: $e');
      return 1.2; // fallback
    }
  }

  /// Get signup bonus
  static Future<double> getSignupBonus() async {
    try {
      final config = await getRewardConfig();
      return config?.getSignupBonus() ?? 200.0;
    } catch (e) {
      print('Error getting signup bonus: $e');
      return 200.0; // fallback
    }
  }

  /// Get monthly bonus
  static Future<double> getMonthlyBonus() async {
    try {
      final config = await getRewardConfig();
      return config?.getMonthlyBonus() ?? 100.0;
    } catch (e) {
      print('Error getting monthly bonus: $e');
      return 100.0; // fallback
    }
  }

  /// Get full loyalty configuration (with caching)
  static Future<LoyaltyConfig?> getLoyaltyConfig() async {
    try {
      // Check cache validity
      if (_cachedConfig != null && _configCacheTime != null) {
        if (DateTime.now().difference(_configCacheTime!) < _cacheExpiry) {
          return _cachedConfig;
        }
      }

      // Fetch from Firestore
      final snap = await _firestore
          .collection('loyalty_config')
          .doc('global')
          .get();

      if (snap.exists) {
        final config = LoyaltyConfig.fromJson(snap.data() ?? {});
        _cachedConfig = config;
        _configCacheTime = DateTime.now();
        return config;
      }

      return null;
    } catch (e) {
      print('Error fetching loyalty config: $e');
      return null;
    }
  }

  /// Get simplified reward configuration (with caching)
  static Future<RewardConfig?> getRewardConfig() async {
    try {
      // Check cache validity
      if (_cachedRewardConfig != null && _rewardCacheTime != null) {
        if (DateTime.now().difference(_rewardCacheTime!) < _cacheExpiry) {
          return _cachedRewardConfig;
        }
      }

      // Fetch from Firestore
      final snap = await _firestore
          .collection('reward_config')
          .doc('global')
          .get();

      if (snap.exists) {
        final config = RewardConfig.fromJson(snap.data() ?? {});
        _cachedRewardConfig = config;
        _rewardCacheTime = DateTime.now();
        return config;
      }

      return null;
    } catch (e) {
      print('Error fetching reward config: $e');
      return null;
    }
  }

  /// Clear config cache (useful after updates)
  static void clearCache() {
    _cachedConfig = null;
    _configCacheTime = null;
    _cachedRewardConfig = null;
    _rewardCacheTime = null;
  }

  /// Get milestone configuration
  static Future<List<MilestoneItem>?> getMilestones() async {
    try {
      final config = await getLoyaltyConfig();
      return config?.milestones;
    } catch (e) {
      print('Error getting milestones: $e');
      return null;
    }
  }

  /// Get special day multiplier for a specific date
  static Future<double> getSpecialDayMultiplier(DateTime date) async {
    try {
      final config = await getLoyaltyConfig();
      if (config?.specialDays == null || config!.specialDays!.isEmpty) {
        return 1.0;
      }

      final dateISO = '${String.fromCharCode(date.month).padLeft(2, '0')}-${String.fromCharCode(date.day).padLeft(2, '0')}';
      
      final specialDay = config.specialDays!.firstWhere(
        (sd) => sd.dateISO == dateISO,
        orElse: () => SpecialDay(dateISO: '', bonusMultiplier: 1.0, name: ''),
      );

      return specialDay.dateISO.isNotEmpty ? specialDay.bonusMultiplier : 1.0;
    } catch (e) {
      print('Error getting special day multiplier: $e');
      return 1.0;
    }
  }

  /// Stream loyalty configuration (real-time updates)
  static Stream<LoyaltyConfig?> streamLoyaltyConfig() {
    return _firestore
        .collection('loyalty_config')
        .doc('global')
        .snapshots()
        .map((snap) {
      if (snap.exists) {
        final config = LoyaltyConfig.fromJson(snap.data() ?? {});
        _cachedConfig = config;
        _configCacheTime = DateTime.now();
        return config;
      }
      return null;
    });
  }

  /// Stream reward configuration (real-time updates)
  static Stream<RewardConfig?> streamRewardConfig() {
    return _firestore
        .collection('reward_config')
        .doc('global')
        .snapshots()
        .map((snap) {
      if (snap.exists) {
        final config = RewardConfig.fromJson(snap.data() ?? {});
        _cachedRewardConfig = config;
        _rewardCacheTime = DateTime.now();
        return config;
      }
      return null;
    });
  }
}
