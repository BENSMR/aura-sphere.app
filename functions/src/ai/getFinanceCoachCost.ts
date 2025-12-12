import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

/**
 * Returns cost & user context BEFORE triggering expensive AI.
 * Used by Flutter to show confirmation dialog.
 */
export interface FinanceCoachCostResponse {
  cost: number;
  plan: string;
  balance: number;
  allowedWithoutCharge: boolean;
  enoughTokens: boolean;
}

export const getFinanceCoachCost = functions.https.onCall(
  async (data: unknown, context): Promise<FinanceCoachCostResponse> => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }

    // Read config once (shared with financeCoach.ts)
    const costPerCall = getOpenAiCostFromConfig();

    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data() as any;

    const plan = (userData?.subscription?.plan as string) || 'free';
    const auraBalance = Number(userData?.auraTokens?.balance ?? 0);

    const paidPlans = ['pro', 'business', 'enterprise'];
    const allowedWithoutCharge = paidPlans.includes(plan);
    const enoughTokens = auraBalance >= costPerCall;

    return {
      cost: costPerCall,
      plan,
      balance: auraBalance,
      allowedWithoutCharge,
      enoughTokens,
    };
  }
);

/**
 * Shared helper to read OpenAI cost from config.
 * Used by both getFinanceCoachCost and financeCoach.ts.
 */
export function getOpenAiCostFromConfig(): number {
  const defaultCost = 5;
  const cfgCost = functions.config().auracoach?.cost;
  if (typeof cfgCost === 'string') {
    const parsed = parseInt(cfgCost, 10);
    return isNaN(parsed) ? defaultCost : parsed;
  }
  return defaultCost;
}
