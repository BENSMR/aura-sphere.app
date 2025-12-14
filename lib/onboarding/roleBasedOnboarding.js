/**
 * ROLE-BASED ONBOARDING ROUTER
 * 
 * Post-login routing based on:
 * - User role (employee, manager, owner)
 * - Subscription plan (solo, team, business)
 * - Onboarding completion status
 * - Platform (web, mobile)
 * 
 * Integrates with Phase 10 (Subscriptions) and Phase 11 (Mobile)
 */

import { getTierById } from '../pricing/subscriptionTiers';
import { getMobileScreens } from '../auth/rolePermissions';

// ─────────────────────────────────────────────────────────────────────────
// ONBOARDING PATHS BY ROLE & PLAN
// ─────────────────────────────────────────────────────────────────────────

const ONBOARDING_PATHS = {
  // EMPLOYEE - Simplest flow (no setup needed)
  employee: {
    default: '/tasks/assigned',
    mobile: '/mobile/tasks',
    needsOnboarding: false
  },

  // MANAGER - Moderate setup (team management)
  manager: {
    solo: {
      new: '/onboarding/manager-setup',
      existing: '/dashboard-team'
    },
    team: {
      new: '/onboarding/manager-setup',
      existing: '/dashboard-team'
    },
    business: {
      new: '/onboarding/manager-setup',
      existing: '/dashboard-team'
    },
    mobile: '/mobile/team'
  },

  // OWNER - Full onboarding (business setup)
  owner: {
    solo: {
      new: '/onboarding/owner-wizard?plan=solo',
      existing: '/dashboard-simple'
    },
    team: {
      new: '/onboarding/owner-wizard?plan=team',
      existing: '/dashboard-full'
    },
    business: {
      new: '/onboarding/owner-wizard?plan=business',
      existing: '/dashboard-full'
    },
    mobile: '/mobile/dashboard'
  }
};

// ─────────────────────────────────────────────────────────────────────────
// MAIN ROUTING FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Route user after login based on role, plan, and onboarding status
 * @param {object} user - User object with role, subscription, onboarding data
 * @param {string} platform - 'web' or 'mobile'
 * @returns {string} Route to navigate to
 * 
 * @example
 * const route = getOnboardingRoute(user, 'web');
 * window.location.href = route;
 */
export const getOnboardingRoute = (user, platform = 'web') => {
  // Validate user
  if (!user || !user.role) {
    return '/login';
  }

  const { role, subscription, hasCompletedOnboarding } = user;

  // Employee: always go to tasks
  if (role === 'employee') {
    return platform === 'mobile' 
      ? ONBOARDING_PATHS.employee.mobile
      : ONBOARDING_PATHS.employee.default;
  }

  // Get subscription tier
  const tierId = subscription?.tierId || 'solo';
  const tier = getTierById(tierId);
  const tierName = tier?.id || 'solo';

  // Manager and Owner: route based on plan and completion
  const rolePaths = ONBOARDING_PATHS[role];
  if (!rolePaths) {
    return '/dashboard'; // Fallback
  }

  // Mobile routing
  if (platform === 'mobile') {
    return rolePaths.mobile;
  }

  // Web routing - check onboarding status
  const planPaths = rolePaths[tierName];
  if (!planPaths) {
    return '/dashboard'; // Fallback
  }

  // Route based on onboarding completion
  const shouldShowOnboarding = 
    !hasCompletedOnboarding && 
    isNewUser(user);

  return shouldShowOnboarding 
    ? planPaths.new 
    : planPaths.existing;
};

/**
 * Handle user login and route appropriately
 * Call this immediately after successful login
 * @param {object} user - Authenticated user object
 * @param {string} platform - 'web' or 'mobile'
 * 
 * @example
 * onAuthStateChanged(auth, (user) => {
 *   if (user) {
 *     handleOnboarding(user, 'web');
 *   }
 * });
 */
