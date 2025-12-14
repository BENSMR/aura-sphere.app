/**
 * ACTIONABLE AI - HELPER FUNCTIONS
 * 
 * Data fetching utilities for AI action suggestions
 * Queries Firestore for real business data:
 * - Overdue invoices
 * - Low inventory
 * - Inactive clients
 * - Overdue tasks
 * - Team workload
 */

import { db } from '../config/firebase';
import {
  collection,
  query,
  where,
  getDocs,
  orderBy,
  limit,
  Timestamp
} from 'firebase/firestore';

// ─────────────────────────────────────────────────────────────────────────
// INVOICE HELPERS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get overdue unpaid invoices
 * @param {string} userId - Owner/user ID
 * @returns {Promise<array>} Array of overdue invoice objects
 * @example
 * const overdue = await getOverdueInvoices(userId);
 * // [{id: 'inv-123', clientId: 'cli-456', amount: 1500, daysLate: 5}, ...]
 */
export async function getOverdueInvoices(userId) {
  try {
    const today = Timestamp.now();
    
    const q = query(
      collection(db, 'invoices'),
      where('ownerId', '==', userId),
      where('status', '==', 'unpaid'),
      where('dueDate', '<', today),
      orderBy('dueDate', 'asc'),
      limit(10)
    );
    
    const snapshot = await getDocs(q);
    
    return snapshot.docs.map(doc => {
      const data = doc.data();
      const dueDate = data.dueDate?.toDate() || new Date();
      const daysLate = Math.floor((today.toDate() - dueDate) / (1000 * 60 * 60 * 24));
      
      return {
        id: doc.id,
        invoiceNumber: data.invoiceNumber,
        clientId: data.clientId,
        clientName: data.clientName,
        amount: data.amount,
        dueDate: dueDate.toLocaleDateString(),
        daysLate,
        status: data.status,
        priority: daysLate > 30 ? 'critical' : daysLate > 7 ? 'high' : 'medium'
      };
    });
  } catch (error) {
    console.error('Error fetching overdue invoices:', error);
    return [];
  }
}

/**
 * Get upcoming invoices (due in next 7 days)
 * @param {string} userId - Owner/user ID
 * @returns {Promise<array>} Array of upcoming invoice objects
 */
export async function getUpcomingInvoices(userId) {
  try {
    const today = Timestamp.now();
    const weekFromNow = Timestamp.fromDate(
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    );
    
    const q = query(
      collection(db, 'invoices'),
      where('ownerId', '==', userId),
      where('status', '==', 'unpaid'),
      where('dueDate', '>=', today),
      where('dueDate', '<=', weekFromNow),
      orderBy('dueDate', 'asc'),
      limit(10)
    );
    
    const snapshot = await getDocs(q);
    
    return snapshot.docs.map(doc => {
      const data = doc.data();
      const dueDate = data.dueDate?.toDate() || new Date();
      const daysUntilDue = Math.floor((dueDate - today.toDate()) / (1000 * 60 * 60 * 24));
      
      return {
        id: doc.id,
        invoiceNumber: data.invoiceNumber,
        clientId: data.clientId,
        clientName: data.clientName,
        amount: data.amount,
        dueDate: dueDate.toLocaleDateString(),
        daysUntilDue
      };
    });
  } catch (error) {
    console.error('Error fetching upcoming invoices:', error);
    return [];
  }
}

/**
 * Get payment statistics
 * @param {string} userId - Owner/user ID
 * @returns {Promise<object>} Payment stats
 */
