/**
 * LOYALTY PROGRAM CORE MODULE
 * 
 * Multi-tier loyalty system with points accumulation, tier progression,
 * and automated rewards. Integrates with Firestore for persistence.
 * 
 * Tiers: Bronze → Silver → Gold → Platinum
 * Features: Points, Discounts, Milestone Rewards, Referrals, Tier Benefits
 */

// ─────────────────────────────────────────────────────────────────────────
// TIER DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────

export const LOYALTY_TIERS = {
  BRONZE: {
    id: 'bronze',
    name: 'Bronze',
    minPoints: 0,
    maxPoints: 499,
    baseDiscount: 0,
    pointsMultiplier: 1,
    benefits: [
      'Join loyalty program',
      'Earn 1 point per dollar spent',
      'Birthday bonus: 25 points'
    ],
    icon: '🥉',
    color: '#CD7F32',
    nextTier: 'silver',
    pointsToNextTier: 500
  },
  SILVER: {
    id: 'silver',
    name: 'Silver',
    minPoints: 500,
    maxPoints: 1499,
    baseDiscount: 5,
    pointsMultiplier: 1.25,
    benefits: [
      '5% discount on all purchases',
      'Earn 1.25 points per dollar spent',
      'Birthday bonus: 50 points',
      'Free shipping on orders $50+'
    ],
    icon: '🥈',
    color: '#C0C0C0',
    nextTier: 'gold',
    pointsToNextTier: 1500
  },
  GOLD: {
    id: 'gold',
    name: 'Gold',
    minPoints: 1500,
    maxPoints: 4999,
    baseDiscount: 10,
    pointsMultiplier: 1.5,
    benefits: [
      '10% discount on all purchases',
      'Earn 1.5 points per dollar spent',
      'Birthday bonus: 100 points',
      'Free shipping on all orders',
      'Priority customer support',
      'Early access to sales'
    ],
    icon: '🥇',
    color: '#FFD700',
    nextTier: 'platinum',
    pointsToNextTier: 5000
  },
  PLATINUM: {
    id: 'platinum',
    name: 'Platinum',
    minPoints: 5000,
    maxPoints: null,
    baseDiscount: 15,
    pointsMultiplier: 2,
    benefits: [
      '15% discount on all purchases',
      'Earn 2 points per dollar spent',
      'Birthday bonus: 250 points',
      'Free shipping on all orders',
      'VIP customer support (24/7)',
      'Early access to sales & new products',
      'Exclusive events & offers',
      'Personal account manager',
      'Free premium gifts quarterly'
    ],
    icon: '💎',
    color: '#E5E4E2',
    nextTier: null,
    pointsToNextTier: null
  }
};

// ─────────────────────────────────────────────────────────────────────────
// REWARD TYPES & REDEMPTION RULES
// ─────────────────────────────────────────────────────────────────────────

export const REWARD_TYPES = {
  POINTS_REDEMPTION: 'points_redemption',      // 100 points = $5 off
  TIER_MILESTONE: 'tier_milestone',            // Unlock new tier
  BIRTHDAY_BONUS: 'birthday_bonus',            // Annual birthday reward
  REFERRAL_BONUS: 'referral_bonus',            // Friend referral reward
  ANNIVERSARY_BONUS: 'anniversary_bonus',      // Account anniversary
  SEASONAL_BONUS: 'seasonal_bonus',            // Holiday promotions
  PURCHASE_MILESTONE: 'purchase_milestone'     // Total spend milestones
};

export const REDEMPTION_RATES = {
  POINTS_TO_DOLLAR: 100,  // 100 points = $1 off
  MINIMUM_REDEMPTION: 500, // Minimum 500 points ($5)
  MAXIMUM_MONTHLY: 3000,   // Max $30 per month
  REFERRAL_BONUS: 100,     // Points awarded per referral
  BIRTHDAY_BONUS_BASE: 25  // Base birthday bonus
};

