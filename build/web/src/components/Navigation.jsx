/**
 * Role-Based Navigation Component
 * 
 * Example sidebar/navigation component that shows
 * different menu items based on user role
 */

import React, { useState } from "react";
import { useRole } from "../hooks/useRole";
import { getCategorizedFeatures, shouldShowAdvancedSection } from "../services/accessControlService";
import { getMobileRoutes, getDesktopRoutes } from "../navigation/mobileRoutes";

/**
 * Navigation Component
 * Shows menu items based on user role and platform
 * 
 * @param {Object} props
 * @param {string} props.platform - Platform type ('mobile', 'web', 'desktop')
 * @param {Function} props.onNavigate - Callback when user clicks nav item
 */
export const Navigation = ({ platform = "web", onNavigate = () => {} }) => {
  const { role, loading } = useRole();
  const [expandAdvanced, setExpandAdvanced] = useState(false);

  if (loading) {
    return <nav>Loading navigation...</nav>;
  }

  if (!role) {
    return <nav>Please log in</nav>;
  }

  const features = getCategorizedFeatures(role, platform);
  const showAdvanced = shouldShowAdvancedSection(role, platform);

  return (
    <nav className={`navigation navigation-${platform}`}>
      <div className="nav-section">
        <h3>Navigation</h3>
        <ul className="nav-items">
          {features.main.map((feature) => (
            <li key={feature}>
              <button
                className="nav-item"
                onClick={() => onNavigate(feature)}
              >
                {featureToLabel(feature)}
              </button>
            </li>
          ))}
        </ul>
      </div>

      {showAdvanced && (
        <div className="nav-section advanced-section">
          <button
            className="nav-section-toggle"
            onClick={() => setExpandAdvanced(!expandAdvanced)}
          >
            {expandAdvanced ? "▼" : "▶"} Advanced
          </button>
          {expandAdvanced && (
            <ul className="nav-items">
              {features.advanced.map((feature) => (
                <li key={feature}>
                  <button
                    className="nav-item"
                    onClick={() => onNavigate(feature)}
                  >
                    {featureToLabel(feature)}
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}

      <div className="nav-section user-info">
        <p className="role-badge">Role: {role}</p>
        <p className="platform-badge">Platform: {platform}</p>
      </div>
    </nav>
  );
};

/**
 * Mobile Bottom Navigation
 * Optimized for mobile/employee experience
 * 
 * @param {Object} props
 * @param {Function} props.onNavigate - Callback when user clicks
 * @param {string} props.activePath - Current active route
 */
export const MobileBottomNav = ({ onNavigate, activePath }) => {
  const { role, loading } = useRole();

  if (loading) return null;
  if (!role) return null;

  const routes = getMobileRoutes(role);

  return (
    <nav className="mobile-bottom-nav">
      <ul className="nav-tabs">
        {routes.map((route) => (
          <li key={route.path} className={activePath === route.path ? "active" : ""}>
            <button
              className="nav-tab-button"
              onClick={() => onNavigate(route.path)}
              title={route.description || route.name}
            >
              <span className="tab-icon">{route.icon || "•"}</span>
              <span className="tab-name">{route.name}</span>
            </button>
          </li>
        ))}
      </ul>
    </nav>
  );
};

/**
 * Desktop Sidebar
 * Full navigation for desktop/owner experience
 * 
 * @param {Object} props
 * @param {Function} props.onNavigate - Callback
 * @param {string} props.activePath - Current route
 */
export const DesktopSidebar = ({ onNavigate, activePath }) => {
  const { role, loading } = useRole();
  const [expandAdvanced, setExpandAdvanced] = useState(false);

  if (loading) return null;
  if (!role) return null;

  const routes = getDesktopRoutes(role);
  const mainRoutes = routes.filter((r) => r.category !== "Advanced");
  const advancedRoutes = routes.filter((r) => r.category === "Advanced");

  return (
    <aside className="desktop-sidebar">
      <div className="sidebar-header">
        <h2>AuraSphere</h2>
        <p className="user-role">{role}</p>
      </div>

      {/* Main Navigation */}
      <div className="nav-section main-nav">
        <h3>Main</h3>
        <ul className="nav-items">
          {mainRoutes.map((route) => (
            <li key={route.path}>
              <button
                className={`nav-item ${activePath === route.path ? "active" : ""}`}
                onClick={() => onNavigate(route.path)}
              >
                <span className="icon">{route.icon}</span>
                <span className="label">{route.name}</span>
              </button>
            </li>
          ))}
        </ul>
      </div>

      {/* Advanced Navigation (Owner only) */}
      {advancedRoutes.length > 0 && (
        <div className="nav-section advanced-nav">
          <button
            className="advanced-toggle"
            onClick={() => setExpandAdvanced(!expandAdvanced)}
          >
            <span className="toggle-icon">{expandAdvanced ? "▼" : "▶"}</span>
            <span>Advanced</span>
          </button>

          {expandAdvanced && (
            <ul className="nav-items advanced-items">
              {advancedRoutes.map((route) => (
                <li key={route.path}>
                  <button
                    className={`nav-item ${activePath === route.path ? "active" : ""}`}
                    onClick={() => onNavigate(route.path)}
                  >
                    <span className="icon">{route.icon}</span>
                    <span className="label">{route.name}</span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </aside>
  );
};

/**
 * Responsive Navigation
 * Automatically switches between mobile and desktop based on screen size
 * 
 * @param {Object} props
 * @param {Function} props.onNavigate - Callback
 * @param {string} props.activePath - Current route
 */
export const ResponsiveNavigation = ({ onNavigate, activePath }) => {
  const [platform, setPlatform] = React.useState(
    window.innerWidth < 768 ? "mobile" : "desktop"
  );

  React.useEffect(() => {
    const handleResize = () => {
      setPlatform(window.innerWidth < 768 ? "mobile" : "desktop");
    };

    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  if (platform === "mobile") {
    return <MobileBottomNav onNavigate={onNavigate} activePath={activePath} />;
  }

  return <DesktopSidebar onNavigate={onNavigate} activePath={activePath} />;
};

/**
 * Helper function: Convert feature identifier to display label
 * 
 * @param {string} feature - Feature identifier
 * @returns {string} Display label
 */
function featureToLabel(feature) {
  return feature
    .split("_")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

export default Navigation;
