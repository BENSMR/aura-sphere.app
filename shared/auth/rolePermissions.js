/**
 * UNIFIED ROLE-BASED ACCESS CONTROL
 * 
 * Simple permission system for checking if a role can access a feature.
 * Works across web, mobile, and all UI components.
 * 
 * Usage:
 *   import { canAccess } from '../auth/rolePermissions';
 *   
 *   {canAccess(userRole, 'finance') && <FinanceTab />}
 *   {canAccess(userRole, 'team_management') && <TeamSettings />}
 */

// ─────────────────────────────────────────────────────────────────────────
// ROLE DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────

export const ROLES = {
  employee: 'employee',
  manager: 'manager',
  owner: 'owner'
};

// ─────────────────────────────────────────────────────────────────────────
// FEATURE DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────

export const FEATURES = {
  // Core features
  INVOICES: 'invoices',
  EXPENSES: 'expenses',
  CLIENTS: 'clients',
  TASKS: 'tasks',
  PROFILE: 'profile',
  
  // Team features
  TEAM_VIEW: 'team_view',
  TEAM_MANAGEMENT: 'team_management',
  
  // Finance features
  FINANCE: 'finance',
  PAYMENTS: 'payments',
  REPORTS: 'reports',
  
  // Advanced features
  INVENTORY: 'inventory',
  PROJECTS: 'projects',
  API_ACCESS: 'api_access',
  AUDIT_LOGS: 'audit_logs',
  
  // AI & Automation
  AI_BASIC: 'ai_basic',
  AI_PRO: 'ai_pro',
  ADVANCED_AI: 'advanced_ai',
  
  // Settings & Config
  SETTINGS: 'settings',
  ROLES_MANAGEMENT: 'roles_management',
  SECURITY: 'security'
};

// ─────────────────────────────────────────────────────────────────────────
// PERMISSION MATRIX
// ─────────────────────────────────────────────────────────────────────────

/**
 * Feature access matrix by role
 * Define which features each role can access
 */
const PERMISSION_MATRIX = {
  employee: {
    // Core (can always access)
    [FEATURES.INVOICES]: true,
    [FEATURES.EXPENSES]: true,
    [FEATURES.CLIENTS]: true,
    [FEATURES.TASKS]: true,
    [FEATURES.PROFILE]: true,
    
    // Team (can view only)
    [FEATURES.TEAM_VIEW]: true,
    [FEATURES.TEAM_MANAGEMENT]: false,
    
    // Finance (no access)
    [FEATURES.FINANCE]: false,
    [FEATURES.PAYMENTS]: false,
    [FEATURES.REPORTS]: false,
    
    // Advanced (no access)
    [FEATURES.INVENTORY]: false,
    [FEATURES.PROJECTS]: true,
    [FEATURES.API_ACCESS]: false,
    [FEATURES.AUDIT_LOGS]: false,
    
    // AI
    [FEATURES.AI_BASIC]: true,
    [FEATURES.AI_PRO]: false,
    [FEATURES.ADVANCED_AI]: false,
    
    // Settings
    [FEATURES.SETTINGS]: true,
    [FEATURES.ROLES_MANAGEMENT]: false,
    [FEATURES.SECURITY]: false
  },
  
  manager: {
    // Core (full access)
    [FEATURES.INVOICES]: true,
    [FEATURES.EXPENSES]: true,
    [FEATURES.CLIENTS]: true,
    [FEATURES.TASKS]: true,
    [FEATURES.PROFILE]: true,
    
    // Team (can manage)
    [FEATURES.TEAM_VIEW]: true,
    [FEATURES.TEAM_MANAGEMENT]: true,
    
    // Finance (can view & manage)
    [FEATURES.FINANCE]: true,
    [FEATURES.PAYMENTS]: true,
    [FEATURES.REPORTS]: true,
    
    // Advanced (limited)
    [FEATURES.INVENTORY]: true,
    [FEATURES.PROJECTS]: true,
    [FEATURES.API_ACCESS]: false,
    [FEATURES.AUDIT_LOGS]: false,
    
    // AI
    [FEATURES.AI_BASIC]: true,
    [FEATURES.AI_PRO]: true,
    [FEATURES.ADVANCED_AI]: false,
    
    // Settings
    [FEATURES.SETTINGS]: true,
    [FEATURES.ROLES_MANAGEMENT]: false,
    [FEATURES.SECURITY]: false
  },
  
  owner: {
    // All features (owner has full access)
    [FEATURES.INVOICES]: true,
    [FEATURES.EXPENSES]: true,
    [FEATURES.CLIENTS]: true,
    [FEATURES.TASKS]: true,
    [FEATURES.PROFILE]: true,
    [FEATURES.TEAM_VIEW]: true,
    [FEATURES.TEAM_MANAGEMENT]: true,
    [FEATURES.FINANCE]: true,
    [FEATURES.PAYMENTS]: true,
    [FEATURES.REPORTS]: true,
    [FEATURES.INVENTORY]: true,
    [FEATURES.PROJECTS]: true,
    [FEATURES.API_ACCESS]: true,
    [FEATURES.AUDIT_LOGS]: true,
    [FEATURES.AI_BASIC]: true,
    [FEATURES.AI_PRO]: true,
    [FEATURES.ADVANCED_AI]: true,
    [FEATURES.SETTINGS]: true,
    [FEATURES.ROLES_MANAGEMENT]: true,
    [FEATURES.SECURITY]: true
  }
};

