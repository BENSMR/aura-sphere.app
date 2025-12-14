/**
 * Access Control Service (Web)
 * 
 * Mirrors Flutter's AccessControlService.dart
 * Manages permission checks for web platform
 */

import { getRoutesByRole, getMainRoutes, getAdvancedRoutes, canAccessRoute } from "../navigation/mobileRoutes";

// Feature catalog (matches Flutter role_model.dart)
export const FEATURES = {
  // Main features (7)
  DASHBOARD: "dashboard",
  CRM: "crm",
  CLIENTS: "clients",
  INVOICES: "invoices",
  TASKS: "tasks",
  EXPENSES: "expenses",
  PROJECTS: "projects",

  // Advanced features (8)
  SUPPLIERS: "suppliers",
  PURCHASE_ORDERS: "purchase_orders",
  INVENTORY: "inventory",
  FINANCE: "finance",
  LOYALTY: "loyalty",
  WALLET: "wallet",
  ANOMALIES: "anomalies",
  ADMIN: "admin",

  // Employee features (6) - subset of above
  ASSIGNED_TASKS: "assigned_tasks",
  LOG_EXPENSE: "log_expense",
  VIEW_CLIENTS: "view_clients",
  COMPLETE_JOBS: "complete_jobs",
  PROFILE: "profile",
  SYNC_STATUS: "sync_status",
};

// Feature access configuration
const FEATURE_ACCESS = {
  [FEATURES.DASHBOARD]: {
    employeeAccess: false,
    desktopOnly: false,
    permissions: ["read"],
  },
  [FEATURES.CRM]: {
    employeeAccess: false,
    desktopOnly: false,
    permissions: ["read", "write"],
  },
  [FEATURES.CLIENTS]: {
    employeeAccess: true, // Employees can view assigned clients
    desktopOnly: false,
    permissions: ["read"], // Read-only for employees
  },
  [FEATURES.INVOICES]: {
    employeeAccess: false,
    desktopOnly: true,
    permissions: ["read", "write", "delete"],
  },
  [FEATURES.TASKS]: {
    employeeAccess: true, // Employees can see assigned tasks
    desktopOnly: false,
    permissions: ["read", "update"], // Limited update for employees
  },
  [FEATURES.EXPENSES]: {
    employeeAccess: true, // Employees can create/view own
    desktopOnly: false,
    permissions: ["create", "read", "update"],
  },
  [FEATURES.PROJECTS]: {
    employeeAccess: false,
    desktopOnly: false,
    permissions: ["read", "write"],
  },
  [FEATURES.SUPPLIERS]: {
    employeeAccess: false,
    desktopOnly: true,
    permissions: ["read", "write", "delete"],
  },
  [FEATURES.PURCHASE_ORDERS]: {
    employeeAccess: false,
    desktopOnly: true,
    permissions: ["read", "write", "delete"],
  },
  [FEATURES.INVENTORY]: {
    employeeAccess: false,
    desktopOnly: true,
    permissions: ["read", "write", "delete"],
  },
  [FEATURES.FINANCE]: {
    employeeAccess: false,
    desktopOnly: true,
    permissions: ["read"],
  },
  [FEATURES.LOYALTY]: {
    employeeAccess: false,
    desktopOnly: true,
    permissions: ["read"],
  },
  [FEATURES.WALLET]: {
    employeeAccess: false,
    desktopOnly: true,
    permissions: ["read", "write"],
  },
  [FEATURES.ANOMALIES]: {
    employeeAccess: false,
    desktopOnly: true,
    permissions: ["read"],
  },
  [FEATURES.ADMIN]: {
    employeeAccess: false,
    desktopOnly: true,
    permissions: ["read", "write", "delete"],
  },
};

/**
 * Check if user role can access a feature
 * Basic permission check
 * 
 * @param {string} userRole - User role ('owner' or 'employee')
 * @param {string} feature - Feature identifier
 * @returns {boolean} True if user can access feature
 */
export const canAccessFeature = (userRole, feature) => {
  if (!userRole || !feature) return false;

  const access = FEATURE_ACCESS[feature];
  if (!access) return false; // Feature doesn't exist

  if (userRole === "owner") {
    return true; // Owners always have access
  }

  if (userRole === "employee") {
    return access.employeeAccess; // Check employee access flag
  }

  return false;
};

/**
 * Check if user can access feature on specific platform
 * Platform-aware permission check
 * 
 * @param {string} userRole - User role
 * @param {string} feature - Feature identifier
 * @param {string} platform - Platform ('mobile', 'tablet', 'web', 'desktop')
 * @returns {boolean} True if user can access on platform
 */
export const canAccessFeatureOnPlatform = (userRole, feature, platform) => {
  if (!canAccessFeature(userRole, feature)) {
    return false;
  }

  const access = FEATURE_ACCESS[feature];
  const isMobileOrTablet = platform === "mobile" || platform === "tablet";

  // Desktop-only features blocked on mobile
  if (access.desktopOnly && isMobileOrTablet) {
    return false;
  }

  return true;
};

/**
 * Get all visible features for user and platform
 * Returns feature identifiers
 * 
 * @param {string} userRole - User role
 * @param {string} platform - Platform type
 * @returns {Array<string>} Accessible feature identifiers
 */
