# Web RBAC Deployment Guide

## Prerequisites

- Node.js 16+ installed
- React 18+ knowledge
- Firebase project set up (matching Flutter backend)
- Firestore rules deployed (see [FIRESTORE_RBAC_DEPLOYMENT.md](../FIRESTORE_RBAC_DEPLOYMENT.md))
- Cloud Functions deployed (see [CLOUD_FUNCTIONS_RBAC_DEPLOYMENT.md](../CLOUD_FUNCTIONS_RBAC_DEPLOYMENT.md))

## Installation

### Step 1: Install Dependencies

```bash
cd web
npm install
```

**Key dependencies:**
```json
{
  "react": "^18.2.0",
  "react-dom": "^18.2.0",
  "react-router-dom": "^6.x.x",
  "firebase": "^10.x.x",
  "axios": "^1.x.x"
}
```

### Step 2: Setup Environment Variables

```bash
cp .env.example .env.development
cp .env.example .env.production
```

Edit `.env.development`:
```
REACT_APP_FIREBASE_API_KEY=your_dev_api_key
REACT_APP_FIREBASE_PROJECT_ID=your_dev_project_id
REACT_APP_ENV=development
REACT_APP_DEBUG_MODE=true
```

Edit `.env.production`:
```
REACT_APP_FIREBASE_API_KEY=your_prod_api_key
REACT_APP_FIREBASE_PROJECT_ID=your_prod_project_id
REACT_APP_ENV=production
REACT_APP_DEBUG_MODE=false
```

### Step 3: Verify Backend Setup

Before deploying web app, ensure:

1. **Firestore Rules Deployed**
```bash
firebase deploy --only firestore:rules
```

2. **Cloud Functions Deployed**
```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

3. **Firebase Authentication Enabled**
   - Enable Email/Password or Google Sign-In
   - Set up custom claims for roles

## Development

### Start Development Server

```bash
npm start
```

App will run at `http://localhost:3000`

### Development Checklist

- [ ] RBAC hooks working (role detection)
- [ ] Protected routes blocking unauthorized access
- [ ] Navigation showing correct menu items
- [ ] Firebase authentication connecting
- [ ] Role detection from custom claims

### Test Role Detection

Create `src/tests/roleDetection.test.js`:

```javascript
import { detectUserRole } from '../auth/roleGuard';

describe('Role Detection', () => {
  test('detects owner role', async () => {
    const role = await detectUserRole();
    expect(['owner', 'employee', null]).toContain(role);
  });
});
```

Run: `npm test -- roleDetection.test.js`

## Building for Production

### Create Optimized Build

```bash
npm run build
```

This creates:
- Minified JavaScript bundles
- Optimized CSS
- Source maps for debugging
- Build size report

### Build Output

```
build/
├── index.html          ← Entry point
├── static/
│   ├── js/             ← JavaScript bundles (chunked)
│   ├── css/            ← CSS files
│   └── media/          ← Images, fonts, etc.
└── favicon.ico
```

### Build Size Check

```bash
# Check build size
npm run build -- --stats

# Analyze bundles
npm run analyze  # if react-scripts > 5.0
```

**Typical sizes:**
- Main bundle: 200-300 KB (gzipped)
- Vendor bundle: 400-500 KB (gzipped)
- Total: 600-800 KB (gzipped)

## Deployment Options

### Option 1: Firebase Hosting (Recommended)

```bash
# Install Firebase tools
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy
firebase deploy --only hosting
```

**firebase.json:**
```json
{
  "hosting": {
    "public": "build",
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### Option 2: Vercel

```bash
npm i -g vercel
vercel --prod
```

### Option 3: Netlify

```bash
npm install -g netlify-cli
netlify deploy --prod --dir=build
```

### Option 4: AWS S3 + CloudFront

```bash
# Build
npm run build

# Upload to S3
aws s3 sync build/ s3://your-bucket-name/

# Invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id YOUR_DIST_ID \
  --paths "/*"
```

## Post-Deployment Verification

### 1. Verify Authentication

```bash
curl https://your-domain.com/
# Should redirect to login if not authenticated
```

### 2. Test Role-Based Access

**Test as Employee:**
- [ ] Can access `/tasks/assigned`
- [ ] Can access `/expenses/log`
- [ ] Cannot access `/invoices`
- [ ] Cannot access `/suppliers`
- [ ] Cannot access `/admin`

**Test as Owner:**
- [ ] Can access all routes
- [ ] Advanced features visible in navigation
- [ ] Can see all menu items

### 3. Verify Firestore Rules

```javascript
// This should succeed for owner
db.collection('invoices').getDocs()

