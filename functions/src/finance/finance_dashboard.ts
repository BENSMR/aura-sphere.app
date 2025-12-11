/**
 * functions/src/finance/finance_dashboard.ts
 *
 * Financial dashboard analytics and KPI calculations with multi-currency support
 * 
 * Triggers:
 * - onInvoiceFinanceSummary: Recalculates on any invoice change
 * - onExpenseFinanceSummary: Recalculates on any expense change
 * - financeDailyRecalc: Nightly full recalculation for all users
 * 
 * Stores summary in: users/{userId}/analytics/financeSummary
 * 
 * Features:
 * - Multi-currency normalization to user's base currency
 * - Tax rate from user settings or country-based VAT defaults
 * - Real-time trigger updates + nightly safety recalculation
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

// --- Simple FX rate table (can be made dynamic later)
const DEFAULT_BASE_CURRENCY = "EUR";
const FX_RATES: Record<string, number> = {
  EUR: 1,
  USD: 0.92,
  GBP: 1.15,
  MAD: 0.09,
};

/**
 * Convert amount from one currency to base currency using FX rates
 */
function convertToBase(
  amount: number,
  currency: string | undefined,
  baseCurrency: string
): number {
  const cur = (currency || baseCurrency || DEFAULT_BASE_CURRENCY).toUpperCase();
  const base = baseCurrency.toUpperCase();
  if (cur === base) return amount;

  const rateFrom = FX_RATES[cur] ?? 1;
  const rateBase = FX_RATES[base] ?? 1;

  // Convert via EUR-like base
  const eurAmount = amount / rateFrom;
  return eurAmount * rateBase;
}

/**
 * Get user's finance configuration (currency, tax rate)
 */
async function getUserFinanceConfig(userId: string) {
  const userDoc = await db.collection("users").doc(userId).get();
  const userData = userDoc.exists ? userDoc.data() : {};

  const baseCurrency =
    (userData?.financeSettings?.baseCurrency as string) ||
    (userData?.currency as string) ||
    DEFAULT_BASE_CURRENCY;

  const taxRate =
    (userData?.financeSettings?.taxRate as number) ??
    // fallback: simple map by country
    (() => {
      const country = (userData?.country as string | undefined)?.toUpperCase();
      if (!country) return 0.2;
      const EU_VAT: Record<string, number> = {
        FR: 0.2,
        ES: 0.21,
        DE: 0.19,
        IT: 0.22,
        NL: 0.21,
      };
      return EU_VAT[country] ?? 0.2;
    })();

  return { baseCurrency: baseCurrency.toUpperCase(), taxRate };
}

/**
 * Recalculate financial summary for one user with:
 * - Multi-currency normalized to baseCurrency
 * - Tax rate taken from user financeSettings or inferred
 */
async function recomputeFinanceSummaryForUser(userId: string) {
  const now = new Date();
  const msPerDay = 1000 * 60 * 60 * 24;

  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const last30 = new Date(now.getTime() - 30 * msPerDay);

  const { baseCurrency, taxRate } = await getUserFinanceConfig(userId);

  let revenueTotal = 0;
  let revenueThisMonth = 0;
  let revenueLast30 = 0;

  let unpaidInvoicesCount = 0;
  let unpaidInvoicesAmount = 0;
  let overdueInvoicesCount = 0;
  let overdueInvoicesAmount = 0;

  // --------- INVOICES ---------
  const invoicesSnap = await db
    .collection("users")
    .doc(userId)
    .collection("invoices")
    .get();

  invoicesSnap.forEach((doc) => {
    const inv = doc.data() as any;
    const totalRaw = Number(inv?.totals?.total ?? inv?.amount ?? 0);
    const currency = inv.currency || baseCurrency;
    const total = convertToBase(totalRaw, currency, baseCurrency);

    const status = inv.status || "draft";
    const issuedAt: Date | null =
      inv.issuedAt?.toDate?.() ?? (inv.issuedAt ? new Date(inv.issuedAt) : null);
    const dueAt: Date | null =
      inv.dueAt?.toDate?.() ?? (inv.dueAt ? new Date(inv.dueAt) : null);

    if (status === "paid") {
      revenueTotal += total;
      if (issuedAt && issuedAt >= startOfMonth) revenueThisMonth += total;
      if (issuedAt && issuedAt >= last30) revenueLast30 += total;
    }

    if (status === "sent" || status === "pending") {
      unpaidInvoicesCount += 1;
      unpaidInvoicesAmount += total;
      if (dueAt && dueAt < now) {
        overdueInvoicesCount += 1;
        overdueInvoicesAmount += total;
      }
    }
  });

  // --------- EXPENSES ---------
  let expensesTotal = 0;
  let expensesThisMonth = 0;
  let expensesLast30 = 0;

  const expensesSnap = await db
    .collection("users")
    .doc(userId)
    .collection("expenses")
    .get();

  expensesSnap.forEach((doc) => {
    const ex = doc.data() as any;
    const amountRaw = Number(ex.amount ?? 0);
    const currency = ex.currency || baseCurrency;
    const amount = convertToBase(amountRaw, currency, baseCurrency);

    const date: Date | null =
      ex.date?.toDate?.() ?? (ex.date ? new Date(ex.date) : null);

    expensesTotal += amount;
    if (date && date >= startOfMonth) expensesThisMonth += amount;
    if (date && date >= last30) expensesLast30 += amount;
  });

  const profitThisMonth = revenueThisMonth - expensesThisMonth;
  const profitLast30 = revenueLast30 - expensesLast30;

  const taxEstimateThisMonth = revenueThisMonth * taxRate;

  const summary = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    currency: baseCurrency,
    taxRate,
    revenueTotal,
    revenueThisMonth,
    revenueLast30,
    expensesTotal,
    expensesThisMonth,
    expensesLast30,
    profitThisMonth,
    profitLast30,
    unpaidInvoicesCount,
    unpaidInvoicesAmount,
    overdueInvoicesCount,
    overdueInvoicesAmount,
    taxEstimateThisMonth,
    profitMarginThisMonth:
      revenueThisMonth > 0
        ? (profitThisMonth / revenueThisMonth) * 100
        : 0,
  };

  await db
    .collection("users")
    .doc(userId)
    .collection("analytics")
    .doc("financeSummary")
    .set(summary, { merge: true });

  console.log(
    `✅ Finance summary updated for user ${userId} in ${baseCurrency}`
  );
  return summary;
}

// Trigger 1 — Any invoice change → recompute summary
export const onInvoiceFinanceSummary = functions.firestore
  .document("users/{userId}/invoices/{invoiceId}")
  .onWrite(async (_change, context) => {
    const { userId } = context.params;
    return recomputeFinanceSummaryForUser(userId);
  });

// Trigger 2 — Any expense change → recompute summary
export const onExpenseFinanceSummary = functions.firestore
  .document("users/{userId}/expenses/{expenseId}")
  .onWrite(async (_change, context) => {
    const { userId } = context.params;
    return recomputeFinanceSummaryForUser(userId);
  });

// Trigger 3 — Nightly scheduled full recompute (safety)
export const financeDailyRecalc = functions.pubsub
  .schedule("every 24 hours")
  .timeZone("UTC")
  .onRun(async () => {
    console.log("⏳ Nightly finance recompute started...");
    const usersSnap = await db.collection("users").get();
    for (const userDoc of usersSnap.docs) {
      await recomputeFinanceSummaryForUser(userDoc.id);
    }
    console.log("✅ Nightly finance recompute finished.");
    return null;
  });
