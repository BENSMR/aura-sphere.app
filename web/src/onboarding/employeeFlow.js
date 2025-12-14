/**
 * Employee Onboarding Flow
 * Handles first-time employee setup and redirection
 * 
 * @module onboarding/employeeFlow
 */

import { getAuth } from 'firebase/auth';
import { getFirestore, doc, updateDoc } from 'firebase/firestore';

/**
 * Handle employee onboarding
 * 
 * Flow:
 * 1. Mark employee as onboarded in Firestore
 * 2. Set localStorage flag for client-side tracking
 * 3. Show optional onboarding tooltip
 * 4. Redirect to tasks dashboard
 * 
 * @param {Object} user - Firebase user object
 * @param {Object} [options={}] - Onboarding options
 * @param {boolean} [options.showTooltip=true] - Show onboarding tooltip
 * @param {string} [options.redirectPath="/tasks/assigned"] - Redirect destination
 * @param {number} [options.redirectDelay=0] - Delay before redirect (ms)
 * @returns {Promise<void>}
 * 
 * @example
 * const user = getAuth().currentUser;
 * await handleEmployeeOnboarding(user, {
 *   showTooltip: true,
 *   redirectPath: "/tasks/assigned",
 *   redirectDelay: 500
 * });
 */
export const handleEmployeeOnboarding = async (user, options = {}) => {
  const {
    showTooltip = true,
    redirectPath = "/tasks/assigned",
    redirectDelay = 0
  } = options;

  try {
    if (!user) {
      console.warn("No user provided to handleEmployeeOnboarding");
      return;
    }

    // Update Firestore document
    const db = getFirestore();
    const userRef = doc(db, "users", user.uid);
    
    await updateDoc(userRef, {
      onboardingCompleted: true,
      onboardingCompletedAt: new Date(),
      role: "employee",
      lastLoginAt: new Date()
    });

    // Set localStorage flags for client-side tracking
    setEmployeeOnboardingFlag(true);
    
    if (showTooltip) {
      setOnboardingTooltip("employee_welcome", "shown");
    }

    // Log onboarding event
    logOnboardingEvent(user.uid, "employee_onboarding_completed");

    // Redirect to employee dashboard
    setTimeout(() => {
      window.location.href = redirectPath;
    }, redirectDelay);

  } catch (error) {
    console.error("Error during employee onboarding:", error);
    throw new Error(`Onboarding failed: ${error.message}`);
  }
};

/**
 * Skip employee onboarding
 * Marks onboarding as skipped, user can access later
 * 
 * @param {Object} user - Firebase user object
 * @returns {Promise<void>}
 */
export const skipEmployeeOnboarding = async (user) => {
  try {
    if (!user) return;

    const db = getFirestore();
    const userRef = doc(db, "users", user.uid);
    
    await updateDoc(userRef, {
      onboardingSkipped: true,
      onboardingSkippedAt: new Date()
    });

    setOnboardingTooltip("employee_welcome", "skipped");
    logOnboardingEvent(user.uid, "employee_onboarding_skipped");

  } catch (error) {
    console.error("Error skipping onboarding:", error);
  }
};

/**
 * Check if employee has completed onboarding
 * 
 * @param {Object} user - Firebase user object
 * @returns {Promise<boolean>} True if onboarding completed
 */
export const isEmployeeOnboarded = async (user) => {
  try {
    if (!user) return false;

    // First check localStorage for quick response
    if (isEmployeeOnboardedLocal()) {
      return true;
    }

    // Then check Firestore as source of truth
    const db = getFirestore();
    const userRef = doc(db, "users", user.uid);
    const userSnap = await getDocs(query(
      collection(db, "users"),
      where("uid", "==", user.uid)
    ));

    if (userSnap.empty) return false;

    const userData = userSnap.docs[0].data();
    const onboarded = userData.onboardingCompleted === true;

    // Sync with localStorage
    if (onboarded) {
      setEmployeeOnboardingFlag(true);
    }

    return onboarded;

  } catch (error) {
    console.error("Error checking onboarding status:", error);
    return false;
  }
};

