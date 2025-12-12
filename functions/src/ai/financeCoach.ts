import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import fetch from 'node-fetch'; // or axios
import { DateTime } from 'luxon';
import { generateForecastForUser } from '../forecasting/generateForecast';
import { getOpenAiCostFromConfig } from './getFinanceCoachCost';

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const OPENAI_KEY = functions.config().openai?.key || null;
const OPENAI_ENDPOINT = 'https://api.openai.com/v1/chat/completions';

// Helper: simple deterministic rule-based analyzer
function ruleBasedAdvisor(summary: {
  currentBalance: number,
  runwayDays: number | null,
  overdueInvoicesCount: number,
  overdueAmount: number,
  avgDailyNet: number,
}) {
  const adv: string[] = [];
  if (summary.runwayDays === null) {
    adv.push("We couldn't estimate runway — we need more historical data.");
  } else {
    if (summary.runwayDays <= 7) {
      adv.push("⚠️ Cash runway is very short (≤ 7 days). Prioritize collecting invoices and delay discretionary spending.");
    } else if (summary.runwayDays <= 30) {
      adv.push("🚨 Runway < 30 days. Contact top clients about early payments and review upcoming costs.");
    } else {
      adv.push("✅ Cash runway healthy. Keep monitoring weekly.");
    }
  }

  if (summary.overdueInvoicesCount > 0) {
    adv.push(`📬 You have ${summary.overdueInvoicesCount} overdue invoices totaling ${summary.overdueAmount}. Consider sending payment reminders or offering a small early-pay discount.`);
  }

  if (summary.avgDailyNet < 0) {
    adv.push("📉 Your average daily net is negative — your business is burning cash. Identify top 3 expense categories and negotiate supplier terms.");
  } else if (summary.avgDailyNet > 0 && summary.currentBalance < 1000) {
    adv.push("💡 You are profitable day-to-day but low reserve. Consider keeping a 1-3 month buffer.");
  }

  // simple prioritized actions
  const actions = [];
  if (summary.overdueInvoicesCount > 0) actions.push({ action: 'send_reminder', label: 'Send invoice reminders' });
  if (summary.runwayDays !== null && summary.runwayDays <= 30) actions.push({ action: 'apply_short_term_loan', label: 'Explore short-term financing' });
  if (summary.avgDailyNet < 0) actions.push({ action: 'reduce_expenses', label: 'Review recurring expenses' });

  return { adv, actions };
}

// Optionally call OpenAI to create friendly narrative
async function openAiNarrative(summaryText: string) {
  if (!OPENAI_KEY) return null;
  try {
    const prompt = `You are an expert small-business CFO. Given the data below, produce:
1) A short headline (1 line).
2) 3 prioritized actions the owner should take (short bullets).
3) One-sentence rationale for each action.

Data:
${summaryText}

Output as a JSON object with keys: headline, actions (array of {title, reason}).
`;
    const res = await fetch(OPENAI_ENDPOINT, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [{ role: 'system', content: 'You are an expert small business CFO.' }, { role: 'user', content: prompt }],
        max_tokens: 400,
        temperature: 0.2
      })
    });
    const body = await res.json();
    const txt = body?.choices?.[0]?.message?.content;
    if (!txt) return null;
    // try parse as JSON, if fails return raw text
    try {
      const json = JSON.parse(txt);
      return json;
    } catch (e) {
      return { text: txt };
    }
  } catch (err) {
    console.error('OpenAI error', err);
    return null;
  }
}

