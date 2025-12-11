import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { logger } from "../utils/logger";

const db = admin.firestore();

/**
 * Calculate AI Score for a client based on multiple factors
 * 
 * Scoring factors:
 * - Payment behavior (on-time payments, frequency)
 * - Lifetime value (tiered scoring)
 * - Activity recency (last activity, last payment)
 * - Engagement level (timeline events, interactions)
 * - Invoice history (count, average amount)
 * - Sentiment and stability
 * 
 * @param userId - User ID
 * @param clientId - Client ID
 * @returns Updated AI score and churn risk
 */
export const calculateClientAIScore = async (
  userId: string,
  clientId: string
): Promise<{ aiScore: number; churnRisk: number; aiTags: string[] }> => {
  const clientRef = db
    .collection("users")
    .doc(userId)
    .collection("clients")
    .doc(clientId);

  const clientDoc = await clientRef.get();
  if (!clientDoc.exists) {
    throw new Error(`Client ${clientId} not found`);
  }

  const data = clientDoc.data()!;

  // Base score: 50 (neutral starting point)
  let score = 50;
  const tags: string[] = [];

  // === FACTOR 1: Payment Behavior (0-20 points) ===
  const totalInvoices = data.totalInvoices ?? 0;
  const lastPaymentDate = data.lastPaymentDate?.toDate();
  const now = new Date();

  if (lastPaymentDate) {
    const daysSincePayment = Math.floor(
      (now.getTime() - lastPaymentDate.getTime()) / (1000 * 60 * 60 * 24)
    );

    if (daysSincePayment <= 30) {
      score += 20; // Recent payment - excellent
    } else if (daysSincePayment <= 60) {
      score += 15; // Payment within 60 days - good
    } else if (daysSincePayment <= 90) {
      score += 10; // Payment within 90 days - acceptable
    }
    // No points if last payment > 90 days ago
  }

  // === FACTOR 2: Lifetime Value (0-30 points) ===
  const lifetimeValue = data.lifetimeValue ?? 0;

  if (lifetimeValue >= 10000) {
    score += 30;
    tags.push("HIGH_VALUE");
  } else if (lifetimeValue >= 5000) {
    score += 20;
    tags.push("HIGH_VALUE");
  } else if (lifetimeValue >= 1000) {
    score += 10;
  }

  // === FACTOR 3: Activity Recency (0-20 points, with penalties) ===
  const lastActivityAt = data.lastActivityAt?.toDate();

  if (lastActivityAt) {
    const daysSinceActivity = Math.floor(
      (now.getTime() - lastActivityAt.getTime()) / (1000 * 60 * 60 * 24)
    );

    if (daysSinceActivity <= 7) {
      score += 20; // Very active
    } else if (daysSinceActivity <= 30) {
      score += 15; // Active
    } else if (daysSinceActivity <= 60) {
      score += 5; // Moderate activity
    } else if (daysSinceActivity <= 90) {
      score -= 10; // Declining activity
      tags.push("AT_RISK");
    } else {
      score -= 25; // Inactive - major concern
      tags.push("DORMANT");
    }
  }

  // === FACTOR 4: Engagement Level (0-15 points) ===
  const timeline = data.timeline ?? [];
  const timelineLength = Array.isArray(timeline) ? timeline.length : 0;

  if (timelineLength >= 20) {
    score += 15; // Highly engaged
  } else if (timelineLength >= 10) {
    score += 10; // Well engaged
  } else if (timelineLength >= 5) {
    score += 5; // Some engagement
  }

  // === FACTOR 5: Invoice Metrics (0-10 points) ===
  if (totalInvoices >= 10) {
    score += 10; // Loyal, recurring customer
    tags.push("RETURNING");
  } else if (totalInvoices >= 5) {
    score += 7;
    tags.push("RETURNING");
  } else if (totalInvoices >= 2) {
    score += 4;
  } else if (totalInvoices === 1) {
    tags.push("NEW");
  }

  // === FACTOR 6: Sentiment Analysis (0-5 points or -10 penalty) ===
  const sentiment = data.sentiment ?? "neutral";

  if (sentiment === "positive") {
    score += 5;
  } else if (sentiment === "negative") {
    score -= 10;
    tags.push("NEGATIVE_SENTIMENT");
  }

  // === FACTOR 7: Stability Level (0-5 points or -5 penalty) ===
  const stabilityLevel = data.stabilityLevel ?? "stable";

  if (stabilityLevel === "stable") {
    score += 5;
  } else if (stabilityLevel === "risky") {
    score -= 5;
  }

  // === FACTOR 8: VIP Status Bonus (+10 points) ===
  const vipStatus = data.vipStatus ?? false;
  if (vipStatus) {
    score += 10;
    tags.push("VIP");
  }

  // === Clamp score to 0-100 range ===
  const finalScore = Math.max(0, Math.min(100, Math.round(score)));

  // === Calculate Churn Risk (inverse relationship with AI score) ===
  let churnRisk = 100 - finalScore;

  // Additional churn risk factors
  const daysSincePayment = lastPaymentDate
    ? Math.floor((now.getTime() - lastPaymentDate.getTime()) / (1000 * 60 * 60 * 24))
    : 999;

  const daysSinceActivity = lastActivityAt
    ? Math.floor((now.getTime() - lastActivityAt.getTime()) / (1000 * 60 * 60 * 24))
    : 999;

  // High churn risk adjustments
  if (daysSincePayment > 90) {
    churnRisk = Math.min(100, churnRisk + 20); // No payment in 90+ days
  }

  if (daysSinceActivity > 60) {
    churnRisk = Math.min(100, churnRisk + 15); // No activity in 60+ days
  }

  if (lifetimeValue < 500 && daysSinceActivity > 45) {
    churnRisk = Math.min(100, churnRisk + 10); // Low value + inactive
  }

  churnRisk = Math.max(0, Math.min(100, Math.round(churnRisk)));

  return { aiScore: finalScore, churnRisk, aiTags: tags };
};

