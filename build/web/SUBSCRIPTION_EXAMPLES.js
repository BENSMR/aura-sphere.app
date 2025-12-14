/**
 * SUBSCRIPTION SYSTEM - IMPLEMENTATION EXAMPLES
 *
 * 8 complete, production-ready examples showing:
 * - Pricing page implementation
 * - Subscription management
 * - Feature gating
 * - Plan upgrades/downgrades
 * - Usage tracking
 * - Firestore integration
 * - Stripe integration points
 * - Admin analytics
 */

import React, { useState, useEffect } from 'react';
import {
  doc,
  getDoc,
  updateDoc,
  collection,
  getDocs,
  query,
  where,
  increment,
  addDoc
} from 'firebase/firestore';
import { db } from '../config/firebase';
import {
  SUBSCRIPTION_TIERS,
  getAllTiers,
  isFeatureAvailable,
  isWithinLimits,
  validateUpgrade,
  createSubscriptionRecord,
  calculatePrice,
  getMaxTeamMembers,
  getRolesByPlan
} from '../pricing/subscriptionTiers';
import {
  PricingTable,
  FeatureComparison,
  BillingManagement,
  UsageTracker,
  UpgradeModal
} from '../components/SubscriptionComponents';

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 1: Complete Pricing Page
// ─────────────────────────────────────────────────────────────────────────

/**
 * Full pricing page with all components
 */
