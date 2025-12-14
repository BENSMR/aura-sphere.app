/**
 * Desktop Sidebar - Implementation Guide & Examples
 * 
 * This guide shows how to use the desktop sidebar navigation component
 * with the desktopSidebar configuration module.
 */

// ============================================================================
// EXAMPLE 1: Basic Desktop Sidebar Usage
// ============================================================================

import React from 'react';
import DesktopSidebar from '../components/DesktopSidebar';
import { useNavigate } from 'react-router-dom';

export function AppLayoutWithSidebar() {
  const navigate = useNavigate();
  
  return (
    <div className="app-layout">
      <DesktopSidebar
        hasUsedInventory={true}
        onNavigate={(path) => navigate(path)}
      />
      
      <main className="main-content">
        {/* Page content */}
      </main>
    </div>
  );
}

// ============================================================================
// EXAMPLE 2: Sidebar with Advanced Features Disabled
// ============================================================================

export function AdminLayout() {
  const navigate = useNavigate();
  
  return (
    <div className="app-layout">
      <DesktopSidebar
        hasUsedInventory={true}
        onNavigate={(path) => navigate(path)}
        showAdvanced={false}  // Hide advanced section
      />
      
      <main className="main-content">
        {/* Content for employees only */}
      </main>
    </div>
  );
}

// ============================================================================
// EXAMPLE 3: Sidebar with Non-Collapsible Advanced Section
// ============================================================================

export function FullAccessLayout() {
  const navigate = useNavigate();
  
  return (
    <div className="app-layout">
      <DesktopSidebar
        hasUsedInventory={true}
        onNavigate={(path) => navigate(path)}
        collapsible={false}  // Always show advanced items
      />
      
      <main className="main-content">
        {/* Full access content */}
      </main>
    </div>
  );
}

// ============================================================================
// EXAMPLE 4: Using Desktop Sidebar Configuration Module Directly
// ============================================================================

import { 
  getDesktopSidebar, 
  getAllSidebarItems, 
  findSidebarItemByPath,
  getSidebarItemCounts,
  isAdvancedMenuItem 
} from '../navigation/desktopSidebar';

export function DirectConfigurationExample() {
  // Get sidebar structure
  const { core, advanced } = getDesktopSidebar(true);
  
  // Get all items
  const allItems = getAllSidebarItems(true);
  
  // Find specific item
  const invoicesItem = findSidebarItemByPath('/invoices', true);
  // Returns: { name: "Invoices", path: "/invoices", icon: "📄", ... }
  
  // Get item counts
  const counts = getSidebarItemCounts(true);
  // Returns: { core: 7, advanced: 6, total: 13 }
  
  // Check if item is advanced
  const isWalletAdvanced = isAdvancedMenuItem('/wallet', true);
  // Returns: true
  
  return (
    <div>
      <p>Total items: {counts.total}</p>
      <p>Core items: {counts.core}</p>
      <p>Advanced items: {counts.advanced}</p>
    </div>
  );
}

// ============================================================================
// EXAMPLE 5: Conditional Inventory Menu Item
// ============================================================================

export function SidebarWithFeatureTracking() {
  const [hasUsedInventory, setHasUsedInventory] = React.useState(false);
  const navigate = useNavigate();
  
  const handleInventoryAccess = () => {
    setHasUsedInventory(true);
    navigate('/inventory');
  };
  
  return (
    <div className="app-layout">
      <DesktopSidebar
        hasUsedInventory={hasUsedInventory}
        onNavigate={(path) => {
          if (path === '/inventory') {
            handleInventoryAccess();
          } else {
            navigate(path);
          }
        }}
      />
      
      <main className="main-content">
        {/* Content */}
      </main>
    </div>
  );
}

// ============================================================================
// EXAMPLE 6: Custom Sidebar with Search
// ============================================================================

import { searchSidebarItems } from '../navigation/desktopSidebar';

