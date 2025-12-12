import 'package:flutter/material.dart';
import '../models/loyalty_model.dart';
import '../models/loyalty_transactions_model.dart';
import '../models/loyalty_config_model.dart';
import '../services/loyalty_service.dart';

class LoyaltyProvider extends ChangeNotifier {
  final LoyaltyService _loyaltyService = LoyaltyService();

  // State
  UserLoyalty? _userLoyalty;
  LoyaltyConfig? _loyaltyConfig;
  List<TokenAuditEntry> _auditLogs = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  UserLoyalty? get userLoyalty => _userLoyalty;
  LoyaltyConfig? get loyaltyConfig => _loyaltyConfig;
  List<TokenAuditEntry> get auditLogs => _auditLogs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed properties
  int get currentStreak => _userLoyalty?.streak.current ?? 0;
  int get lifetimeEarned => _userLoyalty?.totals.lifetimeEarned ?? 0;
  int get lifetimeSpent => _userLoyalty?.totals.lifetimeSpent ?? 0;
  int get badgeCount => _userLoyalty?.badges.length ?? 0;
  bool get isBronze => _userLoyalty?.milestones.bronze ?? false;
  bool get isSilver => _userLoyalty?.milestones.silver ?? false;
  bool get isGold => _userLoyalty?.milestones.gold ?? false;
  bool get isPlatinum => _userLoyalty?.milestones.platinum ?? false;
  bool get isDiamond => _userLoyalty?.milestones.diamond ?? false;

  // Initialize user loyalty
  Future<void> initializeUserLoyalty(String uid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _loyaltyService.initializeLoyaltyProfile(uid);
      await fetchUserLoyalty(uid);
    } catch (e) {
      _error = e.toString();
      print('Error initializing user loyalty: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch user loyalty data
  Future<void> fetchUserLoyalty(String uid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _userLoyalty = await _loyaltyService.getUserLoyalty(uid);
    } catch (e) {
      _error = e.toString();
      print('Error fetching user loyalty: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stream user loyalty for real-time updates
  Stream<UserLoyalty?> streamUserLoyalty(String uid) {
    return _loyaltyService.streamUserLoyalty(uid).map((loyalty) {
      _userLoyalty = loyalty;
      notifyListeners();
      return loyalty;
    });
  }

  // Process daily login
  Future<int> processDailyLogin(String uid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final reward = await _loyaltyService.processDailyLogin(uid);
      await fetchUserLoyalty(uid);
      return reward;
    } catch (e) {
      _error = e.toString();
      print('Error processing daily login: $e');
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Record payment
  Future<void> recordPayment(String sessionId, String uid, String packId, int tokens) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _loyaltyService.recordPaymentProcessed(sessionId, uid, packId, tokens);
      await fetchUserLoyalty(uid);
    } catch (e) {
      _error = e.toString();
      print('Error recording payment: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Award badge
  Future<void> awardBadge(String uid, LoyaltyBadge badge) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _loyaltyService.awardBadge(uid, badge);
      await fetchUserLoyalty(uid);
    } catch (e) {
      _error = e.toString();
      print('Error awarding badge: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check and update milestone
  Future<bool> checkAndUpdateMilestone(String uid, String milestoneKey) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _loyaltyService.checkAndUpdateMilestone(uid, milestoneKey);
      if (success) {
        await fetchUserLoyalty(uid);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      print('Error checking milestone: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch loyalty config
  Future<void> fetchLoyaltyConfig() async {
    try {
      _loyaltyConfig = await _loyaltyService.getLoyaltyConfig();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error fetching loyalty config: $e');
    }
  }

  // Stream loyalty config for real-time updates
  Stream<LoyaltyConfig?> streamLoyaltyConfig() {
    return _loyaltyService.streamLoyaltyConfig().map((config) {
      _loyaltyConfig = config;
      notifyListeners();
      return config;
    });
  }

  // Fetch token audit logs
  Future<void> fetchTokenAuditLogs(String uid, {int limit = 50}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _auditLogs = await _loyaltyService.getTokenAuditLogs(uid, limit: limit);
    } catch (e) {
      _error = e.toString();
      print('Error fetching token audit logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stream token audit logs
  Stream<List<TokenAuditEntry>> streamTokenAuditLogs(String uid, {int limit = 50}) {
    return _loyaltyService.streamTokenAuditLogs(uid, limit: limit).map((logs) {
      _auditLogs = logs;
      notifyListeners();
      return logs;
    });
  }

  // Freeze streak
  Future<void> freezeStreak(String uid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _loyaltyService.freezeStreak(uid);
      await fetchUserLoyalty(uid);
    } catch (e) {
      _error = e.toString();
      print('Error freezing streak: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get next milestone info
  MilestoneItem? getNextMilestone() {
    if (_loyaltyConfig == null) return null;

    final currentSpent = lifetimeSpent;
    for (final milestone in _loyaltyConfig!.milestones) {
      if (currentSpent < milestone.tokensThreshold) {
        return milestone;
      }
    }
    return null;
  }

  // Get progress to next milestone (0-100)
  int getProgressToNextMilestone() {
    final next = getNextMilestone();
    if (next == null) return 100;

    final currentSpent = lifetimeSpent;
    final previousThreshold = _loyaltyConfig?.milestones
            .where((m) => m.tokensThreshold <= currentSpent)
            .map((m) => m.tokensThreshold)
            .fold(0, (max, val) => val > max ? val : max) ??
        0;

    final range = next.tokensThreshold - previousThreshold;
    final progress = currentSpent - previousThreshold;
    return ((progress / range) * 100).toInt().clamp(0, 100);
  }
}