// ─────────────────────────────────────────────────────────────────────────
// MILESTONE DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────

export const PURCHASE_MILESTONES = [
  { totalSpent: 100, reward: 50, label: '$100 lifetime' },
  { totalSpent: 250, reward: 100, label: '$250 lifetime' },
  { totalSpent: 500, reward: 150, label: '$500 lifetime' },
  { totalSpent: 1000, reward: 250, label: '$1000 lifetime' },
  { totalSpent: 2500, reward: 500, label: '$2500 lifetime' },
  { totalSpent: 5000, reward: 1000, label: '$5000 lifetime' }
];

// ─────────────────────────────────────────────────────────────────────────
// CORE LOYALTY FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Calculate points for a transaction
 * @param {number} amount - Purchase amount in dollars
 * @param {string} tier - Current loyalty tier
 * @param {object} options - Additional options
 * @returns {number} Points earned
 */
export const calculatePointsEarned = (amount, tier = 'bronze', options = {}) => {
  if (!amount || amount <= 0) return 0;
  
  const tierInfo = LOYALTY_TIERS[tier.toUpperCase()] || LOYALTY_TIERS.BRONZE;
  let points = Math.floor(amount * tierInfo.pointsMultiplier);
  
  // Bonus multiplier for specific conditions
  if (options.isFirstPurchase) points *= 2;           // 2x for first purchase
  if (options.isDuringPromotion) points *= 1.5;       // 1.5x during promotions
  if (options.referralBonus) points += 50;            // +50 for referrals
  
  return points;
};

/**
 * Determine loyalty tier based on current points
 * @param {number} points - Current loyalty points
 * @returns {object} Tier information
 */
export const getTierFromPoints = (points) => {
  if (points >= 5000) return LOYALTY_TIERS.PLATINUM;
  if (points >= 1500) return LOYALTY_TIERS.GOLD;
  if (points >= 500) return LOYALTY_TIERS.SILVER;
  return LOYALTY_TIERS.BRONZE;
};

/**
 * Get tier progression info
 * @param {number} points - Current loyalty points
 * @returns {object} Tier info, progress percentage, points needed for next tier
 */
export const getTierProgress = (points) => {
  const currentTier = getTierFromPoints(points);
  const nextTier = currentTier.nextTier ? LOYALTY_TIERS[currentTier.nextTier.toUpperCase()] : null;
  
  if (!nextTier) {
    return {
      currentTier,
      nextTier: null,
      progress: 100,
      pointsInTier: points - currentTier.minPoints,
      pointsNeededForNext: 0,
      isMaxTier: true
    };
  }
  
  const tierRange = nextTier.minPoints - currentTier.minPoints;
  const pointsInTier = points - currentTier.minPoints;
  const progress = Math.floor((pointsInTier / tierRange) * 100);
  
  return {
    currentTier,
    nextTier,
    progress: Math.min(progress, 99),
    pointsInTier,
    pointsNeededForNext: nextTier.minPoints - points,
    isMaxTier: false
  };
};

/**
 * Apply loyalty discount to amount
 * @param {number} amount - Original amount
 * @param {string} tier - Loyalty tier
 * @returns {object} Original amount, discount amount, final amount
 */
export const applyLoyaltyDiscount = (amount, tier = 'bronze') => {
  if (!amount || amount <= 0) {
    return { original: 0, discountPercent: 0, discountAmount: 0, final: 0 };
  }
  
  const tierInfo = LOYALTY_TIERS[tier.toUpperCase()] || LOYALTY_TIERS.BRONZE;
  const discountPercent = tierInfo.baseDiscount;
  const discountAmount = (amount * discountPercent) / 100;
  
  return {
    original: amount,
    discountPercent,
    discountAmount: Math.round(discountAmount * 100) / 100,
    final: Math.round((amount - discountAmount) * 100) / 100
  };
};

/**
 * Calculate points redeemable for discount
 * @param {number} pointsAvailable - Current points balance
 * @returns {object} Redeemable points, dollar value, remaining points
 */
