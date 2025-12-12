// functions/src/forecasting/aggregateHistory.ts
import * as admin from 'firebase-admin';
import { DateTime } from 'luxon';

const db = admin.firestore();

/**
 * Aggregates net cash per day for the past N days for a user.
 * Returns: { dates: string[], net: number[] }
 */
export async function aggregateDailyNet(uid: string, days = 120) {
  const end = DateTime.utc().endOf('day');
  const start = end.minus({ days });

  const startDateTs = admin.firestore.Timestamp.fromDate(start.toJSDate());
  const endDateTs = admin.firestore.Timestamp.fromDate(end.toJSDate());

  const invoicesSnap = await db
    .collection('users')
    .doc(uid)
    .collection('invoices')
    .where('date', '>=', startDateTs)
    .where('date', '<=', endDateTs)
    .get();

  const expensesSnap = await db
    .collection('users')
    .doc(uid)
    .collection('expenses')
    .where('date', '>=', startDateTs)
    .where('date', '<=', endDateTs)
    .get();

  const map = new Map<string, { inflow: number; outflow: number }>();
  for (let i = 0; i <= days; i++) {
    const d = start.plus({ days: i }).toISODate()!;
    map.set(d, { inflow: 0, outflow: 0 });
  }

  invoicesSnap.docs.forEach((doc) => {
    const d = doc.data();
    const ts = d.date;
    if (!ts?.toDate) return;
    const isoDate = DateTime.fromJSDate(ts.toDate()).toISODate();
    if (!isoDate) return;
    const amt = Number(d.amount || 0);
    const entry = map.get(isoDate) || { inflow: 0, outflow: 0 };
    entry.inflow += amt;
    map.set(isoDate, entry);
  });

  expensesSnap.docs.forEach((doc) => {
    const d = doc.data();
    const ts = d.date;
    if (!ts?.toDate) return;
    const isoDate = DateTime.fromJSDate(ts.toDate()).toISODate();
    if (!isoDate) return;
    const amt = Number(d.amount || 0);
    const entry = map.get(isoDate) || { inflow: 0, outflow: 0 };
    entry.outflow += amt;
    map.set(isoDate, entry);
  });

  const dates: string[] = [];
  const net: number[] = [];
  for (let i = 0; i <= days; i++) {
    const d = start.plus({ days: i }).toISODate()!;
    const e = map.get(d)!;
    dates.push(d);
    net.push(e.inflow - e.outflow);
  }

  return { dates, net };
}
