/**
 * Desktop Sidebar Navigation Configuration
 * Provides dynamic sidebar menu items based on feature usage and role
 * 
 * @module navigation/desktopSidebar
 */

/**
 * Generate desktop sidebar menu structure
 * 
 * Separates navigation into core and advanced sections with
 * conditional menu items based on feature usage (e.g., inventory)
 * 
 * @param {boolean} [hasUsedInventory=false] - Whether user has accessed inventory
 * @returns {Object} Sidebar structure with core and advanced sections
 * @returns {Array} returns.core - Core menu items (always visible)
 * @returns {Array} returns.advanced - Advanced menu items (collapsible section)
 * 
 * @example
 * const { core, advanced } = getDesktopSidebar(true);
 * // core: [Dashboard, Clients, Invoices, Tasks, Expenses, Team, Inventory]
 * // advanced: [Suppliers, Purchase Orders, Loyalty, Wallet, Alerts, Settings]
 */
export const getDesktopSidebar = (hasUsedInventory = false) => {
  // Core navigation items that appear in the main sidebar
  const core = [
    { 
      name: "Dashboard", 
      path: "/dashboard",
      icon: "📊",
      description: "Business overview and analytics"
    },
    { 
      name: "Clients", 
      path: "/clients",
      icon: "👥",
      description: "Client management"
    },
    { 
      name: "Invoices", 
      path: "/invoices",
      icon: "📄",
      description: "Invoice management"
    },
    { 
      name: "Tasks", 
      path: "/tasks",
      icon: "✓",
      description: "Task tracking"
    },
    { 
      name: "Expenses", 
      path: "/expenses",
      icon: "💰",
      description: "Expense tracking"
    },
    { 
      name: "Team", 
      path: "/team",
      icon: "👨‍💼",
      description: "Team management"
    }
  ];

  // Conditionally add Inventory if user has accessed it
  // This keeps the menu cleaner for users who don't use inventory
  if (hasUsedInventory) {
    core.splice(5, 0, { 
      name: "Inventory", 
      path: "/inventory",
      icon: "📦",
      description: "Inventory management"
    });
  }

  // Advanced features shown in collapsible section
  // These are typically owner-only features
  const advanced = [
    { 
      name: "Suppliers", 
      path: "/suppliers",
      icon: "🏭",
      description: "Supplier management"
    },
    { 
      name: "Purchase Orders", 
      path: "/po",
      icon: "📋",
      description: "Purchase order management"
    },
    { 
      name: "Loyalty", 
      path: "/loyalty",
      icon: "⭐",
      description: "Customer loyalty program"
    },
    { 
      name: "Wallet", 
      path: "/wallet",
      icon: "💳",
      description: "Wallet and billing"
    },
    { 
      name: "Alerts", 
      path: "/alerts",
      icon: "🔔",
      description: "System alerts and notifications"
    },
    { 
      name: "Settings", 
      path: "/settings",
      icon: "⚙️",
      description: "Application settings"
    }
  ];

  return { core, advanced };
};

/**
 * Get all sidebar menu items (core + advanced)
 * 
 * @param {boolean} [hasUsedInventory=false] - Whether user has accessed inventory
 * @returns {Array} Flat array of all menu items
 * 
 * @example
 * const allItems = getAllSidebarItems(true);
 * // Returns array with all core and advanced items
 */
export const getAllSidebarItems = (hasUsedInventory = false) => {
  const { core, advanced } = getDesktopSidebar(hasUsedInventory);
  return [...core, ...advanced];
};

/**
 * Find sidebar item by path
 * 
 * @param {string} path - Route path to search for
 * @param {boolean} [hasUsedInventory=false] - Whether inventory is included
 * @returns {Object|null} Menu item object or null if not found
 * 
 * @example
 * const item = findSidebarItemByPath('/invoices', true);
 * // Returns: { name: "Invoices", path: "/invoices", icon: "📄", ... }
 */
export const findSidebarItemByPath = (path, hasUsedInventory = false) => {
  const allItems = getAllSidebarItems(hasUsedInventory);
  return allItems.find(item => item.path === path) || null;
};

/**
 * Get sidebar item count
 * Useful for responsive design calculations
 * 
 * @param {boolean} [hasUsedInventory=false] - Whether inventory is included
 * @returns {Object} Item counts
 * @returns {number} returns.core - Count of core items
 * @returns {number} returns.advanced - Count of advanced items
 * @returns {number} returns.total - Total menu items
 * 
 * @example
 * const counts = getSidebarItemCounts(true);
 * // { core: 7, advanced: 6, total: 13 }
 */
