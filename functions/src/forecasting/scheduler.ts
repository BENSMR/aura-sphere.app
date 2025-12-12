// functions/src/forecasting/scheduler.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { DateTime } from 'luxon';
import { generateForecastForUser } from './generateForecast';

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

// Run daily at 02:00 UTC to pre-generate forecasts for active users
export const dailyForecastGenerator = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('UTC')
  .onRun(async () => {
    const usersSnap = await db.collection('users').get();
    const promises: Promise<void>[] = [];

    for (const userDoc of usersSnap.docs) {
      const userData = userDoc.data();
      const lastActive = userData.lastActive;

      if (lastActive && lastActive.toDate) {
        const diffDays = DateTime.utc().diff(DateTime.fromJSDate(lastActive.toDate()), 'days').days;
        if (diffDays > 90) continue;
      }

      promises.push(
        generateForecastForUser(userDoc.id, { daysPast: 120, horizon: 90 })
          .then(() => undefined)
          .catch((err) =>
            console.error(`Forecast failed for user ${userDoc.id}:`, err)
          )
      );
    }

    await Promise.allSettled(promises);
    return { success: true };
  });
