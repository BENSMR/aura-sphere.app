import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Admin-only callable function to set/update loyalty configuration
 * Used by admin dashboard to manage reward settings
 */
export const setLoyaltyConfig = functions.https.onCall(
  async (data, context) => {
    // Verify admin authentication
    if (!context.auth?.token?.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Admin access required'
      );
    }

    try {
      const {
        daily,
        weekly,
        milestones,
        specialDays,
      } = data;

      // Validate required fields
      if (!daily || !weekly) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Missing required fields: daily, weekly'
        );
      }

      // Update loyalty config
      await db.collection('loyalty_config').doc('global').set({
        daily: {
          baseReward: daily.baseReward || 50,
          streakBonus: daily.streakBonus || 10,
          maxStreakBonus: daily.maxStreakBonus || 500,
        },
        weekly: {
          thresholdDays: weekly.thresholdDays || 7,
          bonus: weekly.bonus || 500,
        },
        milestones: milestones || [
          { id: 'bronze', name: 'Bronze Member', threshold: 1000, reward: 100 },
          { id: 'silver', name: 'Silver Member', threshold: 5000, reward: 500 },
          { id: 'gold', name: 'Gold Member', threshold: 10000, reward: 1000 },
          { id: 'platinum', name: 'Platinum Member', threshold: 25000, reward: 2500 },
          { id: 'diamond', name: 'Diamond Member', threshold: 50000, reward: 5000 },
        ],
        specialDays: specialDays || [],
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: context.auth.uid,
      }, { merge: true });

      // Log admin action
      await db.collection('admin_logs').add({
        action: 'SET_LOYALTY_CONFIG',
        admin: context.auth.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        data: {
          daily,
          weekly,
          milestonesCount: milestones?.length || 5,
          specialDaysCount: specialDays?.length || 0,
        },
      });

      return {
        success: true,
        message: 'Loyalty configuration updated',
      };
    } catch (error) {
      console.error('Error setting loyalty config:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to update loyalty configuration'
      );
    }
  }
);

/**
 * Set reward configuration (simplified version)
 */
export const setRewardConfig = functions.https.onCall(
  async (data, context) => {
    // Verify admin authentication
    if (!context.auth?.token?.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Admin access required'
      );
    }

    try {
      const {
        dailyReward,
        streakMultiplier,
        weeklyBonus,
        monthlyBonus,
        signupBonus,
        enabled,
      } = data;

      // Update reward config
      await db.collection('reward_config').doc('global').set({
        dailyReward: dailyReward || 5,
        streakMultiplier: streakMultiplier || 1.2,
        weeklyBonus: weeklyBonus || 25,
        monthlyBonus: monthlyBonus || 100,
        signupBonus: signupBonus || 200,
        enabled: enabled !== undefined ? enabled : true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: context.auth.uid,
      }, { merge: true });

      // Log admin action
      await db.collection('admin_logs').add({
        action: 'SET_REWARD_CONFIG',
        admin: context.auth.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        data: {
          dailyReward,
          streakMultiplier,
          weeklyBonus,
          monthlyBonus,
          signupBonus,
          enabled,
        },
      });

      return {
        success: true,
        message: 'Reward configuration updated',
      };
    } catch (error) {
      console.error('Error setting reward config:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to update reward configuration'
      );
    }
  }
);

/**
 * Create or update event reward
 */
export const setEventReward = functions.https.onCall(
  async (data, context) => {
    // Verify admin authentication
    if (!context.auth?.token?.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Admin access required'
      );
    }

    try {
      const {
        id,
        title,
        condition,
        reward,
        description,
        maxRewardsPerDay,
        active,
      } = data;

      // Validate required fields
      if (!title || !condition || reward === undefined) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Missing required fields: title, condition, reward'
        );
      }

      const docRef = id
        ? db.collection('event_rewards').doc(id)
        : db.collection('event_rewards').doc();

      await docRef.set({
        title,
        condition,
        reward,
        description: description || '',
        maxRewardsPerDay: maxRewardsPerDay || null,
        active: active !== undefined ? active : true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: context.auth.uid,
      }, { merge: true });

      // Log admin action
      await db.collection('admin_logs').add({
        action: 'SET_EVENT_REWARD',
        admin: context.auth.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        data: {
          rewardId: docRef.id,
          title,
          condition,
          reward,
        },
      });

      return {
        success: true,
        message: 'Event reward updated',
        rewardId: docRef.id,
      };
    } catch (error) {
      console.error('Error setting event reward:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to update event reward'
      );
    }
  }
);

/**
 * Create or update loyalty campaign
 */
export const setLoyaltyCampaign = functions.https.onCall(
  async (data, context) => {
    // Verify admin authentication
    if (!context.auth?.token?.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Admin access required'
      );
    }

    try {
      const {
        id,
        name,
        campaignDate,
        endDate,
        multiplier,
        description,
        active,
      } = data;

      // Validate required fields
      if (!name || !campaignDate || multiplier === undefined) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Missing required fields: name, campaignDate, multiplier'
        );
      }

      const docRef = id
        ? db.collection('loyalty_campaigns').doc(id)
        : db.collection('loyalty_campaigns').doc();

      await docRef.set({
        name,
        campaignDate: new Date(campaignDate),
        endDate: endDate ? new Date(endDate) : null,
        multiplier,
        description: description || '',
        active: active !== undefined ? active : true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: context.auth.uid,
      }, { merge: true });

      // Log admin action
      await db.collection('admin_logs').add({
        action: 'SET_LOYALTY_CAMPAIGN',
        admin: context.auth.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        data: {
          campaignId: docRef.id,
          name,
          multiplier,
        },
      });

      return {
        success: true,
        message: 'Campaign updated',
        campaignId: docRef.id,
      };
    } catch (error) {
      console.error('Error setting loyalty campaign:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to update campaign'
      );
    }
  }
);

/**
 * Get all admin logs
 */
export const getAdminLogs = functions.https.onCall(
  async (data, context) => {
    // Verify admin authentication
    if (!context.auth?.token?.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Admin access required'
      );
    }

    try {
      const { limit = 100, startAfter } = data;

      let query = db.collection('admin_logs')
        .orderBy('timestamp', 'desc')
        .limit(limit);

      if (startAfter) {
        query = query.startAfter(startAfter);
      }

      const snapshot = await query.get();
      const logs = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));

      return {
        success: true,
        logs,
        count: logs.length,
      };
    } catch (error) {
      console.error('Error getting admin logs:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to fetch admin logs'
      );
    }
  }
);
