# LOYALTY PROGRAM - COMPLETE DOCUMENTATION

## Overview

The Loyalty Program is a sophisticated multi-tier customer rewards system designed to increase customer retention, encourage repeat purchases, and build long-term relationships. Customers earn points with every purchase, unlock tier benefits through spending, and can redeem points for discounts.

**Key Features:**
- 4 loyalty tiers (Bronze → Silver → Gold → Platinum) with escalating benefits
- Points accumulation with tier-based multipliers (1x to 2x)
- Automatic tier progression based on lifetime points
- Points redemption system ($1 off per 100 points)
- Milestone rewards for spending milestones ($100, $250, $500, $1000, $2500, $5000)
- Referral bonuses (100 points per successful referral)
- Birthday bonuses with tier-based scaling
- Comprehensive Firestore integration for persistence
- Complete React component library
- Real-time tier progress tracking
- Analytics and statistics

---

## Table of Contents

1. [Files Overview](#files-overview)
2. [Tier System](#tier-system)
3. [Core Functions API](#core-functions-api)
4. [React Components](#react-components)
5. [Implementation Guide](#implementation-guide)
6. [Firestore Integration](#firestore-integration)
7. [Usage Examples](#usage-examples)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Files Overview

| File | Size | Purpose |
|------|------|---------|
| `web/src/loyalty/loyaltyProgram.js` | 14 KB | Core loyalty module with tier definitions, calculations, and business logic |
| `web/src/components/LoyaltyComponents.jsx` | 12 KB | 10 React components + loyalty widgets for UI |
| `web/LOYALTY_DOCUMENTATION.md` | This file | Complete API reference and integration guide |
| `web/LOYALTY_EXAMPLES.js` | 15 KB | 8 implementation examples with code samples |
| `web/LOYALTY_QUICK_START.md` | 10 KB | Quick start guide and 5-minute integration |
| `web/LOYALTY_SUMMARY.md` | 8 KB | Executive summary and verification checklist |

---

## Tier System

### Bronze Tier (0-499 points)
- **Discount:** 0%
- **Points Multiplier:** 1x
- **Benefits:**
  - Join loyalty program
  - Earn 1 point per dollar spent
  - Birthday bonus: 25 points
- **Entry:** Automatic upon signup

### Silver Tier (500-1,499 points)
- **Discount:** 5%
- **Points Multiplier:** 1.25x
- **Benefits:**
  - 5% discount on all purchases
  - Earn 1.25 points per dollar spent
  - Birthday bonus: 50 points
  - Free shipping on orders $50+
- **Unlock:** 500 points

### Gold Tier (1,500-4,999 points)
- **Discount:** 10%
- **Points Multiplier:** 1.5x
- **Benefits:**
  - 10% discount on all purchases
  - Earn 1.5 points per dollar spent
  - Birthday bonus: 100 points
  - Free shipping on all orders
  - Priority customer support
  - Early access to sales
- **Unlock:** 1,500 points

### Platinum Tier (5,000+ points)
- **Discount:** 15%
- **Points Multiplier:** 2x
- **Benefits:**
  - 15% discount on all purchases
  - Earn 2 points per dollar spent
  - Birthday bonus: 250 points
  - Free shipping on all orders
  - VIP customer support (24/7)
  - Early access to sales & new products
  - Exclusive events & offers
  - Personal account manager
  - Free premium gifts quarterly
- **Unlock:** 5,000 points

---

## Core Functions API

### Point Calculations

#### `calculatePointsEarned(amount, tier, options)`
Calculate points earned from a purchase.

```javascript
import { calculatePointsEarned } from './loyalty/loyaltyProgram';

// Basic purchase
const points = calculatePointsEarned(100, 'silver');
// Returns: 125 (100 * 1.25x multiplier)

// With bonuses
const points = calculatePointsEarned(100, 'gold', {
  isFirstPurchase: true,    // 2x multiplier
  isDuringPromotion: true,  // 1.5x multiplier
  referralBonus: true       // +50 points
});
// Returns: ~450 points
```

**Parameters:**
- `amount` (number): Purchase amount in dollars
- `tier` (string): Loyalty tier ('bronze', 'silver', 'gold', 'platinum')
- `options` (object):
  - `isFirstPurchase` (bool): Apply 2x multiplier
  - `isDuringPromotion` (bool): Apply 1.5x multiplier
  - `referralBonus` (bool): Add 50 bonus points

**Returns:** Integer points earned

---

#### `getTierFromPoints(points)`
Determine tier based on points.

```javascript
import { getTierFromPoints } from './loyalty/loyaltyProgram';

const tier = getTierFromPoints(2000);
// Returns: LOYALTY_TIERS.GOLD
```

**Parameters:**
- `points` (number): Current loyalty points

**Returns:** Tier object with id, name, benefits, etc.

---

#### `getTierProgress(points)`
Get detailed tier progression information.

```javascript
const progress = getTierProgress(1200);
// Returns: {
//   currentTier: { id: 'silver', ... },
//   nextTier: { id: 'gold', ... },
//   progress: 47,           // 47% to next tier
//   pointsInTier: 700,
//   pointsNeededForNext: 300,
//   isMaxTier: false
// }
```

**Parameters:**
- `points` (number): Current loyalty points

**Returns:** Object with tier info and progress percentage

---

### Discount Management

#### `applyLoyaltyDiscount(amount, tier)`
Calculate discount for given tier.

```javascript
const result = applyLoyaltyDiscount(100, 'gold');
// Returns: {
//   original: 100,
//   discountPercent: 10,
//   discountAmount: 10,
//   final: 90
// }
```

**Parameters:**
- `amount` (number): Original amount
- `tier` (string): Loyalty tier

**Returns:** Object with discount breakdown

---

### Points Redemption

#### `calculateRedeemablePoints(pointsAvailable)`
Calculate how many points can be redeemed for discount.

```javascript
const redemption = calculateRedeemablePoints(750);
// Returns: {
//   canRedeem: true,
//   redeemablePoints: 700,
//   dollarValue: 7,        // $7 off (100 pts = $1)
//   remaining: 50,
//   reason: null
// }
```

**Parameters:**
- `pointsAvailable` (number): Current point balance

**Returns:** Object with redemption info
- Minimum: 500 points ($5)
- Maximum per month: 3,000 points ($30)

---

### Profile Building

#### `buildLoyaltyProfile(clientDoc)`
Create complete loyalty profile from Firestore document.

```javascript
const profile = buildLoyaltyProfile(clientData);
// Returns: {
//   tier: {...},
//   points: 2500,
//   tierProgress: {...},
//   redeemable: {...},
//   totalSpent: 1500,
//   totalPurchases: 15,
//   lastPurchaseDate: '2024-12-01',
//   daysSinceLastPurchase: 12,
//   memberDays: 365,
//   stats: {
//     discountsSaved: '150.00',
//     nextRewardAt: '5000 points (2500 more)'
//   },
//   ...
// }
```

---

### Milestone Rewards

#### `checkMilestoneReward(totalSpent, claimedMilestones)`
Check if customer qualifies for milestone reward.

```javascript
const milestone = checkMilestoneReward(750, ['$100 lifetime']);
// Returns: {
//   milestone: { totalSpent: 500, reward: 150, label: '$500 lifetime' },
//   rewardPoints: 150,
//   isClaimed: false
// }
```

**Milestones:**
- $100 spent → 50 points
- $250 spent → 100 points
- $500 spent → 150 points
- $1000 spent → 250 points
- $2500 spent → 500 points
- $5000 spent → 1000 points

---

### Referral Management

#### `calculateReferralBonus(successfulReferrals)`
Calculate total referral bonus points.

```javascript
const bonus = calculateReferralBonus(3);
// Returns: 300 (3 referrals × 100 points)
```

---

#### `calculateBirthdayBonus(tier)`
Get birthday bonus for tier.

```javascript
const bonus = calculateBirthdayBonus('platinum');
// Returns: 250 (25 base × 2x multiplier for Platinum)
```

---

### Statistics

#### `aggregateLoyaltyStats(profiles)`
Generate loyalty program statistics.

```javascript
const stats = aggregateLoyaltyStats(clientProfiles);
// Returns: {
//   totalMembers: 156,
//   byTier: { bronze: 40, silver: 60, gold: 45, platinum: 11 },
//   totalPointsIssued: 425000,
//   averagePointsPerMember: 2724,
//   totalSavedInDiscounts: 12500
// }
```

---

## React Components

### LoyaltyStatusCard
Main loyalty status display with tier badge, points, and next milestone.

```jsx
import { LoyaltyStatusCard } from './components/LoyaltyComponents';

<LoyaltyStatusCard 
  clientData={clientData}
  onAction={(action) => handleAction(action)}
/>
```

**Props:**
- `clientData` (object): Firestore client document
- `onAction` (function): Callback for actions (viewBenefits)

---

### TierShowcase
Display all 4 tiers with unlock status.

```jsx
<TierShowcase 
  currentPoints={2500}
  onUpgrade={(tierId) => handleUpgrade(tierId)}
/>
```

**Props:**
- `currentPoints` (number): Current point balance
- `onUpgrade` (function): Callback when tier selected

---

### PointsRedemption
Redemption interface for converting points to discounts.

```jsx
<PointsRedemption 
  currentPoints={1500}
  onRedeem={(pointsToRedeem) => handleRedemption(pointsToRedeem)}
/>
```

**Props:**
- `currentPoints` (number): Available points
- `onRedeem` (function): Callback with redemption amount

---

### LoyaltyStats
Comprehensive statistics dashboard.

```jsx
<LoyaltyStats clientData={clientData} />
```

**Displays:**
- Member since (days)
- Total purchases
- Lifetime spending
- Discounts saved
- Breakdown by source

---

### LoyaltyDiscountToggle
Simple toggle to apply loyalty discount (enhanced version of user's original code).

```jsx
<LoyaltyDiscountToggle 
  clientId="client_123"
  currentTier="gold"
  onToggle={async (discountData) => {
    await updateDoc(doc(db, 'clients', discountData.clientId), {
      loyaltyDiscount: discountData.loyaltyDiscount,
      tier: discountData.tier,
      appliedAt: discountData.appliedAt
    });
  }}
/>
```

**Props:**
- `clientId` (string): Firestore client ID
- `currentTier` (string): Current loyalty tier
- `onToggle` (function): Callback with discount data

---

### LoyaltyWidget
Compact sidebar/dashboard widget.

```jsx
<LoyaltyWidget 
  clientData={clientData}
  onExpand={() => setShowFullDashboard(true)}
/>
```

---

### ReferralTracker
Manage and share referral links.

```jsx
<ReferralTracker 
  referrals={clientData.referrals}
  referralBonus={calculateReferralBonus(clientData.referrals.length)}
  onRefer={(referralData) => handleReferral(referralData)}
/>
```

---

### BirthdayBonus
Show upcoming birthday bonus countdown.

```jsx
<BirthdayBonus 
  birthDate={clientData.birthDate}
  currentTier={clientData.loyaltyTier}
  onClaimBonus={() => handleBirthdayBonus()}
/>
```

---

## Implementation Guide

### Step 1: Add Loyalty Fields to Firestore Client Document

```javascript
// In firestore.rules
match /clients/{clientId} {
  allow read, write: if request.auth.uid == resource.data.userId;
  
  // Add these fields to client documents
  data {
    // ... existing fields
    loyaltyPoints: int,
    loyaltyTier: string,
    totalSpent: number,
    totalPurchases: int,
    lastPurchaseDate: timestamp,
    joinedDate: timestamp,
    claimedMilestones: array,
    referrals: array,
    lastBirthdayBonus: timestamp,
    preferredRedemption: string,
    birthDate: timestamp,
    loyaltyDiscount: int
  }
}
```

### Step 2: Create Loyalty Transaction Collection

```javascript
// Create new collection: loyaltyTransactions
match /loyaltyTransactions/{transactionId} {
  allow create: if request.auth.uid == request.resource.data.userId;
  allow read: if request.auth.uid == resource.data.userId;
}
```

### Step 3: Initialize Loyalty on Signup

```javascript
import { calculatePointsEarned, buildLoyaltyProfile } from './loyalty/loyaltyProgram';

async function initializeLoyalty(userId) {
  const clientRef = doc(db, 'clients', userId);
  await setDoc(clientRef, {
    loyaltyPoints: 0,
    loyaltyTier: 'bronze',
    totalSpent: 0,
    totalPurchases: 0,
    joinedDate: new Date(),
    claimedMilestones: [],
    referrals: [],
    preferredRedemption: 'discount'
  }, { merge: true });
}
```

### Step 4: Award Points on Purchase

```javascript
async function recordPurchase(clientId, purchaseAmount, tier = 'bronze') {
  const pointsEarned = calculatePointsEarned(purchaseAmount, tier);
  
  const clientRef = doc(db, 'clients', clientId);
  const clientDoc = await getDoc(clientRef);
  const newPoints = (clientDoc.data().loyaltyPoints || 0) + pointsEarned;
  
  // Update client loyalty
  await updateDoc(clientRef, {
    loyaltyPoints: newPoints,
    totalSpent: (clientDoc.data().totalSpent || 0) + purchaseAmount,
    totalPurchases: (clientDoc.data().totalPurchases || 0) + 1,
    lastPurchaseDate: new Date()
  });
  
  // Record transaction
  await addDoc(collection(db, 'loyaltyTransactions'), {
    userId: clientId,
    type: 'purchase',
    amount: purchaseAmount,
    pointsChange: pointsEarned,
    timestamp: new Date(),
    description: `Purchase of $${purchaseAmount}`
  });
}
```

### Step 5: Add Components to Dashboard

```jsx
import { 
  LoyaltyStatusCard, 
  PointsRedemption, 
  LoyaltyStats,
  TierShowcase 
} from './components/LoyaltyComponents';

export function DashboardPage() {
  const [clientData, setClientData] = useState(null);
  
  return (
    <div className="dashboard">
      <section className="loyalty-section">
        <h2>Loyalty Program</h2>
        {clientData && (
          <>
            <LoyaltyStatusCard 
              clientData={clientData}
              onAction={(action) => {
                if (action === 'viewBenefits') {
                  // Show tier benefits modal
                }
              }}
            />
            <PointsRedemption 
              currentPoints={clientData.loyaltyPoints}
              onRedeem={(points) => handleRedemption(points)}
            />
            <LoyaltyStats clientData={clientData} />
            <TierShowcase currentPoints={clientData.loyaltyPoints} />
          </>
        )}
      </section>
    </div>
  );
}
```

---

## Firestore Integration

### Collections Structure

```
clients/
├── {clientId}
│   ├── loyaltyPoints (int)
│   ├── loyaltyTier (string)
│   ├── totalSpent (number)
│   ├── totalPurchases (int)
│   ├── lastPurchaseDate (timestamp)
│   ├── joinedDate (timestamp)
│   ├── claimedMilestones (array)
│   ├── referrals (array)
│   ├── lastBirthdayBonus (timestamp)
│   ├── birthDate (timestamp)
│   └── loyaltyDiscount (int)

loyaltyTransactions/
├── {transactionId}
│   ├── userId (string)
│   ├── type (string) - purchase|redemption|reward|referral
│   ├── amount (number)
│   ├── pointsChange (int)
│   ├── timestamp (timestamp)
│   ├── description (string)
│   ├── reference (string) - order ID, etc
│   └── metadata (object)
```

### Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Loyalty transactions
    match /loyaltyTransactions/{transactionId} {
      allow create: if request.auth.uid == request.resource.data.userId;
      allow read: if request.auth.uid == resource.data.userId;
      allow list: if request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## Usage Examples

### Example 1: Display Loyalty Dashboard
```jsx
function LoyaltyDashboard() {
  const { clientData } = useContext(ClientContext);
  
  return (
    <div className="loyalty-dashboard">
      <LoyaltyStatusCard clientData={clientData} />
      <LoyaltyStats clientData={clientData} />
      <PointsRedemption 
        currentPoints={clientData.loyaltyPoints}
        onRedeem={handleRedemption}
      />
    </div>
  );
}
```

### Example 2: Award Points After Purchase
```javascript
async function completePurchase(clientId, amount) {
  const tier = getTierFromPoints(clientData.loyaltyPoints).id;
  const points = calculatePointsEarned(amount, tier);
  
  await updateDoc(doc(db, 'clients', clientId), {
    loyaltyPoints: increment(points),
    totalSpent: increment(amount),
    totalPurchases: increment(1),
    lastPurchaseDate: new Date()
  });
}
```

### Example 3: Check Tier Progression
```javascript
function checkTierUpdate(clientId, currentPoints) {
  const tier = getTierFromPoints(currentPoints);
  
  updateDoc(doc(db, 'clients', clientId), {
    loyaltyTier: tier.id,
    tierUpdatedAt: new Date()
  });
}
```

---

## Best Practices

1. **Always calculate tier from points** - Don't store tier separately, derive it from points
2. **Record all point changes** - Maintain audit trail in loyaltyTransactions collection
3. **Apply discounts automatically** - Check tier before finalizing orders
4. **Verify milestones** - Check milestone eligibility when points change
5. **Respect redemption limits** - Don't allow more than $30/month redemptions
6. **Handle tier upgrades** - Show celebrations and new benefits when tier unlocks
7. **Track referral sources** - Link referrals to campaigns for ROI tracking
8. **Use points as engagement metric** - Analyze point earning patterns
9. **Plan seasonal bonuses** - Schedule promotions around holidays
10. **Monitor tier distribution** - Ensure healthy mix across tiers

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Points not updating | Verify Firestore write permissions, check calculatePointsEarned logic |
| Tier not changing | Ensure getTierFromPoints is called after point updates |
| Redemption blocked | Check minimum (500) and maximum (3000) point limits |
| Discounts not applying | Verify applyLoyaltyDiscount includes correct tier |
| Referrals not counting | Ensure referral source is tracked in signup |

---

## Next Steps

1. Create loyalty dashboard page
2. Set up admin analytics view
3. Build referral campaign tracking
4. Create loyalty email notifications
5. Add tier milestone celebrations
6. Implement seasonal loyalty promotions
7. Build member-only exclusive offers
8. Create loyalty API endpoints
9. Add customer service tools for loyalty management
10. Build loyalty report generator

