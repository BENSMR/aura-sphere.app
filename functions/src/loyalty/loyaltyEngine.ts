import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Loyalty Engine - Core business logic for loyalty system
 * Handles daily login bonuses, milestone checking, and token crediting
 */

export interface LoyaltyConfig {
  daily: {
    baseReward: number;
    streakBonus: number;
    maxStreakBonus: number;
  };
  weekly: {
    thresholdDays: number;
    bonus: number;
  };
  milestones: {
    id: string;
    name: string;
    threshold: number;
    reward: number;
  }[];
  specialDays?: {
    dateISO: string;
    bonusMultiplier: number;
    name: string;
  }[];
}

interface StreakData {
  current: number;
  lastLogin: Date;
  frozenUntil?: Date | null;
}

interface LoyaltyData {
  streak?: StreakData;
  totals?: {
    lifetimeEarned: number;
    lifetimeSpent: number;
  };
  milestones?: {
    [key: string]: boolean;
  };
  lastBonus?: Date;
}

const GLOBAL_CONFIG_PATH = 'loyalty_config/global';

/**
 * Get current loyalty configuration
 * Returns default config if not found in Firestore
 */
export async function getConfig(): Promise<LoyaltyConfig> {
  try {
    const snap = await db.doc(GLOBAL_CONFIG_PATH).get();
    if (!snap.exists) {
      console.log('Using default loyalty config');
      return getDefaultConfig();
    }
    return snap.data() as LoyaltyConfig;
  } catch (error) {
    console.error('Error fetching loyalty config:', error);
    return getDefaultConfig();
  }
}

/**
 * Get default loyalty configuration
 */
function getDefaultConfig(): LoyaltyConfig {
  return {
    daily: {
      baseReward: 50,
      streakBonus: 10,
      maxStreakBonus: 500,
    },
    weekly: {
      thresholdDays: 7,
      bonus: 500,
    },
    milestones: [
      { id: 'bronze', name: 'Bronze Member', threshold: 1000, reward: 100 },
      { id: 'silver', name: 'Silver Member', threshold: 5000, reward: 500 },
      { id: 'gold', name: 'Gold Member', threshold: 10000, reward: 1000 },
      { id: 'platinum', name: 'Platinum Member', threshold: 25000, reward: 2500 },
      { id: 'diamond', name: 'Diamond Member', threshold: 50000, reward: 5000 },
    ],
    specialDays: [
      { dateISO: '12-25', bonusMultiplier: 2.0, name: 'Christmas' },
      { dateISO: '01-01', bonusMultiplier: 1.5, name: 'New Year' },
      { dateISO: '07-04', bonusMultiplier: 1.5, name: 'Independence Day' },
    ],
  };
}

/**
 * Credit tokens to user wallet and create audit log
 * Uses transaction to ensure atomic updates
 */