// ─────────────────────────────────────────────────────────────────────────
// MAIN PERMISSION FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Check if a role can access a feature
 * @param {string} role - User role (employee, manager, owner)
 * @param {string} feature - Feature name (from FEATURES object)
 * @returns {boolean} True if access granted, false otherwise
 * 
 * @example
 * if (canAccess(userRole, FEATURES.FINANCE)) {
 *   return <FinanceTab />;
 * }
 */
export const canAccess = (role, feature) => {
  // Validate inputs
  if (!role || !feature) {
    return false;
  }
  
  // Normalize role to lowercase
  const normalizedRole = role.toLowerCase();
  
  // Check if role exists in permission matrix
  if (!PERMISSION_MATRIX[normalizedRole]) {
    console.warn(`Unknown role: ${role}`);
    return false;
  }
  
  // Return permission (default false if feature not defined)
  return PERMISSION_MATRIX[normalizedRole][feature] || false;
};

/**
 * Check if a role can access a route
 * @param {string} role - User role
 * @param {string} route - Route path (e.g., '/finance', '/team-management')
 * @returns {boolean} True if access granted
 * 
 * @example
 * if (!canAccessRoute(userRole, '/finance')) {
 *   navigate('/tasks');
 * }
 */
export const canAccessRoute = (role, route) => {
  // Map routes to features
  const routeToFeatureMap = {
    '/finance': FEATURES.FINANCE,
    '/payments': FEATURES.PAYMENTS,
    '/reports': FEATURES.REPORTS,
    '/team': FEATURES.TEAM_MANAGEMENT,
    '/team-view': FEATURES.TEAM_VIEW,
    '/inventory': FEATURES.INVENTORY,
    '/projects': FEATURES.PROJECTS,
    '/api': FEATURES.API_ACCESS,
    '/audit-logs': FEATURES.AUDIT_LOGS,
    '/settings': FEATURES.SETTINGS,
    '/roles': FEATURES.ROLES_MANAGEMENT,
    '/security': FEATURES.SECURITY,
    '/tasks': FEATURES.TASKS,
    '/expenses': FEATURES.EXPENSES,
    '/clients': FEATURES.CLIENTS,
    '/invoices': FEATURES.INVOICES,
    '/profile': FEATURES.PROFILE
  };
  
  const feature = routeToFeatureMap[route.toLowerCase()];
  
  if (!feature) {
    // Route not in map - allow access (public route)
    return true;
  }
  
  return canAccess(role, feature);
};

/**
 * Get all accessible features for a role
 * @param {string} role - User role
 * @returns {array} Array of accessible feature names
 * 
 * @example
 * const features = getAccessibleFeatures(userRole);
 * // ['invoices', 'expenses', 'clients', 'tasks', 'profile', 'team_view', 'ai_basic', ...]
 */
export const getAccessibleFeatures = (role) => {
  const normalizedRole = role.toLowerCase();
  
  if (!PERMISSION_MATRIX[normalizedRole]) {
    return [];
  }
  
  return Object.keys(PERMISSION_MATRIX[normalizedRole])
    .filter(feature => PERMISSION_MATRIX[normalizedRole][feature]);
};

/**
 * Check if a role can perform an action
 * Alias for canAccess() for semantic clarity
 * @param {string} role - User role
 * @param {string} action - Action/feature name
 * @returns {boolean} True if action allowed
 * 
 * @example
 * if (canPerform(userRole, 'approve_expenses')) {
 *   showApproveButton();
 * }
 */
export const canPerform = (role, action) => canAccess(role, action);

/**
 * Get required role to access a feature
 * @param {string} feature - Feature name
 * @returns {string|null} Minimum required role or null if all can access
 * 
 * @example
 * const minRole = getRequiredRole(FEATURES.API_ACCESS);
 * // 'owner'
 */
export const getRequiredRole = (feature) => {
  // Check hierarchy: owner > manager > employee
  if (canAccess(ROLES.employee, feature)) {
    return ROLES.employee;
  }
  if (canAccess(ROLES.manager, feature)) {
    return ROLES.manager;
  }
  if (canAccess(ROLES.owner, feature)) {
    return ROLES.owner;
  }
  
  return null; // Feature not accessible to anyone
};

