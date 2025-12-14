/**
 * React Hook: useRole
 * 
 * Custom hook for managing user role state and detection
 * Handles authentication and role caching
 */

import { useState, useEffect, useCallback } from "react";
import { detectUserRole, watchUserRole } from "../auth/roleGuard";

/**
 * Hook to detect and manage user role
 * 
 * @returns {Object} { role, loading, error, refetch }
 */
export const useRole = () => {
  const [role, setRole] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let isMounted = true;

    const initRole = async () => {
      try {
        const detectedRole = await detectUserRole();
        if (isMounted) {
          setRole(detectedRole);
          setError(null);
        }
      } catch (err) {
        if (isMounted) {
          setError(err.message);
          setRole(null);
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    };

    initRole();

    return () => {
      isMounted = false;
    };
  }, []);

  const refetch = useCallback(async () => {
    setLoading(true);
    try {
      const detectedRole = await detectUserRole();
      setRole(detectedRole);
      setError(null);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, []);

  return { role, loading, error, refetch };
};

/**
 * Hook to watch role changes in real-time
 * Useful when role can change dynamically
 * 
 * @param {string} userId - User ID
 * @returns {Object} { role, loading, error }
 */
export const useWatchRole = (userId) => {
  const [role, setRole] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!userId) {
      setRole(null);
      setLoading(false);
      return;
    }

    setLoading(true);

    try {
      const unsubscribe = watchUserRole(userId, (newRole) => {
        setRole(newRole);
        setLoading(false);
        setError(null);
      });

      return unsubscribe;
    } catch (err) {
      setError(err.message);
      setLoading(false);
    }
  }, [userId]);

  return { role, loading, error };
};

/**
 * Hook to protect component based on role
 * 
 * @param {string|Array<string>} requiredRoles - Required role(s)
 * @param {Function} fallback - Component to show if access denied
 * @returns {Object} { hasAccess, role, loading }
 */
export const useRoleGuard = (requiredRoles, fallback = null) => {
  const { role, loading } = useRole();
  const rolesArray = Array.isArray(requiredRoles) ? requiredRoles : [requiredRoles];

  const hasAccess = role && rolesArray.includes(role);

  return {
    hasAccess,
    role,
    loading,
    fallback,
  };
};

/**
 * Hook for permission checking
 * 
 * @param {string} feature - Feature identifier
 * @returns {Object} { canAccess, permissions, loading }
 */
export const useFeatureAccess = (feature) => {
  const { role, loading } = useRole();
  const { canAccessFeature, getFeaturePermissions } = require("../services/accessControlService");

  const canAccess = canAccessFeature(role, feature);
  const permissions = getFeaturePermissions(role, feature);

  return {
    canAccess,
    permissions,
    loading,
  };
};

/**
 * Hook for route access checking
 * 
 * @param {string} routePath - Route path to check
 * @param {string} platform - Platform type (optional)
 * @returns {Object} { canAccess, loading, redirectTo }
 */
export const useRouteGuard = (routePath, platform = "web") => {
  const { role, loading } = useRole();
  const { canAccessRoute, getUnauthorizedRedirect } = require("../navigation/mobileRoutes");

  const canAccess = canAccessRoute(role, routePath, platform);
  const redirectTo = !canAccess ? getUnauthorizedRedirect(role, platform) : null;

  return {
    canAccess,
    loading,
    redirectTo,
  };
};

/**
 * Hook for getting visible navigation items
 * 
 * @param {string} platform - Platform type (optional)
 * @returns {Object} { features, routes, loading }
 */
export const useVisibleNavigation = (platform = "web") => {
  const { role, loading } = useRole();
  const { getCategorizedFeatures, getVisibleFeatures } = require("../services/accessControlService");
  const { getRoutesByRole } = require("../navigation/mobileRoutes");

  const features = getCategorizedFeatures(role, platform);
  const routes = getRoutesByRole(role, platform);

  return {
    features,
    routes,
    loading,
  };
};

/**
 * Hook for role-based rendering
 * Simpler alternative to useRoleGuard
 * 
 * @param {string|Array<string>} requiredRoles - Required role(s)
 * @returns {boolean} True if user has required role
 */
export const useHasRole = (requiredRoles) => {
  const { role, loading } = useRole();

  if (loading) return false;

  const rolesArray = Array.isArray(requiredRoles) ? requiredRoles : [requiredRoles];
  return rolesArray.includes(role);
};

/**
 * Hook for lazy role detection
 * Useful when you don't need role immediately
 * 
 * @returns {Object} { role, loading, detect }
 */
export const useLazyRole = () => {
  const [role, setRole] = useState(null);
  const [loading, setLoading] = useState(false);

  const detect = useCallback(async () => {
    setLoading(true);
    try {
      const detectedRole = await detectUserRole();
      setRole(detectedRole);
    } catch (error) {
      console.error("Error detecting role:", error);
      setRole(null);
    } finally {
      setLoading(false);
    }
  }, []);

  return { role, loading, detect };
};
