import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { logger } from '../utils/logger';

const db = admin.firestore();

/**
 * Trigger: Fires when a client document is created or updated
 * 
 * Purpose: Auto-calculate AI score and churn risk based on activity patterns
 * - Evaluate payment behavior
 * - Score based on lifetime value
 * - Penalize inactivity
 * - Generate AI tags
 * - Update churn risk (inverse of AI score)
 * 
 * Preconditions:
 * - Client must have basic fields (lifetimeValue, lastPaymentDate, lastActivityAt)
 * 
 * Side Effects:
 * - Updates client's aiScore (0-100)
 * - Updates client's churnRisk (100 - aiScore)
 * - Updates client's aiTags (VIP, AT_RISK, RETURNING, etc)
 * - Updates updatedAt timestamp
 */
export const updateClientAIScore = functions.firestore
  .document('clients/{clientId}')
  .onWrite(async (change, context) => {
    const { clientId } = context.params;
    const clientData = change.after.data();

    try {
      // Validate client exists
      if (!clientData) {
        logger.warn('Client document is empty or deleted', { clientId });
        return { success: false, reason: 'Client deleted' };
      }

      // Don't recalculate if we just updated it (prevent infinite loop)
      if (change.before.data()?.aiScore !== undefined && 
          change.before.data()?.aiScore === clientData.aiScore) {
        return { success: false, reason: 'No changes detected' };
      }

      // Start with baseline score
      let aiScore = 50;

      // ===== FACTOR 1: Payment Behavior =====
      // Clients with recent payments are more engaged
      if (clientData.lastPaymentDate) {
        aiScore += 10;
        logger.info('Payment behavior bonus applied', { clientId });
      }

      // ===== FACTOR 2: Lifetime Value (Most Important) =====
      // Higher spending = higher engagement
      const lifetimeValue = clientData.lifetimeValue || 0;

      if (lifetimeValue > 1000) {
        aiScore += 20;
      }
      if (lifetimeValue > 5000) {
        aiScore += 30; // Additional bonus for high-value clients
      }
      if (lifetimeValue > 10000) {
        aiScore += 20; // VIP tier bonus
      }

      logger.info('Lifetime value scoring', {
        clientId,
        lifetimeValue,
        scoreBonus: aiScore - 50,
      });

      // ===== FACTOR 3: Activity Level =====
      // Inactivity is a strong churn indicator
      if (clientData.lastActivityAt) {
        const lastActivity = clientData.lastActivityAt?.toDate?.()
          ? clientData.lastActivityAt.toDate()
          : new Date(clientData.lastActivityAt);

        const inactiveDays =
          (Date.now() - lastActivity.getTime()) / (1000 * 3600 * 24);

        if (inactiveDays > 90) {
          aiScore -= 25; // Heavy penalty for 90+ day inactivity
          logger.warn('Severe inactivity penalty applied', {
            clientId,
            inactiveDays,
          });
        } else if (inactiveDays > 30) {
          aiScore -= 10; // Moderate penalty for 30+ day inactivity
          logger.info('Inactivity penalty applied', {
            clientId,
            inactiveDays,
          });
        }
      } else {
        // No activity recorded yet
        aiScore -= 15;
      }

      // ===== FACTOR 4: Invoice Count =====
      // Repeat customers are more valuable
      const totalInvoices = clientData.totalInvoices || 0;
      if (totalInvoices >= 5) {
        aiScore += 15; // Loyal customer bonus
      } else if (totalInvoices >= 3) {
        aiScore += 10; // Repeat customer bonus
      }

      // ===== FACTOR 5: Sentiment & Stability =====
      // Existing sentiment and stability levels influence score
      const sentiment = clientData.sentiment || 'unknown';
      if (sentiment === 'positive') {
        aiScore += 10;
      } else if (sentiment === 'negative') {
        aiScore -= 15;
      }

      const stabilityLevel = clientData.stabilityLevel || 'unknown';
      if (stabilityLevel === 'stable') {
        aiScore += 5;
      } else if (stabilityLevel === 'risky') {
        aiScore -= 10;
      } else if (stabilityLevel === 'unstable') {
        aiScore -= 5;
      }

      // ===== NORMALIZE SCORE =====
      // Clamp between 0-100
      aiScore = Math.max(0, Math.min(100, aiScore));

      // ===== CALCULATE CHURN RISK =====
      // Inverse of AI score: high engagement = low churn risk
      const churnRisk = 100 - aiScore;

      // ===== GENERATE AI TAGS =====
      const aiTags: string[] = [];

      // VIP: Score > 80 or lifetime > 10,000
      if (aiScore > 80 || lifetimeValue > 10000) {
        aiTags.push('VIP');
      }

      // AT_RISK: Churn risk > 50
      if (churnRisk > 50) {
        aiTags.push('AT_RISK');
      }

      // RETURNING: 3+ invoices
      if (totalInvoices >= 3) {
        aiTags.push('RETURNING');
      }

      // NEW: Less than 1 invoice
      if (totalInvoices < 1) {
        aiTags.push('NEW');
      }

      // DORMANT: No activity in 90+ days
      if (clientData.lastActivityAt) {
        const lastActivity = clientData.lastActivityAt?.toDate?.()
          ? clientData.lastActivityAt.toDate()
          : new Date(clientData.lastActivityAt);
        const inactiveDays =
          (Date.now() - lastActivity.getTime()) / (1000 * 3600 * 24);

        if (inactiveDays > 90) {
          aiTags.push('DORMANT');
        }
      }

      // HIGH_VALUE: Lifetime > 5,000
      if (lifetimeValue > 5000) {
        aiTags.push('HIGH_VALUE');
      }

      // NEGATIVE_SENTIMENT: Sentiment is negative
      if (sentiment === 'negative') {
        aiTags.push('NEGATIVE_SENTIMENT');
      }

      // Log scoring summary
      logger.info('Client AI score calculated', {
        clientId,
        aiScore,
        churnRisk,
        aiTags,
        lifetimeValue,
        totalInvoices,
        sentiment,
      });

      // ===== UPDATE CLIENT DOCUMENT =====
      // Use merge to preserve other fields
      const clientRef = change.after.ref;
      await clientRef.update({
        aiScore,
        churnRisk,
        aiTags,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info('Client AI metrics updated successfully', {
        clientId,
        aiScore,
        churnRisk,
        tagsCount: aiTags.length,
      });

      return {
        success: true,
        clientId,
        aiScore,
        churnRisk,
        aiTags,
      };
    } catch (error: any) {
      logger.error('updateClientAIScore function failed', {
        clientId,
        error: error.message,
        code: error.code,
      });

      return {
        success: false,
        error: error.message || 'Failed to calculate AI score',
      };
    }
  });

/**
 * Trigger: Callable function to recalculate AI scores for all clients
 * 
 * Purpose: Batch recalculate AI scores (useful for periodic updates)
 * - Recalculates all clients in a user's collection
 * - Can be called from client app or scheduled Cloud Task
 * - Useful for daily/weekly score refreshes
 */
export const recalculateAllClientScores = functions.https.onCall(
  async (data, context) => {
    try {
      // Verify user is authenticated
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const userId = context.auth.uid;
      const clientsRef = db
        .collection('users')
        .doc(userId)
        .collection('clients');

      // Fetch all clients
      const snap = await clientsRef.get();
      let updated = 0;
      let failed = 0;

      // Recalculate each client
      for (const doc of snap.docs) {
        try {
          const clientData = doc.data();

          // Recalculate AI score (duplicate logic from trigger)
          let aiScore = 50;

          if (clientData.lastPaymentDate) aiScore += 10;

          const lifetimeValue = clientData.lifetimeValue || 0;
          if (lifetimeValue > 1000) aiScore += 20;
          if (lifetimeValue > 5000) aiScore += 30;
          if (lifetimeValue > 10000) aiScore += 20;

          if (clientData.lastActivityAt) {
            const lastActivity = clientData.lastActivityAt?.toDate?.()
              ? clientData.lastActivityAt.toDate()
              : new Date(clientData.lastActivityAt);

            const inactiveDays =
              (Date.now() - lastActivity.getTime()) / (1000 * 3600 * 24);

            if (inactiveDays > 90) aiScore -= 25;
            else if (inactiveDays > 30) aiScore -= 10;
          } else {
            aiScore -= 15;
          }

          const totalInvoices = clientData.totalInvoices || 0;
          if (totalInvoices >= 5) aiScore += 15;
          else if (totalInvoices >= 3) aiScore += 10;

          const sentiment = clientData.sentiment || 'unknown';
          if (sentiment === 'positive') aiScore += 10;
          else if (sentiment === 'negative') aiScore -= 15;

          const stabilityLevel = clientData.stabilityLevel || 'unknown';
          if (stabilityLevel === 'stable') aiScore += 5;
          else if (stabilityLevel === 'risky') aiScore -= 10;
          else if (stabilityLevel === 'unstable') aiScore -= 5;

          aiScore = Math.max(0, Math.min(100, aiScore));
          const churnRisk = 100 - aiScore;

          // Generate tags
          const aiTags: string[] = [];
          if (aiScore > 80 || lifetimeValue > 10000) aiTags.push('VIP');
          if (churnRisk > 50) aiTags.push('AT_RISK');
          if (totalInvoices >= 3) aiTags.push('RETURNING');
          if (totalInvoices < 1) aiTags.push('NEW');
          if (lifetimeValue > 5000) aiTags.push('HIGH_VALUE');
          if (sentiment === 'negative') aiTags.push('NEGATIVE_SENTIMENT');

          // Update client
          await doc.ref.update({
            aiScore,
            churnRisk,
            aiTags,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          updated++;
        } catch (err: any) {
          logger.error('Failed to update individual client', {
            userId,
            clientId: doc.id,
            error: err.message,
          });
          failed++;
        }
      }

      logger.info('Batch recalculation completed', {
        userId,
        updated,
        failed,
        total: snap.docs.length,
      });

      return {
        success: true,
        updated,
        failed,
        total: snap.docs.length,
      };
    } catch (error: any) {
      logger.error('recalculateAllClientScores function failed', {
        error: error.message,
        code: error.code,
      });

      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Failed to recalculate scores'
      );
    }
  }
);

/**
 * Scheduled function: Run daily to refresh AI scores
 * 
 * Purpose: Keep AI scores fresh without waiting for write triggers
 * - Runs once per day (configurable via Cloud Scheduler)
 * - Updates all clients across all users
 * - Useful for detecting churn patterns
 * 
 * Note: Requires Cloud Scheduler setup in firebase.json
 */
export const dailyScoreRefresh = functions.pubsub
  .schedule('every day 02:00')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    try {
      const usersRef = db.collection('users');
      const usersSnap = await usersRef.get();

      let totalUpdated = 0;
      let totalFailed = 0;

      for (const userDoc of usersSnap.docs) {
        const userId = userDoc.id;
        const clientsRef = userDoc.ref.collection('clients');
        const clientsSnap = await clientsRef.get();

        for (const clientDoc of clientsSnap.docs) {
          try {
            const clientData = clientDoc.data();

            // Recalculate AI score
            let aiScore = 50;

            if (clientData.lastPaymentDate) aiScore += 10;

            const lifetimeValue = clientData.lifetimeValue || 0;
            if (lifetimeValue > 1000) aiScore += 20;
            if (lifetimeValue > 5000) aiScore += 30;
            if (lifetimeValue > 10000) aiScore += 20;

            if (clientData.lastActivityAt) {
              const lastActivity = clientData.lastActivityAt?.toDate?.()
                ? clientData.lastActivityAt.toDate()
                : new Date(clientData.lastActivityAt);

              const inactiveDays =
                (Date.now() - lastActivity.getTime()) / (1000 * 3600 * 24);

              if (inactiveDays > 90) aiScore -= 25;
              else if (inactiveDays > 30) aiScore -= 10;
            } else {
              aiScore -= 15;
            }

            const totalInvoices = clientData.totalInvoices || 0;
            if (totalInvoices >= 5) aiScore += 15;
            else if (totalInvoices >= 3) aiScore += 10;

            const sentiment = clientData.sentiment || 'unknown';
            if (sentiment === 'positive') aiScore += 10;
            else if (sentiment === 'negative') aiScore -= 15;

            const stabilityLevel = clientData.stabilityLevel || 'unknown';
            if (stabilityLevel === 'stable') aiScore += 5;
            else if (stabilityLevel === 'risky') aiScore -= 10;
            else if (stabilityLevel === 'unstable') aiScore -= 5;

            aiScore = Math.max(0, Math.min(100, aiScore));
            const churnRisk = 100 - aiScore;

            // Generate tags
            const aiTags: string[] = [];
            if (aiScore > 80 || lifetimeValue > 10000) aiTags.push('VIP');
            if (churnRisk > 50) aiTags.push('AT_RISK');
            if (totalInvoices >= 3) aiTags.push('RETURNING');
            if (totalInvoices < 1) aiTags.push('NEW');
            if (lifetimeValue > 5000) aiTags.push('HIGH_VALUE');
            if (sentiment === 'negative') aiTags.push('NEGATIVE_SENTIMENT');

            // Update client
            await clientDoc.ref.update({
              aiScore,
              churnRisk,
              aiTags,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            totalUpdated++;
          } catch (err: any) {
            logger.error('Failed to update client in daily refresh', {
              userId,
              clientId: clientDoc.id,
              error: err.message,
            });
            totalFailed++;
          }
        }
      }

      logger.info('Daily score refresh completed', {
        totalUpdated,
        totalFailed,
      });

      return {
        success: true,
        totalUpdated,
        totalFailed,
      };
    } catch (error: any) {
      logger.error('dailyScoreRefresh function failed', {
        error: error.message,
        code: error.code,
      });

      return {
        success: false,
        error: error.message,
      };
    }
  });
