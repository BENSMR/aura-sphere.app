import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

type FinanceGoals = {
  monthlyRevenueTarget: number;
  profitMarginTarget: number; // in %
  maxExpensesThisMonth: number;
  cashRunwayTargetDays: number;
  currency: string;
};

function getDefaultGoals(currency: string): FinanceGoals {
  return {
    monthlyRevenueTarget: 5000,
    profitMarginTarget: 20,
    maxExpensesThisMonth: 4000,
    cashRunwayTargetDays: 60,
    currency,
  };
}

/**
 * Evaluate goals vs summary and write alerts document.
 */
async function evaluateFinanceGoalsForUser(userId: string) {
  const summaryRef = db
    .collection("users")
    .doc(userId)
    .collection("analytics")
    .doc("financeSummary");

  const summarySnap = await summaryRef.get();
  if (!summarySnap.exists) {
    console.log(`No financeSummary yet for user ${userId}`);
    return;
  }

  const s = summarySnap.data() as any;
  const currency = s.currency || "EUR";

  const goalsRef = db
    .collection("users")
    .doc(userId)
    .collection("analytics")
    .doc("financeGoals");

  const goalsSnap = await goalsRef.get();
  const goals: FinanceGoals = goalsSnap.exists
    ? {
        monthlyRevenueTarget: Number(
          goalsSnap.data()?.monthlyRevenueTarget ?? 0
        ),
        profitMarginTarget: Number(
          goalsSnap.data()?.profitMarginTarget ?? 0
        ),
        maxExpensesThisMonth: Number(
          goalsSnap.data()?.maxExpensesThisMonth ?? 0
        ),
        cashRunwayTargetDays: Number(
          goalsSnap.data()?.cashRunwayTargetDays ?? 0
        ),
        currency,
      }
    : getDefaultGoals(currency);

  // If no goals yet, store defaults for the user:
  if (!goalsSnap.exists) {
    await goalsRef.set(goals, { merge: true });
  }

  const alerts: any[] = [];

  // 1) Revenue vs goal
  const revenue = Number(s.revenueThisMonth ?? 0);
  const revenuePct =
    goals.monthlyRevenueTarget > 0
      ? (revenue / goals.monthlyRevenueTarget) * 100
      : 0;

  if (revenuePct < 50) {
    alerts.push({
      type: "revenue",
      level: "warning",
      message: `Revenue this month is at ${revenuePct.toFixed(
        1
      )}% of your target.`,
    });
  } else if (revenuePct >= 100) {
    alerts.push({
      type: "revenue",
      level: "success",
      message: `You have reached your monthly revenue target 🎉`,
    });
  }

  // 2) Profit margin vs target
  const margin = Number(s.profitMarginThisMonth ?? 0);
  if (margin < goals.profitMarginTarget) {
    alerts.push({
      type: "margin",
      level: "warning",
      message: `Profit margin (${margin.toFixed(
        1
      )}%) is below your target (${goals.profitMarginTarget}%).`,
    });
  }

  // 3) Expenses vs max allowed
  const expenses = Number(s.expensesThisMonth ?? 0);
  if (goals.maxExpensesThisMonth > 0 && expenses > goals.maxExpensesThisMonth) {
    alerts.push({
      type: "expenses",
      level: "danger",
      message: `Expenses this month (${expenses.toFixed(
        2
      )} ${currency}) exceeded your limit (${goals.maxExpensesThisMonth.toFixed(
        2
      )} ${currency}).`,
    });
  }

  // 4) Rough cash runway estimate based on last 30 days profit
  const profitLast30 = Number(s.profitLast30 ?? 0);
  let runwayDaysEstimate = null;
  if (profitLast30 < 0) {
    const avgDailyLoss = Math.abs(profitLast30) / 30;
    const cashBuffer = s.revenueThisMonth - s.expensesThisMonth;
    if (cashBuffer > 0 && avgDailyLoss > 0) {
      runwayDaysEstimate = Math.round(cashBuffer / avgDailyLoss);
    }
  }

  if (runwayDaysEstimate !== null) {
    if (runwayDaysEstimate < goals.cashRunwayTargetDays) {
      alerts.push({
        type: "runway",
        level: "danger",
        message: `Estimated cash runway is only ${runwayDaysEstimate} days, below your target of ${goals.cashRunwayTargetDays} days.`,
      });
    } else {
      alerts.push({
        type: "runway",
        level: "success",
        message: `Cash runway looks acceptable (~${runwayDaysEstimate} days).`,
      });
    }
  }

  // Overall status
  let status: "ok" | "warning" | "danger" = "ok";
  if (alerts.some((a) => a.level === "danger")) status = "danger";
  else if (alerts.some((a) => a.level === "warning")) status = "warning";

  const alertsDoc = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    status,
    revenuePctOfTarget: revenuePct,
    margin,
    expensesThisMonth: expenses,
    runwayDaysEstimate,
    alerts,
  };

  await db
    .collection("users")
    .doc(userId)
    .collection("analytics")
    .doc("financeAlerts")
    .set(alertsDoc, { merge: true });

  console.log(`✅ Finance alerts updated for user ${userId}`);
}

// Trigger — anytime financeSummary changes → re-evaluate
export const onFinanceSummaryGoalsAlerts = functions.firestore
  .document("users/{userId}/analytics/financeSummary")
  .onWrite(async (_change, context) => {
    const { userId } = context.params;
    return evaluateFinanceGoalsForUser(userId);
  });

/**
 * Callable: client sets/updates their finance goals
 */
export const setFinanceGoals = functions.https.onCall(
  async (data, context) => {
    const userId = context.auth?.uid;
    if (!userId) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const goals: Partial<FinanceGoals> = {
      monthlyRevenueTarget: Number(data.monthlyRevenueTarget ?? 0),
      profitMarginTarget: Number(data.profitMarginTarget ?? 0),
      maxExpensesThisMonth: Number(data.maxExpensesThisMonth ?? 0),
      cashRunwayTargetDays: Number(data.cashRunwayTargetDays ?? 0),
    };

    const userDoc = await db.collection("users").doc(userId).get();
    const currency =
      (userDoc.data()?.financeSettings?.baseCurrency as string) ||
      (userDoc.data()?.currency as string) ||
      "EUR";

    const goalsRef = db
      .collection("users")
      .doc(userId)
      .collection("analytics")
      .doc("financeGoals");

    await goalsRef.set(
      {
        ...goals,
        currency,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Re-evaluate alerts after updating goals
    await evaluateFinanceGoalsForUser(userId);

    return { success: true };
  }
);
