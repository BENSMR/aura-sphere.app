# SUBSCRIPTION & PRICING SYSTEM - QUICK START

**Get up and running in 5 minutes**

---

## 🚀 30-Second Overview

AuraSphere Pro's subscription system provides:
- **4 pricing tiers** (Solo, Team, Business, Enterprise)
- **Feature access control** by plan tier
- **Usage limits enforcement** (invoices, storage, users, etc.)
- **Automatic pricing calculations** with yearly discounts
- **Complete Firestore integration** with security
- **Stripe payment hooks** ready to connect

Total code: 52 KB across 3 files

---

## 📋 5-Minute Setup

### Step 1: Import Core Module (30 seconds)

```javascript
import {
  isFeatureAvailable,
  isWithinLimits,
  calculatePrice,
  createSubscriptionRecord
} from './pricing/subscriptionTiers';
```

### Step 2: Add Subscription Field to Firestore Schema (1 minute)

Add to your `users` collection:

```json
{
  "subscription": {
    "tierId": "team",
    "plan": "Team",
    "price": 29,
    "billingCycle": "monthly",
    "startDate": "2024-01-15T00:00:00Z",
    "nextBillingDate": "2024-02-15T00:00:00Z",
    "status": "active",
    "trialEndsAt": "2024-01-29T00:00:00Z"
  },
  "usage": {
    "invoices": 45,
    "expenses": 120,
    "storage": 2048,
    "teamMembers": 3,
    "aiQueries": 250
  }
}
```

### Step 3: Create Pricing Page (2 minutes)

```jsx
import { PricingTable, FeatureComparison } from './components/SubscriptionComponents';

export function PricingPageComponent() {
  return (
    <div>
      <h1>Pricing</h1>
      <PricingTable currentPlanId="solo" onSelect={handleSelectPlan} />
      <FeatureComparison highlightTierId="solo" />
    </div>
  );
}
```

### Step 4: Protect Features (1 minute)

```javascript
// Check feature access
const hasAPIAccess = isFeatureAvailable('team', 'api_access');

// Check usage limits
const canCreateInvoice = isWithinLimits('team', 'invoices', userUsage.invoices);

if (!canCreateInvoice) {
  showMessage('Invoice limit reached. Upgrade your plan.');
}
```

### Step 5: Wire Stripe (1 minute)

See integration points below.

---

## 🎯 API Cheat Sheet

### Getting Tiers

```javascript
import { 
  getTierById,           // Get single tier
  getAllTiers,           // Get all tiers
  getRecommendedTier,    // Returns 'team' (most popular)
  SUBSCRIPTION_TIERS     // Raw tier object
} from './pricing/subscriptionTiers';

// Usage
const tier = getTierById('team');           // Single tier object
const allTiers = getAllTiers();             // Array of 4 tiers
const recommended = getRecommendedTier();   // 'team'
```

### Feature Access

```javascript
import { isFeatureAvailable } from './pricing/subscriptionTiers';

// Returns boolean
isFeatureAvailable('solo', 'ai_assistant');      // false
isFeatureAvailable('team', 'api_access');        // true
isFeatureAvailable('business', 'sso');           // true
isFeatureAvailable('enterprise', 'white_label'); // true
```

### Limits Enforcement

```javascript
import { isWithinLimits } from './pricing/subscriptionTiers';

// Returns boolean
isWithinLimits('team', 'invoices', 450);        // true (500 limit)
isWithinLimits('team', 'storage', 15000);       // false (10GB = 10240 MB)
isWithinLimits('business', 'team_members', 15); // true (20 limit)
```

### Pricing Calculations

```javascript
import { calculatePrice } from './pricing/subscriptionTiers';

// Returns { monthlyPrice, yearlyPrice, yearlyDiscount, savings }
const pricing = calculatePrice('team', 'monthly');
// → { monthlyPrice: 29, yearlyPrice: 348, yearlyDiscount: 0.2, savings: 60 }

const yearlyPricing = calculatePrice('team', 'yearly');
// → { monthlyPrice: 29, yearlyPrice: 278.4, yearlyDiscount: 0.2, savings: 69.6 }
```

### Roles by Tier

```javascript
import { getRolesByPlan } from './pricing/subscriptionTiers';

// Returns array of role IDs
getRolesByPlan('solo');      // ['owner']
getRolesByPlan('team');      // ['owner', 'manager', 'employee']
getRolesByPlan('business');  // ['owner', 'director', 'manager', 'hr', 'finance', 'sales', 'employee', 'viewer']
getRolesByPlan('enterprise'); // ['custom']
```

### Other Utilities

