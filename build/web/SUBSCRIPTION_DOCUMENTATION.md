# SUBSCRIPTION & PRICING SYSTEM - DOCUMENTATION

## Overview

The Subscription System manages all pricing tiers, feature access, usage limits, and billing for AuraSphere Pro. It integrates with Stripe for payments, Firestore for persistence, and provides role-based feature access control.

**Key Features:**
- 4 pricing tiers (Solo → Team → Business → Enterprise)
- Dynamic feature matrices per tier
- Usage limits enforcement (invoices, storage, users, etc)
- Role-based access control (8 roles with tier constraints)
- Billing cycle flexibility (monthly/yearly with discounts)
- Upgrade/downgrade workflows
- Trial period management
- Payment method handling
- Usage tracking & alerts

---

## Files Overview

| File | Size | Purpose |
|------|------|---------|
| `web/src/pricing/subscriptionTiers.js` | 18 KB | Core subscription module with tiers, features, limits |
| `web/src/components/SubscriptionComponents.jsx` | 16 KB | 8 React components for pricing & billing UI |
| `web/SUBSCRIPTION_DOCUMENTATION.md` | This file | Complete API reference and implementation guide |
| `web/SUBSCRIPTION_EXAMPLES.js` | 14 KB | 8 implementation examples with code samples |
| `web/SUBSCRIPTION_QUICK_START.md` | 9 KB | Quick start guide and 5-minute integration |
| `web/SUBSCRIPTION_SUMMARY.md` | 10 KB | Executive summary and verification checklist |

---

## Pricing Tiers

### Solo Tier - $9/month
- **Users:** 1
- **Invoices:** 50/month
- **Storage:** 1 GB
- **AI Queries:** 50/month
- **Best For:** Freelancers, solo entrepreneurs
- **Key Features:** Basic invoicing, expense tracking, clients, tasks

### Team Tier - $29/month ⭐ Recommended
- **Users:** 5
- **Invoices:** 500/month
- **Storage:** 10 GB
- **AI Queries:** 500/month
- **Roles:** Owner, Manager, Employee
- **Best For:** Growing teams
- **Key Features:** All core features, team management, advanced AI, inventory

### Business Tier - $79/month
- **Users:** 20
- **Invoices:** 5,000/month
- **Storage:** 100 GB
- **AI Queries:** 5,000/month
- **Roles:** 8 custom roles available
- **Custom Features:** Yes
- **Best For:** Established businesses
- **Key Features:** All features, advanced analytics, custom dashboards, API access

### Enterprise Tier - Custom Pricing
- **Users:** Unlimited
- **Features:** All + custom development
- **Support:** 24/7 dedicated account manager
- **SLA:** Available
- **Best For:** Large organizations
- **Key Features:** White-label, unlimited everything, custom integrations

---

## API Reference

### Tier Retrieval

#### `getTierById(tierId)`
Get a specific tier by ID.

```javascript
const tier = getTierById('team');
// Returns: { id: 'team', name: 'Team', price: 29, features: {...}, ... }
```

#### `getAllTiers(includeEnterprise)`
Get all available tiers.

```javascript
const tiers = getAllTiers(true);
// Returns array of all 4 tiers
```

#### `getRecommendedTier()`
Get the recommended tier for display.

```javascript
const recommended = getRecommendedTier();
// Returns: Team tier (marked as recommended)
```

---

### Feature Access

#### `isFeatureAvailable(tierId, feature)`
Check if a feature is available in a tier.

```javascript
const hasAI = isFeatureAvailable('team', 'ai_pro');
// Returns: true
```

#### `isWithinLimits(tierId, limitKey, currentUsage)`
Validate usage against limits.

```javascript
const withinLimit = isWithinLimits('team', 'invoices', 450);
// Returns: true (under 500 limit)
```

---

### Pricing Calculations

#### `calculatePrice(tierId, billingCycle)`
Calculate pricing with discounts.

```javascript
const pricing = calculatePrice('team', 'yearly');
// Returns: {
//   yearlyPrice: 278.4,
//   billingCycle: 'yearly',
//   savings: 69.6,
//   savingsPercent: 20,
//   displayPrice: '$278.4/year'
// }
```

#### `compareTiers(tier1Id, tier2Id)`
Compare two tiers side-by-side.

```javascript
const comparison = compareTiers('team', 'business');
// Returns detailed feature comparison
```

---

### Subscription Management

#### `validateUpgrade(currentTierId, newTierId)`
Validate upgrade/downgrade eligibility.

