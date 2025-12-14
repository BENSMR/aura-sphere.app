import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Helper class to initialize loyalty system collections and documents
class LoyaltyInitializer {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Initialize global loyalty configuration (admin only)
  static Future<void> initializeGlobalConfig() async {
    final globalConfigRef = _db.collection('loyalty_config').doc('global');
    final doc = await globalConfigRef.get();

    if (!doc.exists) {
      await globalConfigRef.set({
        'daily': {
          'baseReward': 5,
          'streakBonus': 1,
          'maxStreakBonus': 20,
        },
        'weekly': {
          'thresholdDays': 7,
          'bonus': 50,
        },
        'milestones': [
          {
            'id': 'bronze',
            'name': 'Bronze',
            'tokensThreshold': 100,
            'reward': 10,
          },
          {
            'id': 'silver',
            'name': 'Silver',
            'tokensThreshold': 250,
            'reward': 25,
          },
          {
            'id': 'gold',
            'name': 'Gold',
            'tokensThreshold': 500,
            'reward': 50,
          },
          {
            'id': 'platinum',
            'name': 'Platinum',
            'tokensThreshold': 1000,
            'reward': 100,
          },
          {
            'id': 'diamond',
            'name': 'Diamond',
            'tokensThreshold': 2000,
            'reward': 200,
          },
        ],
        'specialDays': [
          {
            'dateISO': '2024-12-25',
            'bonusMultiplier': 2.0,
            'name': 'Christmas',
          },
          {
            'dateISO': '2024-01-01',
            'bonusMultiplier': 1.5,
            'name': 'New Year',
          },
        ],
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'system',
      });
    }
  }

  /// Initialize user loyalty profile on first login
  static Future<void> initializeUserLoyalty(String uid) async {
    final userLoyaltyRef = _db.collection('users').doc(uid).collection('loyalty').doc('profile');
    final doc = await userLoyaltyRef.get();

    if (!doc.exists) {
      await userLoyaltyRef.set({
        'streak': {
          'current': 0,
          'lastLogin': null,
          'frozenUntil': null,
        },
        'totals': {
          'lifetimeEarned': 0,
          'lifetimeSpent': 0,
        },
        'badges': [],
        'milestones': {
          'bronze': false,
          'silver': false,
          'gold': false,
          'platinum': false,
          'diamond': false,
        },
        'lastBonus': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get global loyalty configuration
  static Future<Map<String, dynamic>> getGlobalConfig() async {
    final doc = await _db.collection('loyalty_config').doc('global').get();
    return doc.data() ?? {};
  }

  /// Stream global loyalty configuration for real-time updates
  static Stream<Map<String, dynamic>> watchGlobalConfig() {
    return _db.collection('loyalty_config').doc('global').snapshots().map(
          (doc) => doc.data() ?? {},
        );
  }

  /// Validate loyalty system is properly initialized
  static Future<bool> validateSetup() async {
    try {
      // Check global config exists
      final globalConfig = await _db.collection('loyalty_config').doc('global').get();
      if (!globalConfig.exists) {
        print('❌ Global config not found');
        return false;
      }

      // Check current user loyalty profile exists
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️  No authenticated user');
        return true; // Will be created on first login
      }

      final userLoyalty = await _db
          .collection('users')
          .doc(user.uid)
          .collection('loyalty')
          .doc('profile')
          .get();

      if (!userLoyalty.exists) {
        print('❌ User loyalty profile not found for ${user.uid}');
        return false;
      }

      print('✅ Loyalty system properly initialized');
      return true;
    } catch (e) {
      print('❌ Error validating loyalty setup: $e');
      return false;
    }
  }

  /// Reset user loyalty data (for testing only)
  static Future<void> resetUserLoyalty(String uid) async {
    // Reset loyalty profile
    await _db.collection('users').doc(uid).collection('loyalty').doc('profile').set({
      'streak': {
        'current': 0,
        'lastLogin': null,
        'frozenUntil': null,
      },
      'totals': {
        'lifetimeEarned': 0,
        'lifetimeSpent': 0,
      },
      'badges': [],
      'milestones': {
        'bronze': false,
        'silver': false,
        'gold': false,
        'platinum': false,
        'diamond': false,
      },
      'lastBonus': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Delete all transactions
    final transactions = await _db
        .collection('users')
        .doc(uid)
        .collection('token_audit')
        .get();

    for (final tx in transactions.docs) {
      await tx.reference.delete();
    }

    print('✅ Loyalty data reset for $uid');
  }
}
