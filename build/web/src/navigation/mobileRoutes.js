/**
 * Mobile Routes Configuration
 * 
 * Defines routes available to employees on mobile
 * Mirrors Flutter employee_dashboard.dart features
 */

/**
 * Employee-only routes (Mobile)
 * Restricted to employees, mobile-first experience
 */
const EMPLOYEE_ROUTES = [
  {
    path: "/tasks/assigned",
    name: "Assigned Tasks",
    description: "View and update tasks assigned to you",
    icon: "tasks",
    permissions: ["read", "update"], // Can read and update status only
    mobileOnly: true,
    requiresAuth: true,
  },
  {
    path: "/expenses/log",
    name: "Log Expense",
    description: "Create and submit expense reports",
    icon: "receipt",
    permissions: ["create", "read"],
    mobileOnly: true,
    requiresAuth: true,
    cameraRequired: true, // Camera for photo receipts
  },
  {
    path: "/clients/view/:id",
    name: "Client Details",
    description: "View clients assigned to you",
    icon: "person",
    permissions: ["read"],
    mobileOnly: true,
    requiresAuth: true,
  },
  {
    path: "/jobs/complete/:id",
    name: "Complete Job",
    description: "Mark jobs as complete with photos",
    icon: "done",
    permissions: ["read", "update"],
    mobileOnly: true,
    requiresAuth: true,
    cameraRequired: true,
  },
  {
    path: "/profile",
    name: "Profile",
    description: "View your profile and permissions",
    icon: "person_circle",
    permissions: ["read"],
    mobileOnly: true,
    requiresAuth: true,
  },
  {
    path: "/sync-status",
    name: "Sync Status",
    description: "Monitor data synchronization",
    icon: "sync",
    permissions: ["read"],
    mobileOnly: true,
    requiresAuth: true,
  },
];

/**
 * Owner main routes (All platforms)
 * Full desktop navigation available
 */
const OWNER_MAIN_ROUTES = [
  {
    path: "/dashboard",
    name: "Dashboard",
    icon: "dashboard",
    category: "Main",
  },
  {
    path: "/crm",
    name: "CRM",
    icon: "people",
    category: "Main",
  },
  {
    path: "/clients",
    name: "Clients",
    icon: "contacts",
    category: "Main",
  },
  {
    path: "/invoices",
    name: "Invoices",
    icon: "receipt",
    category: "Main",
  },
  {
    path: "/tasks",
    name: "Tasks",
    icon: "tasks",
    category: "Main",
  },
  {
    path: "/expenses",
    name: "Expenses",
    icon: "receipt_long",
    category: "Main",
  },
  {
    path: "/projects",
    name: "Projects",
    icon: "folder",
    category: "Main",
  },
];

/**
 * Owner advanced routes (Desktop/Web only)
 * Hidden from mobile, shown in collapsible section
 */
const OWNER_ADVANCED_ROUTES = [
  {
    path: "/suppliers",
    name: "Suppliers",
    icon: "local_shipping",
    category: "Advanced",
    desktopOnly: true,
  },
  {
    path: "/purchase-orders",
    name: "Purchase Orders",
    icon: "shopping_cart",
    category: "Advanced",
    desktopOnly: true,
  },
  {
    path: "/inventory",
    name: "Inventory",
    icon: "inventory_2",
    category: "Advanced",
    desktopOnly: true,
  },
  {
    path: "/finance",
    name: "Finance Dashboard",
    icon: "analytics",
    category: "Advanced",
    desktopOnly: true,
  },
  {
    path: "/loyalty",
    name: "Loyalty Campaigns",
    icon: "star",
    category: "Advanced",
    desktopOnly: true,
  },
  {
    path: "/wallet",
    name: "Wallet & Billing",
    icon: "account_balance_wallet",
    category: "Advanced",
    desktopOnly: true,
  },
  {
    path: "/anomalies",
    name: "Anomaly Detection",
    icon: "warning",
    category: "Advanced",
    desktopOnly: true,
  },
  {
    path: "/admin",
    name: "Admin Panel",
    icon: "admin_panel_settings",
    category: "Advanced",
    desktopOnly: true,
  },
];

/**
 * Get routes for user role
 * Returns appropriate routes based on role and platform
 * 
 * @param {string} userRole - User role ('owner' or 'employee')
 * @param {string} platform - Platform type ('mobile', 'tablet', 'web', 'desktop')
 * @returns {Array} Array of route objects
 */
export const getRoutesByRole = (userRole, platform = "web") => {
  if (userRole === "employee") {
    // Employees only get mobile routes
    return EMPLOYEE_ROUTES;
  }

  if (userRole === "owner") {
    // Owners get all routes, filtered by platform
    const isMobileOrTablet = platform === "mobile" || platform === "tablet";

    if (isMobileOrTablet) {
      // Mobile/tablet: show main routes + employee routes for convenience
      return [...OWNER_MAIN_ROUTES];
    }

    // Web/Desktop: show all routes (main + advanced)
    return [...OWNER_MAIN_ROUTES, ...OWNER_ADVANCED_ROUTES];
  }

  // Fallback: no routes
  return [];
};

