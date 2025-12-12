import admin from 'firebase-admin';

/**
 * Loyalty System Firestore Initialization
 * 
 * This module provides functions to initialize and manage the loyalty system
 * in Firestore. Call initializeLoyaltySystem() on first app setup.
 */

const db = admin.firestore();

/**
 * Initialize global loyalty configuration
 * Call this once during system setup
 */
export async function initializeLoyaltyConfig(): Promise<void> {
  const configRef = db.collection('loyalty_config').doc('global');

  const config = {
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
      {
        id: 'bronze',
        name: 'Bronze Member',
        tokensThreshold: 1000,
        reward: 100,
      },
      {
        id: 'silver',
        name: 'Silver Member',
        tokensThreshold: 5000,
        reward: 500,
      },
      {
        id: 'gold',
        name: 'Gold Member',
        tokensThreshold: 10000,
        reward: 1000,
      },
      {
        id: 'platinum',
        name: 'Platinum Member',
        tokensThreshold: 25000,
        reward: 2500,
      },
      {
        id: 'diamond',
        name: 'Diamond Member',
        tokensThreshold: 50000,
        reward: 5000,
      },
    ],
    specialDays: [
      {
        dateISO: '12-25',
        bonusMultiplier: 2.0,
        name: 'Christmas',
      },
      {
        dateISO: '01-01',
        bonusMultiplier: 1.5,
        name: 'New Year',
      },
      {
        dateISO: '07-04',
        bonusMultiplier: 1.5,
        name: 'Independence Day',
      },
    ],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await configRef.set(config);
  console.log('✅ Loyalty configuration initialized');
}

/**
 * Initialize loyalty profile for a new user
 * Call this during user signup
 */