export const calculateRedeemablePoints = (pointsAvailable) => {
  const maxRedeemablePoints = REDEMPTION_RATES.MAXIMUM_MONTHLY * REDEMPTION_RATES.POINTS_TO_DOLLAR;
  const redeemablePoints = Math.min(pointsAvailable, maxRedeemablePoints);
  
  // Must be minimum multiple
  const roundedPoints = Math.floor(redeemablePoints / REDEMPTION_RATES.POINTS_TO_DOLLAR) * REDEMPTION_RATES.POINTS_TO_DOLLAR;
  
  if (roundedPoints < REDEMPTION_RATES.MINIMUM_REDEMPTION) {
    return {
      canRedeem: false,
      redeemablePoints: 0,
      dollarValue: 0,
      remaining: pointsAvailable,
      reason: `Need at least ${REDEMPTION_RATES.MINIMUM_REDEMPTION} points (${REDEMPTION_RATES.MINIMUM_REDEMPTION / REDEMPTION_RATES.POINTS_TO_DOLLAR} dollars)`
    };
  }
  
  return {
    canRedeem: true,
    redeemablePoints: roundedPoints,
    dollarValue: roundedPoints / REDEMPTION_RATES.POINTS_TO_DOLLAR,
    remaining: pointsAvailable - roundedPoints,
    reason: null
  };
};

/**
 * Check if client qualifies for milestone reward
 * @param {number} totalSpent - Lifetime total spent
 * @param {array} claimedMilestones - Previously claimed milestone IDs
 * @returns {object} Qualifying milestone or null, reward points
 */
export const checkMilestoneReward = (totalSpent, claimedMilestones = []) => {
  const qualifying = PURCHASE_MILESTONES.find(m => 
    totalSpent >= m.totalSpent && !claimedMilestones.includes(m.label)
  );
  
  return qualifying ? { 
    milestone: qualifying, 
    rewardPoints: qualifying.reward,
    isClaimed: false 
  } : { 
    milestone: null, 
    rewardPoints: 0,
    isClaimed: false 
  };
};

/**
 * Calculate referral reward
 * @param {number} successfulReferrals - Number of successful referrals
 * @returns {number} Total referral bonus points
 */
export const calculateReferralBonus = (successfulReferrals = 0) => {
  return successfulReferrals * REDEMPTION_RATES.REFERRAL_BONUS;
};

/**
 * Calculate birthday bonus
 * @param {string} tier - Loyalty tier
 * @returns {number} Birthday bonus points
 */
export const calculateBirthdayBonus = (tier = 'bronze') => {
  const tierInfo = LOYALTY_TIERS[tier.toUpperCase()] || LOYALTY_TIERS.BRONZE;
  const bonus = REDEMPTION_RATES.BIRTHDAY_BONUS_BASE * tierInfo.pointsMultiplier;
  return Math.floor(bonus);
};

/**
 * Build loyalty profile object from Firestore document
 * @param {object} clientDoc - Firestore client document
 * @returns {object} Complete loyalty profile with tier, points, rewards
 */