```javascript
const result = validateUpgrade('solo', 'team');
// Returns: {
//   allowed: true,
//   isUpgrade: true,
//   priceDifference: 20,
//   priceChange: 'increase'
// }
```

#### `createSubscriptionRecord(userId, tierId, billingCycle)`
Create subscription for new user.

```javascript
const subscription = createSubscriptionRecord('user_123', 'team', 'monthly');
// Returns subscription object ready for Firestore
```

#### `formatSubscriptionStatus(subscription)`
Format status for display.

```javascript
const status = formatSubscriptionStatus(subscription);
// Returns: '✅ Active' or '⏳ Trial' etc
```

---

### Role Management

#### `getRolesByPlan(tierId)`
Get available roles for a tier.

```javascript
const roles = getRolesByPlan('team');
// Returns: ['owner', 'manager', 'employee']
```

#### `getMaxTeamMembers(tierId)`
Get user limit for tier.

```javascript
const maxUsers = getMaxTeamMembers('business');
// Returns: 20
```

---

## React Components

### PricingCard
Individual tier pricing card with features and action.

```jsx
<PricingCard 
  tier={SUBSCRIPTION_TIERS.team}
  isCurrentPlan={false}
  onSelect={(tierId) => handleSelect(tierId)}
  billingCycle="monthly"
/>
```

**Props:**
- `tier` - Tier object from SUBSCRIPTION_TIERS
- `isCurrentPlan` - Boolean, highlight if current
- `onSelect` - Callback with selected tier ID
- `billingCycle` - 'monthly' or 'yearly'

---

### PricingTable
Display all pricing cards in grid.

```jsx
<PricingTable 
  currentPlanId="team"
  onSelect={(tierId) => handleSelect(tierId)}
/>
```

---

### FeatureComparison
Detailed feature comparison table.

```jsx
<FeatureComparison highlightTierId="business" />
```

Shows all features across tiers with tabs for:
- Core Features
- AI & Automation
- Loyalty Program
- Integrations
- Usage Limits

---

### UpgradeModal
Modal for confirming plan changes.

```jsx
<UpgradeModal 
  currentTierId="team"
  newTierId="business"
  onConfirm={() => handleUpgrade()}
  onCancel={() => setShowModal(false)}
/>
```

---

### BillingManagement
Current subscription and billing controls.

```jsx
<BillingManagement 
  subscription={userSubscription}
  onChangePlan={(tierId) => handleChangePlan(tierId)}
/>
```

Shows:
- Current plan
- Billing cycle
- Next billing date
- Payment method
- Plan change interface

---

### UsageTracker
Display current usage vs limits.

```jsx
<UsageTracker 
  tierId="team"
  usage={{
    invoices: 450,
    storage: 8000,
    teamMembers: 4,
    aiQueries: 325
  }}
/>
```

---

### RoleAccessDisplay
Show available roles for tier.

```jsx
<RoleAccessDisplay tierId="business" />
```

---

## Implementation Guide

### Step 1: Add Subscription Fields to Firestore

```javascript
// users/{userId}/subscription document
{
  tierId: string,           // 'solo', 'team', 'business', 'enterprise'
  tierName: string,         // 'Team'
  billingCycle: string,     // 'monthly' or 'yearly'
  price: number,            // Current monthly price
  status: string,           // 'active', 'trialing', 'canceled'
  startDate: timestamp,     // When subscription started
  nextBillingDate: timestamp, // Next charge date
  trialEndsAt: timestamp,   // End of trial period
  autoRenew: boolean,       // Auto-renew on billing date
  paymentMethod: string,    // Stripe payment method ID
  stripeSubscriptionId: string, // Stripe subscription ID
  canceledAt: timestamp,    // When canceled (if applicable)
  metadata: object          // Features and limits snapshot
}
```

### Step 2: Create Pricing Page

```jsx
import { PricingTable, FeatureComparison } from './components/SubscriptionComponents';

export function PricingPage() {
  const [currentPlan, setCurrentPlan] = useState(null);
  
  return (
    <div className="pricing-page">
      <h1>Simple, Transparent Pricing</h1>
      <PricingTable 
        currentPlanId={currentPlan}
        onSelect={(tierId) => initiateCheckout(tierId)}
      />
      <FeatureComparison />
    </div>
  );
}
```

### Step 3: Add Subscription Management

