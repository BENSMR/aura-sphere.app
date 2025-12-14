# Web RBAC Integration Checklist

Use this checklist to verify your web RBAC implementation is complete and working correctly.

## Pre-Integration Setup

- [ ] Node.js 16+ installed
- [ ] React 18+ project created
- [ ] Firebase project initialized
- [ ] `.env.development` and `.env.production` files created
- [ ] Firebase authentication enabled
- [ ] Firestore database created
- [ ] Firestore rules deployed (`firebase deploy --only firestore:rules`)
- [ ] Cloud Functions deployed (`firebase deploy --only functions`)

## File Setup (Part 1: Core Files)

### Authentication & Role Detection

- [ ] `src/auth/roleGuard.js` created
- [ ] `src/auth/roleGuard.js` has `detectUserRole()` function
- [ ] `src/auth/roleGuard.js` has `getUserRoleFromFirestore()` function
- [ ] `src/auth/roleGuard.js` has `watchUserRole()` function
- [ ] `src/auth/roleGuard.js` has `initializeRoleCache()` function
- [ ] `src/auth/roleGuard.js` has `withRoleGuard()` HOC
- [ ] `src/auth/roleGuard.js` has `overrideRoleForTesting()` function (dev only)
- [ ] `src/auth/roleGuard.js` has `cachedRole` variable
- [ ] No syntax errors in roleGuard.js: ✅

### Navigation & Routes

- [ ] `src/navigation/mobileRoutes.js` created
- [ ] `src/navigation/mobileRoutes.js` has `EMPLOYEE_ROUTES` array (6 routes)
- [ ] `src/navigation/mobileRoutes.js` has `OWNER_MAIN_ROUTES` array (7 routes)
- [ ] `src/navigation/mobileRoutes.js` has `OWNER_ADVANCED_ROUTES` array (8 routes)
- [ ] `src/navigation/mobileRoutes.js` has `getRoutesByRole()` function
- [ ] `src/navigation/mobileRoutes.js` has `getMobileRoutes()` function
- [ ] `src/navigation/mobileRoutes.js` has `getDesktopRoutes()` function
- [ ] `src/navigation/mobileRoutes.js` has `canAccessRoute()` function
- [ ] `src/navigation/mobileRoutes.js` has `getGroupedRoutes()` function
- [ ] `src/navigation/mobileRoutes.js` has `getRoutesByPermission()` function
- [ ] No syntax errors in mobileRoutes.js: ✅

### Access Control Service

- [ ] `src/services/accessControlService.js` created
- [ ] `src/services/accessControlService.js` has `FEATURES` constant (15 features)
- [ ] `src/services/accessControlService.js` has `FEATURE_ACCESS` object
- [ ] `src/services/accessControlService.js` has `canAccessFeature()` function
- [ ] `src/services/accessControlService.js` has `canAccessFeatureOnPlatform()` function
- [ ] `src/services/accessControlService.js` has `getVisibleFeatures()` function
- [ ] `src/services/accessControlService.js` has `getCategorizedFeatures()` function
- [ ] `src/services/accessControlService.js` has `shouldShowAdvancedSection()` function
- [ ] `src/services/accessControlService.js` has `getAccessSummary()` function
- [ ] `src/services/accessControlService.js` has `getFeaturePermissions()` function
- [ ] `src/services/accessControlService.js` has `hasFeaturePermission()` function
- [ ] No syntax errors in accessControlService.js: ✅

## File Setup (Part 2: React Components & Hooks)

### React Hooks

- [ ] `src/hooks/useRole.js` created
- [ ] `src/hooks/useRole.js` exports `useRole()` hook
- [ ] `src/hooks/useRole.js` exports `useWatchRole()` hook
- [ ] `src/hooks/useRole.js` exports `useRoleGuard()` hook
- [ ] `src/hooks/useRole.js` exports `useFeatureAccess()` hook
- [ ] `src/hooks/useRole.js` exports `useRouteGuard()` hook
- [ ] `src/hooks/useRole.js` exports `useVisibleNavigation()` hook
- [ ] `src/hooks/useRole.js` exports `useHasRole()` hook
- [ ] `src/hooks/useRole.js` exports `useLazyRole()` hook
- [ ] No syntax errors in useRole.js: ✅

### Protected Components

- [ ] `src/components/ProtectedRoute.jsx` created
- [ ] `src/components/ProtectedRoute.jsx` exports `<ProtectedRoute>` component
- [ ] `src/components/ProtectedRoute.jsx` exports `<RoleBasedRender>` component
- [ ] `src/components/ProtectedRoute.jsx` exports `<FeatureVisible>` component
- [ ] ProtectedRoute shows fallback UI when access denied
- [ ] RoleBasedRender accepts requiredRoles prop
- [ ] FeatureVisible accepts feature prop
- [ ] No syntax errors in ProtectedRoute.jsx: ✅

### Navigation Components

