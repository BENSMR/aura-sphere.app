import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { checkAndAwardMilestones } from '../loyalty/loyaltyEngine';

export const onTokenCredit = functions.firestore
  .document('users/{uid}/token_audit/{txId}')
  .onCreate(async (snap, ctx) => {
    try {
      const uid = ctx.params.uid;
      const data = snap.data();
      // only respond to 'loyalty' or 'purchase' credits if desired
      return await checkAndAwardMilestones(uid);
    } catch (err) {
      console.error('milestoneChecker error', err);
      return null;
    }
  });
