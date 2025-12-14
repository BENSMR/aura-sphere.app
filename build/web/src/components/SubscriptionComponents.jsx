/**
 * SUBSCRIPTION MANAGEMENT REACT COMPONENTS
 *
 * Complete UI library for pricing, plan selection, and subscription management:
 * - Pricing display cards
 * - Plan comparison
 * - Upgrade/downgrade flows
 * - Billing management
 * - Feature showcase
 */

import React, { useState, useEffect } from 'react';
import {
  SUBSCRIPTION_TIERS,
  getAllTiers,
  getRecommendedTier,
  calculatePrice,
  compareTiers,
  validateUpgrade,
  isFeatureAvailable,
  isWithinLimits,
  getRolesByPlan
} from './subscriptionTiers';

// ─────────────────────────────────────────────────────────────────────────
// PRICING CARDS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Individual pricing card component
 */
export const PricingCard = ({ 
  tier, 
  isCurrentPlan = false,
  onSelect = () => {},
  billingCycle = 'monthly'
}) => {
  const pricing = calculatePrice(tier.id, billingCycle);
  const isRecommended = getRecommendedTier().id === tier.id;
  
  return (
    <div className={`pricing-card ${isCurrentPlan ? 'current' : ''} ${isRecommended ? 'recommended' : ''}`}
         style={{ borderTopColor: tier.color }}>
      {isRecommended && <div className="recommended-badge">✨ Most Popular</div>}
      {isCurrentPlan && <div className="current-badge">✓ Current Plan</div>}
      
      <div className="pricing-header">
        <span className="tier-icon">{tier.icon}</span>
        <h3 className="tier-name">{tier.name}</h3>
        <p className="tier-description">{tier.description}</p>
      </div>
      
      <div className="pricing-display">
        {tier.price ? (
          <>
            <div className="price-amount">
              <span className="currency">$</span>
              <span className="amount">{tier.price}</span>
              <span className="period">/month</span>
            </div>
            {billingCycle === 'yearly' && tier.yearlyPrice && (
              <div className="yearly-price">
                <span className="label">Billed yearly:</span>
                <span className="price">${tier.yearlyPrice}/year</span>
                <span className="saving">Save {tier.yearlyDiscount}%</span>
              </div>
            )}
          </>
        ) : (
          <div className="custom-price">
            <span className="label">Custom Pricing</span>
            <button className="btn-contact-sales" onClick={() => onSelect(tier.id)}>
              Contact Sales
            </button>
          </div>
        )}
      </div>
      
      <div className="limits-summary">
        <div className="limit-item">
          <span className="limit-icon">👥</span>
          <span className="limit-text">
            {tier.maxUsers === null ? 'Unlimited' : tier.maxUsers} users
          </span>
        </div>
        <div className="limit-item">
          <span className="limit-icon">💾</span>
          <span className="limit-text">
            {tier.limits.storage === null ? 'Unlimited' : tier.limits.storage}MB storage
          </span>
        </div>
        <div className="limit-item">
          <span className="limit-icon">📊</span>
          <span className="limit-text">
            {tier.limits.invoices === null ? 'Unlimited' : tier.limits.invoices} invoices
          </span>
        </div>
      </div>
      
      <div className="tier-features">
        <h4>Key Features</h4>
        <ul>
          {tier.features.core.slice(0, 3).map((feature, idx) => (
            <li key={idx}>
              <span className="checkmark">✓</span>
              <span className="feature-name">{feature.replace(/_/g, ' ')}</span>
            </li>
          ))}
          {tier.features.core.length > 3 && (
            <li className="more-features">
              +{tier.features.core.length - 3} more
            </li>
          )}
        </ul>
      </div>
      
      <button 
        className={`btn-select ${isCurrentPlan ? 'disabled' : 'primary'}`}
        onClick={() => onSelect(tier.id)}
        disabled={isCurrentPlan}
      >
        {isCurrentPlan ? 'Current Plan' : 'Select Plan'}
      </button>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// PRICING TABLE
// ─────────────────────────────────────────────────────────────────────────

/**
 * Pricing comparison table
 */
export const PricingTable = ({ currentPlanId = null, onSelect = () => {} }) => {
  const tiers = getAllTiers(true);
  
  return (
    <div className="pricing-table-container">
      <h2>Compare Our Plans</h2>
      
      <div className="pricing-cards-grid">
        {tiers.map(tier => (
          <PricingCard
            key={tier.id}
            tier={tier}
            isCurrentPlan={currentPlanId === tier.id}
            onSelect={onSelect}
          />
        ))}
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// FEATURE COMPARISON
// ─────────────────────────────────────────────────────────────────────────

/**
 * Detailed feature comparison across tiers
 */
export const FeatureComparison = ({ highlightTierId = null }) => {
  const [selectedCategory, setSelectedCategory] = useState('core');
  const tiers = getAllTiers(true);
  
  const categories = {
    core: 'Core Features',
    ai: 'AI & Automation',
    loyalty: 'Loyalty Program',
    integrations: 'Integrations',
    limits: 'Usage Limits'
  };
  
  return (
    <div className="feature-comparison">
      <h3>Detailed Feature Comparison</h3>
      
      {/* Category Tabs */}
      <div className="category-tabs">
        {Object.entries(categories).map(([key, label]) => (
          <button
            key={key}
            className={`tab ${selectedCategory === key ? 'active' : ''}`}
            onClick={() => setSelectedCategory(key)}
          >
            {label}
          </button>
        ))}
      </div>
      
      {/* Comparison Table */}
      <div className="comparison-table">
        <div className="comparison-header">
          <div className="feature-column">Feature</div>
          {tiers.map(tier => (
            <div 
              key={tier.id}
              className={`tier-column ${highlightTierId === tier.id ? 'highlighted' : ''}`}
              style={{ borderTopColor: tier.color }}
            >
              <div className="tier-name">{tier.name}</div>
              <div className="tier-price">
                {tier.price ? `$${tier.price}/mo` : 'Custom'}
              </div>
            </div>
          ))}
        </div>
        
        <div className="comparison-rows">
          {selectedCategory === 'limits' ? (
            // Show limits comparison
            <div className="limits-rows">
              {['invoices', 'storage', 'teamMembers', 'apiAccess', 'customRoles'].map(limit => (
                <div key={limit} className="comparison-row">
                  <div className="feature-column">{limit.replace(/([A-Z])/g, ' $1')}</div>
                  {tiers.map(tier => (
                    <div key={tier.id} className="tier-column">
                      <span className="limit-value">
                        {tier.limits[limit] === null ? '∞' : tier.limits[limit]}
                      </span>
                    </div>
                  ))}
                </div>
              ))}
            </div>
          ) : (
            // Show feature comparison
            Object.values(tiers[0].features)[Object.keys(categories).indexOf(selectedCategory)]?.map((feature, idx) => (
              <div key={idx} className="comparison-row">
                <div className="feature-column">{feature.replace(/_/g, ' ')}</div>
                {tiers.map(tier => (
                  <div key={tier.id} className="tier-column">
                    {isFeatureAvailable(tier.id, feature) ? (
                      <span className="check">✓</span>
                    ) : (
                      <span className="cross">—</span>
                    )}
                  </div>
                ))}
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// UPGRADE/DOWNGRADE MODAL
// ─────────────────────────────────────────────────────────────────────────

/**
 * Modal for upgrading/downgrading subscription
 */
export const UpgradeModal = ({ 
  currentTierId,
  newTierId,
  onConfirm = () => {},
  onCancel = () => {}
}) => {
  const upgrade = validateUpgrade(currentTierId, newTierId);
  const newTier = SUBSCRIPTION_TIERS[newTierId];
  
  if (!upgrade.allowed) {
    return (
      <div className="modal-overlay">
        <div className="modal-content error">
          <h3>Unable to Change Plan</h3>
          <p>{upgrade.reason}</p>
          <button onClick={onCancel}>Close</button>
        </div>
      </div>
    );
  }
  
  return (
    <div className="modal-overlay">
      <div className="modal-content upgrade-modal">
        <h3>
          {upgrade.isUpgrade ? '⬆️ Upgrade' : '⬇️ Downgrade'} to {newTier.name}
        </h3>
        
        <div className="upgrade-summary">
          <div className="summary-item">
            <span className="label">New Plan:</span>
            <span className="value">{newTier.name}</span>
          </div>
          <div className="summary-item">
            <span className="label">Price Change:</span>
            <span className="value" style={{ color: upgrade.isUpgrade ? '#dc2626' : '#16a34a' }}>
              {upgrade.isUpgrade ? '+' : '-'}${Math.abs(upgrade.priceDifference)}
            </span>
          </div>
          <div className="summary-item highlight">
            <span className="label">New Monthly Cost:</span>
            <span className="value">${newTier.price}/month</span>
          </div>
        </div>
        
        <div className="upgrade-benefits">
          <h4>You'll gain access to:</h4>
          <ul>
            {newTier.features.core.slice(0, 5).map((feature, idx) => (
              <li key={idx}>
                <span className="check">✓</span>
                {feature.replace(/_/g, ' ')}
              </li>
            ))}
          </ul>
        </div>
        
        <div className="modal-actions">
          <button className="btn-cancel" onClick={onCancel}>
            Cancel
          </button>
          <button className="btn-confirm" onClick={() => onConfirm()}>
            Confirm {upgrade.isUpgrade ? 'Upgrade' : 'Downgrade'}
          </button>
        </div>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// BILLING MANAGEMENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Current subscription and billing info
 */
export const BillingManagement = ({ subscription = {}, onChangePlan = () => {} }) => {
  const [showChangeModal, setShowChangeModal] = useState(false);
  const [selectedNewTier, setSelectedNewTier] = useState(null);
  
  const currentTier = SUBSCRIPTION_TIERS[subscription.tierId];
  
  if (!currentTier) {
    return (
      <div className="billing-management">
        <p>No active subscription</p>
      </div>
    );
  }
  
  return (
    <div className="billing-management">
      <h3>📋 Billing & Subscription</h3>
      
      <div className="current-plan">
        <div className="plan-info">
          <h4>Current Plan: {currentTier.name}</h4>
          <p className="plan-status">
            Status: <span className="status-badge">{subscription.status?.toUpperCase()}</span>
          </p>
        </div>
        
        <div className="billing-details">
          <div className="detail-row">
            <span className="label">Monthly Cost:</span>
            <span className="value">${currentTier.price}</span>
          </div>
          <div className="detail-row">
            <span className="label">Billing Cycle:</span>
            <span className="value">{subscription.billingCycle}</span>
          </div>
          <div className="detail-row">
            <span className="label">Next Billing Date:</span>
            <span className="value">
              {new Date(subscription.nextBillingDate).toLocaleDateString()}
            </span>
          </div>
          <div className="detail-row">
            <span className="label">Payment Method:</span>
            <span className="value">{subscription.paymentMethod || 'Not set'}</span>
          </div>
        </div>
      </div>
      
      <div className="plan-actions">
        <button 
          className="btn-change-plan"
          onClick={() => setShowChangeModal(true)}
        >
          Change Plan
        </button>
        <button className="btn-manage-billing">
          Manage Billing →
        </button>
      </div>
      
      {showChangeModal && (
        <div className="plan-selection">
          <h4>Select a Plan</h4>
          <div className="plan-options">
            {getAllTiers(true).map(tier => (
              <div 
                key={tier.id}
                className={`plan-option ${selectedNewTier === tier.id ? 'selected' : ''}`}
                onClick={() => setSelectedNewTier(tier.id)}
              >
                <input 
                  type="radio" 
                  name="new-plan"
                  value={tier.id}
                  checked={selectedNewTier === tier.id}
                  onChange={() => setSelectedNewTier(tier.id)}
                />
                <span className="plan-name">{tier.name}</span>
                <span className="plan-price">
                  {tier.price ? `$${tier.price}/mo` : 'Custom'}
                </span>
              </div>
            ))}
          </div>
          
          <div className="modal-actions">
            <button 
              className="btn-cancel"
              onClick={() => setShowChangeModal(false)}
            >
              Cancel
            </button>
            <button 
              className="btn-confirm"
              onClick={() => {
                onChangePlan(selectedNewTier);
                setShowChangeModal(false);
              }}
              disabled={!selectedNewTier}
            >
              Continue
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// USAGE TRACKER
// ─────────────────────────────────────────────────────────────────────────

/**
 * Show current usage against plan limits
 */
export const UsageTracker = ({ tierId, usage = {} }) => {
  const tier = SUBSCRIPTION_TIERS[tierId];
  if (!tier) return null;
  
  const trackedLimits = ['invoices', 'expenses', 'storage', 'teamMembers', 'aiQueries'];
  
  return (
    <div className="usage-tracker">
      <h3>📊 Usage</h3>
      
      {trackedLimits.map(limitKey => {
        const limit = tier.limits[limitKey];
        const currentUsage = usage[limitKey] || 0;
        const percentage = limit ? (currentUsage / limit) * 100 : 100;
        const isNearLimit = percentage > 80;
        
        return (
          <div key={limitKey} className="usage-item">
            <div className="usage-header">
              <span className="usage-label">{limitKey.replace(/([A-Z])/g, ' $1')}</span>
              <span className="usage-amount">
                {currentUsage} {limit ? `/ ${limit}` : '/ ∞'}
              </span>
            </div>
            
            <div className={`usage-bar ${isNearLimit ? 'warning' : ''}`}>
              <div 
                className="usage-fill"
                style={{ width: `${Math.min(percentage, 100)}%` }}
              ></div>
            </div>
            
            {limit && percentage > 80 && (
              <p className="usage-warning">⚠️ Approaching limit</p>
            )}
          </div>
        );
      })}
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// ROLE ACCESS DISPLAY
// ─────────────────────────────────────────────────────────────────────────

/**
 * Show available roles for current plan
 */
export const RoleAccessDisplay = ({ tierId }) => {
  const tier = SUBSCRIPTION_TIERS[tierId];
  if (!tier) return null;
  
  return (
    <div className="role-access">
      <h4>Available Team Roles</h4>
      <div className="role-badges">
        {tier.roles.map(role => (
          <span key={role} className="role-badge">
            {role.replace(/_/g, ' ')}
          </span>
        ))}
      </div>
      <p className="role-info">
        Max team members: {tier.maxTeamMembers === null ? 'Unlimited' : tier.maxTeamMembers}
      </p>
    </div>
  );
};
