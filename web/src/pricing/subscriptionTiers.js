/**
 * SUBSCRIPTION TIERS & BILLING MANAGEMENT
 *
 * Complete subscription system with:
 * - 4 pricing tiers (Solo → Team → Business → Enterprise)
 * - Feature matrices & access control
 * - Usage limits & quotas
 * - Role definitions per tier
 * - Billing cycle management
 * - Upgrade/downgrade logic
 */

// ─────────────────────────────────────────────────────────────────────────
// SUBSCRIPTION TIER DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────

export const SUBSCRIPTION_TIERS = {
  solo: {
    id: 'solo',
    name: 'Solo',
    description: 'For independent professionals',
    price: 9,
    currency: 'USD',
    billingCycle: 'monthly',
    yearlyDiscount: 17, // ~17% off yearly (9*12 = 108, yearly = 99)
    yearlyPrice: 99,
    icon: '👤',
    color: '#3b82f6',
    
    // Access Control
    maxUsers: 1,
    maxTeamMembers: 0,
    roles: ['owner'],
    
    // Features
    features: {
      core: [
        'invoices',
        'expenses',
        'clients',
        'tasks',
        'mobile',
        'desktop'
      ],
      ai: [
        'ai_basic'
      ],
      loyalty: [
        'loyalty_basic'
      ]
    },
    
    // Usage Limits
    limits: {
      invoices: 50,
      expenses: 100,
      clients: 20,
      projects: 10,
      tasks: 50,
      storage: 1024, // 1 GB
      aiQueries: 50,
      teamMembers: 0,
      customRoles: false,
      apiAccess: false,
      auditLogs: false,
      supportPriority: 'standard'
    },
    
    // Billing
    trialDays: 14,
    canCancel: true,
    autoRenew: true,
    paymentMethods: ['card', 'paypal'],
    
    // Upgrade Path
    nextTier: 'team',
    recommended: false
  },

  team: {
    id: 'team',
    name: 'Team',
    description: 'For small crews (up to 5 people)',
    price: 29,
    currency: 'USD',
    billingCycle: 'monthly',
    yearlyDiscount: 20,
    yearlyPrice: 299, // 20% discount on yearly
    icon: '👥',
    color: '#8b5cf6',
    
    // Access Control
    maxUsers: 5,
    maxTeamMembers: 5,
    roles: ['owner', 'manager', 'employee'],
    
    // Features
    features: {
      core: [
        'invoices',
        'expenses',
        'clients',
        'tasks',
        'inventory',
        'projects',
        'reports',
        'mobile',
        'desktop'
      ],
      ai: [
        'ai_pro',
        'smart_suggestions'
      ],
      loyalty: [
        'loyalty_pro',
        'referral_tracking'
      ]
    },
    
    // Usage Limits
    limits: {
      invoices: 500,
      expenses: 1000,
      clients: 200,
      projects: 50,
      tasks: 500,
      storage: 10240, // 10 GB
      aiQueries: 500,
      teamMembers: 5,
      customRoles: false,
      apiAccess: false,
      auditLogs: false,
      supportPriority: 'priority'
    },
    
    // Billing
    trialDays: 14,
    canCancel: true,
    autoRenew: true,
    paymentMethods: ['card', 'paypal', 'bank_transfer'],
    
    // Upgrade Path
    nextTier: 'business',
    recommended: true
  },

  business: {
    id: 'business',
    name: 'Business',
    description: 'For growing companies (up to 20 people)',
    price: 79,
    currency: 'USD',
    billingCycle: 'monthly',
    yearlyDiscount: 25,
    yearlyPrice: 799, // 25% discount on yearly
    icon: '🏢',
    color: '#ec4899',
    
    // Access Control
    maxUsers: 20,
    maxTeamMembers: 20,
    roles: [
      'owner',
      'director',
      'manager',
      'hr',
      'finance',
      'employee',
      'viewer'
    ],
    
    // Features
    features: {
      core: [
        'invoices',
        'expenses',
        'clients',
        'tasks',
        'inventory',
        'projects',
        'reports',
        'custom_dashboards',
        'data_export',
        'mobile',
        'desktop'
      ],
      ai: [
        'advanced_ai',
        'predictive_analytics',
        'custom_workflows'
      ],
      loyalty: [
        'loyalty_enterprise',
        'custom_tiers',
        'gamification'
      ]
    },
    
    // Usage Limits
    limits: {
      invoices: 5000,
      expenses: 10000,
      clients: 2000,
      projects: 500,
      tasks: 5000,
      storage: 102400, // 100 GB
      aiQueries: 5000,
      teamMembers: 20,
      customRoles: true,
      apiAccess: true,
      auditLogs: true,
      advancedSecurity: true,
      supportPriority: 'vip'
    },
    
    // Billing
    trialDays: 30,
    canCancel: true,
    autoRenew: true,
    paymentMethods: ['card', 'paypal', 'bank_transfer', 'invoice'],
    
    // Upgrade Path
    nextTier: null,
    recommended: false
  }
};

// ─────────────────────────────────────────────────────────────────────────
// TIER ARRAYS & HELPERS
// ─────────────────────────────────────────────────────────────────────────