/**
 * Get employee onboarding status
 * 
 * @param {Object} user - Firebase user object
 * @returns {Promise<Object>} Onboarding status object
 * @returns {boolean} returns.completed - Whether onboarding is done
 * @returns {boolean} returns.skipped - Whether onboarding was skipped
 * @returns {Date|null} returns.completedAt - When onboarding was completed
 * @returns {Date|null} returns.skippedAt - When onboarding was skipped
 */
export const getEmployeeOnboardingStatus = async (user) => {
  try {
    if (!user) {
      return {
        completed: false,
        skipped: false,
        completedAt: null,
        skippedAt: null
      };
    }

    const db = getFirestore();
    const userRef = doc(db, "users", user.uid);
    const userSnap = await getDoc(userRef);

    if (!userSnap.exists()) {
      return {
        completed: false,
        skipped: false,
        completedAt: null,
        skippedAt: null
      };
    }

    const userData = userSnap.data();

    return {
      completed: userData.onboardingCompleted || false,
      skipped: userData.onboardingSkipped || false,
      completedAt: userData.onboardingCompletedAt || null,
      skippedAt: userData.onboardingSkippedAt || null
    };

  } catch (error) {
    console.error("Error getting onboarding status:", error);
    return {
      completed: false,
      skipped: false,
      completedAt: null,
      skippedAt: null
    };
  }
};

/**
 * Get employee onboarding tooltip status
 * Check if specific tooltips have been shown
 * 
 * @param {string} tooltipId - ID of the tooltip
 * @returns {string|null} Status: 'shown', 'skipped', or null
 */
export const getOnboardingTooltipStatus = (tooltipId = "employee_welcome") => {
  return localStorage.getItem(`tooltip_${tooltipId}`);
};

/**
 * Check if employee should see onboarding
 * Returns true if they haven't completed onboarding yet
 * 
 * @param {Object} user - Firebase user object
 * @returns {Promise<boolean>}
 */
export const shouldShowEmployeeOnboarding = async (user) => {
  const status = await getEmployeeOnboardingStatus(user);
  return !status.completed && !status.skipped;
};

// ============================================================================
// LOCAL STORAGE HELPERS
// ============================================================================

/**
 * Set employee onboarding flag in localStorage
 * 
 * @param {boolean} value - Whether employee is onboarded
 */
export const setEmployeeOnboardingFlag = (value) => {
  localStorage.setItem("employeeOnboarded", value ? "true" : "false");
};

/**
 * Check if employee is onboarded (localStorage)
 * Quick check for UI rendering without async call
 * 
 * @returns {boolean}
 */
export const isEmployeeOnboardedLocal = () => {
  return localStorage.getItem("employeeOnboarded") === "true";
};

/**
 * Set onboarding tooltip status
 * 
 * @param {string} tooltipId - ID of the tooltip
 * @param {string} status - Status: 'shown', 'skipped', 'dismissed'
 */
export const setOnboardingTooltip = (tooltipId, status) => {
  localStorage.setItem(`tooltip_${tooltipId}`, status);
};

/**
 * Clear all onboarding data from localStorage
 * Useful for testing or resetting
 */
export const clearOnboardingData = () => {
  localStorage.removeItem("employeeOnboarded");
  localStorage.removeItem("tooltip_employee_welcome");
  localStorage.removeItem("onboarding_dismissed");
};

// ============================================================================
// ANALYTICS
// ============================================================================

/**
 * Log onboarding event to analytics
 * 
 * @param {string} userId - User ID
 * @param {string} eventName - Event name (e.g., 'employee_onboarding_completed')
 * @param {Object} [metadata={}] - Additional event metadata
 */
export const logOnboardingEvent = (userId, eventName, metadata = {}) => {
  // Integration point for analytics (Mixpanel, Google Analytics, etc.)
  console.log("Onboarding Event:", {
    userId,
    eventName,
    timestamp: new Date().toISOString(),
    ...metadata
  });

  // TODO: Send to your analytics service
  // analytics.track(eventName, {
  //   userId,
  //   ...metadata
  // });
};

export default {
  handleEmployeeOnboarding,
  skipEmployeeOnboarding,
  isEmployeeOnboarded,
  getEmployeeOnboardingStatus,
  getOnboardingTooltipStatus,
  shouldShowEmployeeOnboarding,
  setEmployeeOnboardingFlag,
  isEmployeeOnboardedLocal,
  setOnboardingTooltip,
  clearOnboardingData,
  logOnboardingEvent
};