/**
 * Compare two roles by permission level
 * @param {string} role1 - First role
 * @param {string} role2 - Second role
 * @returns {number} -1 if role1 < role2, 0 if equal, 1 if role1 > role2
 * 
 * @example
 * compareRoles('employee', 'manager'); // -1 (employee < manager)
 * compareRoles('owner', 'manager'); // 1 (owner > manager)
 */
export const compareRoles = (role1, role2) => {
  const roleHierarchy = {
    [ROLES.employee]: 1,
    [ROLES.manager]: 2,
    [ROLES.owner]: 3
  };
  
  const level1 = roleHierarchy[role1.toLowerCase()] || 0;
  const level2 = roleHierarchy[role2.toLowerCase()] || 0;
  
  if (level1 < level2) return -1;
  if (level1 > level2) return 1;
  return 0;
};

/**
 * Check if role1 has more permissions than role2
 * @param {string} role1 - First role to check
 * @param {string} role2 - Second role to compare against
 * @returns {boolean} True if role1 >= role2 in hierarchy
 * 
 * @example
 * hasHigherRole('manager', 'employee'); // true
 * hasHigherRole('employee', 'manager'); // false
 */
export const hasHigherRole = (role1, role2) => compareRoles(role1, role2) >= 0;

// ─────────────────────────────────────────────────────────────────────────
// MOBILE-SPECIFIC ACCESS CONTROL
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get accessible mobile screens for a role
 * Maps roles to mobile screen lists
 * @param {string} role - User role
 * @returns {object} { primary: [], secondary: [] } screen arrays
 * 
 * @example
 * const screens = getMobileScreens('employee');
 * // { primary: ['tasks', 'expenses', 'clients', 'jobs', 'profile'], secondary: [] }
 */
export const getMobileScreens = (role) => {
  const screenMap = {
    employee: {
      primary: ['tasks', 'expenses', 'clients', 'jobs', 'profile'],
      secondary: []
    },
    manager: {
      primary: ['team', 'tasks', 'expenses'],
      secondary: ['clients', 'jobs']
    },
    owner: {
      primary: ['dashboard', 'team', 'finances'],
      secondary: ['clients', 'settings']
    }
  };
  
  return screenMap[role.toLowerCase()] || screenMap.employee;
};

/**
 * Check if a role can access a specific mobile screen
 * @param {string} role - User role
 * @param {string} screenId - Screen ID (tasks, expenses, etc)
 * @returns {boolean} True if screen accessible
 * 
 * @example
 * if (canAccessMobileScreen(userRole, 'team')) {
 *   navigateTo('team');
 * }
 */
export const canAccessMobileScreen = (role, screenId) => {
  const screens = getMobileScreens(role);
  const allScreens = [...screens.primary, ...screens.secondary];
  return allScreens.includes(screenId.toLowerCase());
};

// ─────────────────────────────────────────────────────────────────────────
// DEBUG UTILITIES
// ─────────────────────────────────────────────────────────────────────────

/**
 * Print all permissions for a role (debugging)
 * @param {string} role - User role
 * 
 * @example
 * debugPermissions('manager');
 */
export const debugPermissions = (role) => {
  const normalizedRole = role.toLowerCase();
  
  if (!PERMISSION_MATRIX[normalizedRole]) {
    console.error(`Unknown role: ${role}`);
    return;
  }
  
  console.group(`Permissions for ${role}`);
  const permissions = PERMISSION_MATRIX[normalizedRole];
  
  Object.entries(permissions).forEach(([feature, allowed]) => {
    const icon = allowed ? '✅' : '❌';
    console.log(`${icon} ${feature}`);
  });
  
  console.groupEnd();
};

/**
 * Compare permissions between two roles
 * @param {string} role1 - First role
 * @param {string} role2 - Second role
 * 
 * @example
 * comparePermissions('employee', 'manager');
 */
export const comparePermissions = (role1, role2) => {
  const features1 = getAccessibleFeatures(role1);
  const features2 = getAccessibleFeatures(role2);
  
  const onlyIn1 = features1.filter(f => !features2.includes(f));
  const onlyIn2 = features2.filter(f => !features1.includes(f));
  const inBoth = features1.filter(f => features2.includes(f));
  
  console.group(`Permission Comparison: ${role1} vs ${role2}`);
  console.log(`Only in ${role1}:`, onlyIn1);
  console.log(`Only in ${role2}:`, onlyIn2);
  console.log(`In both:`, inBoth);
  console.groupEnd();
};

// ─────────────────────────────────────────────────────────────────────────
// EXPORTS
// ─────────────────────────────────────────────────────────────────────────

export default {
  ROLES,
  FEATURES,
  canAccess,
  canAccessRoute,
  canAccessMobileScreen,
  getAccessibleFeatures,
  canPerform,
  getRequiredRole,
  compareRoles,
  hasHigherRole,
  getMobileScreens,
  debugPermissions,
  comparePermissions
};