export async function getPaymentStats(userId) {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const q = query(
      collection(db, 'invoices'),
      where('ownerId', '==', userId)
    );
    
    const snapshot = await getDocs(q);
    const invoices = snapshot.docs.map(doc => doc.data());
    
    const totalRevenue = invoices
      .filter(inv => inv.status === 'paid')
      .reduce((sum, inv) => sum + (inv.amount || 0), 0);
    
    const unpaidAmount = invoices
      .filter(inv => inv.status === 'unpaid')
      .reduce((sum, inv) => sum + (inv.amount || 0), 0);
    
    const overdue = invoices.filter(inv => 
      inv.status === 'unpaid' && inv.dueDate?.toDate() < today
    ).length;
    
    return {
      totalRevenue: Math.round(totalRevenue * 100) / 100,
      unpaidAmount: Math.round(unpaidAmount * 100) / 100,
      overduCount: overdue,
      totalInvoices: invoices.length,
      paidCount: invoices.filter(i => i.status === 'paid').length
    };
  } catch (error) {
    console.error('Error fetching payment stats:', error);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// INVENTORY HELPERS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get low stock items
 * @param {string} userId - Owner/user ID
 * @param {number} threshold - Stock level threshold (default 10)
 * @returns {Promise<array>} Array of low-stock items
 * @example
 * const lowStock = await getLowStock(userId, 5);
 * // [{id: 'item-1', name: 'Paint', currentStock: 2, minStock: 10}, ...]
 */
export async function getLowStock(userId, threshold = 10) {
  try {
    const q = query(
      collection(db, 'inventory'),
      where('ownerId', '==', userId),
      where('currentStock', '<=', threshold),
      orderBy('currentStock', 'asc'),
      limit(15)
    );
    
    const snapshot = await getDocs(q);
    
    return snapshot.docs.map(doc => {
      const data = doc.data();
      
      return {
        id: doc.id,
        name: data.name,
        sku: data.sku,
        currentStock: data.currentStock,
        minStock: data.minStock || 10,
        reorderQuantity: data.reorderQuantity || data.minStock * 2,
        unitCost: data.unitCost,
        lastRestockDate: data.lastRestockDate?.toDate()?.toLocaleDateString(),
        status: data.currentStock === 0 ? 'out-of-stock' : 'low-stock'
      };
    });
  } catch (error) {
    console.error('Error fetching low stock items:', error);
    return [];
  }
}

/**
 * Get inventory value and stats
 * @param {string} userId - Owner/user ID
 * @returns {Promise<object>} Inventory statistics
 */
export async function getInventoryStats(userId) {
  try {
    const q = query(
      collection(db, 'inventory'),
      where('ownerId', '==', userId)
    );
    
    const snapshot = await getDocs(q);
    const items = snapshot.docs.map(doc => doc.data());
    
    const totalValue = items.reduce((sum, item) => 
      sum + (item.currentStock * item.unitCost || 0), 0
    );
    
    const lowStockCount = items.filter(item => 
      item.currentStock <= (item.minStock || 10)
    ).length;
    
    const outOfStock = items.filter(item => item.currentStock === 0).length;
    
    return {
      totalItems: items.length,
      totalValue: Math.round(totalValue * 100) / 100,
      lowStockCount,
      outOfStock,
      healthScore: outOfStock === 0 && lowStockCount < 3 ? 'good' : 'needs-attention'
    };
  } catch (error) {
    console.error('Error fetching inventory stats:', error);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// CLIENT HELPERS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get inactive clients (no activity in 30+ days)
 * @param {string} userId - Owner/user ID
 * @param {number} days - Days threshold (default 30)
 * @returns {Promise<array>} Array of inactive client objects
 * @example
 * const inactive = await getInactiveClients(userId, 30);
 * // [{id: 'cli-1', name: 'Acme Corp', lastActivity: '2024-10-15', daysSinceContact: 45}, ...]
 */
export async function getInactiveClients(userId, days = 30) {
  try {
    const cutoffDate = Timestamp.fromDate(
      new Date(Date.now() - days * 24 * 60 * 60 * 1000)
    );
    
    const q = query(
      collection(db, 'clients'),
      where('ownerId', '==', userId),
      where('lastContactDate', '<', cutoffDate),
      orderBy('lastContactDate', 'asc'),
      limit(15)
    );
    
    const snapshot = await getDocs(q);
    
    return snapshot.docs.map(doc => {
      const data = doc.data();
      const lastContact = data.lastContactDate?.toDate() || new Date(0);
      const daysSinceContact = Math.floor(
        (Date.now() - lastContact) / (1000 * 60 * 60 * 24)
      );
      
      return {
        id: doc.id,
        name: data.name,
        email: data.email,
        phone: data.phone,
        lastContactDate: lastContact.toLocaleDateString(),
        daysSinceContact,
        totalSpent: data.totalSpent || 0,
        status: daysSinceContact > 90 ? 'at-risk' : 'inactive',
        lastInteraction: data.lastInteraction // 'invoice', 'email', 'call', etc
      };
    });
  } catch (error) {
    console.error('Error fetching inactive clients:', error);
    return [];
  }
}

/**
 * Get high-value inactive clients
 * @param {string} userId - Owner/user ID
 * @returns {Promise<array>} High-value clients with no recent activity
 */
export async function getHighValueInactiveClients(userId) {
  try {
    const cutoffDate = Timestamp.fromDate(
      new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    );
    
    const q = query(
      collection(db, 'clients'),
      where('ownerId', '==', userId),
      where('totalSpent', '>=', 5000), // High value: $5k+
      where('lastContactDate', '<', cutoffDate),
      orderBy('totalSpent', 'desc'),
      limit(10)
    );
    
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      lastContactDate: doc.data().lastContactDate?.toDate()?.toLocaleDateString()
    }));
  } catch (error) {
    console.error('Error fetching high-value inactive clients:', error);
    return [];
  }
}

/**
 * Get client growth metrics
 * @param {string} userId - Owner/user ID
 * @returns {Promise<object>} Client metrics
 */
