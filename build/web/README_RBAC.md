# Web RBAC Implementation Guide

## Overview

This is a React/JavaScript implementation of the AuraSphere Pro Role-Based Access Control (RBAC) system. It mirrors the Flutter implementation while providing web-specific utilities and patterns.

## File Structure

```
web/
├── src/
│   ├── auth/
│   │   └── roleGuard.js              ← Role detection from Firebase
│   ├── navigation/
│   │   └── mobileRoutes.js           ← Route definitions by role
│   ├── services/
│   │   └── accessControlService.js   ← Permission checking logic
│   ├── hooks/
│   │   └── useRole.js                ← React hooks for role management
│   ├── components/
│   │   ├── ProtectedRoute.jsx        ← Route protection component
│   │   └── Navigation.jsx            ← Role-based navigation UI
│   ├── pages/
│   │   ├── LoginPage.jsx
│   │   ├── DashboardPage.jsx
│   │   ├── TasksPage.jsx
│   │   ├── ExpensesPage.jsx
│   │   └── ... (other pages)
│   └── App.jsx                       ← Main app with routing
└── package.json
```

## Key Concepts

### 1. Role Detection (`auth/roleGuard.js`)

```javascript
import { detectUserRole } from './auth/roleGuard';

// Get user's role from Firebase Auth custom claims
const role = await detectUserRole();
// Returns: 'owner' | 'employee' | null
```

**Features:**
- Reads role from Firebase Auth token claims
- Falls back to Firestore document if needed
- Caches role for performance
- Includes real-time watching capability

### 2. Route Management (`navigation/mobileRoutes.js`)

```javascript
import { getMobileRoutes, getDesktopRoutes } from './navigation/mobileRoutes';

// Get routes for employee on mobile
const routes = getMobileRoutes('employee');
// Returns: Array of 6 employee routes

// Get all routes for owner on desktop
const routes = getDesktopRoutes('owner');
// Returns: All 15 routes
```

**Employee Routes (6):**
- `/tasks/assigned` — Assigned tasks
- `/expenses/log` — Create/log expenses
- `/clients/view/:id` — View assigned clients
- `/jobs/complete/:id` — Mark jobs complete
- `/profile` — User profile
- `/sync-status` — Sync status

**Owner Routes (15):**
- All 7 main routes (Dashboard, CRM, Clients, Invoices, Tasks, Expenses, Projects)
- All 8 advanced routes (Suppliers, POs, Inventory, Finance, Loyalty, Wallet, Anomalies, Admin)

### 3. Access Control (`services/accessControlService.js`)

```javascript
import { 
  canAccessFeature, 
  getVisibleFeatures,
  shouldShowAdvancedSection 
} from './services/accessControlService';

// Check permission
const canView = canAccessFeature('employee', 'invoices');
// Returns: false

// Get all visible features
const features = getVisibleFeatures('owner', 'web');
// Returns: Array of 15 feature identifiers

// Check if advanced section shows
const showAdvanced = shouldShowAdvancedSection('owner', 'web');
// Returns: true
```

### 4. React Hooks (`hooks/useRole.js`)

```javascript
import { useRole, useFeatureAccess, useRouteGuard } from './hooks/useRole';

function MyComponent() {
  // Get current user's role
  const { role, loading } = useRole();

  // Check feature access
  const { canAccess, permissions } = useFeatureAccess('invoices');

  // Guard route
  const { canAccess: canViewRoute, redirectTo } = useRouteGuard('/admin');

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      <p>Your role: {role}</p>
      <p>Can view invoices: {canAccess}</p>
    </div>
  );
}
```

## Usage Examples

### Example 1: Protected Route

```jsx
import { ProtectedRoute } from './components/ProtectedRoute';
import InvoicesPage from './pages/InvoicesPage';

function App() {
  return (
    <Routes>
      <Route
        path="/invoices"
        element={
          <ProtectedRoute
            component={InvoicesPage}
            requiredRoles="owner"
            fallback={<div>Access Denied</div>}
          />
        }
      />
    </Routes>
  );
}
```

### Example 2: Conditional Rendering

