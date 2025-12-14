/**
 * LOYALTY PROGRAM REACT COMPONENTS
 * 
 * Complete UI library for loyalty program features:
 * - Tier status display with progress
 * - Points tracker with redemption
 * - Rewards showcase
 * - Loyalty analytics
 */

import React, { useState, useEffect } from 'react';
import {
  LOYALTY_TIERS,
  getTierProgress,
  calculateRedeemablePoints,
  buildLoyaltyProfile,
  applyLoyaltyDiscount,
  calculateBirthdayBonus
} from './loyaltyProgram';

// ─────────────────────────────────────────────────────────────────────────
// LOYALTY STATUS CARD
// ─────────────────────────────────────────────────────────────────────────

/**
 * Main loyalty status card - shows tier, points, and next milestone
 */
export const LoyaltyStatusCard = ({ clientData = {}, onAction = () => {} }) => {
  const profile = buildLoyaltyProfile(clientData);
  const { tier, points, tierProgress } = profile;
  
  return (
    <div className="loyalty-status-card">
      <div className="status-header">
        <div className="tier-badge">
          <span className="tier-icon">{tier.icon}</span>
          <span className="tier-name">{tier.name}</span>
        </div>
        <div className="points-display">
          <div className="points-value">{points.toLocaleString()}</div>
          <div className="points-label">Points</div>
        </div>
      </div>
      
      <div className="status-benefits">
        <div className="benefit-item">
          <span className="benefit-icon">💰</span>
          <span className="benefit-text">{tier.baseDiscount}% Discount</span>
        </div>
        <div className="benefit-item">
          <span className="benefit-icon">⭐</span>
          <span className="benefit-text">{tier.pointsMultiplier}x Points Earn</span>
        </div>
        <div className="benefit-item">
          <span className="benefit-icon">🎁</span>
          <span className="benefit-text">{tier.benefits.length} Benefits</span>
        </div>
      </div>
      
      <div className="tier-progress">
        <div className="progress-header">
          {tierProgress.isMaxTier ? (
            <span className="max-tier-badge">✨ Maximum Tier</span>
          ) : (
            <>
              <span className="progress-label">
                {tierProgress.pointsNeededForNext} to {tierProgress.nextTier.name}
              </span>
              <span className="progress-percent">{tierProgress.progress}%</span>
            </>
          )}
        </div>
        <div className="progress-bar">
          <div className="progress-fill" style={{ width: `${tierProgress.progress}%` }}></div>
        </div>
      </div>
      
      <button 
        className="view-benefits-btn"
        onClick={() => onAction('viewBenefits')}
      >
        View All Benefits
      </button>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// TIER SHOWCASE
// ─────────────────────────────────────────────────────────────────────────

/**
 * Display all tiers with current tier highlighted
 */
export const TierShowcase = ({ currentPoints = 0, onUpgrade = () => {} }) => {
  const tierProgress = getTierProgress(currentPoints);
  const tiers = [
    LOYALTY_TIERS.BRONZE,
    LOYALTY_TIERS.SILVER,
    LOYALTY_TIERS.GOLD,
    LOYALTY_TIERS.PLATINUM
  ];
  
  return (
    <div className="tier-showcase">
      <h3>Loyalty Tiers</h3>
      <div className="tiers-grid">
        {tiers.map(tier => (
          <div 
            key={tier.id}
            className={`tier-card ${tierProgress.currentTier.id === tier.id ? 'active' : ''} ${currentPoints >= tier.minPoints ? 'unlocked' : 'locked'}`}
            style={{ borderTopColor: tier.color }}
          >
            <div className="tier-header">
              <span className="tier-icon-large">{tier.icon}</span>
              <span className="tier-name-card">{tier.name}</span>
            </div>
            
            <div className="tier-points">
              {tier.maxPoints ? `${tier.minPoints} - ${tier.maxPoints}` : `${tier.minPoints}+`}
            </div>
            
            <div className="tier-perks">
              <div className="perk-item">
                <span className="perk-icon">💰</span>
                {tier.baseDiscount}% Off
              </div>
              <div className="perk-item">
                <span className="perk-icon">⭐</span>
                {tier.pointsMultiplier}x Earn
              </div>
            </div>
            
            <button 
              className={`tier-action-btn ${tierProgress.currentTier.id === tier.id ? 'current' : 'future'}`}
              onClick={() => onUpgrade(tier.id)}
              disabled={tierProgress.currentTier.id === tier.id}
            >
              {tierProgress.currentTier.id === tier.id ? 'Current' : 'Unlock'}
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// POINTS REDEMPTION
// ─────────────────────────────────────────────────────────────────────────

/**
 * Points redemption interface
 */
export const PointsRedemption = ({ currentPoints = 0, onRedeem = () => {} }) => {
  const [redeemAmount, setRedeemAmount] = useState(null);
  const redemptionInfo = calculateRedeemablePoints(currentPoints);
  
  const handleRedemption = (type) => {
    if (type === 'max') {
      setRedeemAmount(redemptionInfo.redeemablePoints);
    } else if (type === 'half') {
      setRedeemAmount(Math.floor(redemptionInfo.redeemablePoints / 2 / 100) * 100);
    }
  };
  
  if (!redemptionInfo.canRedeem) {
    return (
      <div className="redemption-card locked">
        <div className="redemption-locked-icon">🔒</div>
        <h4>Points Redemption</h4>
        <p className="redemption-message">{redemptionInfo.reason}</p>
      </div>
    );
  }
  
  return (
    <div className="redemption-card">
      <h4>💳 Redeem Points</h4>
      
      <div className="redemption-info">
        <div className="info-item">
          <span className="info-label">Available:</span>
          <span className="info-value">{currentPoints.toLocaleString()} pts</span>
        </div>
        <div className="info-item">
          <span className="info-label">Can Redeem:</span>
          <span className="info-value">${redemptionInfo.dollarValue.toFixed(2)}</span>
        </div>
      </div>
      
      <div className="redemption-buttons">
        <button 
          className="btn-redemption"
          onClick={() => handleRedemption('half')}
        >
          Half (${(redemptionInfo.dollarValue / 2).toFixed(2)})
        </button>
        <button 
          className="btn-redemption primary"
          onClick={() => handleRedemption('max')}
        >
          All (${redemptionInfo.dollarValue.toFixed(2)})
        </button>
      </div>
      
      {redeemAmount && (
        <button 
          className="btn-redeem-confirm"
          onClick={() => onRedeem(redeemAmount)}
        >
          Confirm Redemption
        </button>
      )}
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// LOYALTY STATISTICS & HISTORY
// ─────────────────────────────────────────────────────────────────────────

/**
 * Comprehensive loyalty statistics dashboard
 */
export const LoyaltyStats = ({ clientData = {} }) => {
  const profile = buildLoyaltyProfile(clientData);
  const { totalSpent, totalPurchases, memberDays, stats, tier } = profile;
  
  return (
    <div className="loyalty-stats">
      <h4>📊 Your Loyalty Stats</h4>
      
      <div className="stats-grid">
        <div className="stat-item">
          <div className="stat-label">Member Since</div>
          <div className="stat-value">{memberDays} days</div>
        </div>
        
        <div className="stat-item">
          <div className="stat-label">Total Purchases</div>
          <div className="stat-value">{totalPurchases}</div>
        </div>
        
        <div className="stat-item">
          <div className="stat-label">Lifetime Spent</div>
          <div className="stat-value">${totalSpent.toFixed(2)}</div>
        </div>
        
        <div className="stat-item">
          <div className="stat-label">Discounts Saved</div>
          <div className="stat-value highlight">${stats.discountsSaved}</div>
        </div>
      </div>
      
      <div className="savings-breakdown">
        <p className="breakdown-title">Discount Breakdown</p>
        <div className="breakdown-item">
          <span>From {tier.name} tier ({tier.baseDiscount}%)</span>
          <span>${(parseFloat(stats.discountsSaved) * 0.8).toFixed(2)}</span>
        </div>
        <div className="breakdown-item">
          <span>From milestone rewards</span>
          <span>${(parseFloat(stats.discountsSaved) * 0.2).toFixed(2)}</span>
        </div>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// TIER BENEFITS DETAIL
// ─────────────────────────────────────────────────────────────────────────

/**
 * Detailed benefits list for a tier
 */
export const TierBenefits = ({ tier = LOYALTY_TIERS.BRONZE, onClose = () => {} }) => {
  return (
    <div className="tier-benefits-modal">
      <div className="modal-header">
        <h3>{tier.icon} {tier.name} Tier Benefits</h3>
        <button className="modal-close" onClick={onClose}>✕</button>
      </div>
      
      <div className="modal-content">
        <div className="benefit-intro">
          <p>As a {tier.name} member, you get:</p>
        </div>
        
        <div className="benefits-list">
          {tier.benefits.map((benefit, idx) => (
            <div key={idx} className="benefit-row">
              <span className="benefit-check">✓</span>
              <span className="benefit-description">{benefit}</span>
            </div>
          ))}
        </div>
        
        <div className="benefit-stats">
          <div className="stat-row">
            <span>Base Discount:</span>
            <span>{tier.baseDiscount}%</span>
          </div>
          <div className="stat-row">
            <span>Points Multiplier:</span>
            <span>{tier.pointsMultiplier}x</span>
          </div>
          <div className="stat-row">
            <span>Total Benefits:</span>
            <span>{tier.benefits.length}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// QUICK DISCOUNT TOGGLE (From user's original code)
// ─────────────────────────────────────────────────────────────────────────

/**
 * Simple toggle for applying loyalty discount (from user's original code)
 * Enhanced with tier awareness
 */
export const LoyaltyDiscountToggle = ({ 
  clientId = '',
  currentTier = 'bronze',
  onToggle = () => {} 
}) => {
  const [isApplying, setIsApplying] = useState(false);
  const tier = LOYALTY_TIERS[currentTier.toUpperCase()] || LOYALTY_TIERS.BRONZE;
  const discount = tier.baseDiscount;
  
  const handleToggle = async (e) => {
    setIsApplying(true);
    try {
      await onToggle({
        clientId,
        loyaltyDiscount: e.target.checked ? discount : 0,
        tier: currentTier,
        appliedAt: new Date().toISOString()
      });
    } finally {
      setIsApplying(false);
    }
  };
  
  return (
    <div className="loyalty-toggle-container">
      <label className="loyalty-toggle">
        <input 
          type="checkbox"
          onChange={handleToggle}
          disabled={isApplying}
          defaultChecked={discount > 0}
        />
        <span className="toggle-text">
          Apply {discount}% {tier.name} Discount
        </span>
      </label>
      {isApplying && <span className="toggle-saving">Saving...</span>}
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// LOYALTY WIDGET (Compact Dashboard)
// ─────────────────────────────────────────────────────────────────────────

/**
 * Compact loyalty widget for dashboard/sidebar
 */
export const LoyaltyWidget = ({ clientData = {}, onExpand = () => {} }) => {
  const profile = buildLoyaltyProfile(clientData);
  const { tier, points, tierProgress } = profile;
  
  return (
    <div className="loyalty-widget">
      <div className="widget-header">
        <span className="widget-title">Loyalty Status</span>
        <span className="tier-badge-compact">{tier.icon} {tier.name}</span>
      </div>
      
      <div className="widget-points">
        <span className="points-number">{points.toLocaleString()}</span>
        <span className="points-text">points</span>
      </div>
      
      <div className="widget-progress-mini">
        <div className="progress-bar-mini">
          <div className="progress-fill-mini" style={{ width: `${tierProgress.progress}%` }}></div>
        </div>
        <span className="progress-text-mini">
          {tierProgress.isMaxTier ? '🎉 Max Tier' : `${tierProgress.pointsNeededForNext} to next`}
        </span>
      </div>
      
      <button 
        className="widget-expand-btn"
        onClick={onExpand}
      >
        View Details →
      </button>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// REFERRAL TRACKER
// ─────────────────────────────────────────────────────────────────────────

/**
 * Track and manage referral rewards
 */
export const ReferralTracker = ({ referrals = [], onRefer = () => {}, referralBonus = 0 }) => {
  const [shareLink, setShareLink] = useState(null);
  const [showShareModal, setShowShareModal] = useState(false);
  
  const generateShareLink = () => {
    const link = `${window.location.origin}?ref=${Math.random().toString(36).substring(7)}`;
    setShareLink(link);
    setShowShareModal(true);
  };
  
  return (
    <div className="referral-tracker">
      <h4>🎯 Refer & Earn</h4>
      
      <div className="referral-stats">
        <div className="ref-stat">
          <span className="ref-label">Successful Referrals:</span>
          <span className="ref-value">{referrals.length}</span>
        </div>
        <div className="ref-stat">
          <span className="ref-label">Bonus Points:</span>
          <span className="ref-value highlight">{referralBonus}</span>
        </div>
      </div>
      
      <button 
        className="btn-refer"
        onClick={generateShareLink}
      >
        Share Referral Link
      </button>
      
      {showShareModal && shareLink && (
        <div className="share-modal">
          <input 
            type="text" 
            className="share-link-input"
            value={shareLink}
            readOnly
          />
          <button 
            className="btn-copy"
            onClick={() => {
              navigator.clipboard.writeText(shareLink);
              alert('Copied!');
            }}
          >
            Copy Link
          </button>
          <button 
            className="btn-close"
            onClick={() => setShowShareModal(false)}
          >
            Close
          </button>
        </div>
      )}
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────
// BIRTHDAY BONUS COUNTDOWN
// ─────────────────────────────────────────────────────────────────────────

/**
 * Show upcoming birthday bonus
 */
export const BirthdayBonus = ({ 
  birthDate = null,
  lastBirthdayBonus = null,
  currentTier = 'bronze',
  onClaimBonus = () => {}
}) => {
  if (!birthDate) {
    return (
      <div className="birthday-bonus-card incomplete">
        <p>Add your birthday to earn bonus points! 🎂</p>
      </div>
    );
  }
  
  const bonus = calculateBirthdayBonus(currentTier);
  const today = new Date();
  const birth = new Date(birthDate);
  const nextBirthday = new Date(today.getFullYear(), birth.getMonth(), birth.getDate());
  
  if (today > nextBirthday) {
    nextBirthday.setFullYear(today.getFullYear() + 1);
  }
  
  const daysUntil = Math.ceil((nextBirthday - today) / (1000 * 60 * 60 * 24));
  const isBirthdayMonth = today.getMonth() === birth.getMonth();
  
  return (
    <div className={`birthday-bonus-card ${isBirthdayMonth ? 'this-month' : ''}`}>
      <h5>🎂 Birthday Bonus</h5>
      <p>{daysUntil} days until +{bonus} points!</p>
      {isBirthdayMonth && (
        <button 
          className="btn-claim-birthday"
          onClick={() => onClaimBonus()}
        >
          Claim Now
        </button>
      )}
    </div>
  );
};