export const TIER_IDS = Object.keys(SUBSCRIPTION_TIERS);
export const TIER_LIST = Object.values(SUBSCRIPTION_TIERS);

/**
 * Get subscription tier by ID
 * @param {string} tierId - Tier ID (solo, team, business)
 * @returns {object} Tier definition or null
 */
export const getTierById = (tierId) => SUBSCRIPTION_TIERS[tierId] || null;

/**
 * Get list of all tiers for display
 * @returns {array} Array of tier objects
 */
export const getAllTiers = () => {
  return TIER_LIST;
};

/**
 * Get recommended tier for display
 * @returns {object} Recommended tier
 */
export const getRecommendedTier = () => {
  return TIER_LIST.find(t => t.recommended) || SUBSCRIPTION_TIERS.team;
};

// ─────────────────────────────────────────────────────────────────────────
// ROLE DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────

export const ROLES = {
  owner: {
    id: 'owner',
    name: 'Owner',
    description: 'Full access to all features',
    permissions: ['all'],
    tier: 'solo' // Available in Solo+
  },
  director: {
    id: 'director',
    name: 'Director',
    description: 'Strategic oversight and team management',
    permissions: [
      'view_all',
      'manage_team',
      'approve_expenses',
      'manage_projects',
      'view_analytics'
    ],
    tier: 'business'
  },
  manager: {
    id: 'manager',
    name: 'Manager',
    description: 'Team and project oversight',
    permissions: [
      'view_assigned',
      'manage_team',
      'approve_expenses',
      'manage_assigned_projects'
    ],
    tier: 'team'
  },
  hr: {
    id: 'hr',
    name: 'HR Manager',
    description: 'Team and payroll management',
    permissions: [
      'manage_team',
      'view_payroll',
      'manage_onboarding',
      'view_time_tracking'
    ],
    tier: 'business'
  },
  finance: {
    id: 'finance',
    name: 'Finance Manager',
    description: 'Financial and billing management',
    permissions: [
      'view_invoices',
      'manage_expenses',
      'view_billing',
      'export_reports',
      'manage_payments'
    ],
    tier: 'business'
  },
  sales: {
    id: 'sales',
    name: 'Sales',
    description: 'Client and proposal management',
    permissions: [
      'view_clients',
      'create_proposals',
      'manage_leads',
      'view_pipeline'
    ],
    tier: 'business'
  },
  employee: {
    id: 'employee',
    name: 'Employee',
    description: 'Task and basic project access',
    permissions: [
      'view_assigned',
      'submit_expenses',
      'update_tasks',
      'view_assigned_projects'
    ],
    tier: 'team'
  },
  viewer: {
    id: 'viewer',
    name: 'Viewer',
    description: 'Read-only access',
    permissions: ['view_assigned'],
    tier: 'business'
  }
};

/**
 * Get roles available for a tier
 * @param {string} tierId - Subscription tier ID
 * @returns {array} Array of role IDs available in tier
 */
export const getRolesByPlan = (tierId) => {
  const tier = getTierById(tierId);
  if (!tier) return ['employee'];
  
  const availableRoles = [];
  Object.entries(ROLES).forEach(([roleId, role]) => {
    if (tier.roles.includes(roleId) || tier.roles.includes('custom')) {
      availableRoles.push(roleId);
    }
  });
  
  return availableRoles;
};

/**
 * Check if feature is available in tier
 * @param {string} tierId - Subscription tier ID
 * @param {string} feature - Feature name
 * @returns {boolean} Feature available in tier
 */
export const isFeatureAvailable = (tierId, feature) => {
  const tier = getTierById(tierId);
  if (!tier) return false;
  
  // Check all feature categories
  for (const category of Object.values(tier.features)) {
    if (Array.isArray(category) && category.includes(feature)) {
      return true;
    }
  }
  
  return false;
};

/**
 * Check if usage is within limits
 * @param {string} tierId - Subscription tier ID
 * @param {string} limitKey - Usage limit key (invoices, storage, etc)
 * @param {number} currentUsage - Current usage value
 * @returns {boolean} Within limits (true) or exceeded (false)
 */
export const isWithinLimits = (tierId, limitKey, currentUsage) => {
  const tier = getTierById(tierId);
  if (!tier) return false;
  
  const limit = tier.limits[limitKey];
  
  // null = unlimited
  if (limit === null) return true;
  if (limit === undefined) return false;
  
  return currentUsage <= limit;
};

/**
 * Get storage limit in MB
 * @param {string} tierId - Subscription tier ID
 * @returns {number} Storage limit in MB
 */
export const getStorageLimit = (tierId) => {
  const tier = getTierById(tierId);
  return tier?.limits.storage || 1024;
};

/**
 * Get max team members
 * @param {string} tierId - Subscription tier ID
 * @returns {number|null} Max team members (null = unlimited)
 */
export const getMaxTeamMembers = (tierId) => {
  const tier = getTierById(tierId);
  return tier?.maxTeamMembers || 0;
};

// ─────────────────────────────────────────────────────────────────────────
// PRICING & BILLING
// ─────────────────────────────────────────────────────────────────────────

