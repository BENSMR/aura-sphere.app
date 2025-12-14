# Web RBAC Quick Start Guide

## 5-Minute Setup

### 1. Install Dependencies (2 min)
```bash
cd web
npm install
```

### 2. Setup Environment (2 min)
```bash
cp .env.example .env.development
# Edit .env.development with your Firebase config values
```

### 3. Start Dev Server (1 min)
```bash
npm start
# App opens at http://localhost:3000
```

## Common Tasks

### Protect a Route

```jsx
import { ProtectedRoute } from './components/ProtectedRoute';

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

### Check User Role

```jsx
import { useRole } from './hooks/useRole';

function MyComponent() {
  const { role } = useRole();
  
  return <div>Your role: {role}</div>;
}
```

### Check Feature Access

```jsx
import { useFeatureAccess } from './hooks/useRole';

function MyComponent() {
  const { canAccess } = useFeatureAccess('invoices');
  
  if (!canAccess) return <div>Access Denied</div>;
  return <div>Invoice Content</div>;
}
```

### Show/Hide Content by Role

```jsx
import { RoleBasedRender } from './components/ProtectedRoute';

<RoleBasedRender requiredRoles="owner">
  <AdminPanel />
</RoleBasedRender>
```

### Add Navigation

```jsx
import { ResponsiveNavigation } from './components/Navigation';

function Layout() {
  return (
    <div>
      <ResponsiveNavigation onNavigate={setPath} activePath={path} />
      <main>{children}</main>
    </div>
  );
}
```

## Role/Feature Reference

### Roles
- `owner` — Full access to all features
- `employee` — Mobile-only, limited to 6 features

### Features (15 total)

**For Both Roles:**
- `dashboard` — Main dashboard
- `tasks` — Task management
- `expenses` — Expense tracking
- `clients` — Client management

**Owner Only:**
- `crm` — CRM system
- `invoices` — Invoice management
- `projects` — Project management
- `suppliers` — Supplier management
- `purchase_orders` — PO management
- `inventory` — Inventory tracking
- `finance` — Financial reports
- `loyalty` — Loyalty programs
- `wallet` — Wallet/billing
- `anomalies` — Anomaly detection
- `admin` — Admin panel

## Development Checklist

Before deploying:

- [ ] All protected routes have ProtectedRoute wrapper
- [ ] All features use useFeatureAccess hook
- [ ] Navigation uses ResponsiveNavigation component
- [ ] Testing passes: `npm test`
- [ ] Build succeeds: `npm run build`
- [ ] No console errors
- [ ] Environment variables set correctly
- [ ] Firebase rules deployed (see FIRESTORE_RBAC_DEPLOYMENT.md)

## Testing Roles Locally

```jsx
// In development, you can override role:
import { overrideRoleForTesting } from './auth/roleGuard';

// Simulate owner
overrideRoleForTesting('owner');

// Simulate employee
overrideRoleForTesting('employee');

// Reset to real role
overrideRoleForTesting(null);
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Role is null | Check Firebase Auth is initialized and user is logged in |
| Can't access protected route | Check Firestore rules are deployed (firebase deploy --only firestore:rules) |
| Features visible to wrong role | Check shouldShowAdvancedSection() is called before rendering |
| Build fails | Run `npm install` to ensure all deps are installed |

## Next Steps

1. Review [README_RBAC.md](./README_RBAC.md) for full API reference
2. See [INTEGRATION_EXAMPLES.jsx](./INTEGRATION_EXAMPLES.jsx) for code examples
3. Check [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for production setup

## Support Files

- **Role Detection:** `src/auth/roleGuard.js`
- **Routes:** `src/navigation/mobileRoutes.js`
- **Permissions:** `src/services/accessControlService.js`
- **React Hooks:** `src/hooks/useRole.js`
- **Components:** `src/components/ProtectedRoute.jsx`, `Navigation.jsx`

## FAQ

**Q: How do I assign a role to a new user?**
A: Use the Cloud Function `assignUserRole(userId, role)` from `functions/src/auth/setupUserRole.ts`

**Q: Can I test with different roles locally?**
A: Yes! Use `overrideRoleForTesting('owner')` in development.

**Q: Are Firestore rules checked on the web?**
A: Yes, Firestore will reject unauthorized requests regardless of client-side checks.

**Q: How do I update a user's role?**
A: Use the `changeUserRole(userId, newRole)` Cloud Function.

**Q: Does this work offline?**
A: Partially. Firestore can cache data, but role detection requires internet for first load.

## Related Documentation

- Flutter RBAC: `../RBAC_QUICK_REFERENCE.md`
- Backend Setup: `../FIRESTORE_RBAC_DEPLOYMENT.md`
- Cloud Functions: `../CLOUD_FUNCTIONS_RBAC_DEPLOYMENT.md`