export async function creditTokens(
  uid: string,
  amount: number,
  reason: string,
  meta: any = {}
): Promise<{ success: boolean; newBalance?: number }> {
  try {
    const userRef = db.doc(`users/${uid}`);

    return await db.runTransaction(async (tx) => {
      // Get current wallet balance
      const walletDocRef = userRef.collection('wallet').doc('profile');
      const walletSnap = await tx.get(walletDocRef);
      let currentBalance = 0;

      if (walletSnap.exists) {
        currentBalance = walletSnap.data()?.auraTokens || 0;
      }

      const newBalance = currentBalance + amount;

      // Update wallet balance
      tx.set(
        walletDocRef,
        {
          auraTokens: newBalance,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // Create audit entry
      const auditRef = userRef.collection('token_audit').doc();
      tx.set(auditRef, {
        action: 'loyalty_credit',
        amount,
        reason,
        meta: {
          ...meta,
          previousBalance: currentBalance,
          newBalance,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update loyalty totals if applicable
      const loyaltyRef = userRef.collection('loyalty').doc('profile');
      const loyaltySnap = await tx.get(loyaltyRef);

      if (loyaltySnap.exists) {
        const loyalty = loyaltySnap.data() as LoyaltyData;
        const currentEarned = loyalty.totals?.lifetimeEarned || 0;

        tx.update(loyaltyRef, {
          'totals.lifetimeEarned': currentEarned + amount,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return { success: true, newBalance };
    });
  } catch (error) {
    console.error('Error crediting tokens:', error);
    return { success: false };
  }
}

/**
 * Helper: Check if two dates are the same day
 */
function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

/**
 * Handle daily login bonus
 * Returns streak count and tokens awarded
 */
export async function handleDailyLogin(uid: string): Promise<{
  streak: number;
  awarded: number;
  message: string;
}> {
  try {
    const cfg = await getConfig();
    const userRef = db.doc(`users/${uid}`);
    const loyaltyRef = userRef.collection('loyalty').doc('profile');

    return await db.runTransaction(async (tx) => {
      const lSnap = await tx.get(loyaltyRef);
      const now = admin.firestore.Timestamp.now();
      const nowDate = new Date(now.toMillis());

      let streak = 0;
      let lastLogin: Date | null = null;
      let frozenUntil: Date | null = null;

      if (lSnap.exists) {
        const data = lSnap.data() as LoyaltyData;
        if (data.streak) {
          streak = data.streak.current || 0;
          lastLogin = data.streak.lastLogin
            ? new Date(data.streak.lastLogin)
            : null;
          frozenUntil = data.streak.frozenUntil
            ? new Date(data.streak.frozenUntil)
            : null;
        }
      }

      // Check if bonus already claimed today
      const lastBonusDoc = lSnap.exists ? lSnap.data()?.lastBonus : null;
      if (lastBonusDoc) {
        const lastBonusDate = new Date(lastBonusDoc);
        if (isSameDay(lastBonusDate, nowDate)) {
          return {
            streak,
            awarded: 0,
            message: 'Already claimed daily bonus today',
          };
        }
      }

      // Check if streak is frozen
      if (frozenUntil && frozenUntil > nowDate) {
        return {
          streak: 0,
          awarded: 0,
          message: `Streak frozen until ${frozenUntil.toISOString()}`,
        };
      }

      // Compute streak continuation
      const yesterday = new Date(nowDate);
      yesterday.setDate(yesterday.getDate() - 1);

      let newStreak = streak;
      let increment = false;

      if (!lastLogin || !isSameDay(lastLogin, nowDate)) {
        if (lastLogin && isSameDay(lastLogin, yesterday)) {
          newStreak += 1;
        } else {
          newStreak = 1;
        }
        increment = true;
      }

      let awarded = 0;
      if (increment) {
        // Calculate daily bonus: base + streak bonus (capped)
        const streakBonus = Math.min(
          cfg.daily.streakBonus * (newStreak - 1),
          cfg.daily.maxStreakBonus
        );
        awarded = cfg.daily.baseReward + streakBonus;

        // Check for special day multiplier
        const dateISO = `${String(nowDate.getMonth() + 1).padStart(2, '0')}-${String(
          nowDate.getDate()
        ).padStart(2, '0')}`;
        const specialDay = cfg.specialDays?.find((sd) => sd.dateISO === dateISO);

        if (specialDay) {
          awarded = Math.floor(awarded * specialDay.bonusMultiplier);
        }

        // Credit tokens (this will also update wallet and create audit log)
        // Note: We need to use a nested transaction here, so we'll do it after this one
        // For now, just return the values and handle credit outside
      }

      // Update streak in loyalty profile
      if (increment) {
        tx.set(
          loyaltyRef,
          {
            streak: {
              current: newStreak,
              lastLogin: nowDate,
              frozenUntil: null,
            },
            lastBonus: nowDate,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }

      return {
        streak: newStreak,
        awarded,
        message: increment ? `Earned ${awarded} tokens! Streak: ${newStreak}` : 'Already claimed today',
      };
    });
  } catch (error) {
    console.error('Error handling daily login:', error);
    throw error;
  }
}

/**
 * Check and award milestones based on lifetime spent
 * Returns array of newly awarded milestone IDs
 */
export async function checkAndAwardMilestones(uid: string): Promise<{
  awarded: string[];
  message: string;
}> {
  try {
    const cfg = await getConfig();
    const userRef = db.doc(`users/${uid}`);
    const loyaltyRef = userRef.collection('loyalty').doc('profile');

    return await db.runTransaction(async (tx) => {
      const lSnap = await tx.get(loyaltyRef);
      const lifetimeSpent = lSnap.exists
        ? lSnap.data()?.totals?.lifetimeSpent || 0
        : 0;

      const currentMilestones = lSnap.exists ? lSnap.data()?.milestones || {} : {};
      const awarded: string[] = [];

      for (const milestone of cfg.milestones) {
        if (lifetimeSpent >= milestone.threshold && !currentMilestones[milestone.id]) {
          awarded.push(milestone.id);
          currentMilestones[milestone.id] = true;
        }
      }

      if (awarded.length > 0) {
        tx.set(
          loyaltyRef,
          {
            milestones: currentMilestones,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        // Create audit entries for each milestone
        for (const msId of awarded) {
          const ms = cfg.milestones.find((m) => m.id === msId);
          if (ms) {
            const auditRef = userRef.collection('token_audit').doc();
            tx.set(auditRef, {
              action: 'milestone_achieved',
              amount: 0,
              reason: `Milestone: ${ms.name}`,
              meta: { milestone: msId, threshold: ms.threshold },
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }
      }

      return {
        awarded,
        message: awarded.length > 0
          ? `Milestones unlocked: ${awarded.join(', ')}`
          : 'No new milestones',
      };
    });
  } catch (error) {
    console.error('Error checking milestones:', error);
    throw error;
  }
}

/**
 * Get user's current loyalty status
 */
export async function getUserLoyaltyStatus(uid: string): Promise<LoyaltyData | null> {
  try {
    const loyaltyRef = db.doc(`users/${uid}/loyalty/profile`);
    const snap = await loyaltyRef.get();
    return snap.exists ? (snap.data() as LoyaltyData) : null;
  } catch (error) {
    console.error('Error getting loyalty status:', error);
    return null;
  }
}

/**
 * Freeze user streak (e.g., for missed login after N days)
 */
export async function freezeStreak(
  uid: string,
  durationDays: number = 3
): Promise<{ success: boolean }> {
  try {
    const userRef = db.doc(`users/${uid}`);
    const loyaltyRef = userRef.collection('loyalty').doc('profile');
    const now = new Date();
    const frozenUntil = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);

    await loyaltyRef.update({
      'streak.current': 0,
      'streak.frozenUntil': frozenUntil,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Audit log
    const auditRef = userRef.collection('token_audit').doc();
    await auditRef.set({
      action: 'streak_frozen',
      amount: 0,
      reason: 'Streak freeze',
      meta: {
        durationDays,
        frozenUntil: frozenUntil.toISOString(),
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    console.error('Error freezing streak:', error);
    return { success: false };
  }
}

/**
 * Process weekly bonus (optional - can be called from scheduled function)
 */
export async function processWeeklyBonus(uid: string): Promise<{
  awarded: number;
  message: string;
}> {
  try {
    const cfg = await getConfig();
    const userRef = db.doc(`users/${uid}`);
    const loyaltyRef = userRef.collection('loyalty').doc('profile');

    const loyaltySnap = await loyaltyRef.get();
    if (!loyaltySnap.exists) {
      return { awarded: 0, message: 'Loyalty profile not found' };
    }

    const loyalty = loyaltySnap.data() as LoyaltyData;
    const streak = loyalty.streak?.current || 0;

    // Award weekly bonus if streak >= threshold
    if (streak >= cfg.weekly.thresholdDays) {
      await creditTokens(uid, cfg.weekly.bonus, 'weekly_bonus', { streak });
      return {
        awarded: cfg.weekly.bonus,
        message: `Weekly bonus awarded: ${cfg.weekly.bonus} tokens`,
      };
    }

    return { awarded: 0, message: 'Streak too low for weekly bonus' };
  } catch (error) {
    console.error('Error processing weekly bonus:', error);
    throw error;
  }
}

export default {
  getConfig,
  creditTokens,
  handleDailyLogin,
  checkAndAwardMilestones,
  getUserLoyaltyStatus,
  freezeStreak,
  processWeeklyBonus,
};