export async function getClientStats(userId) {
  try {
    const q = query(
      collection(db, 'clients'),
      where('ownerId', '==', userId)
    );
    
    const snapshot = await getDocs(q);
    const clients = snapshot.docs.map(doc => doc.data());
    
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const newClients = clients.filter(c => 
      c.createdAt?.toDate?.() > thirtyDaysAgo
    ).length;
    
    const totalRevenue = clients.reduce((sum, c) => sum + (c.totalSpent || 0), 0);
    const averageValue = clients.length ? totalRevenue / clients.length : 0;
    
    return {
      totalClients: clients.length,
      newClientsThisMonth: newClients,
      totalRevenue: Math.round(totalRevenue * 100) / 100,
      averageClientValue: Math.round(averageValue * 100) / 100,
      activeClients: clients.filter(c => {
        const lastContact = c.lastContactDate?.toDate?.() || new Date(0);
        const daysSince = (Date.now() - lastContact) / (1000 * 60 * 60 * 24);
        return daysSince < 30;
      }).length
    };
  } catch (error) {
    console.error('Error fetching client stats:', error);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TASK HELPERS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get overdue tasks
 * @param {string} userId - User ID
 * @returns {Promise<array>} Array of overdue task objects
 */
export async function getOverdueTasks(userId) {
  try {
    const today = Timestamp.now();
    
    const q = query(
      collection(db, 'tasks'),
      where('assignedTo', '==', userId),
      where('status', '!=', 'completed'),
      where('dueDate', '<', today),
      orderBy('dueDate', 'asc'),
      limit(10)
    );
    
    const snapshot = await getDocs(q);
    
    return snapshot.docs.map(doc => {
      const data = doc.data();
      const dueDate = data.dueDate?.toDate() || new Date();
      const daysOverdue = Math.floor(
        (today.toDate() - dueDate) / (1000 * 60 * 60 * 24)
      );
      
      return {
        id: doc.id,
        title: data.title,
        description: data.description,
        dueDate: dueDate.toLocaleDateString(),
        daysOverdue,
        priority: data.priority,
        status: data.status
      };
    });
  } catch (error) {
    console.error('Error fetching overdue tasks:', error);
    return [];
  }
}

/**
 * Get task statistics for user
 * @param {string} userId - User ID
 * @returns {Promise<object>} Task stats
 */
export async function getTaskStats(userId) {
  try {
    const q = query(
      collection(db, 'tasks'),
      where('assignedTo', '==', userId)
    );
    
    const snapshot = await getDocs(q);
    const tasks = snapshot.docs.map(doc => doc.data());
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const overdue = tasks.filter(t => 
      t.status !== 'completed' && t.dueDate?.toDate?.() < today
    ).length;
    
    return {
      totalTasks: tasks.length,
      completedTasks: tasks.filter(t => t.status === 'completed').length,
      activeTasks: tasks.filter(t => t.status === 'in_progress').length,
      overdueTasks: overdue,
      completionRate: tasks.length ? 
        Math.round((tasks.filter(t => t.status === 'completed').length / tasks.length) * 100) 
        : 0
    };
  } catch (error) {
    console.error('Error fetching task stats:', error);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TEAM HELPERS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get team member workload
 * @param {string} userId - Owner/manager ID
 * @returns {Promise<array>} Array of team member workload objects
 */
export async function getTeamWorkload(userId) {
  try {
    // Get all team members
    const membersQ = query(
      collection(db, 'users'),
      where('teamOwnerId', '==', userId)
    );
    
    const membersSnapshot = await getDocs(membersQ);
    const members = membersSnapshot.docs;
    
    const workload = await Promise.all(
      members.map(async (memberDoc) => {
        const memberData = memberDoc.data();
        const stats = await getTaskStats(memberDoc.id);
        
        return {
          id: memberDoc.id,
          name: memberData.displayName || memberData.email,
          role: memberData.role,
          activeTasks: stats?.activeTasks || 0,
          completedTasks: stats?.completedTasks || 0,
          overdueTasks: stats?.overdueTasks || 0,
          completionRate: stats?.completionRate || 0,
          workloadStatus: (stats?.activeTasks || 0) > 10 ? 'overloaded' : 'available'
        };
      })
    );
    
    return workload;
  } catch (error) {
    console.error('Error fetching team workload:', error);
    return [];
  }
}

/**
 * Get team performance summary
 * @param {string} userId - Owner/manager ID
 * @returns {Promise<object>} Team stats
 */
export async function getTeamStats(userId) {
  try {
    const workload = await getTeamWorkload(userId);
    
    const totalActiveTasks = workload.reduce((sum, m) => sum + m.activeTasks, 0);
    const totalOverdue = workload.reduce((sum, m) => sum + m.overdueTasks, 0);
    const avgCompletion = workload.length ? 
      Math.round(workload.reduce((sum, m) => sum + m.completionRate, 0) / workload.length)
      : 0;
    
    return {
      teamSize: workload.length,
      totalActiveTasks,
      totalOverdue,
      averageCompletion: avgCompletion,
      overloadedMembers: workload.filter(m => m.workloadStatus === 'overloaded').length
    };
  } catch (error) {
    console.error('Error fetching team stats:', error);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXPORT ALL
// ─────────────────────────────────────────────────────────────────────────

export default {
  // Invoice functions
  getOverdueInvoices,
  getUpcomingInvoices,
  getPaymentStats,
  
  // Inventory functions
  getLowStock,
  getInventoryStats,
  
  // Client functions
  getInactiveClients,
  getHighValueInactiveClients,
  getClientStats,
  
  // Task functions
  getOverdueTasks,
  getTaskStats,
  
  // Team functions
  getTeamWorkload,
  getTeamStats
};