// This should fail for employee
db.collection('suppliers').getDocs()
```

### 4. Check Console for Errors

```bash
# View application logs
firebase functions:log
```

### 5. Performance Monitoring

Add to App.jsx:
```javascript
import { performance } from 'web-vitals';

performance.mark('app-start');

// ... later ...

performance.mark('app-end');
performance.measure('app-load', 'app-start', 'app-end');
```

## Environment-Specific Configuration

### Development Environment

```bash
npm start  # Runs with .env.development
```

**Features enabled:**
- Debug logging
- Role override for testing
- Slower Firebase emulator if used
- Source maps for debugging

### Production Environment

```bash
npm run build && serve -s build
```

**Optimizations:**
- Debug logging disabled
- Source maps optimized
- Security headers required
- HTTPS enforced

## Security Checklist

- [ ] All Firestore rules deployed
- [ ] All Cloud Functions deployed
- [ ] Firebase Security Rules tested
- [ ] HTTPS enabled
- [ ] CORS configured properly
- [ ] Sensitive env vars in deployment platform (not in .env)
- [ ] Role override disabled in production
- [ ] Firebase Authentication enabled and configured
- [ ] Custom claims set via Cloud Functions
- [ ] Rate limiting configured (if using free tier)

## Troubleshooting Deployment

### Issue: "Firebase is not initialized"

**Solution:** Verify environment variables

```javascript
// In App.jsx
console.log('Firebase config:', {
  projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID,
  authDomain: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN,
  // ... other values
});
```

### Issue: "Role is null/undefined after deployment"

**Solution:** Check custom claims are set

```bash
# Check user has custom claims
firebase auth:get-user user@example.com
```

Should show:
```
customClaims: { "role": "owner" }
```

If not, check Cloud Functions:
```bash
firebase functions:log | grep -i "role"
```

### Issue: "Firestore rules reject valid requests"

**Solution:** Verify rules are deployed

```bash
firebase rules:describe firestore:rules
```

Check rule syntax:
```firestore
# Should allow owner to read invoices
match /invoices/{docId} {
  allow read: if isOwner();
}
```

### Issue: "CORS errors when calling Cloud Functions"

**Solution:** Add CORS headers to functions

```typescript
// In Cloud Function
import * as cors from 'cors';
const corsFn = cors({ origin: true });

export const myFunction = functions.https.onCall(corsFn, (req, res) => {
  // ...
});
```

## Rollback Procedure

If deployment has issues:

```bash
# View deployment history
firebase hosting:releases:list

# Rollback to previous version
firebase hosting:releases:rollback <RELEASE_ID>
```

## Monitoring and Logs

### Firebase Console

1. Go to Firebase Console
2. Select "Hosting"
3. View deployment history
4. Check analytics and error tracking

### Application Monitoring

Add to App.jsx:
```javascript
import * as Sentry from "@sentry/react";

Sentry.init({
  dsn: "your_sentry_dsn",
  environment: process.env.REACT_APP_ENV
});
```

## Continuous Deployment

### GitHub Actions

Create `.github/workflows/deploy-web.yml`:

```yaml
name: Deploy Web App

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - run: cd web && npm install
      - run: cd web && npm run build
      - run: npm test
      
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: 'your-project-id'
```

## Performance Optimization

### Code Splitting

Routes are automatically code-split by React Router:

```javascript
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Admin = lazy(() => import('./pages/Admin'));

<Suspense fallback={<Loading />}>
  <Routes>
    <Route path="/dashboard" element={<Dashboard />} />
    <Route path="/admin" element={<Admin />} />
  </Routes>
</Suspense>
```

### Image Optimization

Use optimized images:

```bash
# Convert to WebP
cwebp input.jpg -o output.webp

# Responsive images
<picture>
  <source srcSet="img.webp" type="image/webp" />
  <img src="img.jpg" alt="Description" />
</picture>
```

### Bundle Analysis

```bash
npm run build -- --stats-file=stats.json
npm install -g webpack-bundle-analyzer
webpack-bundle-analyzer stats.json
```

## Support and Documentation

- [Firebase Hosting Docs](https://firebase.google.com/docs/hosting)
- [React Deployment Guide](https://create-react-app.dev/docs/deployment/)
- [Web RBAC README](./README_RBAC.md)
- [Flutter RBAC Implementation](../RBAC_QUICK_REFERENCE.md)
