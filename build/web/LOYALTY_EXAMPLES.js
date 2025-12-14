/**
 * LOYALTY PROGRAM - IMPLEMENTATION EXAMPLES
 * 
 * 8 complete, production-ready examples showing:
 * - Point calculation and tier management
 * - Dashboard integration
 * - Redemption workflows
 * - Analytics and reporting
 * - Firestore operations
 * - React component usage
 */

import React, { useState, useEffect } from 'react';
import {
  collection,
  doc,
  getDoc,
  updateDoc,
  addDoc,
  query,
  where,
  getDocs,
  increment
} from 'firebase/firestore';
import { db } from '../config/firebase';
import {
  calculatePointsEarned,
  getTierFromPoints,
  getTierProgress,
  applyLoyaltyDiscount,
  buildLoyaltyProfile,
  checkMilestoneReward,
  calculateRedeemablePoints,
  LOYALTY_TIERS
} from '../loyalty/loyaltyProgram';
import {
  LoyaltyStatusCard,
  PointsRedemption,
  LoyaltyStats,
  TierShowcase,
  LoyaltyDiscountToggle
} from '../components/LoyaltyComponents';

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 1: Record Purchase & Award Points
// ─────────────────────────────────────────────────────────────────────────

/**
 * Complete purchase workflow with loyalty point award
 */
