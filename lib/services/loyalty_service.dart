import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/loyalty_model.dart';
import '../models/loyalty_transactions_model.dart';
import '../models/loyalty_config_model.dart';

class LoyaltyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Collection references
  String get _currentUid => _auth.currentUser?.uid ?? '';

  // Cloud Function: Claim daily login bonus
  Future<Map<String, dynamic>?> callClaimDailyBonus() async {
    try {
      final callable = _functions.httpsCallable('onUserLogin');
      final result = await callable.call();
      return result.data as Map<String, dynamic>?;
    } catch (e) {
      print('Error claiming daily bonus: $e');
      return null;
    }
  }

  // Stream loyalty status (for UI updates)
  Stream<DocumentSnapshot> streamLoyaltyStatus(String uid) {
    return _firestore.doc('users/$uid/meta/loyalty').snapshots();
  }

  // Get user loyalty data
  Future<UserLoyalty?> getUserLoyalty(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).collection('loyalty').doc('profile').get();
      if (doc.exists) {
        return UserLoyalty.fromJson(uid, doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Error fetching loyalty data: $e');
      return null;
    }
  }

  // Stream user loyalty data for real-time updates
  Stream<UserLoyalty?> streamUserLoyalty(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('loyalty')
        .doc('profile')
        .snapshots()
        .map((doc) => doc.exists ? UserLoyalty.fromJson(uid, doc.data() ?? {}) : null);
  }

  // Initialize loyalty profile for new user
  Future<void> initializeLoyaltyProfile(String uid) async {
    try {
      final now = DateTime.now();
      final loyaltyData = UserLoyalty(
        uid: uid,
        streak: LoyaltyStreak(
          current: 0,
          lastLogin: now,
          frozenUntil: null,
        ),
        totals: LoyaltyTotals(
          lifetimeEarned: 0,
          lifetimeSpent: 0,
        ),
        badges: [],
        milestones: LoyaltyMilestones(
          bronze: false,
          silver: false,
          gold: false,
          platinum: false,
          diamond: false,
        ),
        lastBonus: null,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('loyalty')
          .doc('profile')
          .set(loyaltyData.toJson());
    } catch (e) {
      print('Error initializing loyalty profile: $e');
    }
  }

  // Record daily login and award daily bonus
  Future<int> processDailyLogin(String uid) async {
    try {
      final now = DateTime.now();
      final loyalty = await getUserLoyalty(uid);
      if (loyalty == null) return 0;

      // Check if already claimed today
      if (loyalty.lastBonus != null) {
        final lastDate = DateTime(loyalty.lastBonus!.year, loyalty.lastBonus!.month, loyalty.lastBonus!.day);
        final today = DateTime(now.year, now.month, now.day);
        if (lastDate == today) {
          return 0; // Already claimed today
        }
      }

      // Get loyalty config
      final config = await getLoyaltyConfig();
      if (config == null) return 0;

      // Calculate reward
      int reward = config.daily.baseReward;

      // Add streak bonus (capped at maxStreakBonus)
      final newStreak = loyalty.streak.current + 1;
      final streakBonus = (newStreak * config.daily.streakBonus).clamp(0, config.daily.maxStreakBonus);
      reward += streakBonus;

      // Check for special day multiplier
      final specialDay = config.specialDays.firstWhere(
        (sd) => sd.dateISO == now.toIso8601String().split('T')[0],
        orElse: () => SpecialDay(dateISO: '', bonusMultiplier: 1.0, name: ''),
      );
      if (specialDay.dateISO.isNotEmpty) {
        reward = (reward * specialDay.bonusMultiplier).toInt();
      }

      // Update loyalty profile
      final updatedLoyalty = UserLoyalty(
        uid: uid,
        streak: LoyaltyStreak(
          current: newStreak,
          lastLogin: now,
          frozenUntil: loyalty.streak.frozenUntil,
        ),
        totals: LoyaltyTotals(
          lifetimeEarned: loyalty.totals.lifetimeEarned + reward,
          lifetimeSpent: loyalty.totals.lifetimeSpent,
        ),
        badges: loyalty.badges,
        milestones: loyalty.milestones,
        lastBonus: now,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('loyalty')
          .doc('profile')
          .set(updatedLoyalty.toJson());

      // Audit log
      await _logTokenAudit(uid, 'daily_bonus', reward, null, {'streak': newStreak, 'special': specialDay.dateISO.isNotEmpty});

      return reward;
    } catch (e) {
      print('Error processing daily login: $e');
      return 0;
    }
  }

  // Record payment and update loyalty
  Future<void> recordPaymentProcessed(String sessionId, String uid, String packId, int tokens) async {
    try {
      final now = DateTime.now();

      // Record payment
      final payment = PaymentProcessed(
        sessionId: sessionId,
        uid: uid,
        packId: packId,
        tokens: tokens,
        processedAt: now,
      );

      await _firestore
          .collection('payments_processed')
          .doc(sessionId)
          .set(payment.toJson());

      // Update loyalty totals
      final loyalty = await getUserLoyalty(uid);
      if (loyalty != null) {
        final updatedLoyalty = UserLoyalty(
          uid: uid,
          streak: loyalty.streak,
          totals: LoyaltyTotals(
            lifetimeEarned: loyalty.totals.lifetimeEarned,
            lifetimeSpent: loyalty.totals.lifetimeSpent + tokens,
          ),
          badges: loyalty.badges,
          milestones: loyalty.milestones,
          lastBonus: loyalty.lastBonus,
        );

        await _firestore
            .collection('users')
            .doc(uid)
            .collection('loyalty')
            .doc('profile')
            .set(updatedLoyalty.toJson());
      }

      // Audit log
      await _logTokenAudit(uid, 'purchase', tokens, sessionId, {'packId': packId});
    } catch (e) {
      print('Error recording payment: $e');
    }
  }

  // Award milestone and badge
  Future<void> awardBadge(String uid, LoyaltyBadge badge) async {
    try {
      final loyalty = await getUserLoyalty(uid);
      if (loyalty != null) {
        final updatedBadges = [...loyalty.badges, badge];
        final updatedLoyalty = UserLoyalty(
          uid: uid,
          streak: loyalty.streak,
          totals: loyalty.totals,
          badges: updatedBadges,
          milestones: loyalty.milestones,
          lastBonus: loyalty.lastBonus,
        );

        await _firestore
            .collection('users')
            .doc(uid)
            .collection('loyalty')
            .doc('profile')
            .set(updatedLoyalty.toJson());

        // Audit log
        await _logTokenAudit(uid, 'badge_awarded', 0, null, {'badgeId': badge.id, 'badgeName': badge.name});
      }
    } catch (e) {
      print('Error awarding badge: $e');
    }
  }

  // Check and update milestone status
  Future<bool> checkAndUpdateMilestone(String uid, String milestoneKey) async {
    try {
      final loyalty = await getUserLoyalty(uid);
      if (loyalty == null) return false;

      // Map milestone keys to milestone objects
      final milestones = loyalty.milestones;
      bool alreadyEarned = false;

      switch (milestoneKey) {
        case 'bronze':
          alreadyEarned = milestones.bronze;
          break;
        case 'silver':
          alreadyEarned = milestones.silver;
          break;
        case 'gold':
          alreadyEarned = milestones.gold;
          break;
        case 'platinum':
          alreadyEarned = milestones.platinum;
          break;
        case 'diamond':
          alreadyEarned = milestones.diamond;
          break;
      }

      if (alreadyEarned) return false;

      // Update milestone
      final updatedMilestones = LoyaltyMilestones(
        bronze: milestoneKey == 'bronze' ? true : milestones.bronze,
        silver: milestoneKey == 'silver' ? true : milestones.silver,
        gold: milestoneKey == 'gold' ? true : milestones.gold,
        platinum: milestoneKey == 'platinum' ? true : milestones.platinum,
        diamond: milestoneKey == 'diamond' ? true : milestones.diamond,
      );

      final updatedLoyalty = UserLoyalty(
        uid: uid,
        streak: loyalty.streak,
        totals: loyalty.totals,
        badges: loyalty.badges,
        milestones: updatedMilestones,
        lastBonus: loyalty.lastBonus,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('loyalty')
          .doc('profile')
          .set(updatedLoyalty.toJson());

      // Audit log
      await _logTokenAudit(uid, 'milestone_achieved', 0, null, {'milestone': milestoneKey});

      return true;
    } catch (e) {
      print('Error updating milestone: $e');
      return false;
    }
  }

  // Get loyalty configuration
  Future<LoyaltyConfig?> getLoyaltyConfig() async {
    try {
      final doc = await _firestore.collection('loyalty_config').doc('global').get();
      if (doc.exists) {
        return LoyaltyConfig.fromJson(doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Error fetching loyalty config: $e');
      return null;
    }
  }

  // Stream loyalty configuration for real-time updates
  Stream<LoyaltyConfig?> streamLoyaltyConfig() {
    return _firestore
        .collection('loyalty_config')
        .doc('global')
        .snapshots()
        .map((doc) => doc.exists ? LoyaltyConfig.fromJson(doc.data() ?? {}) : null);
  }

  // Initialize loyalty configuration (admin only)
  Future<void> initializeLoyaltyConfig() async {
    try {
      final config = LoyaltyConfig(
        daily: DailyConfig(
          baseReward: 50,
          streakBonus: 10,
          maxStreakBonus: 500,
        ),
        weekly: WeeklyConfig(
          thresholdDays: 7,
          bonus: 500,
        ),
        milestones: [
          MilestoneItem(id: 'bronze', name: 'Bronze Member', tokensThreshold: 1000, reward: 100),
          MilestoneItem(id: 'silver', name: 'Silver Member', tokensThreshold: 5000, reward: 500),
          MilestoneItem(id: 'gold', name: 'Gold Member', tokensThreshold: 10000, reward: 1000),
          MilestoneItem(id: 'platinum', name: 'Platinum Member', tokensThreshold: 25000, reward: 2500),
          MilestoneItem(id: 'diamond', name: 'Diamond Member', tokensThreshold: 50000, reward: 5000),
        ],
        specialDays: [
          SpecialDay(dateISO: '12-25', bonusMultiplier: 2.0, name: 'Christmas'),
          SpecialDay(dateISO: '01-01', bonusMultiplier: 1.5, name: 'New Year'),
          SpecialDay(dateISO: '07-04', bonusMultiplier: 1.5, name: 'Independence Day'),
        ],
      );

      await _firestore.collection('loyalty_config').doc('global').set(config.toJson());
    } catch (e) {
      print('Error initializing loyalty config: $e');
    }
  }

  // Get payment record
  Future<PaymentProcessed?> getPaymentProcessed(String sessionId) async {
    try {
      final doc = await _firestore.collection('payments_processed').doc(sessionId).get();
      if (doc.exists) {
        return PaymentProcessed.fromJson(sessionId, doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Error fetching payment record: $e');
      return null;
    }
  }

  // Get token audit logs for user
  Future<List<TokenAuditEntry>> getTokenAuditLogs(String uid, {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(uid)
          .collection('token_audit')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => TokenAuditEntry.fromJson(doc.id, uid, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching token audit logs: $e');
      return [];
    }
  }

  // Stream token audit logs
  Stream<List<TokenAuditEntry>> streamTokenAuditLogs(String uid, {int limit = 50}) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('token_audit')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((query) => query.docs
            .map((doc) => TokenAuditEntry.fromJson(doc.id, uid, doc.data()))
            .toList());
  }

  // Internal: Log token transaction
  Future<void> _logTokenAudit(String uid, String action, int amount, String? sessionId, Map<String, dynamic>? metadata) async {
    try {
      final txId = _firestore.collection('users').doc(uid).collection('token_audit').doc().id;
      final entry = TokenAuditEntry(
        txId: txId,
        uid: uid,
        action: action,
        amount: amount,
        sessionId: sessionId,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('token_audit')
          .doc(txId)
          .set(entry.toJson());
    } catch (e) {
      print('Error logging token audit: $e');
    }
  }

  // Freeze streak (when user misses login)
  Future<void> freezeStreak(String uid) async {
    try {
      final loyalty = await getUserLoyalty(uid);
      if (loyalty != null) {
        final frozenUntil = DateTime.now().add(const Duration(days: 3));
        final updatedLoyalty = UserLoyalty(
          uid: uid,
          streak: LoyaltyStreak(
            current: 0,
            lastLogin: loyalty.streak.lastLogin,
            frozenUntil: frozenUntil,
          ),
          totals: loyalty.totals,
          badges: loyalty.badges,
          milestones: loyalty.milestones,
          lastBonus: loyalty.lastBonus,
        );

        await _firestore
            .collection('users')
            .doc(uid)
            .collection('loyalty')
            .doc('profile')
            .set(updatedLoyalty.toJson());

        await _logTokenAudit(uid, 'streak_frozen', 0, null, {'frozenUntil': frozenUntil.toIso8601String()});
      }
    } catch (e) {
      print('Error freezing streak: $e');
    }
  }
}
