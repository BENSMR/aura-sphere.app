import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getConfig, creditTokens } from '../loyalty/loyaltyEngine';

// every day at 01:00 UTC
export const dailyLoyaltyHousekeeping = functions.pubsub.schedule('0 1 * * *').onRun(async (context) => {
  const cfg = await getConfig();
  const now = admin.firestore.Timestamp.now();
  const usersSnap = await admin.firestore().collection('users').limit(500).get(); // paginate in prod
  for (const u of usersSnap.docs) {
    const uid = u.id;
    // Example: If user streak >= weekly threshold and not yet awarded this week, give weekly bonus
    const loyaltyRef = admin.firestore().doc(`users/${uid}/loyalty/profile`);
    const lSnap = await loyaltyRef.get();
    const streak = lSnap.exists ? lSnap.data()?.streak?.current || 0 : 0;
    // simplified: reward weekly every time streak % threshold == 0
    if (streak > 0 && (streak % cfg.weekly.thresholdDays) === 0) {
      // avoid double awarding: check lastBonus or a weekly flag
      // simple approach: store lastWeeklyRewardDate
      const lastWeekly = lSnap.exists ? lSnap.data()?.lastWeeklyReward : null;
      const todayISO = new Date(now.toMillis()).toISOString().slice(0,10);
      if (lastWeekly !== todayISO) {
        await creditTokens(uid, cfg.weekly.bonus, 'weekly_streak_bonus', {});
        await loyaltyRef.set({ lastWeeklyReward: todayISO }, { merge: true });
      }
    }
  }
  return null;
});