- [ ] `src/components/Navigation.jsx` created
- [ ] `src/components/Navigation.jsx` exports `<Navigation>` component
- [ ] `src/components/Navigation.jsx` exports `<MobileBottomNav>` component
- [ ] `src/components/Navigation.jsx` exports `<DesktopSidebar>` component
- [ ] `src/components/Navigation.jsx` exports `<ResponsiveNavigation>` component
- [ ] MobileBottomNav shows 5 employee tabs when appropriate
- [ ] DesktopSidebar shows main + advanced sections for owner
- [ ] ResponsiveNavigation switches at 768px breakpoint
- [ ] No syntax errors in Navigation.jsx: ✅

### Main App

- [ ] `src/App.jsx` created
- [ ] `src/App.jsx` initializes Firebase config from env vars
- [ ] `src/App.jsx` has Router setup
- [ ] `src/App.jsx` has example routes for all 21 endpoints
- [ ] `src/App.jsx` uses ProtectedRoute wrapper for routes
- [ ] All routes in App.jsx have appropriate role guards
- [ ] No syntax errors in App.jsx: ✅

## Configuration Files

### Environment Variables

- [ ] `.env.example` created with all required variables
- [ ] `.env.development` created from `.env.example`
- [ ] `.env.production` created from `.env.example`
- [ ] All Firebase config values filled in `.env.development`
- [ ] All Firebase config values filled in `.env.production`
- [ ] REACT_APP_FIREBASE_API_KEY set
- [ ] REACT_APP_FIREBASE_AUTH_DOMAIN set
- [ ] REACT_APP_FIREBASE_PROJECT_ID set
- [ ] REACT_APP_FIREBASE_STORAGE_BUCKET set
- [ ] REACT_APP_FIREBASE_MESSAGING_SENDER_ID set
- [ ] REACT_APP_FIREBASE_APP_ID set

### Package Configuration

- [ ] `package.json` created
- [ ] `package.json` has react dependency
- [ ] `package.json` has react-dom dependency
- [ ] `package.json` has react-router-dom dependency
- [ ] `package.json` has firebase dependency
- [ ] `package.json` has npm start script
- [ ] `package.json` has npm run build script
- [ ] `package.json` has npm test script
- [ ] `package.json` has npm run deploy script (optional)

## Firebase Integration

### Authentication Setup

- [ ] Firebase Auth enabled in Firebase Console
- [ ] Email/Password sign-in enabled (or OAuth2)
- [ ] Custom claims enabled for role assignment
- [ ] Firebase Admin SDK initialized in Cloud Functions

### Firestore Rules Verification

- [ ] Firestore rules deployed to Firebase
- [ ] Rules include `isOwner()` function
- [ ] Rules include `isEmployee()` function
- [ ] `/invoices` collection protected with isOwner()
- [ ] `/suppliers` collection protected with isOwner()
- [ ] `/wallet` collection protected with isOwner()
- [ ] Other owner-only collections protected
- [ ] Employee routes only access allowed collections

### Cloud Functions

- [ ] `functions/src/auth/setupUserRole.ts` exists
- [ ] `onUserCreate()` function deployed
- [ ] `assignUserRole()` function deployed
- [ ] `changeUserRole()` function deployed
- [ ] `getUserRole()` function deployed
- [ ] `listAllUsers()` function deployed
- [ ] Functions setting role in custom claims
- [ ] Functions updating Firestore `users.{uid}` document

## Development Verification

### Local Development

- [ ] `npm install` completes without errors
- [ ] `npm start` starts dev server successfully
- [ ] App loads at `http://localhost:3000`
- [ ] Firebase initialization shows no errors
- [ ] Console shows no critical errors (warnings OK)

### Role Detection

- [ ] User can log in with email/password
- [ ] `useRole()` hook detects role correctly
- [ ] Role persists on page refresh
- [ ] Role updates when changed in Firestore
- [ ] Development role override works: `overrideRoleForTesting('owner')`

### Route Protection

- [ ] Employee cannot access `/suppliers` route
- [ ] Employee cannot access `/admin` route
- [ ] Employee can access `/tasks/assigned` route
- [ ] Owner can access all routes
- [ ] Unauthorized routes show fallback/error page
- [ ] Route guards in ProtectedRoute work correctly

### Navigation

- [ ] ResponsiveNavigation shows bottom tabs on mobile (<768px)
- [ ] ResponsiveNavigation shows sidebar on desktop (>768px)
- [ ] Mobile nav shows 6 employee routes (when employee)
- [ ] Desktop nav shows all routes (when owner)
- [ ] Advanced features section collapse/expand (owner only)
- [ ] Active route highlighted in navigation
- [ ] Navigation updates when role changes

### Feature Access

- [ ] `useFeatureAccess('invoices')` returns canAccess=false for employee
- [ ] `useFeatureAccess('tasks')` returns canAccess=true for employee
- [ ] `useFeatureAccess('invoices')` returns canAccess=true for owner
- [ ] `getVisibleFeatures('employee')` returns 6 features
- [ ] `getVisibleFeatures('owner')` returns 15 features
- [ ] `shouldShowAdvancedSection('owner')` returns true
- [ ] `shouldShowAdvancedSection('employee')` returns false

