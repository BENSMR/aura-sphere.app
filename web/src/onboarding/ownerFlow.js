/**
 * Owner Onboarding Flow
 * Handles first-time owner setup with step-by-step guidance
 * 
 * @module onboarding/ownerFlow
 */

import { getFirestore, doc, updateDoc } from 'firebase/firestore';

/**
 * Owner onboarding steps
 * Define sequence of setup steps for new owners
 */
export const OWNER_ONBOARDING_STEPS = [
  {
    id: "setup_profile",
    name: "Setup Business Profile",
    path: "/settings/profile",
    description: "Add your business name, logo, and contact information",
    required: true,
    estimatedTime: 5
  },
  {
    id: "add_team_members",
    name: "Add Team Members",
    path: "/team/members",
    description: "Invite employees to your account",
    required: false,
    estimatedTime: 10
  },
  {
    id: "configure_invoices",
    name: "Configure Invoice Settings",
    path: "/settings/invoices",
    description: "Set up invoice templates and numbering",
    required: false,
    estimatedTime: 5
  },
  {
    id: "setup_expenses",
    name: "Categorize Expenses",
    path: "/settings/expenses",
    description: "Configure expense categories and budget limits",
    required: false,
    estimatedTime: 10
  },
  {
    id: "invite_first_client",
    name: "Add First Client",
    path: "/clients/new",
    description: "Create your first client in the system",
    required: false,
    estimatedTime: 5
  },
  {
    id: "create_first_invoice",
    name: "Create First Invoice",
    path: "/invoices/new",
    description: "Issue your first invoice using the platform",
    required: false,
    estimatedTime: 10
  }
];

/**
 * Handle owner onboarding initialization
 * 
 * @param {Object} user - Firebase user object
 * @param {Object} [options={}] - Onboarding options
 * @param {boolean} [options.showWelcome=true] - Show welcome modal
 * @param {string} [options.redirectPath="/onboarding/owner"] - Redirect destination
 * @returns {Promise<void>}
 */
export const handleOwnerOnboarding = async (user, options = {}) => {
  const {
    showWelcome = true,
    redirectPath = "/onboarding/owner"
  } = options;

  try {
    if (!user) {
      console.warn("No user provided to handleOwnerOnboarding");
      return;
    }

    const db = getFirestore();
    const userRef = doc(db, "users", user.uid);

    // Initialize owner onboarding in Firestore
    await updateDoc(userRef, {
      onboardingStarted: true,
      onboardingStartedAt: new Date(),
      role: "owner",
      onboardingProgress: {
        completedSteps: [],
        currentStep: "setup_profile",
        progressPercentage: 0
      }
    });

    // Set localStorage flags
    setOwnerOnboardingFlag(true);
    setOnboardingStep("setup_profile");

    if (showWelcome) {
      setOwnerWelcomeFlag(true);
    }

    logOnboardingEvent(user.uid, "owner_onboarding_started");

    // Redirect to onboarding flow
    window.location.href = redirectPath;

  } catch (error) {
    console.error("Error initializing owner onboarding:", error);
    throw new Error(`Owner onboarding initialization failed: ${error.message}`);
  }
};

/**
 * Mark owner onboarding step as completed
 * 
 * @param {Object} user - Firebase user object
 * @param {string} stepId - ID of completed step
 * @returns {Promise<void>}
 */
export const completeOwnerOnboardingStep = async (user, stepId) => {
  try {
    if (!user) return;

    const db = getFirestore();
    const userRef = doc(db, "users", user.uid);

    // Get current progress
    const currentProgress = getOwnerOnboardingProgress();
    const completedSteps = currentProgress.completedSteps || [];

    if (!completedSteps.includes(stepId)) {
      completedSteps.push(stepId);
    }

    // Calculate progress percentage
    const progressPercentage = Math.round(
      (completedSteps.length / OWNER_ONBOARDING_STEPS.length) * 100
    );

    // Find next required step
    const nextRequiredStep = OWNER_ONBOARDING_STEPS.find(
      step => step.required && !completedSteps.includes(step.id)
    );

    const nextStep = nextRequiredStep
      ? nextRequiredStep.id
      : OWNER_ONBOARDING_STEPS.find(
          step => !completedSteps.includes(step.id)
        )?.id || null;

    // Update Firestore
    await updateDoc(userRef, {
      "onboardingProgress.completedSteps": completedSteps,
      "onboardingProgress.currentStep": nextStep,
      "onboardingProgress.progressPercentage": progressPercentage,
      "onboardingProgress.lastUpdatedAt": new Date()
    });

    // Update localStorage
    updateOwnerOnboardingProgress({
      completedSteps,
      currentStep: nextStep,
      progressPercentage
    });

    setOnboardingStep(stepId);
    logOnboardingEvent(user.uid, "owner_onboarding_step_completed", { stepId });

  } catch (error) {
    console.error("Error completing onboarding step:", error);
  }
};

/**
 * Skip remaining owner onboarding steps
 * User can still access setup pages from settings
 * 
 * @param {Object} user - Firebase user object
 * @returns {Promise<void>}
 */
export const skipOwnerOnboarding = async (user) => {
  try {
    if (!user) return;

    const db = getFirestore();
    const userRef = doc(db, "users", user.uid);

    await updateDoc(userRef, {
      onboardingSkipped: true,
      onboardingSkippedAt: new Date(),
      "onboardingProgress.currentStep": null
    });

    localStorage.removeItem("ownerOnboarding");
    logOnboardingEvent(user.uid, "owner_onboarding_skipped");

  } catch (error) {
    console.error("Error skipping onboarding:", error);
  }
};