export const getVisibleFeatures = (userRole, platform = "web") => {
  return Object.entries(FEATURE_ACCESS)
    .filter(([feature, access]) => {
      if (userRole === "owner") {
        // Owners see everything except desktop-only on mobile
        const isMobileOrTablet = platform === "mobile" || platform === "tablet";
        if (access.desktopOnly && isMobileOrTablet) {
          return false;
        }
        return true;
      }

      if (userRole === "employee") {
        // Employees only see what's enabled for them
        return access.employeeAccess;
      }

      return false;
    })
    .map(([feature]) => feature);
};

/**
 * Get categorized features for navigation UI
 * Useful for building sidebars and menus
 * 
 * @param {string} userRole - User role
 * @param {string} platform - Platform type
 * @returns {Object} Features grouped by category (main, advanced)
 */
export const getCategorizedFeatures = (userRole, platform = "web") => {
  const mainFeatures = [
    FEATURES.DASHBOARD,
    FEATURES.CRM,
    FEATURES.CLIENTS,
    FEATURES.INVOICES,
    FEATURES.TASKS,
    FEATURES.EXPENSES,
    FEATURES.PROJECTS,
  ];

  const advancedFeatures = [
    FEATURES.SUPPLIERS,
    FEATURES.PURCHASE_ORDERS,
    FEATURES.INVENTORY,
    FEATURES.FINANCE,
    FEATURES.LOYALTY,
    FEATURES.WALLET,
    FEATURES.ANOMALIES,
    FEATURES.ADMIN,
  ];

  const visible = getVisibleFeatures(userRole, platform);

  return {
    main: mainFeatures.filter((f) => visible.includes(f)),
    advanced: advancedFeatures.filter((f) => visible.includes(f)),
  };
};

/**
 * Check if advanced section should be shown
 * Determines if sidebar collapsible exists
 * 
 * @param {string} userRole - User role
 * @param {string} platform - Platform type
 * @returns {boolean} True if advanced section exists
 */
export const shouldShowAdvancedSection = (userRole, platform = "web") => {
  if (userRole === "owner") {
    // Owners have advanced section on desktop
    return platform === "web" || platform === "desktop";
  }

  // Employees never see advanced section
  return false;
};

/**
 * Check if user can access a specific route
 * Route protection check
 * 
 * @param {string} userRole - User role
 * @param {string} routeName - Route name (path)
 * @param {string} platform - Platform type
 * @returns {boolean} True if user can access route
 */
export const canAccessRoute = (userRole, routeName, platform = "web") => {
  if (!userRole) return false;

  // Use route-based checking
  const routes = getRoutesByRole(userRole, platform);
  return routes.some((route) => route.path === routeName);
};

/**
 * Get redirect URL for unauthorized access
 * Where to send user when access denied
 * 
 * @param {string} userRole - User role
 * @param {string} platform - Platform type
 * @returns {string} Redirect URL
 */
export const getUnauthorizedRedirect = (userRole, platform = "web") => {
  if (!userRole) {
    return "/login";
  }

  if (userRole === "employee") {
    return "/tasks/assigned"; // Employee dashboard
  }

  // Owner dashboard
  return "/dashboard";
};

/**
 * Get human-readable access summary
 * For debugging and display purposes
 * 
 * @param {string} userRole - User role
 * @param {string} platform - Platform type
 * @returns {Object} Summary with stats and feature lists
 */
export const getAccessSummary = (userRole, platform = "web") => {
  const visible = getVisibleFeatures(userRole, platform);
  const categorized = getCategorizedFeatures(userRole, platform);

  return {
    role: userRole,
    platform,
    totalFeaturesVisible: visible.length,
    mainFeaturesCount: categorized.main.length,
    advancedFeaturesCount: categorized.advanced.length,
    mainFeatures: categorized.main,
    advancedFeatures: categorized.advanced,
    canViewAdvanced: shouldShowAdvancedSection(userRole, platform),
  };
};

/**
 * Get feature permissions for user
 * Detailed permission breakdown
 * 
 * @param {string} userRole - User role
 * @param {string} feature - Feature identifier
 * @returns {Object|null} Permission object or null if no access
 */
export const getFeaturePermissions = (userRole, feature) => {
  if (!canAccessFeature(userRole, feature)) {
    return null;
  }

  const access = FEATURE_ACCESS[feature];

  if (userRole === "employee" && !access.employeeAccess) {
    return null;
  }

  return {
    feature,
    canRead: access.permissions.includes("read"),
    canCreate: access.permissions.includes("create"),
    canUpdate: access.permissions.includes("update"),
    canDelete: access.permissions.includes("delete"),
    desktopOnly: access.desktopOnly,
    permissions: access.permissions,
  };
};

/**
 * Check if feature requires specific permission
 * 
 * @param {string} userRole - User role
 * @param {string} feature - Feature identifier
 * @param {string} permission - Permission to check
 * @returns {boolean} True if user has permission
 */
export const hasFeaturePermission = (userRole, feature, permission) => {
  const perms = getFeaturePermissions(userRole, feature);
  if (!perms) return false;

  return perms.permissions.includes(permission);
};

/**
 * Export feature catalog
 */
export const getFeatureCatalog = () => {
  return FEATURE_ACCESS;
};
