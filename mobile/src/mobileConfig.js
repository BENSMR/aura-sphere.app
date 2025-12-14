/**
 * MOBILE EMPLOYEE APP - CORE CONFIGURATION
 *
 * Mobile routing, screens, navigation, and role-based logic
 * Optimized for employee field/on-site workflows
 *
 * @module mobileConfig
 */

// ─────────────────────────────────────────────────────────────────────────
// MOBILE SCREENS & NAVIGATION
// ─────────────────────────────────────────────────────────────────────────

/**
 * Mobile screen definitions by role
 * Employees see task/expense focused screens
 * Managers/Owners see team/admin screens
 */
export const MOBILE_SCREENS = {
  // Employee screens (field/task focused)
  employee: {
    primary: [
      { id: "tasks", path: "/mobile/tasks/assigned", label: "Tasks", icon: "✓" },
      { id: "expenses", path: "/mobile/expenses/log", label: "Expenses", icon: "💰" },
      { id: "clients", path: "/mobile/clients/view", label: "Clients", icon: "👥" }
    ],
    secondary: [
      { id: "jobs", path: "/mobile/jobs/complete/:id", label: "Jobs", icon: "🔧" },
      { id: "profile", path: "/mobile/profile", label: "Profile", icon: "👤" }
    ]
  },

  // Manager screens (team oversight)
  manager: {
    primary: [
      { id: "team", path: "/mobile/team/status", label: "Team", icon: "👥" },
      { id: "tasks", path: "/mobile/tasks/view", label: "Tasks", icon: "✓" },
      { id: "expenses", path: "/mobile/expenses/review", label: "Expenses", icon: "💰" }
    ],
    secondary: [
      { id: "clients", path: "/mobile/clients/view", label: "Clients", icon: "📋" },
      { id: "profile", path: "/mobile/profile", label: "Profile", icon: "👤" }
    ]
  },

  // Owner/Director screens (full access)
  owner: {
    primary: [
      { id: "dashboard", path: "/mobile/dashboard", label: "Dashboard", icon: "📊" },
      { id: "team", path: "/mobile/team/manage", label: "Team", icon: "👥" },
      { id: "finances", path: "/mobile/finances/overview", label: "Finances", icon: "💳" }
    ],
    secondary: [
      { id: "clients", path: "/mobile/clients/manage", label: "Clients", icon: "📋" },
      { id: "settings", path: "/mobile/settings", label: "Settings", icon: "⚙️" }
    ]
  }
};

/**
 * Screen metadata and permissions
 */
export const SCREEN_CONFIG = {
  tasks: {
    name: "Tasks",
    icon: "✓",
    description: "View and manage assigned tasks",
    requiredRole: ["employee", "manager", "owner"],
    requiredFeature: "task_management"
  },
  expenses: {
    name: "Expenses",
    icon: "💰",
    description: "Log and track expenses",
    requiredRole: ["employee", "manager", "finance", "owner"],
    requiredFeature: "expense_tracking"
  },
  clients: {
    name: "Clients",
    icon: "👥",
    description: "View and manage client information",
    requiredRole: ["employee", "manager", "sales", "owner"],
    requiredFeature: "client_management"
  },
  jobs: {
    name: "Jobs",
    icon: "🔧",
    description: "Complete assigned job tasks",
    requiredRole: ["employee"],
    requiredFeature: "job_management"
  },
  profile: {
    name: "Profile",
    icon: "👤",
    description: "View and edit profile",
    requiredRole: ["employee", "manager", "owner"],
    requiredFeature: null // Always available
  },
  team: {
    name: "Team",
    icon: "👥",
    description: "Manage team members and assignments",
    requiredRole: ["manager", "hr", "owner"],
    requiredFeature: "team_management"
  },
  dashboard: {
    name: "Dashboard",
    icon: "📊",
    description: "Business overview and metrics",
    requiredRole: ["manager", "owner", "director"],
    requiredFeature: "analytics"
  },
  finances: {
    name: "Finances",
    icon: "💳",
    description: "Financial overview and reports",
    requiredRole: ["finance", "owner", "director"],
    requiredFeature: "financial_management"
  }
};

// ─────────────────────────────────────────────────────────────────────────
// ROLE-BASED NAVIGATION
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get mobile screens for user's role
 * @param {string} role - User's role (employee, manager, owner, etc)
 * @returns {Array} Primary and secondary screens
 * @example
 * const screens = getScreensByRole('employee');
 * // → { primary: [...], secondary: [...] }
 */
export function getScreensByRole(role) {
  return MOBILE_SCREENS[role] || MOBILE_SCREENS.employee;
}

/**
 * Get bottom navigation tabs for role
 * @param {string} role - User's role
 * @returns {Array} Tab items with path, label, icon
 */
export function getNavigationTabs(role) {
  const screens = getScreensByRole(role);
  return [...screens.primary, ...screens.secondary].slice(0, 5); // Bottom nav limit
}

/**
 * Get home screen route for role
 * @param {string} role - User's role
 * @returns {string} Path to home screen
 */
export function getHomeScreen(role) {
  const screens = getScreensByRole(role);
  return screens.primary[0].path; // First primary screen is home
}