/**
 * Complete full owner onboarding
 * Mark as fully onboarded when all required steps complete
 * 
 * @param {Object} user - Firebase user object
 * @returns {Promise<void>}
 */
export const completeOwnerOnboarding = async (user) => {
  try {
    if (!user) return;

    const db = getFirestore();
    const userRef = doc(db, "users", user.uid);

    await updateDoc(userRef, {
      onboardingCompleted: true,
      onboardingCompletedAt: new Date(),
      "onboardingProgress.currentStep": null,
      "onboardingProgress.progressPercentage": 100
    });

    localStorage.setItem("ownerOnboarded", "true");
    logOnboardingEvent(user.uid, "owner_onboarding_completed");

  } catch (error) {
    console.error("Error completing onboarding:", error);
  }
};

/**
 * Get owner onboarding status
 * 
 * @returns {Object} Status object
 */
export const getOwnerOnboardingStatus = () => {
  return {
    started: localStorage.getItem("ownerOnboarding") === "true",
    completed: localStorage.getItem("ownerOnboarded") === "true",
    currentStep: localStorage.getItem("currentOnboardingStep"),
    progress: getOwnerOnboardingProgress()
  };
};

/**
 * Get onboarding step by ID
 * 
 * @param {string} stepId - Step ID
 * @returns {Object|null} Step object or null
 */
export const getOnboardingStep = (stepId) => {
  return OWNER_ONBOARDING_STEPS.find(step => step.id === stepId) || null;
};

/**
 * Get all onboarding steps with completion status
 * 
 * @param {Array<string>} [completedSteps=[]] - List of completed step IDs
 * @returns {Array<Object>} Steps with completion status
 */
export const getOnboardingStepsWithStatus = (completedSteps = []) => {
  return OWNER_ONBOARDING_STEPS.map(step => ({
    ...step,
    completed: completedSteps.includes(step.id)
  }));
};

/**
 * Calculate estimated time remaining
 * 
 * @param {Array<string>} [completedSteps=[]] - Completed step IDs
 * @returns {number} Minutes remaining
 */
export const getEstimatedTimeRemaining = (completedSteps = []) => {
  return OWNER_ONBOARDING_STEPS
    .filter(step => !completedSteps.includes(step.id))
    .reduce((total, step) => total + step.estimatedTime, 0);
};

// ============================================================================
// LOCAL STORAGE HELPERS
// ============================================================================

/**
 * Set owner onboarding flag
 */
export const setOwnerOnboardingFlag = (value) => {
  localStorage.setItem("ownerOnboarding", value ? "true" : "false");
};

/**
 * Set owner welcome flag (to show welcome modal once)
 */
export const setOwnerWelcomeFlag = (value) => {
  localStorage.setItem("ownerWelcome", value ? "true" : "false");
};

/**
 * Check if should show owner welcome modal
 */
export const shouldShowOwnerWelcome = () => {
  return localStorage.getItem("ownerWelcome") === "true";
};

/**
 * Set current onboarding step
 */
export const setOnboardingStep = (stepId) => {
  localStorage.setItem("currentOnboardingStep", stepId);
};

/**
 * Get current onboarding step
 */
export const getCurrentOnboardingStep = () => {
  return localStorage.getItem("currentOnboardingStep");
};

/**
 * Get owner onboarding progress from localStorage
 */
export const getOwnerOnboardingProgress = () => {
  const stored = localStorage.getItem("ownerOnboardingProgress");
  if (!stored) {
    return {
      completedSteps: [],
      currentStep: "setup_profile",
      progressPercentage: 0
    };
  }
  return JSON.parse(stored);
};

/**
 * Update owner onboarding progress in localStorage
 */
export const updateOwnerOnboardingProgress = (progress) => {
  localStorage.setItem("ownerOnboardingProgress", JSON.stringify(progress));
};

/**
 * Clear all owner onboarding data
 */
export const clearOwnerOnboardingData = () => {
  localStorage.removeItem("ownerOnboarding");
  localStorage.removeItem("ownerOnboarded");
  localStorage.removeItem("ownerWelcome");
  localStorage.removeItem("currentOnboardingStep");
  localStorage.removeItem("ownerOnboardingProgress");
};

// ============================================================================
// ANALYTICS
// ============================================================================

/**
 * Log onboarding event
 */
export const logOnboardingEvent = (userId, eventName, metadata = {}) => {
  console.log("Owner Onboarding Event:", {
    userId,
    eventName,
    timestamp: new Date().toISOString(),
    ...metadata
  });

  // TODO: Send to analytics service
};

export default {
  OWNER_ONBOARDING_STEPS,
  handleOwnerOnboarding,
  completeOwnerOnboardingStep,
  skipOwnerOnboarding,
  completeOwnerOnboarding,
  getOwnerOnboardingStatus,
  getOnboardingStep,
  getOnboardingStepsWithStatus,
  getEstimatedTimeRemaining,
  setOwnerOnboardingFlag,
  setOwnerWelcomeFlag,
  shouldShowOwnerWelcome,
  setOnboardingStep,
  getCurrentOnboardingStep,
  getOwnerOnboardingProgress,
  updateOwnerOnboardingProgress,
  clearOwnerOnboardingData,
  logOnboardingEvent
};
