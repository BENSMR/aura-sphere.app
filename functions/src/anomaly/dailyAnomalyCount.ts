import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

/**
 * Daily Anomaly Count Aggregation
 * 
 * Scheduled daily (e.g., 1 AM UTC) to compute:
 * - Total anomalies detected yesterday
 * - By severity (critical, high, medium, low)
 * - By entity type (invoice, expense, inventory, audit)
 * 
 * Results stored in: /analytics/anomalies_daily/{YYYY-MM-DD}
 * 
 * Example doc:
 * {
 *   date: '2025-12-11',
 *   total: 15,
 *   severities: { critical: 2, high: 7, medium: 5, low: 1 },
 *   entityTypes: { invoice: 8, expense: 4, inventory: 2, audit: 1 },
 *   createdAt: timestamp
 * }
 */
export const dailyAnomalyCount = functions.pubsub
  .schedule('1 0 * * *') // 1 AM UTC daily
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      const now = new Date();
      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);
      
      const dateStr = yesterday.toISOString().split('T')[0]; // YYYY-MM-DD
      const startOfDay = new Date(yesterday);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(yesterday);
      endOfDay.setHours(23, 59, 59, 999);
      
      // Query anomalies detected yesterday
      const snapshot = await db
        .collection('anomalies')
        .where('detectedAt', '>=', admin.firestore.Timestamp.fromDate(startOfDay))
        .where('detectedAt', '<=', admin.firestore.Timestamp.fromDate(endOfDay))
        .get();
      
      // Initialize counters
      const severities: { [key: string]: number } = {
        critical: 0,
        high: 0,
        medium: 0,
        low: 0,
      };
      
      const entityTypes: { [key: string]: number } = {
        invoice: 0,
        expense: 0,
        inventory: 0,
        audit: 0,
      };
      
      // Aggregate counts
      snapshot.forEach((doc) => {
        const data = doc.data();
        
        // Count by severity
        const severity = (data.severity || 'low').toLowerCase();
        if (severity in severities) {
          severities[severity]++;
        }
        
        // Count by entity type
        const entityType = (data.entityType || 'unknown').toLowerCase();
        if (entityType in entityTypes) {
          entityTypes[entityType]++;
        }
      });
      
      // Store aggregated result
      const dailyDoc = {
        date: dateStr,
        total: snapshot.size,
        severities,
        entityTypes,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      await db
        .collection('analytics')
        .doc('anomalies_daily')
        .collection('days')
        .doc(dateStr)
        .set(dailyDoc, { merge: true });
      
      console.log(`✓ Aggregated ${snapshot.size} anomalies for ${dateStr}`);
      return { success: true, count: snapshot.size, date: dateStr };
    } catch (error) {
      console.error('Error in dailyAnomalyCount:', error);
      throw error;
    }
  });

/**
 * Query endpoint for daily anomaly counts
 * GET /query/anomaliesDailyCount?days=30&severity=high
 */
export const queryAnomaliesDailyCount = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
    }

    const { days = 30, severity } = data;

    try {
      const snapshot = await db
        .collection('analytics')
        .doc('anomalies_daily')
        .collection('days')
        .orderBy('date', 'desc')
        .limit(Math.min(days, 365))
        .get();

      const results = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          date: data.date,
          total: data.total,
          severities: data.severities,
          entityTypes: data.entityTypes,
        };
      });

      // Filter by severity if requested
      if (severity) {
        return results.map((r) => ({
          date: r.date,
          count: r.severities[severity] || 0,
        }));
      }

      return results.reverse(); // Return in ascending date order
    } catch (error) {
      console.error('Error querying anomaly counts:', error);
      throw new functions.https.HttpsError('internal', 'Failed to query anomaly counts');
    }
  }
);