/**
 * Calculate total price with discount
 * @param {string} tierId - Subscription tier ID
 * @param {string} billingCycle - 'monthly' or 'yearly'
 * @returns {object} Pricing breakdown
 */
export const calculatePrice = (tierId, billingCycle = 'monthly') => {
  const tier = getTierById(tierId);
  if (!tier) return null;
  
  if (billingCycle === 'yearly') {
    const yearlyPrice = tier.yearlyPrice;
    const monthlyCost = tier.price * 12;
    const savings = monthlyCost - yearlyPrice;
    const savingsPercent = tier.yearlyDiscount;
    
    return {
      monthlyPrice: tier.price,
      yearlyPrice,
      billingCycle: 'yearly',
      monthlyEquivalent: yearlyPrice / 12,
      savings,
      savingsPercent,
      displayPrice: `$${yearlyPrice}/year`
    };
  }
  
  return {
    monthlyPrice: tier.price,
    billingCycle: 'monthly',
    yearlyEquivalent: tier.yearlyPrice,
    savings: 0,
    savingsPercent: 0,
    displayPrice: `$${tier.price}/month`
  };
};

/**
 * Compare two tiers' features
 * @param {string} tier1Id - First tier ID
 * @param {string} tier2Id - Second tier ID
 * @returns {object} Feature comparison
 */
export const compareTiers = (tier1Id, tier2Id) => {
  const tier1 = getTierById(tier1Id);
  const tier2 = getTierById(tier2Id);
  
  if (!tier1 || !tier2) return null;
  
  return {
    tier1: {
      id: tier1.id,
      name: tier1.name,
      price: tier1.price,
      features: tier1.features
    },
    tier2: {
      id: tier2.id,
      name: tier2.name,
      price: tier2.price,
      features: tier2.features
    }
  };
};

// ─────────────────────────────────────────────────────────────────────────
// SUBSCRIPTION MANAGEMENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Determine if upgrade/downgrade is allowed
 * @param {string} currentTierId - Current subscription tier
 * @param {string} newTierId - Desired tier
 * @returns {object} Upgrade details
 */
export const validateUpgrade = (currentTierId, newTierId) => {
  const currentTier = getTierById(currentTierId);
  const newTier = getTierById(newTierId);
  
  if (!currentTier || !newTier) {
    return { allowed: false, reason: 'Invalid tier' };
  }
  
  const tierOrder = ['solo', 'team', 'business', 'enterprise'];
  const currentIndex = tierOrder.indexOf(currentTierId);
  const newIndex = tierOrder.indexOf(newTierId);
  
  const isUpgrade = newIndex > currentIndex;
  const isDowngrade = newIndex < currentIndex;
  
  return {
    allowed: true,
    isUpgrade,
    isDowngrade,
    currentTier: currentTier.name,
    newTier: newTier.name,
    priceDifference: isUpgrade 
      ? newTier.price - currentTier.price 
      : currentTier.price - newTier.price,
    priceChange: isUpgrade ? 'increase' : 'decrease'
  };
};

/**
 * Create subscription record for user
 * @param {string} userId - Firestore user ID
 * @param {string} tierId - Subscription tier ID
 * @param {string} billingCycle - 'monthly' or 'yearly'
 * @returns {object} Subscription record
 */
export const createSubscriptionRecord = (userId, tierId, billingCycle = 'monthly') => {
  const tier = getTierById(tierId);
  const pricing = calculatePrice(tierId, billingCycle);
  
  return {
    userId,
    tierId,
    tierName: tier.name,
    billingCycle,
    startDate: new Date().toISOString(),
    nextBillingDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    price: billingCycle === 'yearly' ? pricing.yearlyPrice : pricing.monthlyPrice,
    status: 'active', // active, trialing, past_due, canceled, expired
    autoRenew: tier.autoRenew,
    paymentMethod: null, // To be set during checkout
    stripeSubscriptionId: null, // To be set during payment
    trialEndsAt: new Date(Date.now() + tier.trialDays * 24 * 60 * 60 * 1000).toISOString(),
    canceledAt: null,
    metadata: {
      teamSize: 0,
      features: tier.features,
      limits: tier.limits
    }
  };
};

/**
 * Format subscription status for display
 * @param {object} subscription - Subscription record
 * @returns {string} Formatted status
 */
export const formatSubscriptionStatus = (subscription) => {
  if (!subscription) return 'No subscription';
  
  const statuses = {
    active: '✅ Active',
    trialing: '⏳ Trial',
    past_due: '⚠️ Payment Due',
    canceled: '❌ Canceled',
    expired: '⏰ Expired'
  };
  
  return statuses[subscription.status] || subscription.status;
};

/**
 * Export feature matrix for comparison
 * @returns {object} Complete feature matrix
 */
export const getFeatureMatrix = () => {
  const features = {};
  
  // Collect all features from all tiers
  TIER_LIST.forEach(tier => {
    Object.entries(tier.features).forEach(([category, featureList]) => {
      featureList.forEach(feature => {
        if (!features[feature]) {
          features[feature] = {};
        }
        features[feature][tier.id] = true;
      });
    });
  });
  
  return features;
};