/**
 * Firestore trigger: Update AI Score when client data changes
 * Path: users/{userId}/clients/{clientId}
 * 
 * Automatically recalculates AI score and churn risk
 * Generates AI tags for quick filtering
 */
export const updateClientAIScore = functions.firestore
  .document("users/{userId}/clients/{clientId}")
  .onWrite(async (change, context) => {
    try {
      const userId = context.params.userId;
      const clientId = context.params.clientId;

      // Skip if document was deleted
      if (!change.after.exists) {
        return null;
      }

      const afterData = change.after.data()!;

      // Prevent infinite loops - check if aiScore or churnRisk just changed
      if (change.before.exists) {
        const beforeData = change.before.data()!;
        const beforeAIScore = beforeData.aiScore ?? 0;
        const afterAIScore = afterData.aiScore ?? 0;
        const beforeChurnRisk = beforeData.churnRisk ?? 0;
        const afterChurnRisk = afterData.churnRisk ?? 0;

        // If only AI score/churn changed (and nothing else significant), skip
        if (
          Math.abs(beforeAIScore - afterAIScore) < 5 &&
          Math.abs(beforeChurnRisk - afterChurnRisk) < 5 &&
          beforeData.lifetimeValue === afterData.lifetimeValue &&
          beforeData.totalInvoices === afterData.totalInvoices
        ) {
          return null;
        }
      }

      // Calculate new AI score and churn risk
      const { aiScore, churnRisk, aiTags } = await calculateClientAIScore(
        userId,
        clientId
      );

      // Update client document
      await change.after.ref.update({
        aiScore,
        churnRisk,
        aiTags,
        updatedAt: admin.firestore.Timestamp.now(),
      });

      logger.info(
        `Updated AI score for client ${clientId}: score=${aiScore}, churn=${churnRisk}, tags=[${aiTags.join(", ")}]`
      );

      return null;
    } catch (error) {
      logger.error("Error in updateClientAIScore", error);
      // Don't throw - prevents infinite retries
      return null;
    }
  });

/**
 * Callable function: Recalculate AI scores for all clients
 * 
 * Useful for batch updates or migrations
 */
export const recalculateAllClientScores = functions.https.onCall(
  async (data, context) => {
    try {
      // Verify authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Must be authenticated to recalculate scores"
        );
      }

      const userId = context.auth.uid;

      // Get all clients for user
      const clientsSnapshot = await db
        .collection("users")
        .doc(userId)
        .collection("clients")
        .get();

      let updated = 0;
      let failed = 0;

      // Process each client
      for (const clientDoc of clientsSnapshot.docs) {
        try {
          const { aiScore, churnRisk, aiTags } = await calculateClientAIScore(
            userId,
            clientDoc.id
          );

          await clientDoc.ref.update({
            aiScore,
            churnRisk,
            aiTags,
            updatedAt: admin.firestore.Timestamp.now(),
          });

          updated++;
        } catch (error) {
          logger.error(`Failed to update client ${clientDoc.id}`, error);
          failed++;
        }
      }

      logger.info(
        `Recalculated scores for user ${userId}: ${updated} updated, ${failed} failed`
      );

      return {
        success: true,
        updated,
        failed,
        total: clientsSnapshot.size,
      };
    } catch (error) {
      logger.error("Error in recalculateAllClientScores", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to recalculate scores"
      );
    }
  }
);

/**
 * Scheduled function: Daily AI score refresh
 * Runs every day at 2:00 AM UTC
 * 
 * Requires Cloud Scheduler configuration:
 * gcloud scheduler jobs create pubsub daily-score-refresh \
 *   --schedule="0 2 * * *" \
 *   --topic=daily-score-refresh \
 *   --message-body='{"refresh":"scores"}'
 */
export const dailyScoreRefresh = functions.pubsub
  .topic("daily-score-refresh")
  .onPublish(async (message) => {
    try {
      logger.info("Starting daily AI score refresh");

      // Get all users
      const usersSnapshot = await db.collection("users").get();

      let totalUpdated = 0;
      let totalFailed = 0;

      // Process each user's clients
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;

        const clientsSnapshot = await db
          .collection("users")
          .doc(userId)
          .collection("clients")
          .get();

        for (const clientDoc of clientsSnapshot.docs) {
          try {
            const { aiScore, churnRisk, aiTags } = await calculateClientAIScore(
              userId,
              clientDoc.id
            );

            await clientDoc.ref.update({
              aiScore,
              churnRisk,
              aiTags,
              updatedAt: admin.firestore.Timestamp.now(),
            });

            totalUpdated++;
          } catch (error) {
            logger.error(
              `Failed to update client ${clientDoc.id} for user ${userId}`,
              error
            );
            totalFailed++;
          }
        }
      }

      logger.info(
        `Daily score refresh complete: ${totalUpdated} updated, ${totalFailed} failed`
      );

      return null;
    } catch (error) {
      logger.error("Error in dailyScoreRefresh", error);
      throw error;
    }
  });