export const getSidebarItemCounts = (hasUsedInventory = false) => {
  const { core, advanced } = getDesktopSidebar(hasUsedInventory);
  return {
    core: core.length,
    advanced: advanced.length,
    total: core.length + advanced.length
  };
};

/**
 * Check if a path is in advanced section
 * 
 * @param {string} path - Route path to check
 * @param {boolean} [hasUsedInventory=false] - Whether inventory is included
 * @returns {boolean} True if path is in advanced section
 * 
 * @example
 * const isAdvanced = isAdvancedMenuItem('/suppliers', true);
 * // Returns: true
 */
export const isAdvancedMenuItem = (path, hasUsedInventory = false) => {
  const { advanced } = getDesktopSidebar(hasUsedInventory);
  return advanced.some(item => item.path === path);
};

/**
 * Check if a path is in core section
 * 
 * @param {string} path - Route path to check
 * @param {boolean} [hasUsedInventory=false] - Whether inventory is included
 * @returns {boolean} True if path is in core section
 * 
 * @example
 * const isCore = isCoreMenuItem('/dashboard', true);
 * // Returns: true
 */
export const isCoreMenuItem = (path, hasUsedInventory = false) => {
  const { core } = getDesktopSidebar(hasUsedInventory);
  return core.some(item => item.path === path);
};

/**
 * Get section for a given path
 * 
 * @param {string} path - Route path to check
 * @param {boolean} [hasUsedInventory=false] - Whether inventory is included
 * @returns {string|null} 'core' | 'advanced' | null
 * 
 * @example
 * const section = getMenuSection('/wallet', true);
 * // Returns: 'advanced'
 */
export const getMenuSection = (path, hasUsedInventory = false) => {
  if (isCoreMenuItem(path, hasUsedInventory)) return 'core';
  if (isAdvancedMenuItem(path, hasUsedInventory)) return 'advanced';
  return null;
};

/**
 * Filter sidebar items by icon type or category
 * Useful for searching or organizing menu items
 * 
 * @param {string} searchTerm - Text to search in name or description
 * @param {boolean} [hasUsedInventory=false] - Whether inventory is included
 * @returns {Array} Filtered menu items
 * 
 * @example
 * const results = searchSidebarItems('management', true);
 * // Returns all items with 'management' in name or description
 */
export const searchSidebarItems = (searchTerm, hasUsedInventory = false) => {
  const allItems = getAllSidebarItems(hasUsedInventory);
  const term = searchTerm.toLowerCase();
  
  return allItems.filter(item => 
    item.name.toLowerCase().includes(term) ||
    item.description.toLowerCase().includes(term)
  );
};

/**
 * Get sidebar configuration with metadata
 * Includes responsive breakpoints and styling hints
 * 
 * @param {boolean} [hasUsedInventory=false] - Whether inventory is included
 * @returns {Object} Complete sidebar configuration
 * 
 * @example
 * const config = getSidebarConfig(true);
 * // {
 * //   width: 280,
 * //   mobileBreakpoint: 768,
 * //   animationDuration: 300,
 * //   core: [...],
 * //   advanced: [...]
 * // }
 */
export const getSidebarConfig = (hasUsedInventory = false) => {
  const { core, advanced } = getDesktopSidebar(hasUsedInventory);
  
  return {
    // Sidebar dimensions
    width: 280,
    minWidth: 200,
    maxWidth: 350,
    
    // Responsive settings
    mobileBreakpoint: 768,
    tabletBreakpoint: 1024,
    
    // Animation settings
    animationDuration: 300,
    collapseDuration: 200,
    
    // Styling
    backgroundColor: '#ffffff',
    borderColor: '#e0e0e0',
    hoverColor: '#f5f5f5',
    
    // Menu structure
    core,
    advanced,
    
    // Metadata
    counts: {
      core: core.length,
      advanced: advanced.length,
      total: core.length + advanced.length
    }
  };
};

export default {
  getDesktopSidebar,
  getAllSidebarItems,
  findSidebarItemByPath,
  getSidebarItemCounts,
  isAdvancedMenuItem,
  isCoreMenuItem,
  getMenuSection,
  searchSidebarItems,
  getSidebarConfig
};
