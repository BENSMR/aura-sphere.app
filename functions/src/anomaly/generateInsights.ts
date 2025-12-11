import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

interface AnomalyInsight {
  title: string;
  description: string;
  severity: "low" | "medium" | "high" | "critical";
  type: "vendor_pattern" | "time_pattern" | "frequency_spike" | "amount_anomaly";
  entityType: string; // invoice, expense, inventory, audit
  percentage: number; // e.g., 34 for 34% increase
  timeWindow: string; // e.g., "after 6 PM", "Friday", "weekend"
  affectedCount: number;
  samplesIds: string[]; // up to 5 sample anomaly IDs
  createdAt: FirebaseFirestore.Timestamp;
}

/**
 * Generate Anomaly Insights
 * Scheduled daily (e.g., 6 AM UTC) to analyze patterns
 * 
 * Detects:
 * 1. Vendor concentration (same vendor multiple times = fraud risk)
 * 2. Time patterns (unusual hours = suspicious)
 * 3. Weekly trends (34% increase vs last week = alert)
 * 4. Amount spikes (unusually high amounts)
 * 
 * Results stored in: /analytics/anomaly_insights/{YYYY-MM-DD}
 */
export const generateAnomalyInsights = functions.pubsub
  .schedule('6 0 * * *') // 6 AM UTC daily
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      const insights: AnomalyInsight[] = [];
      const now = new Date();
      const today = now.toISOString().split('T')[0];
      
      // Get anomalies from last 7 days
      const sevenDaysAgo = new Date(now);
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
      const fourteenDaysAgo = new Date(now);
      fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14);
      
      // Query this week's anomalies
      const thisWeekSnapshot = await db
        .collection('anomalies')
        .where('detectedAt', '>=', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
        .get();
      
      // Query last week's anomalies
      const lastWeekSnapshot = await db
        .collection('anomalies')
        .where('detectedAt', '>=', admin.firestore.Timestamp.fromDate(fourteenDaysAgo))
        .where('detectedAt', '<', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
        .get();
      
      // Analyze expense anomalies by time patterns
      const expenseInsights = analyzeTimePatterns(thisWeekSnapshot.docs);
      insights.push(...expenseInsights);
      
      // Analyze vendor concentration
      const vendorInsights = analyzeVendorPatterns(thisWeekSnapshot.docs);
      insights.push(...vendorInsights);
      
      // Analyze week-over-week trends
      const thisWeekCount = thisWeekSnapshot.size;
      const lastWeekCount = lastWeekSnapshot.size;
      const percentChange = lastWeekCount > 0 
        ? Math.round(((thisWeekCount - lastWeekCount) / lastWeekCount) * 100)
        : 0;
      
      if (Math.abs(percentChange) >= 20) {
        insights.push({
          title: `Weekly Anomaly ${percentChange >= 0 ? 'Increase' : 'Decrease'}`,
          description: `This week shows a ${Math.abs(percentChange)}% ${percentChange >= 0 ? 'increase' : 'decrease'} in anomalies compared to last week (${thisWeekCount} vs ${lastWeekCount}).`,
          severity: percentChange >= 50 ? 'critical' : percentChange >= 30 ? 'high' : 'medium',
          type: 'frequency_spike',
          entityType: 'all',
          percentage: Math.abs(percentChange),
          timeWindow: 'this week',
          affectedCount: thisWeekCount,
          samplesIds: thisWeekSnapshot.docs.slice(0, 5).map(d => d.id),
          createdAt: admin.firestore.Timestamp.now(),
        });
      }
      
      // Store insights
      if (insights.length > 0) {
        const batchInsights = insights.slice(0, 10); // Keep top 10 insights
        await db
          .collection('analytics')
          .doc('anomaly_insights')
          .collection('daily')
          .doc(today)
          .set(
            {
              date: today,
              insights: batchInsights,
              count: batchInsights.length,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
      }
      
      console.log(`✓ Generated ${insights.length} anomaly insights for ${today}`);
      return { success: true, insightCount: insights.length };
    } catch (error) {
      console.error('Error in generateAnomalyInsights:', error);
      throw error;
    }
  });

function analyzeTimePatterns(
  anomalies: FirebaseFirestore.QueryDocumentSnapshot[]
): AnomalyInsight[] {
  const insights: AnomalyInsight[] = [];
  
  // Group by hour of day
  const hourPatterns: { [key: number]: { count: number; ids: string[] } } = {};
  
  anomalies.forEach((doc) => {
    const data = doc.data();
    if (data.entityType !== 'expense') return;
    
    const date = data.detectedAt?.toDate();
    if (!date) return;
    
    const hour = date.getHours();
    if (!hourPatterns[hour]) {
      hourPatterns[hour] = { count: 0, ids: [] };
    }
    hourPatterns[hour].count++;
    if (hourPatterns[hour].ids.length < 5) {
      hourPatterns[hour].ids.push(doc.id);
    }
  });
  
  // Find unusual hours (typically after 6 PM = hours 18-23)
  const businessHours = [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]; // 6 AM - 5 PM
  const avgBusinessCount = businessHours.reduce((sum, h) => sum + (hourPatterns[h]?.count || 0), 0) / businessHours.length;
  
  for (const hour of [18, 19, 20, 21, 22, 23]) {
    const eveningCount = hourPatterns[hour]?.count || 0;
    const increasePercent = avgBusinessCount > 0 
      ? Math.round(((eveningCount - avgBusinessCount) / avgBusinessCount) * 100)
      : 0;
    
    if (increasePercent >= 25 && eveningCount >= 2) {
      insights.push({
        title: `Evening Expense Spike`,
        description: `${increasePercent}% more expense anomalies detected after 6 PM, mainly caused by atypical vendor patterns.`,
        severity: increasePercent >= 50 ? 'high' : 'medium',
        type: 'time_pattern',
        entityType: 'expense',
        percentage: increasePercent,
        timeWindow: `after ${hour}:00`,
        affectedCount: eveningCount,
        samplesIds: hourPatterns[hour]?.ids || [],
        createdAt: admin.firestore.Timestamp.now(),
      });
    }
  }
  
  return insights;
}

function analyzeVendorPatterns(
  anomalies: FirebaseFirestore.QueryDocumentSnapshot[]
): AnomalyInsight[] {
  const insights: AnomalyInsight[] = [];
  
  // Group by vendor
  const vendorMap: { [vendor: string]: { count: number; ids: string[] } } = {};
  
  anomalies.forEach((doc) => {
    const data = doc.data();
    if (data.entityType !== 'expense') return;
    
    const vendor = data.sample?.merchant || data.sample?.vendor || 'unknown';
    if (!vendor || vendor === 'unknown') return;
    
    if (!vendorMap[vendor]) {
      vendorMap[vendor] = { count: 0, ids: [] };
    }
    vendorMap[vendor].count++;
    if (vendorMap[vendor].ids.length < 5) {
      vendorMap[vendor].ids.push(doc.id);
    }
  });
  
  // Find vendors with suspicious concentration
  const avgVendorCount = Object.values(vendorMap).reduce((sum, v) => sum + v.count, 0) / Object.keys(vendorMap).length;
  
  for (const [vendor, { count, ids }] of Object.entries(vendorMap)) {
    const increasePercent = avgVendorCount > 0
      ? Math.round(((count - avgVendorCount) / avgVendorCount) * 100)
      : 0;
    
    if (count >= 5 && increasePercent >= 100) {
      insights.push({
        title: `Suspicious Vendor Concentration`,
        description: `Vendor "${vendor}" has ${count} anomalies this week (${increasePercent}% above average). High concentration may indicate fraud or system error.`,
        severity: count >= 10 ? 'critical' : 'high',
        type: 'vendor_pattern',
        entityType: 'expense',
        percentage: increasePercent,
        timeWindow: 'this week',
        affectedCount: count,
        samplesIds: ids,
        createdAt: admin.firestore.Timestamp.now(),
      });
    }
  }
  
  return insights;
}

/**
 * Query endpoint for anomaly insights
 */
export const queryAnomalyInsights = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
    }

    const { days = 7, severity } = data;

    try {
      const snapshot = await db
        .collection('analytics')
        .doc('anomaly_insights')
        .collection('daily')
        .orderBy('date', 'desc')
        .limit(Math.min(days, 30))
        .get();

      let allInsights: AnomalyInsight[] = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        if (Array.isArray(data.insights)) {
          allInsights = allInsights.concat(data.insights);
        }
      });

      // Filter by severity if requested
      if (severity) {
        allInsights = allInsights.filter((i) => i.severity === severity);
      }

      // Sort by severity and recency
      allInsights.sort((a, b) => {
        const severityOrder = { critical: 0, high: 1, medium: 2, low: 3 };
        return severityOrder[a.severity] - severityOrder[b.severity];
      });

      return allInsights;
    } catch (error) {
      console.error('Error querying anomaly insights:', error);
      throw new functions.https.HttpsError('internal', 'Failed to query insights');
    }
  }
);