/**
 * Get all accessible screens for role
 * @param {string} role - User's role
 * @returns {Array} All accessible screen configs
 */
export function getAllScreensForRole(role) {
  const screens = getScreensByRole(role);
  return [...screens.primary, ...screens.secondary];
}

// ─────────────────────────────────────────────────────────────────────────
// AI CONTEXT MANAGEMENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get AI context based on mobile screen
 * @param {string} screenId - Current screen ID
 * @param {string} userId - User ID
 * @returns {object} Context for AI action generation
 */
export function getMobileAIContext(screenId, userId) {
  const contexts = {
    tasks: {
      focus: "task_completion",
      priority: "deadline_urgency",
      maxSuggestions: 1,
      actionTypes: ["task_reminder", "deadline_warning", "delegation_opportunity"]
    },
    expenses: {
      focus: "expense_capture",
      priority: "receipt_accuracy",
      maxSuggestions: 1,
      actionTypes: ["receipt_recognition", "receipt_categorization", "duplicate_detection"]
    },
    clients: {
      focus: "client_engagement",
      priority: "relationship_health",
      maxSuggestions: 1,
      actionTypes: ["client_follow_up", "payment_reminder", "upsell_opportunity"]
    },
    jobs: {
      focus: "job_completion",
      priority: "completion_status",
      maxSuggestions: 1,
      actionTypes: ["job_suggestion", "material_check", "safety_reminder"]
    },
    team: {
      focus: "team_management",
      priority: "task_distribution",
      maxSuggestions: 1,
      actionTypes: ["workload_balance", "skill_match", "availability_check"]
    },
    dashboard: {
      focus: "business_metrics",
      priority: "performance_alerts",
      maxSuggestions: 1,
      actionTypes: ["metric_alert", "trend_analysis", "opportunity_detection"]
    }
  };

  return contexts[screenId] || contexts.tasks;
}

// ─────────────────────────────────────────────────────────────────────────
// ONBOARDING & ROUTING
// ─────────────────────────────────────────────────────────────────────────

/**
 * Handle post-login mobile routing
 * Routes based on role, subscription, and setup status
 * @param {object} user - User object with role, subscription, setupComplete
 * @returns {string} Target path
 * @example
 * const path = handleMobileOnboarding(user);
 * // → "/mobile/tasks/assigned" or "/onboarding/owner-wizard"
 */
export function handleMobileOnboarding(user) {
  const { role, subscription, setupComplete } = user;

  // Employee → go straight to tasks (quick access)
  if (role === "employee") {
    return "/mobile/tasks/assigned";
  }

  // Manager → go to team status
  if (role === "manager" && setupComplete) {
    return "/mobile/team/status";
  }

  // Owner/Director → show setup wizard if new, else dashboard
  if (role === "owner" || role === "director") {
    if (!setupComplete) {
      return "/onboarding/owner-wizard";
    }
    return "/mobile/dashboard";
  }

  // Other roles → default to home
  return getHomeScreen(role);
}

/**
 * Check if user can access screen on mobile
 * @param {object} user - User object
 * @param {string} screenId - Screen to access
 * @returns {boolean} Can user access this screen
 */
export function canAccessMobileScreen(user, screenId) {
  const screenConfig = SCREEN_CONFIG[screenId];
  if (!screenConfig) return false;

  // Check role requirement
  if (!screenConfig.requiredRole.includes(user.role)) {
    return false;
  }

  // Check feature requirement (if subscription has feature gating)
  if (screenConfig.requiredFeature) {
    // Import from subscriptionTiers if available
    // return isFeatureAvailable(user.subscription.tierId, screenConfig.requiredFeature);
  }

  return true;
}

/**
 * Get restricted screen message
 * @param {string} screenId - Screen user tried to access
 * @param {string} role - User's role
 * @returns {string} Explanation message
 */
export function getRestrictedScreenMessage(screenId, role) {
  const screen = SCREEN_CONFIG[screenId];
  return `${screen?.name} is not available for ${role}s. Access: ${screen?.requiredRole.join(", ")}`;
}

// ─────────────────────────────────────────────────────────────────────────
// MOBILE NAVIGATION STATE
// ─────────────────────────────────────────────────────────────────────────

/**
 * Mobile navigation state manager
 * Tracks current screen, history, and active tab
 */
export class MobileNavigation {
  constructor(initialRole = "employee") {
    this.role = initialRole;
    this.currentScreen = getHomeScreen(initialRole);
    this.history = [this.currentScreen];
    this.activeTabIndex = 0;
  }

  /**
   * Navigate to screen
   * @param {string} path - Screen path
   * @returns {boolean} Success
   */
  navigateTo(path) {
    if (this.isValidPath(path)) {
      this.history.push(path);
      this.currentScreen = path;
      this.updateActiveTab(path);
      return true;
    }
    return false;
  }

  /**
   * Go back to previous screen
   * @returns {boolean} Success
   */
  goBack() {
    if (this.history.length > 1) {
      this.history.pop();
      this.currentScreen = this.history[this.history.length - 1];
      return true;
    }
    return false;
  }

