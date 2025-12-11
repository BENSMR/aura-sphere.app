/**
 * functions/src/finance/financeCoach.ts
 *
 * AI-powered financial coaching based on user's finance summary
 * 
 * Callable function:
 * - Reads users/{userId}/analytics/financeSummary
 * - Generates AI advice using OpenAI (with rule-based fallback)
 * - Stores result in users/{userId}/analytics/financeCoach
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import OpenAI from "openai";

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

const OPENAI_KEY =
  functions.config()?.openai?.key || process.env.OPENAI_API_KEY || null;

let openai: OpenAI | null = null;
if (OPENAI_KEY) {
  openai = new OpenAI({ apiKey: OPENAI_KEY });
}

/**
 * Callable function:
 *  - Reads users/{userId}/analytics/financeSummary
 *  - Returns advice string
 *  - Stores it in analytics/financeCoach
 */
export const generateFinanceCoachAdvice = functions.https.onCall(
  async (data, context) => {
    const userId = context.auth?.uid || data.userId;
    if (!userId) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User not authenticated"
      );
    }

    const summaryDoc = await db
      .collection("users")
      .doc(userId)
      .collection("analytics")
      .doc("financeSummary")
      .get();

    if (!summaryDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "No finance summary found"
      );
    }

    const s = summaryDoc.data() as any;

    // Fallback simple advice
    let advice =
      "Your financial summary is not bad. Try to increase profit and reduce overdue invoices.";

    if (openai) {
      const prompt = `
You are a concise financial coach for small businesses.

Here is the user's finance summary (all normalized to ${s.currency}):

Revenue this month: ${s.revenueThisMonth}
Expenses this month: ${s.expensesThisMonth}
Profit this month: ${s.profitThisMonth}
Profit margin this month: ${s.profitMarginThisMonth}%
Unpaid invoices: ${s.unpaidInvoicesCount} (${s.unpaidInvoicesAmount})
Overdue invoices: ${s.overdueInvoicesCount} (${s.overdueInvoicesAmount})
Tax estimate this month: ${s.taxEstimateThisMonth}

Write:
- 2 sentences about the current situation (good/bad/ok)
- 3 short bullet-point suggestions (action items).

Keep it under 200 words, friendly but direct.
      `;

      try {
        const completion = await openai.chat.completions.create({
          model: "gpt-4o-mini",
          temperature: 0.3,
          messages: [
            {
              role: "system",
              content: "You are a helpful, direct financial coach.",
            },
            { role: "user", content: prompt },
          ],
          max_tokens: 220,
        });

        advice =
          completion.choices?.[0]?.message?.content ??
          advice;
      } catch (err) {
        console.error("Finance coach OpenAI error:", err);
      }
    } else {
      // rule-based fallback
      advice = "";
      if (s.profitThisMonth < 0) {
        advice +=
          "You are currently running at a loss this month. Focus on reducing expenses and increasing invoices collection.\n";
      } else if (s.profitMarginThisMonth < 10) {
        advice +=
          "Your profit margin is low. Consider raising prices or cutting low-value costs.\n";
      } else {
        advice +=
          "Your profit level looks healthy. Try to maintain or improve this trend.\n";
      }

      if (s.overdueInvoicesCount > 0) {
        advice +=
          "- You have overdue invoices. Prioritize chasing these payments.\n";
      }

      if (s.expensesThisMonth > s.revenueThisMonth * 0.8) {
        advice +=
          "- Expenses are very high vs revenue. Audit your major expense categories.\n";
      }
    }

    const coachDocRef = db
      .collection("users")
      .doc(userId)
      .collection("analytics")
      .doc("financeCoach");

    await coachDocRef.set(
      {
        advice,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { advice };
  }
);