// Callable: returns advisory summary
export const getFinanceCoachCallable = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'Not signed in');

  // 1) Obtain forecast doc (use precomputed if exists)
  // re-use existing fetch logic: try forecasts doc
  const forecastDoc = await db.collection('users').doc(uid).collection('forecasts').doc('cashflow').get();
  let forecast = forecastDoc.exists ? forecastDoc.data() : null;

  // If not present or stale, generate quickly (non-blocking could be preferred)
  if (!forecast) {
    forecast = await generateForecastForUser(uid, { daysPast: 120, horizon: 90 }).catch((e: any) => null);
  }

  // 2) compute simple metrics
  const currentBalance = (forecast?.currentBalance ?? 0) as number;
  const runwayDays = forecast?.runwayDays ?? null;
  const dailyNetSeries = forecast?.dailyNetForecast ?? [];
  const avgDailyNet = (dailyNetSeries && dailyNetSeries.length) ? (dailyNetSeries.reduce((s:any,v:any)=>s+v,0)/dailyNetSeries.length) : 0;

  // 3) overdue invoices
  const invSnap = await db.collection('users').doc(uid).collection('invoices')
    .where('status', '==', 'overdue').get();
  const overdueCount = invSnap.size;
  let overdueAmt = 0;
  invSnap.docs.forEach(d => overdueAmt += Number(d.data().amount || 0));

  const summary = {
    currentBalance,
    runwayDays,
    overdueInvoicesCount: overdueCount,
    overdueAmount: overdueAmt,
    avgDailyNet
  };

  // 4) deterministic recommendations
  const deterministic = ruleBasedAdvisor(summary);

  // 5) openAI narrative (optional)
  const summaryText = `
currentBalance: ${currentBalance}
runwayDays: ${runwayDays}
overdueInvoicesCount: ${overdueCount}
overdueAmount: ${overdueAmt}
avgDailyNet: ${avgDailyNet.toFixed(2)}
`;
  const aiNarrative = await openAiNarrative(summaryText);

  // 6) persist audit of coach output (non-PII)
  await db.collection('users').doc(uid).collection('coach').doc('last').set({
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    summary,
    deterministic,
    aiNarrative: aiNarrative ? aiNarrative : null
  }, { merge: true });

  return {
    summary,
    deterministic,
    aiNarrative
  };
});

// Scheduled job: daily push (optional)
export const dailyFinanceCoach = functions.pubsub.schedule('0 7 * * *') // 07:00 UTC; will be converted per-user in scheduler logic if needed
  .onRun(async (context) => {
    const usersSnap = await db.collection('users').get();
    const tasks: Promise<any>[] = [];
    usersSnap.docs.forEach(u => {
      // only for active users who enabled coach in settings
      tasks.push((async () => {
        const settings = (await db.collection('users').doc(u.id).collection('settings').doc('digest').get()).data();
        if (!settings?.digestEnabled) return;
        // call callable internally
        try {
          await getFinanceCoachInternal(u.id);
          // optionally send push / email
        } catch (e) {
          console.error('coach daily failed for', u.id, e);
        }
      })());
    });
    await Promise.all(tasks);
    return null;
  });

// helper internal invocation (no auth)
async function getFinanceCoachInternal(uid: string) {
  // mimic callable body
  const forecastDoc = await db.collection('users').doc(uid).collection('forecasts').doc('cashflow').get();
  let forecast = forecastDoc.exists ? forecastDoc.data() : null;
  if (!forecast) forecast = await generateForecastForUser(uid, { daysPast: 120, horizon: 90 }).catch((e: any)=>null);

  const currentBalance = (forecast?.currentBalance ?? 0) as number;
  const runwayDays = forecast?.runwayDays ?? null;
  const dailyNetSeries = forecast?.dailyNetForecast ?? [];
  const avgDailyNet = (dailyNetSeries && dailyNetSeries.length) ? (dailyNetSeries.reduce((s:any,v:any)=>s+v,0)/dailyNetSeries.length) : 0;

  const invSnap = await db.collection('users').doc(uid).collection('invoices')
    .where('status', '==', 'overdue').get();
  const overdueCount = invSnap.size;
  let overdueAmt = 0;
  invSnap.docs.forEach(d => overdueAmt += Number(d.data().amount || 0));

  const summary = { currentBalance, runwayDays, overdueInvoicesCount: overdueCount, overdueAmount: overdueAmt, avgDailyNet };

  const deterministic = ruleBasedAdvisor(summary);
  const aiNarrative = OPENAI_KEY ? await openAiNarrative(JSON.stringify(summary)) : null;

  await db.collection('users').doc(uid).collection('coach').doc('last').set({
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    summary,
    deterministic,
    aiNarrative: aiNarrative ? aiNarrative : null
  }, { merge: true });

  // Optionally: send email/push using your digest system
  return { summary, deterministic, aiNarrative };
}
