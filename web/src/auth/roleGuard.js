/**
 * Role Detection Guard
 * 
 * Detects and manages user role from Firebase Auth custom claims
 * Coordinates with Firestore for role persistence
 */

import { getAuth, onAuthStateChanged } from "firebase/auth";
import { getFirestore, doc, getDoc } from "firebase/firestore";

/**
 * Detect user role from auth token claims
 * Falls back to Firestore document if token claims unavailable
 * 
 * @returns {Promise<string|null>} Role ('owner', 'employee') or null if unauthenticated
 */
export const detectUserRole = async () => {
  return new Promise((resolve) => {
    const auth = getAuth();
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        try {
          // Get fresh token with custom claims
          const token = await user.getIdTokenResult(true);
          const role = token.claims.role || "owner"; // default fallback
          
          unsubscribe(); // stop listener
          resolve(role);
        } catch (error) {
          console.error("Error getting auth token:", error);
          unsubscribe();
          resolve("owner"); // default fallback on error
        }
      } else {
        unsubscribe();
        resolve(null);
      }
    });
  });
};

/**
 * Get role from Firestore user document
 * Used as fallback or for offline access
 * 
 * @param {string} uid - User ID
 * @returns {Promise<string|null>} Role from Firestore or null
 */
export const getUserRoleFromFirestore = async (uid) => {
  if (!uid) return null;
  
  try {
    const db = getFirestore();
    const userDoc = await getDoc(doc(db, "users", uid));
    
    if (userDoc.exists()) {
      return userDoc.data().role || "owner";
    }
    return "owner"; // default if doc doesn't exist
  } catch (error) {
    console.error("Error fetching role from Firestore:", error);
    return "owner"; // default fallback
  }
};

/**
 * Watch user role in real-time
 * Useful for updating UI when role changes
 * 
 * @param {string} uid - User ID
 * @param {Function} onRoleChange - Callback when role changes (role: string) => void
 * @returns {Function} Unsubscribe function
 */
export const watchUserRole = (uid, onRoleChange) => {
  if (!uid) return () => {};
  
  const db = getFirestore();
  const userDocRef = doc(db, "users", uid);
  
  const unsubscribe = onSnapshot(userDocRef, (docSnapshot) => {
    if (docSnapshot.exists()) {
      const role = docSnapshot.data().role || "owner";
      onRoleChange(role);
    }
  }, (error) => {
    console.error("Error watching role:", error);
    onRoleChange("owner"); // fallback
  });
  
  return unsubscribe;
};

/**
 * Check if user is authenticated and has a role
 * 
 * @returns {Promise<boolean>} True if authenticated with valid role
 */
export const isUserAuthenticated = async () => {
  const role = await detectUserRole();
  return role !== null;
};

/**
 * Get current user's role synchronously from local cache
 * For cases where async call isn't available
 * 
 * @returns {string|null} Cached role or null
 */
export let cachedRole = null;

/**
 * Initialize role cache on app startup
 * Call this in your App.js or main setup function
 */
export const initializeRoleCache = async () => {
  const auth = getAuth();
  const user = auth.currentUser;
  
  if (user) {
    const token = await user.getIdTokenResult(true);
    cachedRole = token.claims.role || "owner";
  } else {
    cachedRole = null;
  }
  
  return cachedRole;
};

/**
 * Enforce role on component render
 * Higher-order function for protecting components
 * 
 * @param {Function} Component - React component to protect
 * @param {string|string[]} requiredRoles - Role(s) required ('owner', 'employee', or both)
 * @returns {Function} Protected component
 */
export const withRoleGuard = (Component, requiredRoles) => {
  return (props) => {
    const [userRole, setUserRole] = React.useState(null);
    const [loading, setLoading] = React.useState(true);
    
    React.useEffect(() => {
      detectUserRole().then((role) => {
        setUserRole(role);
        setLoading(false);
      });
    }, []);
    
    if (loading) {
      return <div>Loading...</div>;
    }
    
    const rolesArray = Array.isArray(requiredRoles) ? requiredRoles : [requiredRoles];
    const hasAccess = userRole && rolesArray.includes(userRole);
    
    if (!hasAccess) {
      return <div>Access denied. Required role: {rolesArray.join(", ")}</div>;
    }
    
    return <Component {...props} userRole={userRole} />;
  };
};

/**
 * Manual role override for testing/admin purposes
 * NEVER use in production without proper security checks
 * 
 * @param {string} role - Role to set ('owner' or 'employee')
 */
export const overrideRoleForTesting = (role) => {
  if (process.env.NODE_ENV === "development") {
    cachedRole = role;
    console.warn(`Role overridden to: ${role} (development only)`);
  }
};

// Optional: Import for real-time updates
import { onSnapshot } from "firebase/firestore";
