import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/loyalty_model.dart';
import '../models/loyalty_transactions_model.dart';
import '../models/loyalty_config_model.dart';
import '../models/reward_config_model.dart';
import '../models/event_reward_model.dart';
import '../models/loyalty_campaign_model.dart';

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
    return _firestore.doc('users/$uid/loyalty/profile').snapshots();
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

  // ==================== Reward Config Methods ====================

  /// Get reward configuration
  Future<RewardConfig?> getRewardConfig() async {
    try {
      final doc = await _firestore.collection('reward_config').doc('global').get();
      if (doc.exists) {
        return RewardConfig.fromJson(doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Error fetching reward config: $e');
      return null;
    }
  }

  /// Stream reward configuration for real-time updates
  Stream<RewardConfig?> streamRewardConfig() {
    return _firestore
        .collection('reward_config')
        .doc('global')
        .snapshots()
        .map((doc) => doc.exists ? RewardConfig.fromJson(doc.data() ?? {}) : null);
  }

  /// Initialize reward configuration (admin only)
  Future<void> initializeRewardConfig({
    double dailyReward = 5,
    double streakMultiplier = 1.2,
    double weeklyBonus = 25,
    double monthlyBonus = 100,
    double signupBonus = 200,
  }) async {
    try {
      final config = RewardConfig(
        dailyReward: dailyReward,
        streakMultiplier: streakMultiplier,
        weeklyBonus: weeklyBonus,
        monthlyBonus: monthlyBonus,
        signupBonus: signupBonus,
        enabled: true,
      );

      await _firestore.collection('reward_config').doc('global').set(config.toJson());
    } catch (e) {
      print('Error initializing reward config: $e');
    }
  }

  /// Update reward configuration (admin only)
  Future<void> updateRewardConfig(RewardConfig config) async {
    try {
      await _firestore.collection('reward_config').doc('global').set(config.toJson());
    } catch (e) {
      print('Error updating reward config: $e');
    }
  }

  /// Award signup bonus to new user
  Future<void> awardSignupBonus(String uid) async {
    try {
      final config = await getRewardConfig();
      if (config == null || !config.enabled) return;

      final signupBonus = config.getSignupBonus();
      await creditTokens(uid, signupBonus.toInt(), 'signup_bonus', {'bonus': signupBonus});
    } catch (e) {
      print('Error awarding signup bonus: $e');
    }
  }

  /// Calculate and award monthly bonus
  Future<void> processMonthlyBonus(String uid) async {
    try {
      final config = await getRewardConfig();
      if (config == null || !config.enabled) return;

      final monthlyBonus = config.getMonthlyBonus();
      await creditTokens(uid, monthlyBonus.toInt(), 'monthly_bonus', {'bonus': monthlyBonus});

      // Audit log
      await _logTokenAudit(uid, 'monthly_bonus', monthlyBonus.toInt(), null, {
        'bonus': monthlyBonus,
        'processedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error processing monthly bonus: $e');
    }
  }

  // ==================== Event Reward Methods ====================

  /// Get all active event rewards
  Future<List<EventReward>> getActiveEventRewards() async {
    try {
      final query = await _firestore
          .collection('event_rewards')
          .where('active', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => EventReward.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching active event rewards: $e');
      return [];
    }
  }

  /// Stream all event rewards
  Stream<List<EventReward>> streamEventRewards() {
    return _firestore
        .collection('event_rewards')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => EventReward.fromJson(doc.id, doc.data()))
            .toList());
  }

  /// Create event reward (admin only)
  Future<String?> createEventReward({
    required String title,
    required String condition,
    required int reward,
    String? description,
    int? maxRewardsPerDay,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final eventReward = EventReward(
        id: '',
        title: title,
        condition: condition,
        reward: reward,
        active: true,
        description: description,
        maxRewardsPerDay: maxRewardsPerDay,
        metadata: metadata,
      );

      final docRef = await _firestore
          .collection('event_rewards')
          .add(eventReward.toJson());

      return docRef.id;
    } catch (e) {
      print('Error creating event reward: $e');
      return null;
    }
  }

  /// Update event reward (admin only)
  Future<void> updateEventReward(String rewardId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('event_rewards')
          .doc(rewardId)
          .update({...updates, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Error updating event reward: $e');
    }
  }

  /// Check if user already claimed this event today
  Future<bool> hasClaimedEventToday(String uid, String condition) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final query = await _firestore
          .collection('users')
          .doc(uid)
          .collection('event_reward_claims')
          .where('condition', isEqualTo: condition)
          .where('claimedAt', isGreaterThanOrEqualTo: startOfDay)
          .where('claimedAt', isLessThanOrEqualTo: endOfDay)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking event claim: $e');
      return false;
    }
  }

  /// Award event reward to user
  Future<bool> awardEventReward({
    required String uid,
    required String eventRewardId,
    required String condition,
    required int tokensEarned,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if already claimed today (for daily-limited events)
      final alreadyClaimed = await hasClaimedEventToday(uid, condition);
      if (alreadyClaimed) {
        print('User already claimed this event today');
        return false;
      }

      // Credit tokens
      await creditTokens(uid, tokensEarned, 'event_reward_$condition',
          {'eventRewardId': eventRewardId, ...?metadata});

      // Record the claim
      final claimRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('event_reward_claims')
          .doc();

      await claimRef.set({
        'eventRewardId': eventRewardId,
        'condition': condition,
        'tokensEarned': tokensEarned,
        'metadata': metadata,
        'claimedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error awarding event reward: $e');
      return false;
    }
  }

  /// Get user's event reward claims
  Future<List<EventRewardClaim>> getUserEventRewardClaims(String uid,
      {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(uid)
          .collection('event_reward_claims')
          .orderBy('claimedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => EventRewardClaim.fromJson(doc.id, uid, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching event reward claims: $e');
      return [];
    }
  }

  /// Stream user's event reward claims
  Stream<List<EventRewardClaim>> streamUserEventRewardClaims(String uid,
      {int limit = 50}) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('event_reward_claims')
        .orderBy('claimedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((query) =>
            query.docs
                .map((doc) => EventRewardClaim.fromJson(doc.id, uid, doc.data()))
                .toList());
  }

  /// Initialize default event rewards
  Future<void> initializeDefaultEventRewards() async {
    try {
      // Check if already initialized
      final existing = await _firestore.collection('event_rewards').get();
      if (existing.docs.isNotEmpty) {
        print('Event rewards already initialized');
        return;
      }

      // Create default events
      final defaultEvents = [
        {
          'title': 'First Invoice',
          'condition': 'invoice_created',
          'reward': 50,
          'description': 'Create your first invoice',
          'maxRewardsPerDay': 1,
        },
        {
          'title': 'Add Client',
          'condition': 'client_added',
          'reward': 25,
          'description': 'Add a new client to your CRM',
          'maxRewardsPerDay': null,
        },
        {
          'title': 'Log Expense',
          'condition': 'expense_logged',
          'reward': 10,
          'description': 'Log an expense with receipt',
          'maxRewardsPerDay': null,
        },
        {
          'title': 'Complete Profile',
          'condition': 'profile_completed',
          'reward': 100,
          'description': 'Complete your business profile',
          'maxRewardsPerDay': 1,
        },
        {
          'title': 'First Payment',
          'condition': 'payment_received',
          'reward': 75,
          'description': 'Receive your first payment',
          'maxRewardsPerDay': 1,
        },
      ];

      for (final event in defaultEvents) {
        await _firestore.collection('event_rewards').add({
          ...event,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('Default event rewards initialized');
    } catch (e) {
      print('Error initializing event rewards: $e');
    }
  }

  // ==================== Loyalty Campaign Methods ====================

  /// Get all active campaigns
  Future<List<LoyaltyCampaign>> getActiveCampaigns() async {
    try {
      final query = await _firestore
          .collection('loyalty_campaigns')
          .where('active', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => LoyaltyCampaign.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching active campaigns: $e');
      return [];
    }
  }

  /// Get campaigns that are currently active (date-wise)
  Future<List<LoyaltyCampaign>> getCurrentActiveCampaigns() async {
    try {
      final campaigns = await getActiveCampaigns();
      return campaigns.where((c) => c.isDateActive()).toList();
    } catch (e) {
      print('Error filtering current campaigns: $e');
      return [];
    }
  }

  /// Stream all campaigns
  Stream<List<LoyaltyCampaign>> streamCampaigns() {
    return _firestore
        .collection('loyalty_campaigns')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => LoyaltyCampaign.fromJson(doc.id, doc.data()))
            .toList());
  }

  /// Create campaign (admin only)
  Future<String?> createCampaign({
    required String name,
    required DateTime campaignDate,
    DateTime? endDate,
    required double multiplier,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final campaign = LoyaltyCampaign(
        id: '',
        name: name,
        campaignDate: campaignDate,
        endDate: endDate,
        multiplier: multiplier,
        active: true,
        description: description,
        metadata: metadata,
      );

      final docRef = await _firestore
          .collection('loyalty_campaigns')
          .add(campaign.toJson());

      return docRef.id;
    } catch (e) {
      print('Error creating campaign: $e');
      return null;
    }
  }

  /// Update campaign (admin only)
  Future<void> updateCampaign(String campaignId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('loyalty_campaigns')
          .doc(campaignId)
          .update({...updates, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Error updating campaign: $e');
    }
  }

  /// Get best applicable campaign multiplier
  Future<double> getApplicableCampaignMultiplier() async {
    try {
      final campaigns = await getCurrentActiveCampaigns();
      if (campaigns.isEmpty) return 1.0;

      // Return the highest multiplier
      return campaigns.fold<double>(1.0, (max, campaign) {
        return campaign.multiplier > max ? campaign.multiplier : max;
      });
    } catch (e) {
      print('Error getting campaign multiplier: $e');
      return 1.0;
    }
  }

  /// Apply campaign multiplier to reward
  int applyCampaignMultiplier(int baseReward, double multiplier) {
    return (baseReward * multiplier).toInt();
  }

  /// Award reward with campaign multiplier applied
  Future<void> awardWithCampaignBonus({
    required String uid,
    required int baseReward,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get current campaign multiplier
      final multiplier = await getApplicableCampaignMultiplier();
      final finalReward = applyCampaignMultiplier(baseReward, multiplier);

      // Get active campaigns for logging
      final campaigns = await getCurrentActiveCampaigns();
      final campaignName =
          campaigns.isNotEmpty ? campaigns.first.name : 'No Campaign';
      final campaignId =
          campaigns.isNotEmpty ? campaigns.first.id : '';

      // Award tokens
      await creditTokens(
        uid,
        finalReward,
        reason,
        {
          ...?metadata,
          'campaignApplied': campaignName,
          'baseReward': baseReward,
          'multiplier': multiplier,
          'finalReward': finalReward,
        },
      );

      // Log campaign application
      if (campaigns.isNotEmpty) {
        final log = CampaignApplicationLog(
          id: '',
          uid: uid,
          campaignId: campaignId,
          campaignName: campaignName,
          baseReward: baseReward,
          multipliedReward: finalReward,
          multiplier: multiplier,
          reason: reason,
          appliedAt: DateTime.now(),
          metadata: metadata,
        );

        await _firestore
            .collection('users')
            .doc(uid)
            .collection('campaign_logs')
            .add(log.toJson());
      }
    } catch (e) {
      print('Error awarding with campaign bonus: $e');
    }
  }

  /// Get user's campaign application logs
  Future<List<CampaignApplicationLog>> getUserCampaignLogs(String uid,
      {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(uid)
          .collection('campaign_logs')
          .orderBy('appliedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => CampaignApplicationLog.fromJson(doc.id, uid, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching campaign logs: $e');
      return [];
    }
  }

  /// Stream user's campaign logs
  Stream<List<CampaignApplicationLog>> streamUserCampaignLogs(String uid,
      {int limit = 50}) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('campaign_logs')
        .orderBy('appliedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((query) => query.docs
            .map((doc) => CampaignApplicationLog.fromJson(doc.id, uid, doc.data()))
            .toList());
  }

  /// Get campaign by ID
  Future<LoyaltyCampaign?> getCampaignById(String campaignId) async {
    try {
      final doc = await _firestore
          .collection('loyalty_campaigns')
          .doc(campaignId)
          .get();

      if (doc.exists) {
        return LoyaltyCampaign.fromJson(doc.id, doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Error fetching campaign: $e');
      return null;
    }
  }

  /// Initialize default campaigns
  Future<void> initializeDefaultCampaigns() async {
    try {
      // Check if already initialized
      final existing = await _firestore.collection('loyalty_campaigns').get();
      if (existing.docs.isNotEmpty) {
        print('Campaigns already initialized');
        return;
      }

      // Create default campaigns
      final defaultCampaigns = [
        {
          'name': 'Black Friday',
          'campaignDate': DateTime(2025, 11, 29),
          'endDate': null,
          'multiplier': 2.0,
          'description': '2x rewards on Black Friday',
          'active': true,
        },
        {
          'name': 'Cyber Monday',
          'campaignDate': DateTime(2025, 12, 1),
          'endDate': null,
          'multiplier': 2.0,
          'description': '2x rewards on Cyber Monday',
          'active': true,
        },
        {
          'name': 'New Year',
          'campaignDate': DateTime(2026, 1, 1),
          'endDate': DateTime(2026, 1, 7),
          'multiplier': 1.5,
          'description': '1.5x rewards during New Year week',
          'active': true,
        },
        {
          'name': 'Christmas',
          'campaignDate': DateTime(2025, 12, 20),
          'endDate': DateTime(2025, 12, 26),
          'multiplier': 2.0,
          'description': '2x rewards during Christmas week',
          'active': true,
        },
      ];

      for (final campaign in defaultCampaigns) {
        await _firestore.collection('loyalty_campaigns').add({
          ...campaign,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('Default campaigns initialized');
    } catch (e) {
      print('Error initializing campaigns: $e');
    }
  }
}