export function Example1_PricingPage() {
  const [currentPlan, setCurrentPlan] = useState(null);
  const [billingCycle, setBillingCycle] = useState('monthly');
  const [selectedPlan, setSelectedPlan] = useState(null);
  const [showModal, setShowModal] = useState(false);

  useEffect(() => {
    // Load user's current plan
    loadCurrentPlan();
  }, []);

  async function loadCurrentPlan() {
    const userRef = doc(db, 'users', 'current_user_id');
    const userDoc = await getDoc(userRef);
    const tier = userDoc.data()?.subscription?.tierId;
    setCurrentPlan(tier);
  }

  const handleSelectPlan = (tierId) => {
    setSelectedPlan(tierId);
    
    if (tierId === currentPlan) {
      return; // Already on this plan
    }
    
    setShowModal(true);
  };

  return (
    <div className="pricing-page-container">
      <section className="pricing-hero">
        <h1>💰 Simple, Transparent Pricing</h1>
        <p>Choose the perfect plan for your business</p>
        
        {/* Billing Cycle Toggle */}
        <div className="billing-toggle">
          <button 
            className={`toggle-btn ${billingCycle === 'monthly' ? 'active' : ''}`}
            onClick={() => setBillingCycle('monthly')}
          >
            Monthly
          </button>
          <button 
            className={`toggle-btn ${billingCycle === 'yearly' ? 'active' : ''}`}
            onClick={() => setBillingCycle('yearly')}
          >
            Yearly <span className="badge">Save 20%</span>
          </button>
        </div>
      </section>

      {/* Pricing Cards */}
      <PricingTable 
        currentPlanId={currentPlan}
        onSelect={handleSelectPlan}
      />

      {/* Feature Comparison */}
      <FeatureComparison highlightTierId={currentPlan} />

      {/* FAQ Section */}
      <section className="pricing-faq">
        <h2>Frequently Asked Questions</h2>
        <div className="faq-items">
          <details>
            <summary>Can I change plans later?</summary>
            <p>Yes! You can upgrade or downgrade your plan anytime. Changes take effect on your next billing cycle.</p>
          </details>
          <details>
            <summary>Is there a free trial?</summary>
            <p>All plans come with a 14-30 day free trial. No credit card required.</p>
          </details>
          <details>
            <summary>What if I need more users?</summary>
            <p>Contact our sales team for custom pricing on additional users or upgrade to a higher tier.</p>
          </details>
        </div>
      </section>

      {/* Upgrade Modal */}
      {showModal && selectedPlan && (
        <UpgradeModal 
          currentTierId={currentPlan}
          newTierId={selectedPlan}
          onConfirm={() => initiateCheckout(selectedPlan)}
          onCancel={() => setShowModal(false)}
        />
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 2: Feature Gating
// ─────────────────────────────────────────────────────────────────────────

/**
 * Protect features based on subscription tier
 */
export async function example2_checkFeatureAccess(userId, feature) {
  console.log(`\n🔐 EXAMPLE 2: Checking feature access for ${feature}`);

  try {
    const userRef = doc(db, 'users', userId);
    const userDoc = await getDoc(userRef);
    const tierId = userDoc.data()?.subscription?.tierId;

    const hasAccess = isFeatureAvailable(tierId, feature);

    if (!hasAccess) {
      console.log(`  ❌ ${feature} not available in ${tierId} plan`);
      return {
        allowed: false,
        feature,
        tier: tierId,
        message: `Upgrade to access ${feature}`,
        nextTier: SUBSCRIPTION_TIERS[tierId]?.nextTier
      };
    }

    console.log(`  ✅ ${feature} available in ${tierId} plan`);
    return { allowed: true, feature, tier: tierId };

  } catch (error) {
    console.error('Error checking feature access:', error);
    return { allowed: false, error: error.message };
  }
}

/**
 * Gating React component
 */
export function Example2_FeatureGate({ feature, children, onUpgrade = () => {} }) {
  const [hasAccess, setHasAccess] = useState(null);
  const [userTier, setUserTier] = useState(null);

  useEffect(() => {
    checkAccess();
  }, [feature]);

  async function checkAccess() {
    const result = await example2_checkFeatureAccess('current_user_id', feature);
    setHasAccess(result.allowed);
    setUserTier(result.tier);
  }

  if (hasAccess === null) return <div>Loading...</div>;

  if (!hasAccess) {
    return (
      <div className="feature-locked">
        <div className="lock-icon">🔒</div>
        <h3>This feature is not available in your plan</h3>
        <p>Upgrade to {SUBSCRIPTION_TIERS[SUBSCRIPTION_TIERS[userTier]?.nextTier]?.name} to access {feature}</p>
        <button className="btn-upgrade" onClick={onUpgrade}>
          Upgrade Now
        </button>
      </div>
    );
  }

  return children;
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 3: Usage Limit Enforcement
// ─────────────────────────────────────────────────────────────────────────

/**
 * Check and enforce usage limits
 */
export async function example3_createResourceWithLimitCheck(userId, resourceType) {
  console.log(`\n📊 EXAMPLE 3: Creating ${resourceType} with limit check`);

  try {
    const userRef = doc(db, 'users', userId);
    const userDoc = await getDoc(userRef);
    const subscription = userDoc.data()?.subscription;
    const usage = userDoc.data()?.usage || {};

    const limitKey = resourceType.toLowerCase() + 's'; // invoices, expenses, etc
    const currentUsage = usage[limitKey] || 0;

    // Check limit
    if (!isWithinLimits(subscription.tierId, limitKey, currentUsage + 1)) {
      const tier = SUBSCRIPTION_TIERS[subscription.tierId];
      const limit = tier.limits[limitKey];

      console.log(`  ❌ ${resourceType} limit (${limit}) exceeded`);
      return {
        success: false,
        reason: 'limit_exceeded',
        current: currentUsage,
        limit,
        tier: tier.name
      };
    }

    console.log(`  ✅ Creating ${resourceType} (${currentUsage + 1}/${tier.limits[limitKey]})`);

    // Increment usage
    await updateDoc(userRef, {
      [`usage.${limitKey}`]: increment(1)
    });

    return { success: true, resourceType, newUsage: currentUsage + 1 };

  } catch (error) {
    console.error('Error:', error);
    return { success: false, error: error.message };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 4: Plan Upgrade Flow
// ─────────────────────────────────────────────────────────────────────────

/**
 * Complete upgrade workflow
 */
export async function example4_upgradeSubscription(userId, newTierId) {
  console.log(`\n⬆️ EXAMPLE 4: Upgrading subscription to ${newTierId}`);

  try {
    const userRef = doc(db, 'users', userId);
    const userDoc = await getDoc(userRef);
    const currentTierId = userDoc.data()?.subscription?.tierId;

    // Validate upgrade
    const validation = validateUpgrade(currentTierId, newTierId);

    if (!validation.allowed) {
      console.log(`  ❌ ${validation.reason}`);
      return { success: false, error: validation.reason };
    }

    console.log(`  🔄 ${validation.currentTier} → ${validation.newTier}`);
    console.log(`  💰 Price change: $${validation.priceDifference}/month`);

    // Create new subscription record
    const newSubscription = createSubscriptionRecord(userId, newTierId, 'monthly');

    // Save to Firestore
    await updateDoc(userRef, {
      subscription: newSubscription
    });

    // Log transaction
    await addDoc(collection(db, 'subscriptionChanges'), {
      userId,
      from: currentTierId,
      to: newTierId,
      timestamp: new Date(),
      priceChange: validation.priceDifference,
      changeType: 'upgrade'
    });

    console.log(`  ✅ Upgrade successful`);
    return { success: true, newSubscription };

  } catch (error) {
    console.error('Error upgrading:', error);
    return { success: false, error: error.message };
  }
}

/**
 * React component for upgrade flow
 */
export function Example4_UpgradeFlow({ currentTierId, onSuccess = () => {} }) {
  const [selectedTier, setSelectedTier] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleUpgrade = async () => {
    setLoading(true);
    const result = await example4_upgradeSubscription('current_user_id', selectedTier);
    setLoading(false);
    
    if (result.success) {
      onSuccess(result.newSubscription);
    }
  };

  return (
    <div className="upgrade-flow">
      <h3>Select a plan to upgrade to:</h3>
      <div className="tier-options">
        {getAllTiers(false)
          .filter(t => SUBSCRIPTION_TIERS[currentTierId]?.nextTier === t.id)
          .map(tier => (
            <div 
              key={tier.id}
              className={`tier-option ${selectedTier === tier.id ? 'selected' : ''}`}
              onClick={() => setSelectedTier(tier.id)}
            >
              <h4>{tier.name}</h4>
              <p>${tier.price}/month</p>
              <p className="benefits">{tier.features.core.length} features</p>
            </div>
          ))}
      </div>

      <button
        className="btn-upgrade-confirm"
        onClick={handleUpgrade}
        disabled={!selectedTier || loading}
      >
        {loading ? 'Upgrading...' : 'Upgrade Now'}
      </button>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 5: Team Member Management
// ─────────────────────────────────────────────────────────────────────────

/**
 * Manage team members with tier limits
 */
export async function example5_addTeamMember(userId, memberData) {
  console.log(`\n👥 EXAMPLE 5: Adding team member`);

  try {
    const userRef = doc(db, 'users', userId);
    const userDoc = await getDoc(userRef);
    const tierId = userDoc.data()?.subscription?.tierId;
    const currentTeamSize = userDoc.data()?.team?.length || 0;

    const maxMembers = getMaxTeamMembers(tierId);

    if (currentTeamSize >= maxMembers) {
      console.log(`  ❌ Team limit (${maxMembers}) reached`);
      return {
        success: false,
        reason: 'team_limit_exceeded',
        current: currentTeamSize,
        max: maxMembers,
        nextTier: SUBSCRIPTION_TIERS[tierId]?.nextTier
      };
    }

    // Get available roles for tier
    const availableRoles = getRolesByPlan(tierId);

    if (!availableRoles.includes(memberData.role)) {
      console.log(`  ❌ Role not available in ${tierId} plan`);
      return {
        success: false,
        reason: 'role_not_available',
        requestedRole: memberData.role,
        availableRoles
      };
    }

    console.log(`  ✅ Adding ${memberData.name} as ${memberData.role}`);
    console.log(`  👥 Team size: ${currentTeamSize + 1}/${maxMembers}`);

    // Add team member
    await updateDoc(userRef, {
      team: [...(userDoc.data()?.team || []), memberData]
    });

    return { success: true, memberAdded: memberData, teamSize: currentTeamSize + 1 };

  } catch (error) {
    console.error('Error adding team member:', error);
    return { success: false, error: error.message };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 6: Subscription Management Dashboard
// ─────────────────────────────────────────────────────────────────────────

/**
 * React component for subscription management
 */
export function Example6_SubscriptionDashboard() {
  const [subscription, setSubscription] = useState(null);
  const [usage, setUsage] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadSubscriptionData();
  }, []);

  async function loadSubscriptionData() {
    const userRef = doc(db, 'users', 'current_user_id');
    const userDoc = await getDoc(userRef);
    setSubscription(userDoc.data()?.subscription);
    setUsage(userDoc.data()?.usage);
    setLoading(false);
  }

  if (loading) return <div>Loading...</div>;

  return (
    <div className="subscription-dashboard">
      <h1>📋 Subscription & Billing</h1>

      <section className="subscription-info">
        <BillingManagement 
          subscription={subscription}
          onChangePlan={(tierId) => example4_upgradeSubscription('current_user_id', tierId)}
        />
      </section>

      <section className="usage-info">
        <UsageTracker 
          tierId={subscription.tierId}
          usage={usage}
        />
      </section>

      <section className="billing-history">
        <h3>📜 Billing History</h3>
        <p>Last charge: ${subscription.price} on {new Date(subscription.nextBillingDate).toLocaleDateString()}</p>
      </section>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 7: Subscription Analytics
// ─────────────────────────────────────────────────────────────────────────

/**
 * Generate subscription analytics
 */
export async function example7_generateSubscriptionAnalytics() {
  console.log(`\n📊 EXAMPLE 7: Generating subscription analytics`);

  try {
    const usersRef = collection(db, 'users');
    const usersSnap = await getDocs(usersRef);

    const analytics = {
      totalUsers: usersSnap.size,
      byTier: { solo: 0, team: 0, business: 0, enterprise: 0 },
      totalMRR: 0, // Monthly Recurring Revenue
      churn: 0,
      upgradeRate: 0,
      averageUsagePercent: {}
    };

    const usageByTier = { solo: [], team: [], business: [], enterprise: [] };

    usersSnap.forEach(userDoc => {
      const subscription = userDoc.data()?.subscription;
      const usage = userDoc.data()?.usage || {};

      if (subscription) {
        analytics.byTier[subscription.tierId]++;
        analytics.totalMRR += subscription.price;

        // Track usage percentages
        const tier = SUBSCRIPTION_TIERS[subscription.tierId];
        const invoiceUsage = (usage.invoices || 0) / tier.limits.invoices;
        usageByTier[subscription.tierId].push(invoiceUsage);
      }
    });

    // Calculate average usage per tier
    Object.entries(usageByTier).forEach(([tier, usages]) => {
      if (usages.length > 0) {
        const avgUsage = usages.reduce((a, b) => a + b, 0) / usages.length;
        analytics.averageUsagePercent[tier] = (avgUsage * 100).toFixed(1);
      }
    });

    console.log(`
╔════════════════════════════════════════╗
║     SUBSCRIPTION ANALYTICS              ║
╠════════════════════════════════════════╣
║ Total Users:        ${String(analytics.totalUsers).padEnd(20)}║
║ Monthly Recurring:  $${String(analytics.totalMRR).padEnd(18)}║
╠════════════════════════════════════════╣
║ TIER DISTRIBUTION                       ║
║ Solo:      ${String(analytics.byTier.solo).padEnd(26)}║
║ Team:      ${String(analytics.byTier.team).padEnd(26)}║
║ Business:  ${String(analytics.byTier.business).padEnd(26)}║
║ Enterprise:${String(analytics.byTier.enterprise).padEnd(26)}║
╠════════════════════════════════════════╣
║ AVG USAGE %                             ║
${Object.entries(analytics.averageUsagePercent).map(([tier, usage]) => 
  `║ ${String(tier).padEnd(10)}: ${String(usage + '%').padEnd(24)}║`
).join('\n')}
╚════════════════════════════════════════╝
    `);

    return analytics;

  } catch (error) {
    console.error('Error generating analytics:', error);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 8: Stripe Integration
// ─────────────────────────────────────────────────────────────────────────

/**
 * Initiate Stripe checkout
 */
export async function example8_initiateStripeCheckout(tierId, billingCycle = 'monthly') {
  console.log(`\n💳 EXAMPLE 8: Initiating Stripe checkout for ${tierId} (${billingCycle})`);

  try {
    const pricing = calculatePrice(tierId, billingCycle);
    const tier = SUBSCRIPTION_TIERS[tierId];

    // Stripe price IDs (configure in your Stripe account)
    const STRIPE_PRICES = {
      solo_monthly: 'price_solo_monthly',
      team_monthly: 'price_team_monthly',
      // ... etc
    };

    const priceId = STRIPE_PRICES[`${tierId}_${billingCycle}`];

    console.log(`  📝 Plan: ${tier.name}`);
    console.log(`  💰 Amount: $${pricing.monthlyPrice}/month`);

    // In production, use @stripe/react-stripe-js
    // const stripe = await loadStripe(STRIPE_PUBLIC_KEY);
    // await stripe.redirectToCheckout({
    //   lineItems: [{ price: priceId, quantity: 1 }],
    //   mode: 'subscription',
    //   successUrl: 'https://app.example.com/success',
    //   cancelUrl: 'https://app.example.com/pricing'
    // });

    console.log(`  ✅ Redirecting to Stripe checkout...`);
    return { success: true, priceId, pricing };

  } catch (error) {
    console.error('Error initiating checkout:', error);
    return { success: false, error: error.message };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// CSS STYLING
// ─────────────────────────────────────────────────────────────────────────

export const SUBSCRIPTION_STYLES = `
.pricing-page-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 60px 20px;
}

.pricing-hero {
  text-align: center;
  margin-bottom: 60px;
}

.pricing-hero h1 {
  font-size: 48px;
  margin-bottom: 10px;
}

.billing-toggle {
  display: flex;
  gap: 12px;
  justify-content: center;
  margin: 30px 0;
}

.toggle-btn {
  padding: 12px 24px;
  border: 2px solid #e5e7eb;
  background: white;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s ease;
}

.toggle-btn.active {
  border-color: #667eea;
  background: #667eea;
  color: white;
}

.pricing-card {
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  padding: 30px;
  background: white;
  transition: all 0.3s ease;
  position: relative;
}

.pricing-card.recommended {
  border-color: #667eea;
  box-shadow: 0 10px 30px rgba(102, 126, 234, 0.2);
  transform: scale(1.05);
}

.pricing-card.current {
  border-color: #48bb78;
  background: #f0fdf4;
}

.recommended-badge {
  position: absolute;
  top: -12px;
  left: 20px;
  background: #667eea;
  color: white;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
}

.price-amount {
  display: flex;
  align-items: baseline;
  gap: 4px;
  margin: 20px 0;
}

.price-amount .amount {
  font-size: 48px;
  font-weight: bold;
  color: #667eea;
}

.price-amount .period {
  color: #6b7280;
}

.feature-locked {
  text-align: center;
  padding: 40px;
  border: 2px dashed #e5e7eb;
  border-radius: 12px;
  background: #f9fafb;
}

.lock-icon {
  font-size: 48px;
  margin-bottom: 20px;
}

.usage-item {
  margin-bottom: 24px;
}

.usage-bar {
  width: 100%;
  height: 12px;
  background: #e5e7eb;
  border-radius: 6px;
  overflow: hidden;
}

.usage-fill {
  height: 100%;
  background: linear-gradient(90deg, #667eea, #764ba2);
  transition: width 0.3s ease;
}

.usage-bar.warning .usage-fill {
  background: linear-gradient(90deg, #f59e0b, #ef4444);
}

@media (max-width: 768px) {
  .pricing-hero h1 {
    font-size: 32px;
  }
  
  .pricing-card.recommended {
    transform: scale(1);
  }
  
  .pricing-cards-grid {
    grid-template-columns: 1fr;
  }
}
`;