```jsx
import { RoleBasedRender } from './components/ProtectedRoute';

function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>

      {/* Show advanced section only for owners on web */}
      <RoleBasedRender requiredRoles="owner">
        <section>
          <h2>Advanced Features</h2>
          <p>Owner-only content here</p>
        </section>
      </RoleBasedRender>

      {/* Show alternative for employees */}
      <RoleBasedRender 
        requiredRoles="employee" 
        fallback={<p>Available to employees only</p>}
      >
        <section>
          <h2>Employee Features</h2>
        </section>
      </RoleBasedRender>
    </div>
  );
}
```

### Example 3: Navigation Component

```jsx
import { ResponsiveNavigation } from './components/Navigation';

function App() {
  const [currentPath, setCurrentPath] = useState('/dashboard');

  return (
    <div className="app-layout">
      {/* Automatically switches between mobile bottom nav and desktop sidebar */}
      <ResponsiveNavigation 
        onNavigate={setCurrentPath}
        activePath={currentPath}
      />

      <main>
        {/* Page content */}
      </main>
    </div>
  );
}
```

### Example 4: Custom Hook Usage

```jsx
import { useHasRole, useVisibleNavigation } from './hooks/useRole';

function MyComponent() {
  // Simple role check
  const isOwner = useHasRole('owner');

  // Get navigation items for current user
  const { features, routes } = useVisibleNavigation('web');

  return (
    <>
      {isOwner && <AdminPanel />}
      
      <nav>
        {routes.map(route => (
          <NavItem key={route.path} route={route} />
        ))}
      </nav>
    </>
  );
}
```

## Security Best Practices

### 1. Always Protect Routes

```jsx
// ❌ WRONG - Client-side check only
function InvoicesPage() {
  const { role } = useRole();
  
  if (role !== 'owner') {
    return <div>Not authorized</div>;
  }
  
  // User could bypass this in browser console
  return <InvoicesContent />;
}

// ✅ RIGHT - Use ProtectedRoute
<Route
  path="/invoices"
  element={
    <ProtectedRoute
      component={InvoicesPage}
      requiredRoles="owner"
    />
  }
/>
```

### 2. Firestore Rules Enforce Access

Even if a user bypasses client-side checks, Firestore rules prevent unauthorized access:

```firestore
match /invoices/{docId} {
  allow read, write: if isOwner();
}
```

### 3. Token Refresh

Always refresh the token when role changes:

```javascript
const token = await user.getIdTokenResult(true); // Force refresh
const role = token.claims.role;
```

## Configuration

### Environment Variables

Create `.env` file:

```
REACT_APP_FIREBASE_API_KEY=your_api_key
REACT_APP_FIREBASE_AUTH_DOMAIN=your_auth_domain
REACT_APP_FIREBASE_PROJECT_ID=your_project_id
REACT_APP_FIREBASE_STORAGE_BUCKET=your_storage_bucket
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
REACT_APP_FIREBASE_APP_ID=your_app_id
```

### Firebase Configuration

Update `auth/roleGuard.js` if using different Firebase instance:

```javascript
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
```

## Common Patterns

### Pattern 1: Lazy Loading

Load user role only when needed:

```jsx
import { useLazyRole } from './hooks/useRole';

function MyComponent() {
  const { role, loading, detect } = useLazyRole();

  return (
    <button onClick={detect}>
      {loading ? 'Detecting role...' : `Detected: ${role}`}
    </button>
  );
}
```

### Pattern 2: Role Change Detection

Watch for role changes in real-time:

```jsx
import { useWatchRole } from './hooks/useRole';

function AdminPanel({ userId }) {
  const { role, loading } = useWatchRole(userId);

  return <div>Current role: {role}</div>;
}
```

### Pattern 3: Feature Permission Checking

```jsx
import { getFeaturePermissions } from './services/accessControlService';

function Editor({ feature }) {
  const { role } = useRole();
  const perms = getFeaturePermissions(role, feature);

  return (
    <>
      {perms?.canRead && <ReadButton />}
      {perms?.canCreate && <CreateButton />}
      {perms?.canUpdate && <EditButton />}
      {perms?.canDelete && <DeleteButton />}
    </>
  );
}
```

## Testing

### Test Protected Route

