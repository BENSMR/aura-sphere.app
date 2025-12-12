// functions/src/forecasting/generateForecast.ts
import * as admin from 'firebase-admin';
import { holtLinear, buildDateRange, linearRegression, residualsAndStd } from './forecastUtils';
import { aggregateDailyNet } from './aggregateHistory';
import { DateTime } from 'luxon';

const db = admin.firestore();

/** Core forecast function */
export async function generateForecastForUser(uid: string, options?: { daysPast?: number; horizon?: number }) {
  const daysPast = options?.daysPast ?? 90;
  const horizon = options?.horizon ?? 90;

  // 1) Aggregate history
  const { net } = await aggregateDailyNet(uid, daysPast);

  // 2) Forecast net cash flow
  const smoothed = holtLinear(net, 0.25, 0.05, horizon);

  // 3) Linear trend on last 30 days
  const recentNet = net.slice(-30);
  const xs = recentNet.map((_, i) => i);
  const { a, b } = linearRegression(xs, recentNet);
  const lastIndex = net.length - 1;
  const linearProj: number[] = [];
  for (let i = 1; i <= horizon; i++) {
    linearProj.push(a + b * (lastIndex + i));
  }

  // 4) Combine forecasts
  const combined = smoothed.map((s, i) => (s + linearProj[i]) / 2);

  // 5) Cumulative balance
  const currentBalance = await computeCurrentBalance(uid);
  const cumulative: number[] = [];
  let running = currentBalance;
  for (const value of combined) {
    running += value;
    cumulative.push(running);
  }

  // 6) Confidence band (simplified)
  const { std } = residualsAndStd(net.slice(-30), net.slice(-30));
  const confidenceBand = combined.map((v) => ({ low: v - 2 * std, high: v + 2 * std }));

  // 7) Runway (days until balance < 0)
  let runway: number | null = null;
  for (let i = 0; i < cumulative.length; i++) {
    if (cumulative[i] < 0) {
      runway = i + 1;
      break;
    }
  }

  const forecastDoc = {
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    horizonDays: horizon,
    dates: buildDateRange(new Date(), horizon),
    dailyNetForecast: combined,
    cumulativeBalance: cumulative,
    currentBalance,
    runwayDays: runway,
    confidenceStd: std,
  };

  await db.collection('users').doc(uid).collection('forecasts').doc('cashflow').set(forecastDoc, { merge: true });
  return forecastDoc;
}

async function computeCurrentBalance(uid: string): Promise<number> {
  const balanceRef = db.collection('users').doc(uid).collection('wallet').doc('balance');
  const balanceSnap = await balanceRef.get();
  if (balanceSnap.exists) {
    const balanceData = balanceSnap.data();
    const amount = balanceData?.amount;
    if (typeof amount === 'number') return amount;
  }

  // Fallback: sum paid invoices minus paid expenses
  let totalInflow = 0;
  const invoices = await db
    .collection('users')
    .doc(uid)
    .collection('invoices')
    .where('status', '==', 'paid')
    .get();
  invoices.docs.forEach((doc) => {
    totalInflow += Number(doc.data().amount || 0);
  });

  let totalOutflow = 0;
  const expenses = await db
    .collection('users')
    .doc(uid)
    .collection('expenses')
    .where('status', '==', 'paid')
    .get();
  expenses.docs.forEach((doc) => {
    totalOutflow += Number(doc.data().amount || 0);
  });

  return totalInflow - totalOutflow;
}