```javascript
import {
  getMaxTeamMembers,      // Returns number or 'unlimited'
  compareTiers,           // Compare features between tiers
  validateUpgrade,        // Validate upgrade path
  createSubscriptionRecord // Generate subscription object
} from './pricing/subscriptionTiers';

// Usage
getMaxTeamMembers('team');        // 5
getMaxTeamMembers('business');    // 20
getMaxTeamMembers('enterprise');  // 'unlimited'

compareTiers('solo', 'team');
// → { tier1: solo, tier2: team, differences: [...] }

validateUpgrade('solo', 'team');
// → { allowed: true, currentTier: 'solo', newTier: 'team', priceDifference: 20 }

createSubscriptionRecord('user-123', 'team', 'monthly');
// → { tierId: 'team', status: 'active', startDate: Date, nextBillingDate: Date, ... }
```

---

## 3️⃣ Common Scenarios

### Scenario 1: Feature Gate Before Showing Button

```jsx
import { isFeatureAvailable } from './pricing/subscriptionTiers';

function ReportFeature({ userTier }) {
  if (!isFeatureAvailable(userTier, 'advanced_reporting')) {
    return (
      <div className="locked">
        <p>Advanced reports available in Business plan</p>
        <button onClick={showUpgradeModal}>Upgrade</button>
      </div>
    );
  }

  return <AdvancedReports />;
}
```

### Scenario 2: Validate Before Creating Resource

```javascript
async function createInvoice(userId, invoiceData) {
  // Get user's tier and usage
  const user = await getUser(userId);
  const usage = user.usage.invoices;
  const tier = user.subscription.tierId;

  // Check limit
  if (!isWithinLimits(tier, 'invoices', usage + 1)) {
    throw new Error(`Invoice limit reached for ${tier} plan`);
  }

  // Create invoice
  const invoice = await db.collection('invoices').add(invoiceData);
  
  // Increment usage
  await updateDoc(doc(db, 'users', userId), {
    'usage.invoices': increment(1)
  });

  return invoice;
}
```

### Scenario 3: Show Usage Progress

```jsx
import { UsageTracker } from './components/SubscriptionComponents';

function DashboardWidget({ userTier, userUsage }) {
  return (
    <UsageTracker 
      tierId={userTier}
      usage={{
        invoices: userUsage.invoices,
        storage: userUsage.storageBytes,
        teamMembers: userUsage.teamMembers,
        aiQueries: userUsage.aiCalls
      }}
    />
  );
}
```

---

## 🧪 Testing Checklist

Before deploying, verify:

- [ ] Can access all 4 pricing tiers
- [ ] Feature gating blocks locked features
- [ ] Usage limits prevent resource creation
- [ ] Upgrade path works and updates Firestore
- [ ] Pricing shows correct yearly discount
- [ ] All 7 components render without errors
- [ ] Firestore security rules allow only user's own data
- [ ] Stripe test keys configured in Cloud Functions

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| Feature not gating | Check `features` object in SUBSCRIPTION_TIERS for that tier |
| Wrong price calculation | Verify `billingCycle` param is 'monthly' or 'yearly' |
| Limit not enforcing | Ensure `usage` field is set in Firestore user doc |
| Components not rendering | Import from correct path: `./components/SubscriptionComponents` |
| Firestore errors | Check security rules allow user to read/write `subscription` field |

---

## 📚 Full Documentation

For complete API reference, implementation patterns, and Stripe integration:

→ See [SUBSCRIPTION_DOCUMENTATION.md](./SUBSCRIPTION_DOCUMENTATION.md)

---

## 🎓 Examples

8 complete, production-ready examples:

→ See [SUBSCRIPTION_EXAMPLES.js](./SUBSCRIPTION_EXAMPLES.js)

1. Complete Pricing Page
2. Feature Gating
3. Usage Limit Enforcement
4. Plan Upgrade Flow
5. Team Member Management
6. Subscription Dashboard
7. Analytics Generation
8. Stripe Checkout

---

## 🚀 Next Steps

1. **Configure Firestore** - Add `subscription` and `usage` fields to users
2. **Add Pricing Page** - Use PricingTable and FeatureComparison components
3. **Implement Feature Gates** - Wrap features with `isFeatureAvailable` checks
4. **Connect Stripe** - Use example 8 as template for payment flow
5. **Set Security Rules** - Ensure users can only manage their own subscriptions
6. **Test Workflows** - Run through checklists above

---

## 💡 Pro Tips

✅ **Use `getRecommendedTier()`** when displaying pricing - highlights Team as most popular

✅ **Show annual savings** when billing cycle changes - $60 for Team annually

✅ **Display max members** before showing team add form - prevent confusion

✅ **Log all upgrades** to `subscriptionChanges` collection - audit trail

✅ **Use feature gating** at component level - cleaner UX than error messages

---

**Questions?** Check [SUBSCRIPTION_DOCUMENTATION.md](./SUBSCRIPTION_DOCUMENTATION.md) for complete guide.