export const buildLoyaltyProfile = (clientDoc = {}) => {
  const {
    loyaltyPoints = 0,
    totalSpent = 0,
    totalPurchases = 0,
    lastPurchaseDate = null,
    joinedDate = new Date().toISOString(),
    claimedMilestones = [],
    referrals = [],
    lastBirthdayBonus = null,
    preferredRedemption = 'discount'
  } = clientDoc;
  
  const tierProgress = getTierProgress(loyaltyPoints);
  const milestoneStatus = checkMilestoneReward(totalSpent, claimedMilestones);
  const redeemableInfo = calculateRedeemablePoints(loyaltyPoints);
  const referralBonus = calculateReferralBonus(referrals.length);
  
  return {
    tier: tierProgress.currentTier,
    points: loyaltyPoints,
    tierProgress,
    redeemable: redeemableInfo,
    totalSpent,
    totalPurchases,
    averageOrderValue: totalPurchases > 0 ? (totalSpent / totalPurchases).toFixed(2) : 0,
    lastPurchaseDate,
    daysSinceLastPurchase: lastPurchaseDate ? 
      Math.floor((Date.now() - new Date(lastPurchaseDate).getTime()) / (1000 * 60 * 60 * 24)) : null,
    joinedDate,
    memberDays: Math.floor((Date.now() - new Date(joinedDate).getTime()) / (1000 * 60 * 60 * 24)),
    milestone: milestoneStatus,
    referrals,
    referralBonus,
    preferredRedemption,
    stats: {
      discountsSaved: ((totalSpent * tierProgress.currentTier.baseDiscount) / 100).toFixed(2),
      nextRewardAt: tierProgress.nextTier ? 
        `${tierProgress.nextTier.minPoints} points (${tierProgress.pointsNeededForNext} more)` : 
        'Platinum tier unlocked'
    }
  };
};

// ─────────────────────────────────────────────────────────────────────────
// TRANSACTION RECORDING
// ─────────────────────────────────────────────────────────────────────────

/**
 * Record loyalty transaction (purchase, redemption, etc.)
 * @param {string} userId - Firestore user ID
 * @param {string} type - Transaction type (purchase, redemption, reward)
 * @param {object} data - Transaction details
 * @returns {object} Transaction record
 */
export const createLoyaltyTransaction = (userId, type, data = {}) => {
  return {
    userId,
    type,
    timestamp: new Date().toISOString(),
    amount: data.amount || 0,
    pointsChange: data.pointsChange || 0,
    description: data.description || '',
    reference: data.reference || '', // Order ID, etc
    tier: data.tier || 'bronze',
    metadata: data.metadata || {}
  };
};

/**
 * Format loyalty profile for display
 * @param {object} profile - Loyalty profile object
 * @returns {string} Formatted display string
 */
export const formatLoyaltyStatus = (profile) => {
  const tier = profile.tier;
  const progress = profile.tierProgress;
  
  let status = `${tier.icon} ${tier.name} Member\n`;
  status += `${profile.points} points | ${profile.totalPurchases} purchases\n`;
  status += `Saved: $${profile.stats.discountsSaved} in discounts\n`;
  
  if (!progress.isMaxTier) {
    status += `→ ${progress.pointsNeededForNext} points to ${progress.nextTier.name}`;
  } else {
    status += `✨ Maximum tier reached!`;
  }
  
  return status;
};

/**
 * Export loyalty data for analytics
 * @param {array} profiles - Array of loyalty profiles
 * @returns {object} Aggregated statistics
 */
export const aggregateLoyaltyStats = (profiles = []) => {
  const stats = {
    totalMembers: profiles.length,
    byTier: {
      bronze: 0,
      silver: 0,
      gold: 0,
      platinum: 0
    },
    totalPointsIssued: 0,
    totalPointsRedeemed: 0,
    averagePointsPerMember: 0,
    averageTierDiscount: 0,
    totalSavedInDiscounts: 0,
    averagePurchasesPerMember: 0
  };
  
  profiles.forEach(profile => {
    const tierKey = profile.tier.id;
    stats.byTier[tierKey]++;
    stats.totalPointsIssued += profile.points;
    stats.averagePurchasesPerMember += profile.totalPurchases;
    stats.totalSavedInDiscounts += parseFloat(profile.stats.discountsSaved);
  });
  
  if (profiles.length > 0) {
    stats.averagePointsPerMember = Math.floor(stats.totalPointsIssued / profiles.length);
    stats.averagePurchasesPerMember = Math.floor(stats.averagePurchasesPerMember / profiles.length);
    stats.averageTierDiscount = (
      (stats.byTier.silver * 5 + 
       stats.byTier.gold * 10 + 
       stats.byTier.platinum * 15) / profiles.length
    ).toFixed(1);
  }
  
  return stats;
};