export async function example1_recordPurchaseWithLoyalty(clientId, purchaseAmount) {
  console.log(`\n📝 EXAMPLE 1: Recording purchase for client ${clientId}`);
  
  try {
    // 1. Fetch current client data
    const clientRef = doc(db, 'clients', clientId);
    const clientSnap = await getDoc(clientRef);
    const clientData = clientSnap.data();
    
    // 2. Calculate points based on current tier
    const currentTier = getTierFromPoints(clientData.loyaltyPoints || 0).id;
    const pointsEarned = calculatePointsEarned(purchaseAmount, currentTier);
    
    console.log(`  💰 Purchase: $${purchaseAmount}`);
    console.log(`  ⭐ Current Tier: ${currentTier}`);
    console.log(`  🎯 Points Earned: ${pointsEarned}`);
    
    // 3. Calculate new total and check for tier upgrade
    const newPointsTotal = (clientData.loyaltyPoints || 0) + pointsEarned;
    const newTier = getTierFromPoints(newPointsTotal).id;
    const tierUpgraded = currentTier !== newTier;
    
    if (tierUpgraded) {
      console.log(`  🎉 TIER UPGRADE: ${currentTier} → ${newTier}!`);
    }
    
    // 4. Check for milestone rewards
    const newTotalSpent = (clientData.totalSpent || 0) + purchaseAmount;
    const milestone = checkMilestoneReward(newTotalSpent, clientData.claimedMilestones || []);
    
    if (milestone.milestone) {
      console.log(`  🏆 MILESTONE UNLOCKED: ${milestone.milestone.label} (+${milestone.rewardPoints} points)`);
    }
    
    // 5. Update client document with new loyalty info
    await updateDoc(clientRef, {
      loyaltyPoints: newPointsTotal,
      loyaltyTier: newTier,
      totalSpent: newTotalSpent,
      totalPurchases: increment(1),
      lastPurchaseDate: new Date(),
      ...(milestone.milestone && {
        claimedMilestones: [...(clientData.claimedMilestones || []), milestone.milestone.label],
        loyaltyPoints: newPointsTotal + milestone.rewardPoints
      })
    });
    
    // 6. Record transaction in loyalty history
    const transactionRef = collection(db, 'loyaltyTransactions');
    await addDoc(transactionRef, {
      userId: clientId,
      type: 'purchase',
      amount: purchaseAmount,
      pointsChange: pointsEarned,
      timestamp: new Date(),
      description: `Purchase of $${purchaseAmount}`,
      reference: `order_${Date.now()}`,
      tier: currentTier,
      metadata: {
        tierUpgraded,
        newTier: tierUpgraded ? newTier : null,
        milestone: milestone.milestone ? milestone.milestone.label : null
      }
    });
    
    console.log(`  ✅ Purchase recorded successfully`);
    return { success: true, pointsEarned, tierUpgraded, milestone };
    
  } catch (error) {
    console.error('Error recording purchase:', error);
    return { success: false, error: error.message };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 2: Render Loyalty Dashboard
// ─────────────────────────────────────────────────────────────────────────

/**
 * Full loyalty dashboard component with all key sections
 */
export function Example2_LoyaltyDashboard() {
  const [clientData, setClientData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview');
  
  useEffect(() => {
    // Load client data on mount
    loadClientData();
  }, []);
  
  async function loadClientData() {
    try {
      // In real app, get clientId from auth
      const clientId = 'sample_client_123';
      const clientRef = doc(db, 'clients', clientId);
      const snap = await getDoc(clientRef);
      setClientData(snap.data());
    } catch (error) {
      console.error('Error loading client data:', error);
    } finally {
      setLoading(false);
    }
  }
  
  if (loading) return <div>Loading...</div>;
  if (!clientData) return <div>No client data found</div>;
  
  return (
    <div className="loyalty-dashboard">
      <h1>💎 Your Loyalty Program</h1>
      
      {/* Tab Navigation */}
      <div className="dashboard-tabs">
        <button 
          className={`tab ${activeTab === 'overview' ? 'active' : ''}`}
          onClick={() => setActiveTab('overview')}
        >
          Overview
        </button>
        <button 
          className={`tab ${activeTab === 'tiers' ? 'active' : ''}`}
          onClick={() => setActiveTab('tiers')}
        >
          Tiers
        </button>
        <button 
          className={`tab ${activeTab === 'redeem' ? 'active' : ''}`}
          onClick={() => setActiveTab('redeem')}
        >
          Redeem Points
        </button>
        <button 
          className={`tab ${activeTab === 'stats' ? 'active' : ''}`}
          onClick={() => setActiveTab('stats')}
        >
          Statistics
        </button>
      </div>
      
      {/* Overview Tab */}
      {activeTab === 'overview' && (
        <div className="tab-content">
          <LoyaltyStatusCard 
            clientData={clientData}
            onAction={(action) => {
              if (action === 'viewBenefits') {
                setActiveTab('tiers');
              }
            }}
          />
        </div>
      )}
      
      {/* Tiers Tab */}
      {activeTab === 'tiers' && (
        <div className="tab-content">
          <TierShowcase currentPoints={clientData.loyaltyPoints} />
        </div>
      )}
      
      {/* Redeem Tab */}
      {activeTab === 'redeem' && (
        <div className="tab-content">
          <PointsRedemption 
            currentPoints={clientData.loyaltyPoints}
            onRedeem={(points) => example3_redeemPoints(clientData.id, points)}
          />
        </div>
      )}
      
      {/* Stats Tab */}
      {activeTab === 'stats' && (
        <div className="tab-content">
          <LoyaltyStats clientData={clientData} />
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 3: Points Redemption
// ─────────────────────────────────────────────────────────────────────────

/**
 * Complete points redemption workflow
 */
export async function example3_redeemPoints(clientId, pointsToRedeem) {
  console.log(`\n🎁 EXAMPLE 3: Redeeming ${pointsToRedeem} points for client ${clientId}`);
  
  try {
    const clientRef = doc(db, 'clients', clientId);
    const clientSnap = await getDoc(clientRef);
    const clientData = clientSnap.data();
    
    // 1. Validate redemption
    const redemptionInfo = calculateRedeemablePoints(clientData.loyaltyPoints);
    
    if (pointsToRedeem > redemptionInfo.redeemablePoints) {
      console.error(`❌ Cannot redeem ${pointsToRedeem} points (only ${redemptionInfo.redeemablePoints} available)`);
      return { success: false, error: 'Insufficient redeemable points' };
    }
    
    const dollarValue = pointsToRedeem / 100;
    console.log(`  💰 Redemption Value: $${dollarValue.toFixed(2)}`);
    
    // 2. Update client points balance
    const newPointsBalance = clientData.loyaltyPoints - pointsToRedeem;
    
    await updateDoc(clientRef, {
      loyaltyPoints: newPointsBalance,
      totalPointsRedeemed: (clientData.totalPointsRedeemed || 0) + pointsToRedeem,
      lastRedemptionDate: new Date()
    });
    
    // 3. Record redemption transaction
    await addDoc(collection(db, 'loyaltyTransactions'), {
      userId: clientId,
      type: 'redemption',
      pointsChange: -pointsToRedeem,
      dollarValue,
      timestamp: new Date(),
      description: `Redeemed ${pointsToRedeem} points for $${dollarValue.toFixed(2)} off`,
      reference: `redemption_${Date.now()}`
    });
    
    // 4. Create coupon/discount code if needed
    const discountCode = `LOYAL${Date.now()}`;
    console.log(`  🎟️ Discount Code: ${discountCode}`);
    
    console.log(`  ✅ Redemption successful!`);
    return { 
      success: true, 
      dollarValue, 
      newBalance: newPointsBalance,
      discountCode 
    };
    
  } catch (error) {
    console.error('Error redeeming points:', error);
    return { success: false, error: error.message };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 4: Apply Loyalty Discount at Checkout
// ─────────────────────────────────────────────────────────────────────────

/**
 * Calculate order total with loyalty discount applied
 */
export function example4_applyDiscountAtCheckout(clientData, subtotal) {
  console.log(`\n💳 EXAMPLE 4: Applying loyalty discount at checkout`);
  
  const tier = getTierFromPoints(clientData.loyaltyPoints);
  const discountInfo = applyLoyaltyDiscount(subtotal, tier.id);
  
  console.log(`  🛒 Subtotal: $${subtotal.toFixed(2)}`);
  console.log(`  💎 Tier: ${tier.name}`);
  console.log(`  🏷️ Discount: ${discountInfo.discountPercent}% (-$${discountInfo.discountAmount.toFixed(2)})`);
  console.log(`  💰 Total: $${discountInfo.final.toFixed(2)}`);
  
  return {
    subtotal: discountInfo.original,
    discountPercent: discountInfo.discountPercent,
    discountAmount: discountInfo.discountAmount,
    total: discountInfo.final,
    tier: tier.name,
    savings: discountInfo.discountAmount
  };
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 5: Generate Loyalty Report
// ─────────────────────────────────────────────────────────────────────────

/**
 * Build comprehensive loyalty analytics report
 */
export async function example5_generateLoyaltyReport() {
  console.log(`\n📊 EXAMPLE 5: Generating loyalty program report`);
  
  try {
    // 1. Fetch all client loyalty data
    const clientsRef = collection(db, 'clients');
    const clientsSnap = await getDocs(clientsRef);
    
    const report = {
      generatedAt: new Date(),
      totalMembers: clientsSnap.size,
      byTier: { bronze: 0, silver: 0, gold: 0, platinum: 0 },
      totalPointsIssued: 0,
      totalPointsRedeemed: 0,
      totalDiscountsSaved: 0,
      averagePointsPerMember: 0,
      tierProgression: {},
      topSpenders: []
    };
    
    const memberData = [];
    
    // 2. Process each client
    clientsSnap.forEach(clientDoc => {
      const data = clientDoc.data();
      const tier = getTierFromPoints(data.loyaltyPoints || 0);
      
      report.byTier[tier.id]++;
      report.totalPointsIssued += data.loyaltyPoints || 0;
      report.totalPointsRedeemed += data.totalPointsRedeemed || 0;
      report.totalDiscountsSaved += (data.totalSpent || 0) * (tier.baseDiscount / 100);
      
      memberData.push({
        id: clientDoc.id,
        points: data.loyaltyPoints || 0,
        spent: data.totalSpent || 0,
        tier: tier.id,
        purchases: data.totalPurchases || 0
      });
    });
    
    // 3. Calculate averages
    report.averagePointsPerMember = Math.floor(report.totalPointsIssued / report.totalMembers);
    
    // 4. Find top spenders
    report.topSpenders = memberData
      .sort((a, b) => b.spent - a.spent)
      .slice(0, 10)
      .map(m => ({
        id: m.id,
        tier: m.tier,
        spent: m.spent,
        points: m.points,
        purchases: m.purchases
      }));
    
    // 5. Calculate tier progression
    Object.keys(report.byTier).forEach(tier => {
      report.tierProgression[tier] = {
        count: report.byTier[tier],
        percentage: ((report.byTier[tier] / report.totalMembers) * 100).toFixed(1)
      };
    });
    
    console.log(`
    ╔═══════════════════════════════════════╗
    ║     LOYALTY PROGRAM REPORT            ║
    ╠═══════════════════════════════════════╣
    ║ Total Members:      ${String(report.totalMembers).padEnd(20)}║
    ║ Avg Points/Member:  ${String(report.averagePointsPerMember).padEnd(20)}║
    ║ Total Discounts:    $${String(report.totalDiscountsSaved.toFixed(2)).padEnd(19)}║
    ║ Points Redeemed:    ${String(report.totalPointsRedeemed).padEnd(20)}║
    ╠═══════════════════════════════════════╣
    ║ TIER DISTRIBUTION                     ║
    ${Object.keys(report.tierProgression).map(tier => 
      `║ ${String(tier.toUpperCase()).padEnd(8)} ${String(report.tierProgression[tier].count).padEnd(6)} members (${String(report.tierProgression[tier].percentage + '%').padEnd(5)})       ║`
    ).join('\n')}
    ╚═══════════════════════════════════════╝
    `);
    
    return report;
    
  } catch (error) {
    console.error('Error generating report:', error);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 6: Tier Progress Visualization Component
// ─────────────────────────────────────────────────────────────────────────

/**
 * React component showing path to next tier with visual breakdown
 */
export function Example6_TierProgressVisual({ clientData }) {
  const profile = buildLoyaltyProfile(clientData);
  const { currentTier, nextTier, progress, pointsNeededForNext } = profile.tierProgress;
  
  return (
    <div className="tier-progress-visual">
      <h3>Progress to {nextTier?.name || 'Maximum Tier'}</h3>
      
      <div className="progress-container">
        {/* Current Tier */}
        <div className="tier-marker">
          <div className="tier-badge current">{currentTier.icon}</div>
          <span className="tier-label">{currentTier.name}</span>
        </div>
        
        {/* Progress Bar */}
        <div className="progress-track">
          <div className="progress-bar">
            <div className="progress-fill" style={{ width: `${progress}%` }}>
              <span className="progress-text">{progress}%</span>
            </div>
          </div>
          <div className="progress-labels">
            <span className="progress-start">{currentTier.minPoints}</span>
            <span className="progress-current">{profile.points}</span>
            <span className="progress-end">{nextTier?.minPoints || 'Max'}</span>
          </div>
        </div>
        
        {/* Next Tier */}
        {nextTier && (
          <div className="tier-marker">
            <div className="tier-badge next" style={{ opacity: 0.5 }}>
              {nextTier.icon}
            </div>
            <span className="tier-label">{nextTier.name}</span>
          </div>
        )}
      </div>
      
      {/* Points Needed Display */}
      {nextTier && pointsNeededForNext > 0 && (
        <div className="points-needed">
          <p className="needs-text">
            <strong>{pointsNeededForNext}</strong> points needed to reach <strong>{nextTier.name}</strong>
          </p>
          <div className="points-breakdown">
            <span className="earned">Earned: {profile.points}</span>
            <span className="separator">→</span>
            <span className="needed">{nextTier.minPoints}</span>
          </div>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 7: Batch Award Milestone Points
// ─────────────────────────────────────────────────────────────────────────

/**
 * Check all clients for milestone rewards and award automatically
 */
export async function example7_batchAwardMilestones() {
  console.log(`\n🏆 EXAMPLE 7: Batch awarding milestone points`);
  
  try {
    const clientsRef = collection(db, 'clients');
    const clientsSnap = await getDocs(clientsRef);
    
    let awardCount = 0;
    let totalPointsAwarded = 0;
    
    for (const clientDoc of clientsSnap.docs) {
      const clientData = clientDoc.data();
      const clientId = clientDoc.id;
      
      // Check for new milestones
      const milestone = checkMilestoneReward(
        clientData.totalSpent || 0,
        clientData.claimedMilestones || []
      );
      
      if (milestone.milestone) {
        console.log(`  🎯 ${clientId}: Awarding ${milestone.rewardPoints} pts for ${milestone.milestone.label}`);
        
        // Award points
        await updateDoc(doc(db, 'clients', clientId), {
          loyaltyPoints: increment(milestone.rewardPoints),
          claimedMilestones: [...(clientData.claimedMilestones || []), milestone.milestone.label]
        });
        
        // Record transaction
        await addDoc(collection(db, 'loyaltyTransactions'), {
          userId: clientId,
          type: 'reward',
          pointsChange: milestone.rewardPoints,
          timestamp: new Date(),
          description: `Milestone reward: ${milestone.milestone.label}`,
          reference: `milestone_${milestone.milestone.label}`
        });
        
        awardCount++;
        totalPointsAwarded += milestone.rewardPoints;
      }
    }
    
    console.log(`  ✅ Awarded to ${awardCount} clients, ${totalPointsAwarded} total points`);
    return { awardCount, totalPointsAwarded };
    
  } catch (error) {
    console.error('Error batch awarding milestones:', error);
    return { awardCount: 0, error: error.message };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 8: Birthday Bonus Automation
// ─────────────────────────────────────────────────────────────────────────

/**
 * Check for birthday anniversaries and award bonus points
 */
export async function example8_awardBirthdayBonuses() {
  console.log(`\n🎂 EXAMPLE 8: Awarding birthday bonuses`);
  
  try {
    const today = new Date();
    const month = today.getMonth();
    const day = today.getDate();
    
    // Find clients with birthdays today
    const clientsRef = collection(db, 'clients');
    const birthdayQuery = query(clientsRef, where('isBirthdayToday', '==', true));
    const birthdaySnap = await getDocs(birthdayQuery);
    
    let bonusCount = 0;
    let totalBonusPoints = 0;
    
    for (const clientDoc of birthdaySnap.docs) {
      const clientData = clientDoc.data();
      const clientId = clientDoc.id;
      
      // Check if already awarded this year
      const lastBonus = clientData.lastBirthdayBonus 
        ? new Date(clientData.lastBirthdayBonus)
        : null;
      
      const alreadyAwarded = lastBonus && 
        lastBonus.getFullYear() === today.getFullYear();
      
      if (!alreadyAwarded) {
        const tier = getTierFromPoints(clientData.loyaltyPoints || 0);
        const bonusPoints = Math.floor(25 * tier.pointsMultiplier); // 25 base for bronze
        
        console.log(`  🎁 ${clientId}: Birthday bonus +${bonusPoints} pts (${tier.name})`);
        
        // Award bonus
        await updateDoc(doc(db, 'clients', clientId), {
          loyaltyPoints: increment(bonusPoints),
          lastBirthdayBonus: new Date()
        });
        
        // Record transaction
        await addDoc(collection(db, 'loyaltyTransactions'), {
          userId: clientId,
          type: 'reward',
          pointsChange: bonusPoints,
          timestamp: new Date(),
          description: `Birthday bonus (${tier.name})`,
          reference: `birthday_${today.getFullYear()}`
        });
        
        bonusCount++;
        totalBonusPoints += bonusPoints;
      }
    }
    
    console.log(`  ✅ Awarded ${bonusCount} birthday bonuses, ${totalBonusPoints} total points`);
    return { bonusCount, totalBonusPoints };
    
  } catch (error) {
    console.error('Error awarding birthday bonuses:', error);
    return { bonusCount: 0, error: error.message };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// CSS STYLING REFERENCE
// ─────────────────────────────────────────────────────────────────────────

export const LOYALTY_STYLES = `
/* Loyalty Dashboard Base */
.loyalty-dashboard {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  background: #f8f9fa;
}

/* Status Card */
.loyalty-status-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 24px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.status-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.tier-badge {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 24px;
  font-weight: bold;
}

.tier-icon {
  font-size: 40px;
}

.points-display {
  text-align: right;
}

.points-value {
  font-size: 32px;
  font-weight: bold;
  color: #2ecc71;
}

.points-label {
  color: #7f8c8d;
  font-size: 14px;
}

/* Tier Progress */
.tier-progress {
  margin-top: 20px;
}

.progress-bar {
  width: 100%;
  height: 12px;
  background: #ecf0f1;
  border-radius: 6px;
  overflow: hidden;
  margin: 10px 0;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #3498db, #2ecc71);
  transition: width 0.3s ease;
}

/* Tier Cards Grid */
.tiers-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin: 20px 0;
}

.tier-card {
  border: 2px solid #ecf0f1;
  border-radius: 12px;
  padding: 20px;
  text-align: center;
  transition: all 0.3s ease;
  cursor: pointer;
}

.tier-card.active {
  border-color: #2ecc71;
  background: #f0fdf4;
  box-shadow: 0 4px 12px rgba(46, 204, 113, 0.2);
}

.tier-card.locked {
  opacity: 0.6;
}

.tier-icon-large {
  font-size: 48px;
  margin-bottom: 10px;
}

.tier-name-card {
  font-weight: bold;
  font-size: 18px;
  display: block;
  margin: 10px 0;
}

/* Redemption Card */
.redemption-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.redemption-card.locked {
  opacity: 0.7;
  background: #f8f9fa;
}

.redemption-locked-icon {
  font-size: 48px;
  text-align: center;
  margin: 20px 0;
}

.redemption-buttons {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin: 16px 0;
}

.btn-redemption {
  padding: 10px 16px;
  border: 1px solid #3498db;
  background: white;
  color: #3498db;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.3s ease;
}

.btn-redemption.primary {
  background: #3498db;
  color: white;
}

.btn-redemption:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(52, 152, 219, 0.2);
}

/* Statistics */
.loyalty-stats {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 16px;
  margin: 20px 0;
}

.stat-item {
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
  text-align: center;
}

.stat-label {
  font-size: 12px;
  color: #7f8c8d;
  text-transform: uppercase;
  margin-bottom: 8px;
  display: block;
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #2c3e50;
}

.stat-value.highlight {
  color: #2ecc71;
}

/* Loyalty Widget */
.loyalty-widget {
  background: white;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.widget-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.widget-points {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin: 12px 0;
}

.points-number {
  font-size: 28px;
  font-weight: bold;
  color: #2ecc71;
}

/* Responsive */
@media (max-width: 768px) {
  .loyalty-dashboard {
    padding: 12px;
  }
  
  .status-header {
    flex-direction: column;
    gap: 12px;
    align-items: flex-start;
  }
  
  .tiers-grid {
    grid-template-columns: 1fr;
  }
  
  .stats-grid {
    grid-template-columns: 1fr 1fr;
  }
  
  .redemption-buttons {
    grid-template-columns: 1fr;
  }
}
`;