export const handleOnboarding = (user, platform = 'web') => {
  const route = getOnboardingRoute(user, platform);
  
  if (platform === 'mobile') {
    // Mobile: use React Navigation or similar
    // navigateTo(route);
    window.location.href = route;
  } else {
    // Web: use window.location or router
    window.location.href = route;
  }
};

/**
 * Determine if user is new (never completed onboarding)
 * @param {object} user - User object
 * @returns {boolean} True if new user
 */
export const isNewUser = (user) => {
  return !user.hasCompletedOnboarding && !user.createdAt 
    ? false 
    : !user.hasCompletedOnboarding;
};

/**
 * Mark onboarding as complete in Firestore
 * @param {string} userId - User ID
 * @param {object} setupData - Data captured during onboarding
 * @returns {Promise<void>}
 * 
 * @example
 * await completeOnboarding(userId, { 
 *   businessName: 'Acme Corp',
 *   industry: 'construction' 
 * });
 */
export const completeOnboarding = async (userId, setupData = {}) => {
  try {
    // Update user document
    const userRef = doc(db, 'users', userId);
    await updateDoc(userRef, {
      hasCompletedOnboarding: true,
      onboardingCompletedAt: new Date(),
      onboardingData: setupData
    });

    // Log completion event
    console.log(`Onboarding completed for user ${userId}`, setupData);

    return true;
  } catch (error) {
    console.error('Error marking onboarding complete:', error);
    return false;
  }
};

// ─────────────────────────────────────────────────────────────────────────
// ONBOARDING STEP SEQUENCES
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get onboarding steps for a user's role and plan
 * @param {string} role - User role (owner, manager, employee)
 * @param {string} tierId - Subscription tier ID
 * @returns {array} Array of onboarding steps
 * 
 * @example
 * const steps = getOnboardingSteps('owner', 'team');
 * // [
 * //   { id: 'business-info', title: 'Business Info', duration: '5 min' },
 * //   { id: 'team-setup', title: 'Team Setup', duration: '10 min' },
 * //   { id: 'payment', title: 'Payment', duration: '5 min' }
 * // ]
 */
export const getOnboardingSteps = (role, tierId = 'solo') => {
  // Shared steps for all users
  const sharedSteps = [
    {
      id: 'welcome',
      title: 'Welcome',
      description: 'Let\'s set up your account',
      duration: '2 min',
      component: 'WelcomeStep'
    },
    {
      id: 'business-info',
      title: 'Business Info',
      description: 'Tell us about your business',
      duration: '5 min',
      component: 'BusinessInfoStep',
      fields: ['businessName', 'industry', 'businessType']
    }
  ];

  // Role-specific steps
  const roleSteps = {
    owner: [
      ...sharedSteps,
      {
        id: 'team-setup',
        title: 'Team Setup',
        description: 'Invite your team members',
        duration: '10 min',
        component: 'TeamSetupStep',
        enabled: ['team', 'business'].includes(tierId)
      },
      {
        id: 'features',
        title: 'Configure Features',
        description: 'Choose features to enable',
        duration: '5 min',
        component: 'FeaturesStep'
      },
      {
        id: 'payment',
        title: 'Payment Method',
        description: 'Add payment information',
        duration: '5 min',
        component: 'PaymentStep'
      },
      {
        id: 'complete',
        title: 'You\'re All Set!',
        description: 'Ready to start using AuraSphere',
        duration: '1 min',
        component: 'CompleteStep'
      }
    ],
    manager: [
      ...sharedSteps,
      {
        id: 'team-role',
        title: 'Team Role',
        description: 'Set up your team responsibilities',
        duration: '5 min',
        component: 'TeamRoleStep'
      },
      {
        id: 'complete',
        title: 'Ready to Go!',
        description: 'Start managing your team',
        duration: '1 min',
        component: 'CompleteStep'
      }
    ],
    employee: [
      {
        id: 'welcome',
        title: 'Welcome to the Team',
        description: 'Your workspace is ready',
        duration: '2 min',
        component: 'EmployeeWelcomeStep'
      }
    ]
  };

  return roleSteps[role] || [];
};