/**
 * Get mobile-only routes
 * Convenience function for mobile navigation
 * 
 * @param {string} userRole - User role
 * @returns {Array} Mobile routes only
 */
export const getMobileRoutes = (userRole) => {
  if (userRole === "employee") {
    return EMPLOYEE_ROUTES;
  }

  if (userRole === "owner") {
    // Owner on mobile gets main routes (desktop routes hidden)
    return OWNER_MAIN_ROUTES;
  }

  return [];
};

/**
 * Get desktop/web routes
 * Full navigation for web platform
 * 
 * @param {string} userRole - User role
 * @returns {Array} All routes including advanced
 */
export const getDesktopRoutes = (userRole) => {
  if (userRole === "employee") {
    // Employees on desktop still limited to mobile routes
    return EMPLOYEE_ROUTES;
  }

  if (userRole === "owner") {
    return [...OWNER_MAIN_ROUTES, ...OWNER_ADVANCED_ROUTES];
  }

  return [];
};

/**
 * Get main routes only (for sidebar navigation)
 * 
 * @param {string} userRole - User role
 * @returns {Array} Main category routes
 */
export const getMainRoutes = (userRole) => {
  if (userRole === "employee") {
    return EMPLOYEE_ROUTES;
  }

  if (userRole === "owner") {
    return OWNER_MAIN_ROUTES;
  }

  return [];
};

/**
 * Get advanced routes (owner only)
 * 
 * @returns {Array} Advanced routes
 */
export const getAdvancedRoutes = () => {
  return OWNER_ADVANCED_ROUTES;
};

/**
 * Check if user can access a specific route
 * 
 * @param {string} userRole - User role
 * @param {string} routePath - Route path to check
 * @param {string} platform - Platform type
 * @returns {boolean} True if user can access route
 */
export const canAccessRoute = (userRole, routePath, platform = "web") => {
  const routes = getRoutesByRole(userRole, platform);
  const normalizedPath = routePath.replace(/:\w+/g, ":id"); // Normalize params

  return routes.some((route) => {
    const routeNormalized = route.path.replace(/:\w+/g, ":id");
    return routeNormalized === normalizedPath;
  });
};

/**
 * Get route metadata (for UI rendering)
 * 
 * @param {string} routePath - Route path
 * @returns {Object|null} Route metadata or null if not found
 */
export const getRouteMetadata = (routePath) => {
  const allRoutes = [
    ...EMPLOYEE_ROUTES,
    ...OWNER_MAIN_ROUTES,
    ...OWNER_ADVANCED_ROUTES,
  ];

  return (
    allRoutes.find((route) => route.path === routePath) || null
  );
};

/**
 * Get grouped routes for navigation UI
 * Useful for rendering categorized menus
 * 
 * @param {string} userRole - User role
 * @param {string} platform - Platform type
 * @returns {Object} Routes grouped by category
 */
export const getGroupedRoutes = (userRole, platform = "web") => {
  const routes = getRoutesByRole(userRole, platform);

  return routes.reduce((groups, route) => {
    const category = route.category || "Other";
    if (!groups[category]) {
      groups[category] = [];
    }
    groups[category].push(route);
    return groups;
  }, {});
};

/**
 * Get routes by permission
 * Filter routes by required permission
 * 
 * @param {string} userRole - User role
 * @param {string} permission - Permission to check ('read', 'create', 'update', 'delete')
 * @returns {Array} Routes with specified permission
 */
export const getRoutesByPermission = (userRole, permission) => {
  const routes = getRoutesByRole(userRole);

  return routes.filter((route) => {
    if (!route.permissions) return false;
    return route.permissions.includes(permission);
  });
};

/**
 * Redirect URL based on role and access denial
 * Called when user tries to access unauthorized route
 * 
 * @param {string} userRole - User role
 * @param {string} platform - Platform type
 * @returns {string} Redirect URL
 */
export const getUnauthorizedRedirect = (userRole, platform = "web") => {
  if (!userRole) {
    return "/login"; // Not authenticated
  }

  if (userRole === "employee") {
    return "/tasks/assigned"; // Employee dashboard
  }

  // Owner
  if (platform === "mobile" || platform === "tablet") {
    return "/dashboard"; // Mobile dashboard
  }

  return "/dashboard"; // Web dashboard
};

/**
 * Export all route configurations for testing/reference
 */
export const ROUTES = {
  EMPLOYEE: EMPLOYEE_ROUTES,
  OWNER_MAIN: OWNER_MAIN_ROUTES,
  OWNER_ADVANCED: OWNER_ADVANCED_ROUTES,
};