  /**
   * Check if path is valid for role
   * @private
   */
  isValidPath(path) {
    const screenId = this.extractScreenId(path);
    return canAccessMobileScreen({ role: this.role }, screenId);
  }

  /**
   * Extract screen ID from path
   * @private
   */
  extractScreenId(path) {
    const parts = path.split("/");
    return parts[2]; // /mobile/{screenId}/...
  }

  /**
   * Update active tab based on current screen
   * @private
   */
  updateActiveTab(path) {
    const tabs = getNavigationTabs(this.role);
    const index = tabs.findIndex(tab => tab.path === path || path.includes(tab.id));
    if (index >= 0) {
      this.activeTabIndex = index;
    }
  }

  /**
   * Get current state
   */
  getState() {
    return {
      currentScreen: this.currentScreen,
      activeTabIndex: this.activeTabIndex,
      canGoBack: this.history.length > 1,
      tabs: getNavigationTabs(this.role)
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// MOBILE SESSION MANAGEMENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Session handler for mobile app
 * Manages authentication state and re-authentication
 */
export class MobileSession {
  constructor(userId, user) {
    this.userId = userId;
    this.user = user;
    this.sessionStart = Date.now();
    this.lastActivity = Date.now();
    this.sessionTimeout = 30 * 60 * 1000; // 30 minutes
  }

  /**
   * Update last activity time
   */
  updateActivity() {
    this.lastActivity = Date.now();
  }

  /**
   * Check if session is expired
   */
  isExpired() {
    return Date.now() - this.lastActivity > this.sessionTimeout;
  }

  /**
   * Get session info
   */
  getInfo() {
    return {
      userId: this.userId,
      role: this.user.role,
      sessionDuration: Date.now() - this.sessionStart,
      inactiveTime: Date.now() - this.lastActivity,
      expired: this.isExpired()
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// MOBILE-SPECIFIC UTILITIES
// ─────────────────────────────────────────────────────────────────────────

/**
 * Check if running on mobile device
 * @returns {boolean}
 */
export function isMobileDevice() {
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
    navigator.userAgent
  );
}

/**
 * Check if screen is small (mobile)
 * @returns {boolean}
 */
export function isSmallScreen() {
  return typeof window !== "undefined" && window.innerWidth < 768;
}

/**
 * Optimize image for mobile
 * @param {string} url - Image URL
 * @param {number} maxWidth - Max width in pixels
 * @returns {string} Optimized URL (with resize params if supported)
 */
export function optimizeMobileImage(url, maxWidth = 400) {
  // For Firebase Storage: add alt=media&w={maxWidth}
  // For other services: implement custom resize logic
  if (url.includes("firebaseio.com")) {
    return `${url}?alt=media&w=${maxWidth}`;
  }
  return url;
}

/**
 * Format data for mobile display
 * Shorter text, condensed layouts
 * @param {string} text - Text to format
 * @param {number} maxLength - Max characters
 * @returns {string} Truncated text with ellipsis
 */
export function truncateForMobile(text, maxLength = 50) {
  if (!text) return "";
  return text.length > maxLength ? text.substring(0, maxLength) + "..." : text;
}

/**
 * Get mobile-friendly date format
 * @param {Date} date - Date to format
 * @returns {string} Formatted date (e.g., "Jan 15, 2:30 PM")
 */
export function formatMobileDate(date) {
  const options = {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  };
  return new Date(date).toLocaleDateString("en-US", options);
}

/**
 * Vibrate device (feedback)
 * @param {number} duration - Milliseconds
 */
export function vibrateDevice(duration = 100) {
  if (navigator.vibrate) {
    navigator.vibrate(duration);
  }
}

/**
 * Get safe area insets (for notch/home indicator)
 * @returns {object} Safe area insets
 */
export function getSafeAreaInsets() {
  if (typeof window === "undefined") {
    return { top: 0, bottom: 0, left: 0, right: 0 };
  }

  return {
    top: parseInt(getComputedStyle(document.documentElement).getPropertyValue("--safe-area-inset-top")) || 0,
    bottom: parseInt(getComputedStyle(document.documentElement).getPropertyValue("--safe-area-inset-bottom")) || 0,
    left: parseInt(getComputedStyle(document.documentElement).getPropertyValue("--safe-area-inset-left")) || 0,
    right: parseInt(getComputedStyle(document.documentElement).getPropertyValue("--safe-area-inset-right")) || 0
  };
}

// ─────────────────────────────────────────────────────────────────────────
// EXPORTS
// ─────────────────────────────────────────────────────────────────────────

export default {
  MOBILE_SCREENS,
  SCREEN_CONFIG,
  getScreensByRole,
  getNavigationTabs,
  getHomeScreen,
  getAllScreensForRole,
  getMobileAIContext,
  handleMobileOnboarding,
  canAccessMobileScreen,
  getRestrictedScreenMessage,
  MobileNavigation,
  MobileSession,
  isMobileDevice,
  isSmallScreen,
  optimizeMobileImage,
  truncateForMobile,
  formatMobileDate,
  vibrateDevice,
  getSafeAreaInsets
};