export async function initializeUserLoyaltyProfile(uid: string): Promise<void> {
  const loyaltyRef = db.collection('users').doc(uid).collection('loyalty').doc('profile');

  const profile = {
    streak: {
      current: 0,
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      frozenUntil: null,
    },
    totals: {
      lifetimeEarned: 0,
      lifetimeSpent: 0,
    },
    badges: [],
    milestones: {
      bronze: false,
      silver: false,
      gold: false,
      platinum: false,
      diamond: false,
    },
    lastBonus: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await loyaltyRef.set(profile);
  console.log(`✅ Loyalty profile initialized for user ${uid}`);
}

/**
 * Award daily bonus to user
 * Call this when user logs in (after checking 24h cooldown)
 */
export async function awardDailyBonus(
  uid: string,
  config?: any
): Promise<number> {
  const loyaltyRef = db.collection('users').doc(uid).collection('loyalty').doc('profile');
  const loyaltyDoc = await loyaltyRef.get();
  const loyalty = loyaltyDoc.data();

  if (!loyalty) {
    throw new Error(`Loyalty profile not found for user ${uid}`);
  }

  // Check if bonus already claimed today
  if (loyalty.lastBonus) {
    const lastBonusDate = new Date(loyalty.lastBonus.toDate());
    const todayDate = new Date();
    if (
      lastBonusDate.getFullYear() === todayDate.getFullYear() &&
      lastBonusDate.getMonth() === todayDate.getMonth() &&
      lastBonusDate.getDate() === todayDate.getDate()
    ) {
      return 0; // Already claimed today
    }
  }

  // Get config if not provided
  if (!config) {
    const configDoc = await db.collection('loyalty_config').doc('global').get();
    config = configDoc.data();
  }

  // Calculate reward
  let reward = config.daily.baseReward;

  // Add streak bonus (capped at maxStreakBonus)
  const newStreak = loyalty.streak.current + 1;
  const streakBonus = Math.min(newStreak * config.daily.streakBonus, config.daily.maxStreakBonus);
  reward += streakBonus;

  // Check for special day multiplier
  const today = new Date();
  const dateISO = `${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
  const specialDay = config.specialDays.find((sd: any) => sd.dateISO === dateISO);

  if (specialDay) {
    reward = Math.floor(reward * specialDay.bonusMultiplier);
  }

  // Update loyalty profile
  const now = admin.firestore.FieldValue.serverTimestamp();
  await loyaltyRef.update({
    'streak.current': newStreak,
    'streak.lastLogin': now,
    'totals.lifetimeEarned': loyalty.totals.lifetimeEarned + reward,
    lastBonus: now,
    updatedAt: now,
  });

  // Log transaction
  await logTokenAudit(uid, 'daily_bonus', reward, null, {
    streak: newStreak,
    specialDay: specialDay?.name || null,
  });

  console.log(`✅ Daily bonus awarded: ${reward} tokens to ${uid}`);
  return reward;
}

/**
 * Record payment and update loyalty totals
 * Call this when payment is processed
 */
export async function recordPaymentTransaction(
  uid: string,
  sessionId: string,
  packId: string,
  tokens: number
): Promise<void> {
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Record payment
  const paymentRef = db.collection('payments_processed').doc(sessionId);
  await paymentRef.set({
    uid,
    packId,
    tokens,
    processedAt: now,
  });

  // Update loyalty totals
  const loyaltyRef = db.collection('users').doc(uid).collection('loyalty').doc('profile');
  await loyaltyRef.update({
    'totals.lifetimeSpent': admin.firestore.FieldValue.increment(tokens),
    updatedAt: now,
  });

  // Log transaction
  await logTokenAudit(uid, 'purchase', tokens, sessionId, {
    packId,
  });

  console.log(`✅ Payment recorded: ${tokens} tokens for user ${uid}`);
}

/**
 * Award badge to user
 */
export async function awardBadge(
  uid: string,
  badgeId: string,
  name: string,
  level: number = 1
): Promise<void> {
  const loyaltyRef = db.collection('users').doc(uid).collection('loyalty').doc('profile');
  const now = admin.firestore.FieldValue.serverTimestamp();

  const badge = {
    id: badgeId,
    name,
    level,
    earnedAt: now,
  };

  await loyaltyRef.update({
    badges: admin.firestore.FieldValue.arrayUnion([badge]),
    updatedAt: now,
  });

  // Log transaction
  await logTokenAudit(uid, 'badge_awarded', 0, null, {
    badgeId,
    badgeName: name,
  });

  console.log(`✅ Badge awarded to ${uid}: ${name}`);
}

/**
 * Check and award milestone
 */
export async function checkAndAwardMilestone(
  uid: string,
  milestoneKey: string
): Promise<boolean> {
  const loyaltyRef = db.collection('users').doc(uid).collection('loyalty').doc('profile');
  const loyaltyDoc = await loyaltyRef.get();
  const loyalty = loyaltyDoc.data();

  if (!loyalty) {
    return false;
  }

  // Check if already earned
  if (loyalty.milestones[milestoneKey]) {
    return false;
  }

  const now = admin.firestore.FieldValue.serverTimestamp();

  // Update milestone
  await loyaltyRef.update({
    [`milestones.${milestoneKey}`]: true,
    updatedAt: now,
  });

  // Log transaction
  await logTokenAudit(uid, 'milestone_achieved', 0, null, {
    milestone: milestoneKey,
  });

  console.log(`✅ Milestone awarded to ${uid}: ${milestoneKey}`);
  return true;
}

/**
 * Log token transaction to audit trail
 * Internal use only
 */
async function logTokenAudit(
  uid: string,
  action: string,
  amount: number,
  sessionId: string | null,
  metadata: any
): Promise<void> {
  const auditRef = db.collection('users').doc(uid).collection('token_audit').doc();

  await auditRef.set({
    action,
    amount,
    sessionId: sessionId || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    metadata: metadata || {},
  });
}

/**
 * Get user loyalty profile
 */
export async function getUserLoyalty(uid: string): Promise<any> {
  const doc = await db.collection('users').doc(uid).collection('loyalty').doc('profile').get();
  return doc.exists ? doc.data() : null;
}

/**
 * Get loyalty config
 */
export async function getLoyaltyConfig(): Promise<any> {
  const doc = await db.collection('loyalty_config').doc('global').get();
  return doc.exists ? doc.data() : null;
}

/**
 * Freeze user streak (when they miss login)
 */
export async function freezeUserStreak(uid: string, durationDays: number = 3): Promise<void> {
  const loyaltyRef = db.collection('users').doc(uid).collection('loyalty').doc('profile');
  const now = new Date();
  const frozenUntil = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);

  const now_ts = admin.firestore.FieldValue.serverTimestamp();
  await loyaltyRef.update({
    'streak.current': 0,
    'streak.frozenUntil': frozenUntil,
    updatedAt: now_ts,
  });

  // Log transaction
  await logTokenAudit(uid, 'streak_frozen', 0, null, {
    frozenUntil: frozenUntil.toISOString(),
    durationDays,
  });

  console.log(`✅ Streak frozen for ${uid} until ${frozenUntil.toISOString()}`);
}

/**
 * Get token audit logs for user
 */
export async function getUserAuditLogs(uid: string, limit: number = 50): Promise<any[]> {
  const snapshot = await db
    .collection('users')
    .doc(uid)
    .collection('token_audit')
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => ({
    txId: doc.id,
    ...doc.data(),
  }));
}

/**
 * Cleanup old audit logs (monthly maintenance)
 * Keeps logs for 90 days
 */
export async function cleanupOldAuditLogs(retentionDays: number = 90): Promise<void> {
  const ninetyDaysAgo = new Date(Date.now() - retentionDays * 24 * 60 * 60 * 1000);

  const usersSnapshot = await db.collection('users').get();
  let deletedCount = 0;

  for (const userDoc of usersSnapshot.docs) {
    const auditSnapshot = await userDoc.ref
      .collection('token_audit')
      .where('createdAt', '<', ninetyDaysAgo)
      .get();

    for (const auditDoc of auditSnapshot.docs) {
      await auditDoc.ref.delete();
      deletedCount++;
    }
  }

  console.log(`✅ Cleaned up ${deletedCount} old audit logs`);
}

export default {
  initializeLoyaltyConfig,
  initializeUserLoyaltyProfile,
  awardDailyBonus,
  recordPaymentTransaction,
  awardBadge,
  checkAndAwardMilestone,
  getUserLoyalty,
  getLoyaltyConfig,
  freezeUserStreak,
  getUserAuditLogs,
  cleanupOldAuditLogs,
};
