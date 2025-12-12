import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { 
  handleDailyLogin, 
  checkAndAwardMilestones, 
  creditTokens,
  getUserLoyaltyStatus,
  getConfig 
} from './loyaltyEngine';
import { recordPaymentTransaction, getUserLoyalty } from './loyaltyManager';

const db = admin.firestore();

/**
 * Process Stripe payment webhook and update loyalty
 * Called when payment_intent.succeeded webhook is received
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

    // Record payment using manager function
    await recordPaymentTransaction(uid, sessionId, packId, tokenCount);

    // Credit tokens using engine
    await creditTokens(uid, tokenCount, `purchase_${packId}`, {
      packId,
      sessionId,
    });

    // Check if any milestones should be awarded
    const { awarded: milestones } = await checkAndAwardMilestones(uid);

    res.status(200).json({
      success: true,
      message: 'Loyalty updated',
      sessionId,
      milestonesUnlocked: milestones,
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

    // Use loyalty engine to handle daily login
    const { streak, awarded, message } = await handleDailyLogin(uid);

    // If tokens were awarded, credit them
    if (awarded > 0) {
      await creditTokens(uid, awarded, 'daily_bonus', { streak });
    }

    // Check for milestone achievements
    const { awarded: milestones } = await checkAndAwardMilestones(uid);

    return {
      success: true,
      reward: awarded,
      streak,
      milestonesUnlocked: milestones,
      message: awarded > 0 ? `Earned ${awarded} tokens! ${message}` : message,
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
