/**
 * Desktop Sidebar Component
 * Displays role-based navigation menu for desktop users
 * 
 * Features:
 * - Conditional inventory menu item based on usage
 * - Collapsible advanced section
 * - Active route highlighting
 * - Icon display with tooltips
 * - Search functionality (optional)
 * - Responsive design
 * 
 * @component
 */

import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { getDesktopSidebar, isAdvancedMenuItem } from './desktopSidebar';
import { useRole } from '../hooks/useRole';

/**
 * DesktopSidebar Component
 * 
 * @param {Object} props
 * @param {boolean} [props.hasUsedInventory=false] - Whether to show inventory menu
 * @param {string} [props.activePath] - Currently active route path
 * @param {Function} [props.onNavigate] - Callback when menu item clicked
 * @param {boolean} [props.showAdvanced=true] - Whether to show advanced section
 * @param {boolean} [props.collapsible=true] - Whether advanced section is collapsible
 * @returns {React.ReactElement} Desktop sidebar component
 * 
 * @example
 * <DesktopSidebar 
 *   hasUsedInventory={true}
 *   onNavigate={(path) => navigate(path)}
 *   collapsible={true}
 * />
 */
export const DesktopSidebar = ({
  hasUsedInventory = false,
  activePath = null,
  onNavigate = null,
  showAdvanced = true,
  collapsible = true
}) => {
  const navigate = useNavigate();
  const location = useLocation();
  const { role } = useRole();
  
  const [isAdvancedOpen, setIsAdvancedOpen] = useState(false);
  const [activeItem, setActiveItem] = useState(activePath || location.pathname);
  
  const { core, advanced } = getDesktopSidebar(hasUsedInventory);
  
  // Only show advanced section if user is owner
  const canAccessAdvanced = role === 'owner';
  const displayAdvanced = showAdvanced && canAccessAdvanced;
  
  const handleNavigate = (path) => {
    setActiveItem(path);
    if (onNavigate) {
      onNavigate(path);
    } else {
      navigate(path);
    }
  };
  
  const toggleAdvanced = (e) => {
    e.preventDefault();
    setIsAdvancedOpen(!isAdvancedOpen);
  };
  
  return (
    <aside className="desktop-sidebar" role="navigation" aria-label="Main navigation">
      {/* Sidebar Header */}
      <div className="sidebar-header">
        <h2 className="sidebar-title">AuraSphere Pro</h2>
      </div>
      
      {/* Core Navigation Items */}
      <nav className="sidebar-section sidebar-core" aria-label="Core navigation">
        <ul className="sidebar-menu">
          {core.map((item) => (
            <li key={item.path} className="sidebar-item">
              <button
                className={`sidebar-link ${activeItem === item.path ? 'active' : ''}`}
                onClick={() => handleNavigate(item.path)}
                title={item.description}
                aria-current={activeItem === item.path ? 'page' : undefined}
              >
                <span className="sidebar-icon">{item.icon}</span>
                <span className="sidebar-name">{item.name}</span>
              </button>
            </li>
          ))}
        </ul>
      </nav>
      
      {/* Advanced Section */}
      {displayAdvanced && (
        <nav className="sidebar-section sidebar-advanced" aria-label="Advanced features">
          {/* Advanced Toggle Button */}
          <button
            className={`advanced-toggle ${isAdvancedOpen ? 'open' : ''}`}
            onClick={toggleAdvanced}
            aria-expanded={isAdvancedOpen}
            aria-controls="advanced-menu"
            disabled={!collapsible}
          >
            <span className="toggle-icon">
              {collapsible ? (isAdvancedOpen ? '▼' : '▶') : ''}
            </span>
            <span className="toggle-label">Advanced Features</span>
          </button>
          
          {/* Advanced Menu Items */}
          {(isAdvancedOpen || !collapsible) && (
            <ul id="advanced-menu" className="sidebar-menu advanced-menu">
              {advanced.map((item) => (
                <li key={item.path} className="sidebar-item">
                  <button
                    className={`sidebar-link advanced-link ${activeItem === item.path ? 'active' : ''}`}
                    onClick={() => handleNavigate(item.path)}
                    title={item.description}
                    aria-current={activeItem === item.path ? 'page' : undefined}
                  >
                    <span className="sidebar-icon">{item.icon}</span>
                    <span className="sidebar-name">{item.name}</span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </nav>
      )}
      
      {/* Employee Notice */}
      {!canAccessAdvanced && (
        <div className="sidebar-footer">
          <p className="employee-notice">
            Advanced features available to owners only
          </p>
        </div>
      )}
    </aside>
  );
};

/**
 * Sidebar Menu Item Component (for custom styling)
 * 
 * @param {Object} props
 * @param {string} props.path - Route path
 * @param {string} props.name - Display name
 * @param {string} props.icon - Icon/emoji
 * @param {string} props.description - Item description
 * @param {boolean} [props.isActive=false] - Whether item is active
 * @param {Function} props.onClick - Click handler
 * @returns {React.ReactElement}
 */
export const SidebarMenuItem = ({
  path,
  name,
  icon,
  description,
  isActive = false,
  onClick
}) => {
  return (
    <li className="sidebar-item">
      <button
        className={`sidebar-link ${isActive ? 'active' : ''}`}
        onClick={() => onClick(path)}
        title={description}
        aria-current={isActive ? 'page' : undefined}
      >
        <span className="sidebar-icon">{icon}</span>
        <span className="sidebar-name">{name}</span>
      </button>
    </li>
  );
};

/**
 * Sidebar Divider (visual separator)
 * 
 * @returns {React.ReactElement}
 */
export const SidebarDivider = () => (
  <div className="sidebar-divider" role="separator" aria-hidden="true" />
);

/**
 * Sidebar Section (for custom organization)
 * 
 * @param {Object} props
 * @param {string} [props.title] - Section title
 * @param {React.ReactNode} props.children - Menu items
 * @param {string} [props.className] - CSS class
 * @returns {React.ReactElement}
 */
export const SidebarSection = ({ title, children, className = '' }) => (
  <nav className={`sidebar-section ${className}`} aria-label={title}>
    {title && <h3 className="section-title">{title}</h3>}
    <ul className="sidebar-menu">
      {children}
    </ul>
  </nav>
);

export default DesktopSidebar;
