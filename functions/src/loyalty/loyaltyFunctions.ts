import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { recordPaymentTransaction, checkAndAwardMilestone, getUserLoyalty } from './loyaltyManager';

const db = admin.firestore();

/**
 * Process Stripe payment webhook and update loyalty
 * Called when payment_intent.succeeded webhook is received
 * 
 * Webhook body:
 * {
 *   sessionId: string,
 *   uid: string,
 *   packId: string,
 *   tokenCount: number
 * }
 */
export const onPaymentSuccessUpdateLoyalty = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    const { sessionId, uid, packId, tokenCount } = req.body;

    // Validate required fields
    if (!sessionId || !uid || !packId || !tokenCount) {
      res.status(400).send('Missing required fields');
      return;
    }

    // Record payment in loyalty system
    await recordPaymentTransaction(uid, sessionId, packId, tokenCount);

    // Check if any milestones should be awarded
    const loyalty = await getUserLoyalty(uid);
    if (loyalty) {
      const spent = loyalty.totals.lifetimeSpent + tokenCount;

      // Check milestones (in order)
      const milestones = [
        { key: 'bronze', threshold: 1000 },
        { key: 'silver', threshold: 5000 },
        { key: 'gold', threshold: 10000 },
        { key: 'platinum', threshold: 25000 },
        { key: 'diamond', threshold: 50000 },
      ];

      for (const milestone of milestones) {
        if (spent >= milestone.threshold && !loyalty.milestones[milestone.key]) {
          await checkAndAwardMilestone(uid, milestone.key);
          console.log(`✅ Milestone awarded: ${milestone.key} for user ${uid}`);
        }
      }
    }

    res.status(200).json({
      success: true,
      message: 'Loyalty updated',
      sessionId,
    });
  } catch (error) {
    console.error('Error updating loyalty:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

/**
 * Scheduled daily function to process daily bonuses
 * Runs every day at midnight UTC
 * 
 * This is optional - you can also process daily bonuses on app startup
 */
export const processDailyBonusesScheduled = functions.pubsub
  .schedule('0 0 * * *') // Every day at midnight UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('🔔 Starting daily bonus processing...');

    try {
      // Note: This is a fire-and-forget approach.
      // In production, you'd track which users have claimed and sync with app.
      // Better approach: Process on app startup via client call.
      console.log('✅ Daily bonus processing scheduled (processed by clients on startup)');
      return null;
    } catch (error) {
      console.error('Error in scheduled daily bonus:', error);
      throw error;
    }
  });

/**
 * Cloud Function to claim daily bonus
 * Called from client side with authentication
 */
export const claimDailyBonus = functions.https.onCall(async (data, context) => {
  try {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;

    // Get loyalty profile
    const loyaltyRef = db.collection('users').doc(uid).collection('loyalty').doc('profile');
    const loyaltyDoc = await loyaltyRef.get();

    if (!loyaltyDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Loyalty profile not found');
    }

    const loyalty = loyaltyDoc.data();

    // Check if already claimed today
    if (loyalty?.lastBonus) {
      const lastBonusDate = new Date(loyalty.lastBonus.toDate());
      const today = new Date();

      if (
        lastBonusDate.getFullYear() === today.getFullYear() &&
        lastBonusDate.getMonth() === today.getMonth() &&
        lastBonusDate.getDate() === today.getDate()
      ) {
        return {
          success: false,
          message: 'Already claimed today',
          nextClaimTime: new Date(lastBonusDate.getTime() + 24 * 60 * 60 * 1000),
          reward: 0,
        };
      }
    }

    // Get loyalty config
    const configDoc = await db.collection('loyalty_config').doc('global').get();
    const config = configDoc.data();

    if (!config) {
      throw new functions.https.HttpsError('internal', 'Loyalty config not found');
    }

    // Calculate reward
    let reward = config.daily.baseReward;
    const newStreak = (loyalty?.streak.current || 0) + 1;
    const streakBonus = Math.min(newStreak * config.daily.streakBonus, config.daily.maxStreakBonus);
    reward += streakBonus;

    // Check for special day multiplier
    const today = new Date();
    const dateISO = `${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
    const specialDay = config.specialDays.find((sd: any) => sd.dateISO === dateISO);

    if (specialDay) {
      reward = Math.floor(reward * specialDay.bonusMultiplier);
    }

    // Update loyalty profile
    const now = admin.firestore.FieldValue.serverTimestamp();
    await loyaltyRef.update({
      'streak.current': newStreak,
      'streak.lastLogin': now,
      'totals.lifetimeEarned': (loyalty?.totals.lifetimeEarned || 0) + reward,
      lastBonus: now,
      updatedAt: now,
    });

    // Log audit
    await db
      .collection('users')
      .doc(uid)
      .collection('token_audit')
      .add({
        action: 'daily_bonus',
        amount: reward,
        sessionId: null,
        createdAt: now,
        metadata: {
          streak: newStreak,
          special: specialDay?.name || null,
        },
      });

    // Check if any milestones should be awarded
    const updatedLoyalty = await loyaltyRef.get();
    const updatedData = updatedLoyalty.data();

    if (updatedData) {
      const earned = updatedData.totals.lifetimeEarned;

      // Check milestones
      const milestones = [
        { key: 'bronze', threshold: 1000 },
        { key: 'silver', threshold: 5000 },
        { key: 'gold', threshold: 10000 },
        { key: 'platinum', threshold: 25000 },
        { key: 'diamond', threshold: 50000 },
      ];

      for (const milestone of milestones) {
        if (earned >= milestone.threshold && !updatedData.milestones[milestone.key]) {
          await loyaltyRef.update({
            [`milestones.${milestone.key}`]: true,
          });

          await db
            .collection('users')
            .doc(uid)
            .collection('token_audit')
            .add({
              action: 'milestone_achieved',
              amount: 0,
              sessionId: null,
              createdAt: now,
              metadata: { milestone: milestone.key },
            });

          console.log(`✅ Milestone awarded: ${milestone.key} for user ${uid}`);
        }
      }
    }

    return {
      success: true,
      reward,
      streak: newStreak,
      message: `Earned ${reward} tokens!`,
    };
  } catch (error) {
    console.error('Error claiming daily bonus:', error);
    throw new functions.https.HttpsError(
      'internal',
      error instanceof Error ? error.message : 'Unknown error'
    );
  }
});

/**
 * Get user loyalty profile (readable Cloud Function)
 */
export const getUserLoyaltyProfile = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;
    const loyaltyDoc = await db.collection('users').doc(uid).collection('loyalty').doc('profile').get();

    if (!loyaltyDoc.exists) {
      return {
        success: false,
        message: 'Loyalty profile not found',
      };
    }

    return {
      success: true,
      data: loyaltyDoc.data(),
    };
  } catch (error) {
    console.error('Error getting loyalty profile:', error);
    throw new functions.https.HttpsError(
      'internal',
      error instanceof Error ? error.message : 'Unknown error'
    );
  }
});

export default {
  onPaymentSuccessUpdateLoyalty,
  processDailyBonusesScheduled,
  claimDailyBonus,
  getUserLoyaltyProfile,
};
