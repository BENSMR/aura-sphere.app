import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();

const db = admin.firestore();

/**
 * Configurable via `firebase functions:config:set analytics.window_days=7 analytics.max_docs=2000`
 * Default windowDays = 7, maxDocs = 2000
 */
function getConfig() {
  const cfg = functions.config().analytics || {};
  return {
    windowDays: parseInt(cfg.window_days || '7', 10),
    maxDocs: parseInt(cfg.max_docs || '2000', 10),
    summaryCollection: cfg.summary_collection || 'analytics/anomaly_summary',
    dailyCollection: cfg.daily_collection || 'analytics/anomaly_daily'
  };
}

type AggResult = {
  counts: { critical: number; high: number; medium: number; low: number };
  total: number;
  bySource: Record<string, number>;
  trend: { day: string; count: number }[]; // YYYY-MM-DD
  topEntities: { entityType: string; entityId: string; score: number; severity: string }[];
  riskScore: number; // 0..100
  generatedAt: admin.firestore.Timestamp;
};

/**
 * Core aggregator: reads recent anomalies and writes daily aggregate + summary doc.
 */
export async function aggregateAnomalies(windowDays = 7, maxDocs = 2000): Promise<AggResult> {
  const now = new Date();
  const startDay = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  startDay.setUTCDate(startDay.getUTCDate() - (windowDays - 1));
  const startTs = admin.firestore.Timestamp.fromDate(startDay);

  // Query anomalies within the window (limit to maxDocs)
  const snap = await db.collection('anomalies')
    .where('detectedAt', '>=', startTs)
    .orderBy('detectedAt', 'desc')
    .limit(maxDocs)
    .get();

  let critical = 0, high = 0, medium = 0, low = 0;
  const bySource: Record<string, number> = {};
  const dayCounts: Record<string, number> = {};
  const entityMap: Record<string, { entityType: string; entityId: string; score: number; severity: string }> = {};

  snap.docs.forEach(doc => {
    const d = doc.data();
    const severity = (d.severity || 'low').toString();
    switch (severity) {
      case 'critical':
        critical++;
        break;
      case 'high':
        high++;
        break;
      case 'medium':
        medium++;
        break;
      default:
        low++;
        break;
    }

    const etype = (d.entityType || 'unknown').toString();
    bySource[etype] = (bySource[etype] || 0) + 1;

    const ts = d.detectedAt as admin.firestore.Timestamp | undefined;
    const dt = ts ? ts.toDate() : doc.createTime?.toDate() || new Date();
    const dayKey = dt.toISOString().slice(0, 10); // YYYY-MM-DD
    dayCounts[dayKey] = (dayCounts[dayKey] || 0) + 1;

    const score = (d.score ? Number(d.score) : 0);
    const eid = d.entityId ? d.entityId.toString() : doc.id;
    const key = `${etype}:${eid}`;

    // Keep the highest score seen for an entity in window
    if (!entityMap[key] || (entityMap[key].score < score)) {
      entityMap[key] = { entityType: etype, entityId: eid, score, severity };
    }
  });

  const total = critical + high + medium + low;
  // Weighted risk score 0..100 (critical=4, high=3, medium=2, low=1)
  const riskScore = total > 0 ? ((critical * 4 + high * 3 + medium * 2 + low * 1) / (total * 4)) * 100 : 0;

  // Build trend points for each day in the window (oldest -> newest)
  const trend: { day: string; count: number }[] = [];
  for (let i = windowDays - 1; i >= 0; i--) {
    const d = new Date(startDay);
    d.setUTCDate(startDay.getUTCDate() + i);
    const key = d.toISOString().slice(0, 10);
    trend.push({ day: key, count: dayCounts[key] || 0 });
  }

  // Top entities by score desc
  const topEntities = Object.values(entityMap)
    .sort((a, b) => b.score - a.score)
    .slice(0, 50) // keep top 50
    .map(e => ({ entityType: e.entityType, entityId: e.entityId, score: e.score, severity: e.severity }));

  const agg: AggResult = {
    counts: { critical, high, medium, low },
    total,
    bySource,
    trend,
    topEntities,
    riskScore,
    generatedAt: admin.firestore.Timestamp.now(),
  };

  // Write daily snapshot + update summary
  const cfg = getConfig();
  const dailyCollection = db.collection(cfg.dailyCollection);
  const summaryDocRef = db.doc(`${cfg.summaryCollection}/latest`);

  // Daily doc id: latest day's date (UTC)
  const dailyId = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const dailyDocRef = dailyCollection.doc(dailyId);

  // Compose daily doc payload (trim heavy fields)
  const dailyPayload = {
    date: dailyId,
    generatedAt: agg.generatedAt,
    counts: agg.counts,
    total: agg.total,
    bySource: agg.bySource,
    trend: agg.trend,
    topEntities: agg.topEntities.slice(0, 20), // store top 20 to limit size
    riskScore: Number(agg.riskScore.toFixed(2)),
    windowDays,
    note: `Auto-generated aggregate for last ${windowDays} days`,
  };

  // Use transaction to save both docs
  await db.runTransaction(async tx => {
    tx.set(dailyDocRef, dailyPayload, { merge: true });
    tx.set(summaryDocRef, {
      updatedAt: agg.generatedAt,
      latestDailyId: dailyId,
      counts: agg.counts,
      total: agg.total,
      riskScore: Number(agg.riskScore.toFixed(2)),
      topEntities: agg.topEntities.slice(0, 10),
    }, { merge: true });
  });

  return agg;
}

/**
 * Scheduled function (recommended): runs once per day in UTC.
 * Adjust schedule as needed.
 */
export const dailyAggregateScheduler = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('UTC')
  .onRun(async (context) => {
    const cfg = getConfig();
    const windowDays = cfg.windowDays;
    const maxDocs = cfg.maxDocs;
    functions.logger.info('running dailyAggregateScheduler', { windowDays, maxDocs });
    try {
      await aggregateAnomalies(windowDays, maxDocs);
      functions.logger.info('daily aggregation finished');
    } catch (err) {
      functions.logger.error('daily aggregation failed', err);
    }
    return null;
  });

/**
 * Callable / HTTP trigger to run aggregation on demand (protected by IAM or function-level checks).
 * Useful for on-demand refresh after large ingestion.
 */
export const aggregateAnomaliesCallable = functions.https.onCall(async (data, context) => {
  // Optionally restrict to admins or authenticated users:
  // if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  // if (!context.auth.token.admin) throw new functions.https.HttpsError('permission-denied', 'Admin only');

  const cfg = getConfig();
  const windowDays = data?.windowDays ? Number(data.windowDays) : cfg.windowDays;
  const maxDocs = data?.maxDocs ? Number(data.maxDocs) : cfg.maxDocs;
  functions.logger.info('aggregateAnomaliesCallable requested', { windowDays, maxDocs, uid: context.auth?.uid });
  try {
    const result = await aggregateAnomalies(windowDays, maxDocs);
    return { success: true, summary: { total: result.total, riskScore: result.riskScore } };
  } catch (err: any) {
    functions.logger.error('aggregateAnomaliesCallable failed', err);
    throw new functions.https.HttpsError('internal', 'Aggregation failed');
  }
});