export function SearchableSidebar() {
  const [searchTerm, setSearchTerm] = React.useState('');
  const navigate = useNavigate();
  
  const results = searchTerm 
    ? searchSidebarItems(searchTerm, true) 
    : [];
  
  const handleSearchSelect = (path) => {
    navigate(path);
    setSearchTerm('');
  };
  
  return (
    <div className="app-layout">
      <aside className="desktop-sidebar">
        <div className="sidebar-search">
          <input
            type="text"
            placeholder="Search menu..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
          
          {searchTerm && results.length > 0 && (
            <ul className="search-results">
              {results.map((item) => (
                <li key={item.path}>
                  <button onClick={() => handleSearchSelect(item.path)}>
                    <span>{item.icon}</span>
                    <span>{item.name}</span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
        
        {!searchTerm && (
          <DesktopSidebar hasUsedInventory={true} />
        )}
      </aside>
      
      <main className="main-content">
        {/* Content */}
      </main>
    </div>
  );
}

// ============================================================================
// EXAMPLE 7: Sidebar with Custom Styling and Theming
// ============================================================================

export function ThemedSidebar() {
  const [isDarkMode, setIsDarkMode] = React.useState(false);
  const navigate = useNavigate();
  
  return (
    <div className={`app-layout ${isDarkMode ? 'dark-mode' : 'light-mode'}`}>
      <style>{`
        .desktop-sidebar {
          background-color: ${isDarkMode ? '#1e1e1e' : '#ffffff'};
          color: ${isDarkMode ? '#ffffff' : '#000000'};
          border-right: 1px solid ${isDarkMode ? '#333333' : '#e0e0e0'};
        }
        
        .sidebar-link:hover {
          background-color: ${isDarkMode ? '#333333' : '#f5f5f5'};
        }
        
        .sidebar-link.active {
          background-color: ${isDarkMode ? '#404040' : '#f0f0f0'};
          border-left: 3px solid #4CAF50;
        }
      `}</style>
      
      <DesktopSidebar
        hasUsedInventory={true}
        onNavigate={(path) => navigate(path)}
      />
      
      <main className="main-content">
        {/* Content */}
      </main>
    </div>
  );
}

// ============================================================================
// EXAMPLE 8: Responsive Sidebar (Desktop/Mobile Toggle)
// ============================================================================

import { ResponsiveNavigation } from './Navigation';

export function ResponsiveSidebarLayout() {
  const navigate = useNavigate();
  const [isMobile, setIsMobile] = React.useState(window.innerWidth < 768);
  
  React.useEffect(() => {
    const handleResize = () => {
      setIsMobile(window.innerWidth < 768);
    };
    
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);
  
  return (
    <div className="app-layout">
      {isMobile ? (
        // Mobile: Use bottom navigation
        <ResponsiveNavigation 
          onNavigate={(path) => navigate(path)}
        />
      ) : (
        // Desktop: Use sidebar
        <DesktopSidebar
          hasUsedInventory={true}
          onNavigate={(path) => navigate(path)}
        />
      )}
      
      <main className="main-content">
        {/* Content */}
      </main>
    </div>
  );
}

// ============================================================================
// EXAMPLE 9: Sidebar with Breadcrumb Integration
// ============================================================================

import { findSidebarItemByPath } from '../navigation/desktopSidebar';

export function SidebarWithBreadcrumbs() {
  const navigate = useNavigate();
  const location = useLocation();
  
  const currentItem = findSidebarItemByPath(location.pathname, true);
  
  return (
    <div className="app-layout">
      <DesktopSidebar
        hasUsedInventory={true}
        onNavigate={(path) => navigate(path)}
        activePath={location.pathname}
      />
      
      <div className="main-container">
        {currentItem && (
          <nav className="breadcrumb" aria-label="Breadcrumb">
            <ul>
              <li><a href="/">Home</a></li>
              <li aria-current="page">{currentItem.name}</li>
            </ul>
          </nav>
        )}
        
        <main className="main-content">
          {/* Content */}
        </main>
      </div>
    </div>
  );
}

// ============================================================================
// EXAMPLE 10: Sidebar with Usage Analytics
// ============================================================================

export function SidebarWithAnalytics() {
  const navigate = useNavigate();
  const [menuUsage, setMenuUsage] = React.useState({});
  
  const handleNavigate = (path) => {
    // Track menu usage
    setMenuUsage(prev => ({
      ...prev,
      [path]: (prev[path] || 0) + 1
    }));
    
    navigate(path);
  };
  
  return (
    <div className="app-layout">
      <DesktopSidebar
        hasUsedInventory={Object.keys(menuUsage).includes('/inventory')}
        onNavigate={handleNavigate}
      />
      
      <main className="main-content">
        {/* Content */}
      </main>
      
      {process.env.REACT_APP_DEBUG_MODE && (
        <aside className="debug-panel">
          <h3>Menu Usage</h3>
          <ul>
            {Object.entries(menuUsage).map(([path, count]) => (
              <li key={path}>{path}: {count} clicks</li>
            ))}
          </ul>
        </aside>
      )}
    </div>
  );
}

// ============================================================================
// CSS STYLING GUIDE
// ============================================================================

/*

.desktop-sidebar {
  position: fixed;
  left: 0;
  top: 0;
  width: 280px;
  height: 100vh;
  background-color: #ffffff;
  border-right: 1px solid #e0e0e0;
  overflow-y: auto;
  padding: 0;
  z-index: 100;
}

.sidebar-header {
  padding: 20px;
  border-bottom: 1px solid #e0e0e0;
}

.sidebar-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #333;
}

.sidebar-section {
  padding: 10px 0;
}

.sidebar-menu {
  list-style: none;
  margin: 0;
  padding: 0;
}

.sidebar-item {
  margin: 0;
  padding: 0;
}

.sidebar-link {
  display: flex;
  align-items: center;
  width: 100%;
  padding: 12px 20px;
  border: none;
  background: none;
  color: #555;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s ease;
}

.sidebar-link:hover {
  background-color: #f5f5f5;
  color: #333;
}

.sidebar-link.active {
  background-color: #f0f0f0;
  border-left: 3px solid #4CAF50;
  padding-left: 17px;
  color: #333;
}

.sidebar-icon {
  display: inline-block;
  width: 24px;
  margin-right: 12px;
  text-align: center;
  font-size: 16px;
}

.sidebar-name {
  flex: 1;
  text-align: left;
}

.advanced-toggle {
  display: flex;
  align-items: center;
  width: 100%;
  padding: 12px 20px;
  border: none;
  background: none;
  color: #555;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  text-transform: uppercase;
  margin-top: 10px;
}

.advanced-toggle:hover {
  background-color: #f5f5f5;
}

.advanced-toggle.open {
  background-color: #f0f0f0;
}

.toggle-icon {
  display: inline-block;
  width: 16px;
  margin-right: 8px;
  font-size: 12px;
  transition: transform 0.2s ease;
}

.advanced-menu {
  background-color: #fafafa;
  border-top: 1px solid #e0e0e0;
}

.advanced-link {
  padding-left: 40px !important;
}

.sidebar-footer {
  padding: 20px;
  text-align: center;
  border-top: 1px solid #e0e0e0;
  margin-top: 20px;
}

.employee-notice {
  font-size: 12px;
  color: #999;
  margin: 0;
}

.main-content {
  margin-left: 280px;
  padding: 20px;
}

@media (max-width: 768px) {
  .desktop-sidebar {
    display: none;
  }
  
  .main-content {
    margin-left: 0;
  }
}

*/