### Component Protection

- [ ] `<RoleBasedRender requiredRoles="owner">` hides content from employee
- [ ] `<FeatureVisible feature="invoices">` hides content from employee
- [ ] Fallback UI shows when access denied
- [ ] Content renders when role has access

## Testing

### Unit Tests

- [ ] Test `canAccessFeature()` with various roles
- [ ] Test `getVisibleFeatures()` returns correct count
- [ ] Test `shouldShowAdvancedSection()` logic
- [ ] Test `getMobileRoutes()` vs `getDesktopRoutes()`
- [ ] Test hook initial state and loading state

### Integration Tests

- [ ] Test protected route blocks unauthorized access
- [ ] Test role change re-renders protected content
- [ ] Test navigation updates on role change
- [ ] Test feature visibility matches permissions
- [ ] Test multiple roles in one app session

### Manual Testing Scenarios

**Scenario 1: Employee Access Pattern**
- [ ] Login as employee
- [ ] Can see dashboard, tasks, expenses, clients only
- [ ] Cannot see suppliers, invoices, admin
- [ ] Mobile-only: bottom nav shows 6 items
- [ ] Try accessing `/suppliers` → redirected

**Scenario 2: Owner Access Pattern**
- [ ] Login as owner
- [ ] Can see all main features
- [ ] Advanced section visible and collapsible
- [ ] Desktop: sidebar shows all 15 routes
- [ ] Can access any route without restriction

**Scenario 3: Role Change**
- [ ] Login as employee
- [ ] Assign owner role via Cloud Function
- [ ] UI automatically updates (advanced features appear)
- [ ] New routes become accessible
- [ ] Navigation refreshes to show all options

**Scenario 4: Session Recovery**
- [ ] Login as owner
- [ ] Refresh page
- [ ] Role persists (caching works)
- [ ] All routes still accessible
- [ ] No re-authentication needed immediately

## Performance Checks

- [ ] Initial page load < 3 seconds
- [ ] Role detection < 100ms (after cache)
- [ ] Route guard < 50ms
- [ ] Feature check < 1ms
- [ ] Navigation render < 200ms
- [ ] No console warnings (only info logs)
- [ ] No memory leaks (check DevTools)

## Security Verification

- [ ] Cannot access employee data as owner (if implemented)
- [ ] Cannot access owner data as employee
- [ ] Firestore rules reject unauthorized requests
- [ ] Role override disabled in production
- [ ] Environment variables not exposed in build
- [ ] No credentials in client-side code
- [ ] HTTPS enforced in production

## Deployment Checklist

### Pre-Deployment

- [ ] All tests passing: `npm test`
- [ ] Build succeeds: `npm run build`
- [ ] No console errors
- [ ] No TypeScript errors (if using TS)
- [ ] Environment variables configured
- [ ] Firestore rules deployed
- [ ] Cloud Functions deployed
- [ ] Firebase Auth configured

### Deployment

- [ ] Build artifacts ready: `build/` directory
- [ ] Firebase Hosting configured
- [ ] Deployment script configured: `npm run deploy`
- [ ] Performance baseline established
- [ ] Error tracking configured (optional: Sentry, etc.)

### Post-Deployment

- [ ] App loads in production
- [ ] Role detection works in production
- [ ] Protected routes working in production
- [ ] Navigation displays correctly
- [ ] No console errors in production
- [ ] Firebase rules enforced
- [ ] Performance metrics acceptable

## Documentation

- [ ] README_RBAC.md reviewed
- [ ] QUICK_START.md reviewed
- [ ] DEPLOYMENT_GUIDE.md reviewed
- [ ] INTEGRATION_EXAMPLES.jsx reviewed
- [ ] Code comments added to custom components
- [ ] Team documentation updated
- [ ] API changes documented

## Final Sign-Off

- [ ] All checklist items completed
- [ ] Code reviewed by team
- [ ] Security review passed
- [ ] Performance acceptable
- [ ] Ready for production
- [ ] Deployment scheduled
- [ ] Rollback plan documented

---

## Troubleshooting Quick Reference

| Issue | Checklist Item | Solution |
|-------|---|---|
| Role is null | Firebase Integration → Auth | Check user is logged in |
| Routes all accessible | Route Protection | Check ProtectedRoute wrapper |
| Features visible to wrong role | Feature Access | Check shouldShowAdvancedSection |
| Build fails | Package.json | Run `npm install` |
| Firebase not initialized | Config Files | Check `.env` variables |

## Sign-Off

**Completed By:** _________________  
**Date:** _________________  
**Reviewed By:** _________________  
**Date:** _________________  

---

**Version:** 1.0  
**Last Updated:** 2024  
**Status:** Ready for Implementation