```javascript
import { render, screen } from '@testing-library/react';
import { ProtectedRoute } from './components/ProtectedRoute';

jest.mock('./hooks/useRole', () => ({
  useRole: () => ({ role: 'employee', loading: false })
}));

test('blocks employee from owner route', () => {
  render(
    <ProtectedRoute
      component={() => <div>Owner Content</div>}
      requiredRoles="owner"
    />
  );
  
  expect(screen.getByText('Access Denied')).toBeInTheDocument();
});
```

### Test Role Hook

```javascript
import { renderHook } from '@testing-library/react';
import { useRole } from './hooks/useRole';

jest.mock('./auth/roleGuard', () => ({
  detectUserRole: () => Promise.resolve('owner')
}));

test('detects user role', async () => {
  const { result } = renderHook(() => useRole());
  
  await waitFor(() => {
    expect(result.current.role).toBe('owner');
  });
});
```

## Performance Optimization

### 1. Memoize Role Checks

```jsx
import { useMemo } from 'react';
import { getVisibleFeatures } from './services/accessControlService';

function MyComponent() {
  const { role } = useRole();

  // Only recompute when role changes
  const visibleFeatures = useMemo(
    () => getVisibleFeatures(role),
    [role]
  );

  return <Navigation features={visibleFeatures} />;
}
```

### 2. Cache Role in Context

```jsx
import { createContext, useContext, useEffect, useState } from 'react';
import { detectUserRole } from './auth/roleGuard';

const RoleContext = createContext();

export function RoleProvider({ children }) {
  const [role, setRole] = useState(null);

  useEffect(() => {
    detectUserRole().then(setRole);
  }, []);

  return (
    <RoleContext.Provider value={role}>
      {children}
    </RoleContext.Provider>
  );
}

export function useContextRole() {
  return useContext(RoleContext);
}
```

### 3. Lazy Load Advanced Features

```jsx
import { lazy, Suspense } from 'react';
import { shouldShowAdvancedSection } from './services/accessControlService';

const AdvancedFeatures = lazy(() => import('./pages/AdvancedFeatures'));

function App() {
  const { role } = useRole();

  return (
    <>
      {shouldShowAdvancedSection(role) && (
        <Suspense fallback={<div>Loading...</div>}>
          <AdvancedFeatures />
        </Suspense>
      )}
    </>
  );
}
```

## Troubleshooting

### Issue: "Role is always null"

**Solution:** Ensure user is authenticated before checking role

```javascript
const auth = getAuth();
if (auth.currentUser) {
  const role = await detectUserRole();
} else {
  // Redirect to login
}
```

### Issue: "Role doesn't update when changed"

**Solution:** Force token refresh after role assignment

```javascript
const user = getAuth().currentUser;
await user.getIdTokenResult(true); // Force refresh
```

### Issue: "Advanced features visible to employees"

**Solution:** Check `shouldShowAdvancedSection()` before rendering

```javascript
const { role } = useRole();
const showAdvanced = shouldShowAdvancedSection(role);

{showAdvanced && <AdvancedSection />}
```

## Deployment

### Build for Production

```bash
npm run build
```

### Environment Setup

Ensure all Firebase environment variables are set in deployment platform:

```bash
export REACT_APP_FIREBASE_PROJECT_ID=aurasphere-pro
export REACT_APP_FIREBASE_API_KEY=your_key
# ... other vars
```

### Firebase Rules Verification

Before deploying, verify Firestore rules are in place:

```bash
firebase rules:describe firestore:rules
```

## Integration with Backend

The web app expects the same Firebase setup as Flutter:

1. **Custom Claims:** Cloud Functions set `role` in auth token
2. **Firestore:** `users/{uid}` document with `role` field
3. **Security Rules:** Enforce role in `request.auth.token.role`

See `FIRESTORE_RBAC_DEPLOYMENT.md` for backend setup.

## Further Reading

- [Flutter Implementation](../RBAC_QUICK_REFERENCE.md)
- [Firestore Rules](../FIRESTORE_RBAC_DEPLOYMENT.md)
- [Firebase Auth Custom Claims](https://firebase.google.com/docs/auth/admin-sdk-setup)
- [React Hooks Documentation](https://react.dev/reference/react)

## Support

For issues or questions:
1. Check `FIRESTORE_RBAC_TESTING.md` for test scenarios
2. Review `RBAC_QUICK_REFERENCE.md` for API reference
3. See `troubleshooting` section above