```jsx
import { BillingManagement, UsageTracker } from './components/SubscriptionComponents';

export function SettingsPage({ user }) {
  return (
    <div className="settings">
      <BillingManagement 
        subscription={user.subscription}
        onChangePlan={handlePlanChange}
      />
      <UsageTracker 
        tierId={user.subscription.tierId}
        usage={user.usage}
      />
    </div>
  );
}
```

### Step 4: Implement Feature Gating

```javascript
import { isFeatureAvailable, isWithinLimits } from './pricing/subscriptionTiers';

// Check feature access
if (!isFeatureAvailable(userTier, 'api_access')) {
  return <UpgradePrompt feature="API Access" />;
}

// Check usage limits
if (!isWithinLimits(userTier, 'invoices', userUsage.invoices)) {
  return <LimitExceededModal />;
}
```

### Step 5: Wire Up Stripe Integration

```javascript
import { calculatePrice, createSubscriptionRecord } from './pricing/subscriptionTiers';

async function initiateCheckout(tierId) {
  const pricing = calculatePrice(tierId, 'monthly');
  
  const stripe = await loadStripe(STRIPE_KEY);
  const result = await stripe.redirectToCheckout({
    lineItems: [{
      price: STRIPE_PRICE_IDS[tierId],
      quantity: 1
    }],
    mode: 'subscription',
    successUrl: 'https://app.example.com/success',
    cancelUrl: 'https://app.example.com/pricing'
  });
}
```

---

## Firestore Collections

### users/{userId}/subscription
Stores current subscription status and details.

### billingHistory/{userId}/{chargeId}
Records of all charges and transactions.

### invoices/{userId}/{invoiceId}
Customer invoices for SaaS charges.

---

## Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /users/{userId}/subscription {
    allow read: if request.auth.uid == userId;
    allow update: if false; // Only backend updates
    allow create: if request.auth.uid == userId;
  }
  
  match /billingHistory/{userId}/{chargeId} {
    allow read: if request.auth.uid == userId;
    allow create, update: if false; // Backend only
  }
}
```

---

## Stripe Integration Points

1. **Create Subscription** - When user chooses plan
2. **Update Subscription** - When user upgrades/downgrades
3. **Handle Webhooks** - Payment success, failure, renewal
4. **Manage Payment Method** - Add/remove/update cards
5. **Cancel Subscription** - When user leaves

---

## Best Practices

1. **Always validate tier access** before showing features
2. **Check usage limits** before creating resources
3. **Enforce limits server-side** in Cloud Functions
4. **Show upgrade prompts** when limits approached
5. **Cache tier info** with user session
6. **Log tier changes** for audit trail
7. **Handle trial period** with special messaging
8. **Graceful degradation** when hitting limits
9. **Email notifications** for billing changes
10. **Annual discount** encourages yearly plans

---

## Usage Example: Full Integration

```javascript
// Check user has access to feature
async function checkFeatureAccess(userId, feature) {
  const userRef = doc(db, 'users', userId);
  const userDoc = await getDoc(userRef);
  const tierId = userDoc.data().subscription.tierId;
  
  if (!isFeatureAvailable(tierId, feature)) {
    throw new Error('Feature not available in your plan');
  }
  
  return true;
}

// Track usage and enforce limits
async function recordInvoice(userId, invoice) {
  const userRef = doc(db, 'users', userId);
  const userDoc = await getDoc(userRef);
  const tier = userDoc.data().subscription.tierId;
  const currentInvoices = userDoc.data().usage?.invoices || 0;
  
  if (!isWithinLimits(tier, 'invoices', currentInvoices + 1)) {
    throw new Error('Invoice limit exceeded for your plan');
  }
  
  // Create invoice...
  await updateDoc(userRef, {
    'usage.invoices': increment(1)
  });
}

// Handle upgrade
async function upgradeSubscription(userId, newTierId) {
  const result = validateUpgrade(
    currentUser.subscription.tierId,
    newTierId
  );
  
  if (!result.allowed) {
    throw new Error('Invalid upgrade');
  }
  
  // Redirect to Stripe
  initiateCheckout(newTierId);
}
```

---

## Next Steps

1. **Create pricing page** - Use PricingTable component
2. **Add subscription management** - Use BillingManagement
3. **Implement feature gating** - Use isFeatureAvailable checks
4. **Set up Stripe** - Configure webhooks and checkout
5. **Build admin dashboard** - Monitor subscriptions
6. **Create trial flow** - 14-30 day free trial
7. **Email notifications** - Trial ending, renewal, etc
8. **Usage analytics** - Track tier distribution, churn

