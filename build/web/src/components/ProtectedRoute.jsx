/**
 * Protected Route Component
 * 
 * Example component for route protection
 * Checks user role before rendering page
 */

import React from "react";
import { useRole } from "../hooks/useRole";
import { canAccessRoute } from "../navigation/mobileRoutes";

/**
 * ProtectedRoute Component
 * Wraps a route to enforce role-based access
 * 
 * @param {Object} props
 * @param {React.Component} props.component - Component to render
 * @param {string|Array<string>} props.requiredRoles - Required role(s)
 * @param {string} props.path - Route path
 * @param {React.Component} props.fallback - Component to show if denied
 */
export const ProtectedRoute = ({
  component: Component,
  requiredRoles,
  path,
  fallback: FallbackComponent,
  ...rest
}) => {
  const { role, loading } = useRole();

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  const rolesArray = Array.isArray(requiredRoles) ? requiredRoles : [requiredRoles];
  const hasAccess = role && rolesArray.includes(role);

  if (!hasAccess) {
    if (FallbackComponent) {
      return <FallbackComponent />;
    }

    return (
      <div className="access-denied">
        <h1>Access Denied</h1>
        <p>You don't have permission to access this page.</p>
        <p>Required role: {rolesArray.join(", ")}</p>
      </div>
    );
  }

  return <Component {...rest} userRole={role} />;
};

/**
 * Conditional Render Component
 * Shows/hides content based on user role
 * 
 * @param {Object} props
 * @param {React.ReactNode} props.children - Content to show if access granted
 * @param {string|Array<string>} props.requiredRoles - Required role(s)
 * @param {React.ReactNode} props.fallback - Content to show if denied
 */
export const RoleBasedRender = ({
  children,
  requiredRoles,
  fallback = null,
}) => {
  const { role, loading } = useRole();

  if (loading) {
    return null;
  }

  const rolesArray = Array.isArray(requiredRoles) ? requiredRoles : [requiredRoles];
  const hasAccess = role && rolesArray.includes(role);

  if (!hasAccess) {
    return fallback;
  }

  return children;
};

/**
 * Feature Visibility Component
 * Shows/hides features based on feature access rules
 * 
 * @param {Object} props
 * @param {React.ReactNode} props.children - Content
 * @param {string} props.feature - Feature identifier
 * @param {React.ReactNode} props.fallback - Fallback content
 */
export const FeatureVisible = ({
  children,
  feature,
  fallback = null,
}) => {
  const { role, loading } = useRole();
  const { canAccessFeature } = require("../services/accessControlService");

  if (loading) {
    return null;
  }

  const hasAccess = canAccessFeature(role, feature);

  if (!hasAccess) {
    return fallback;
  }

  return children;
};

export default ProtectedRoute;