/**
 * Get next step in onboarding flow
 * @param {string} role - User role
 * @param {string} currentStepId - Current step ID
 * @param {string} tierId - Subscription tier
 * @returns {object|null} Next step or null if complete
 * 
 * @example
 * const nextStep = getNextStep('owner', 'business-info', 'team');
 */
export const getNextStep = (role, currentStepId, tierId = 'solo') => {
  const steps = getOnboardingSteps(role, tierId)
    .filter(step => step.enabled !== false);

  const currentIndex = steps.findIndex(s => s.id === currentStepId);
  
  if (currentIndex === -1 || currentIndex === steps.length - 1) {
    return null; // No next step or onboarding complete
  }

  return steps[currentIndex + 1];
};

// ─────────────────────────────────────────────────────────────────────────
// PROGRESS TRACKING
// ─────────────────────────────────────────────────────────────────────────

/**
 * Calculate onboarding progress percentage
 * @param {string} role - User role
 * @param {string} currentStepId - Current step ID
 * @param {string} tierId - Subscription tier
 * @returns {number} Progress percentage (0-100)
 */
export const getOnboardingProgress = (role, currentStepId, tierId = 'solo') => {
  const steps = getOnboardingSteps(role, tierId)
    .filter(step => step.enabled !== false);

  const currentIndex = steps.findIndex(s => s.id === currentStepId);
  
  if (currentIndex === -1) return 0;
  
  return Math.round(((currentIndex + 1) / steps.length) * 100);
};

/**
 * Skip remaining onboarding steps
 * @param {string} userId - User ID
 * @param {object} partialData - Any data collected so far
 * @returns {Promise<void>}
 */
export const skipOnboarding = async (userId, partialData = {}) => {
  try {
    const userRef = doc(db, 'users', userId);
    await updateDoc(userRef, {
      hasCompletedOnboarding: true,
      onboardingSkipped: true,
      onboardingSkippedAt: new Date(),
      onboardingData: partialData
    });

    console.log(`Onboarding skipped for user ${userId}`);
    return true;
  } catch (error) {
    console.error('Error skipping onboarding:', error);
    return false;
  }
};

// ─────────────────────────────────────────────────────────────────────────
// ONBOARDING DATA HANDLERS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Save onboarding step data (before completing full onboarding)
 * @param {string} userId - User ID
 * @param {string} stepId - Step ID
 * @param {object} data - Step data to save
 * @returns {Promise<void>}
 */
export const saveStepData = async (userId, stepId, data) => {
  try {
    const userRef = doc(db, 'users', userId);
    await updateDoc(userRef, {
      [`onboardingProgress.${stepId}`]: data,
      onboardingUpdatedAt: new Date()
    });

    return true;
  } catch (error) {
    console.error('Error saving step data:', error);
    return false;
  }
};

/**
 * Get saved onboarding data for a user
 * @param {string} userId - User ID
 * @returns {Promise<object>} Onboarding data
 */
export const getOnboardingData = async (userId) => {
  try {
    const userRef = doc(db, 'users', userId);
    const userSnap = await getDoc(userRef);

    if (!userSnap.exists()) {
      return null;
    }

    const userData = userSnap.data();
    return {
      data: userData.onboardingData || {},
      progress: userData.onboardingProgress || {},
      completed: userData.hasCompletedOnboarding || false,
      completedAt: userData.onboardingCompletedAt
    };
  } catch (error) {
    console.error('Error fetching onboarding data:', error);
    return null;
  }
};

// ─────────────────────────────────────────────────────────────────────────
// EXPORT
// ─────────────────────────────────────────────────────────────────────────

export default {
  getOnboardingRoute,
  handleOnboarding,
  isNewUser,
  completeOnboarding,
  getOnboardingSteps,
  getNextStep,
  getOnboardingProgress,
  skipOnboarding,
  saveStepData,
  getOnboardingData
};
