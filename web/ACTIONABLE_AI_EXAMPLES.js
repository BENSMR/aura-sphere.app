/**
 * Actionable AI Examples
 * 10 production-ready implementation examples
 * 
 * @file
 */

// =============================================================================
// EXAMPLE 1: Basic Dashboard with Actions
// =============================================================================

import React, { useState, useEffect } from 'react';
import { getActionableAI } from '../ai/actionsOnly';
import { ActionsList } from '../components/ActionableAIComponents';

function DashboardPage({ user, businessData }) {
  const [actions, setActions] = useState([]);

  useEffect(() => {
    // Build context from business data
    const context = buildContextFromBusiness(businessData);

    // Generate actions (max 3)
    const generatedActions = getActionableAI(context, {
      maxActions: 3,
      enabledTypes: [
        'remind_client',
        'send_invoice_reminder',
        'reorder_item',
        'approve_expense'
      ]
    });

    setActions(generatedActions);
  }, [businessData]);

  return (
    <div className="dashboard">
      <h1>Dashboard</h1>

      {actions.length > 0 && (
        <div className="actions-section">
          <ActionsList
            actions={actions}
            onActionComplete={() => {
              // Refresh business data
              refetchBusinessData();
            }}
          />
        </div>
      )}

      <div className="main-content">
        {/* Rest of dashboard */}
      </div>
    </div>
  );
}

function buildContextFromBusiness(data) {
  const inactiveClients = data.clients.filter(c =>
    Date.now() - new Date(c.lastContactDate) > 14 * 24 * 60 * 60 * 1000
  );

  const overdueInvoices = data.invoices.filter(i =>
    i.status === 'unpaid' &&
    Date.now() - new Date(i.dueDate) > 0
  );

  const lowStockItems = data.inventory.filter(i =>
    i.quantity < i.reorderPoint
  );

  return {
    // Client management
    inactiveClient: inactiveClients.length > 0,
    clientName: inactiveClients[0]?.name,
    clientId: inactiveClients[0]?.id,
    days: inactiveClients[0] 
      ? Math.floor((Date.now() - new Date(inactiveClients[0].lastContactDate)) / (24 * 60 * 60 * 1000))
      : 0,

    // Invoices
    overdueInvoice: overdueInvoices.length > 0,
    invoiceNumber: overdueInvoices[0]?.number,
    invoiceId: overdueInvoices[0]?.id,
    amountDue: overdueInvoices[0]?.total,
    daysOverdue: overdueInvoices[0]
      ? Math.floor((Date.now() - new Date(overdueInvoices[0].dueDate)) / (24 * 60 * 60 * 1000))
      : 0,

    // Inventory
    lowStock: lowStockItems.length > 0,
    item: lowStockItems[0]?.name,
    itemId: lowStockItems[0]?.id,
    currentStock: lowStockItems[0]?.quantity,
    reorderPoint: lowStockItems[0]?.reorderPoint,
    supplier: lowStockItems[0]?.preferredSupplier,
    supplierId: lowStockItems[0]?.preferredSupplierId
  };
}

// =============================================================================
// EXAMPLE 2: Action Widget in Header
// =============================================================================

import { ActionsWidget, ActionPanel } from '../components/ActionableAIComponents';

function AppHeader({ actions }) {
  const [showActionPanel, setShowActionPanel] = useState(false);

  return (
    <header className="app-header">
      <div className="header-left">
        <h1>AuraSphere Pro</h1>
      </div>

      <div className="header-right">
        {/* Other header items */}

        {/* Actions Widget */}
        <ActionsWidget
          actions={actions}
          onOpenActions={() => setShowActionPanel(true)}
        />

        {/* Action Panel Modal */}
        <ActionPanel
          actions={actions}
          isOpen={showActionPanel}
          onClose={() => setShowActionPanel(false)}
        />
      </div>
    </header>
  );
}

// =============================================================================
// EXAMPLE 3: Using the useActionableAI Hook
// =============================================================================

import { useActionableAI } from '../components/ActionableAIComponents';

function ClientsPage({ clientsData }) {
  const [showAll, setShowAll] = useState(false);

  // Hook automatically generates actions from context
  const {
    actions,
    isLoading,
    error,
    actionCount,
    criticalCount,
    highCount
  } = useActionableAI({
    inactiveClient: clientsData.hasInactive,
    clientName: clientsData.mostInactiveClient?.name,
    clientId: clientsData.mostInactiveClient?.id,
    days: clientsData.mostInactiveClient?.inactiveDays
  });

  if (isLoading) {
    return <LoadingSpinner />;
  }

  return (
    <div className="clients-page">
      {error && <ErrorAlert message={error} />}

      {criticalCount > 0 && (
        <div className="alert alert-critical">
          {criticalCount} critical action(s) needed
        </div>
      )}

      {highCount > 0 && (
        <div className="alert alert-high">
          {highCount} high-priority action(s) recommended
        </div>
      )}

      {actionCount > 0 && !showAll && (
        <div className="actions-preview">
          <p>
            {actionCount} suggested action{actionCount !== 1 ? 's' : ''} available
          </p>
          <button onClick={() => setShowAll(true)}>
            View Actions →
          </button>
        </div>
      )}

      {showAll && <ActionsList actions={actions} />}

      {/* Clients list below */}
      <ClientsList clients={clientsData.all} />
    </div>
  );
}

// =============================================================================
// EXAMPLE 4: Auto-Execute Urgent Actions
// =============================================================================

import { actionProcessor } from '../ai/actionProcessor';

async function executeUrgentActionsAuto(actions, userId) {
  // Filter for critical and immediate urgency
  const urgentActions = actions.filter(a =>
    a.priority === 'critical' &&
    a.urgency === 0 // IMMEDIATE
  );

  // Queue all urgent actions
  for (const action of urgentActions) {
    try {
      const queueId = await actionProcessor.queueAction(action, {
        priority: 1,    // Higher priority in queue
        immediate: false // Will execute in sequence
      });

      console.log(`Queued urgent action: ${action.title}`);

      // Persist to Firestore
      await persistAction(userId, action, {
        state: 'queued',
        queueId
      });

    } catch (error) {
      console.error(`Failed to queue action: ${action.title}`, error);
    }
  }

  // Start processing queue
  await actionProcessor.processQueue();
}

// =============================================================================
// EXAMPLE 5: Action History & Analytics
// =============================================================================

import { getActionStats, getActionHistoryFromFirestore } from '../ai/actionProcessor';

function ActionAnalyticsPage({ user }) {
  const [stats, setStats] = useState(null);
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadAnalytics = async () => {
      try {
        // Get last 30 days of stats
        const actionStats = await getActionStats(user.uid, 30);
        setStats(actionStats);

        // Get history
        const actionHistory = await getActionHistoryFromFirestore(user.uid, 50);
        setHistory(actionHistory);

      } finally {
        setLoading(false);
      }
    };

    loadAnalytics();
  }, [user]);

  if (loading) return <LoadingSpinner />;

  return (
    <div className="analytics-page">
      <h1>Action Analytics</h1>

      {stats && (
        <div className="stats-grid">
          <div className="stat-card">
            <h3>Total Actions</h3>
            <p className="stat-value">{stats.totalActions}</p>
          </div>

          <div className="stat-card">
            <h3>Success Rate</h3>
            <p className="stat-value">{stats.successRate}</p>
          </div>

          <div className="stat-card">
            <h3>Avg per Day</h3>
            <p className="stat-value">{stats.averageActionsPerDay}</p>
          </div>

          <div className="stat-card">
            <h3>Failed</h3>
            <p className="stat-value">{stats.failureCount}</p>
          </div>
        </div>
      )}

      {stats && (
        <div className="stats-breakdown">
          <h2>By Category</h2>
          <ul>
            {Object.entries(stats.byCategory).map(([category, count]) => (
              <li key={category}>
                {category}: <strong>{count}</strong>
              </li>
            ))}
          </ul>
        </div>
      )}

      <div className="history-section">
        <h2>Recent Actions ({history.length})</h2>
        <table>
          <thead>
            <tr>
              <th>Type</th>
              <th>Category</th>
              <th>Result</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            {history.map(item => (
              <tr key={item.id}>
                <td>{item.actionType}</td>
                <td>{item.category}</td>
                <td>
                  <span className={`badge badge-${item.result}`}>
                    {item.result}
                  </span>
                </td>
                <td>{new Date(item.executedAt).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// =============================================================================
// EXAMPLE 6: Real-Time Action Queue Monitor
// =============================================================================

import { ActionQueue } from '../components/ActionableAIComponents';

function AdminPanel() {
  return (
    <div className="admin-panel">
      <h1>Action Queue Monitor</h1>

      {/* Real-time queue display */}
      <ActionQueue />

      {/* Rest of admin panel */}
    </div>
  );
}

// =============================================================================
// EXAMPLE 7: Smart Context Builder from Multiple Sources
// =============================================================================

function buildSmartContext(clients, invoices, inventory, expenses, tasks) {
  const now = Date.now();
  const weekAgo = now - 7 * 24 * 60 * 60 * 1000;
  const monthAgo = now - 30 * 24 * 60 * 60 * 1000;

  // Find most critical issues
  const inactiveClients = clients.filter(c => {
    const lastContact = new Date(c.lastContactDate).getTime();
    return now - lastContact > 14 * 24 * 60 * 60 * 1000;
  });

  const veryOverdueInvoices = invoices.filter(i => {
    const dueDate = new Date(i.dueDate).getTime();
    return now - dueDate > 30 * 24 * 60 * 60 * 1000 && i.status === 'unpaid';
  });

  const criticalLowStock = inventory.filter(i =>
    i.quantity < (i.reorderPoint * 0.5)  // Less than 50% of reorder point
  );

  const pendingExpenses = expenses.filter(e => e.status === 'pending');

  const overdueTasksCount = tasks.filter(t =>
    new Date(t.dueDate).getTime() < now && t.status !== 'completed'
  ).length;

  return {
    // Client actions
    inactiveClient: inactiveClients.length > 0,
    clientName: inactiveClients[0]?.name,
    clientId: inactiveClients[0]?.id,
    days: inactiveClients[0] ?
      Math.floor((now - new Date(inactiveClients[0].lastContactDate).getTime()) / (24 * 60 * 60 * 1000)) : 0,

    // Invoice actions
    overdueInvoice: veryOverdueInvoices.length > 0,
    invoiceNumber: veryOverdueInvoices[0]?.number,
    invoiceId: veryOverdueInvoices[0]?.id,
    amountDue: veryOverdueInvoices[0]?.amount,
    daysOverdue: veryOverdueInvoices[0] ?
      Math.floor((now - new Date(veryOverdueInvoices[0].dueDate).getTime()) / (24 * 60 * 60 * 1000)) : 0,

    // Inventory actions
    lowStock: criticalLowStock.length > 0,
    item: criticalLowStock[0]?.name,
    itemId: criticalLowStock[0]?.id,
    currentStock: criticalLowStock[0]?.quantity,
    reorderPoint: criticalLowStock[0]?.reorderPoint,
    supplier: criticalLowStock[0]?.supplier,
    supplierId: criticalLowStock[0]?.supplierId,

    // Expense actions
    expenseApprovalPending: pendingExpenses.length > 0,
    expenseAmount: pendingExpenses[0]?.amount,
    expenseCategory: pendingExpenses[0]?.category,
    expenseId: pendingExpenses[0]?.id,

    // Task actions
    taskOverdue: overdueTasksCount > 0
  };
}

// =============================================================================
// EXAMPLE 8: Periodic Background Action Generation
// =============================================================================

function usePeriodicActionGeneration(businessData, interval = 300000) {
  const [actions, setActions] = useState([]);

  useEffect(() => {
    // Generate immediately
    const context = buildContextFromBusiness(businessData);
    const generated = getActionableAI(context);
    setActions(generated);

    // Then regenerate every interval (default 5 minutes)
    const timer = setInterval(() => {
      const updatedContext = buildContextFromBusiness(businessData);
      const updatedActions = getActionableAI(updatedContext);
      setActions(updatedActions);
    }, interval);

    return () => clearInterval(timer);
  }, [businessData, interval]);

  return actions;
}

// Usage in component
function DashboardWithAutoRefresh() {
  const actions = usePeriodicActionGeneration(businessData, 300000); // 5 min

  return <ActionsList actions={actions} />;
}

// =============================================================================
// EXAMPLE 9: Action Priority Filtering
// =============================================================================

import { ACTION_PRIORITY } from '../ai/actionsOnly';

function FilteredActionsList({ actions, showOnly = 'all' }) {
  let filtered = actions;

  if (showOnly === 'critical') {
    filtered = actions.filter(a => a.priority === ACTION_PRIORITY.CRITICAL);
  } else if (showOnly === 'high') {
    filtered = actions.filter(a =>
      a.priority === ACTION_PRIORITY.CRITICAL ||
      a.priority === ACTION_PRIORITY.HIGH
    );
  }

  return (
    <div className="filtered-actions">
      <div className="filter-controls">
        <button onClick={() => setShowOnly('all')}>All</button>
        <button onClick={() => setShowOnly('high')}>High+</button>
        <button onClick={() => setShowOnly('critical')}>Critical</button>
      </div>

      <ActionsList actions={filtered} />
    </div>
  );
}

// =============================================================================
// EXAMPLE 10: Mobile-Responsive Action Widget
// =============================================================================

function ResponsiveActionWidget({ actions }) {
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768);

  useEffect(() => {
    const handleResize = () => {
      setIsMobile(window.innerWidth < 768);
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  if (isMobile) {
    return (
      <div className="mobile-action-widget">
        <button className="floating-action-button">
          <span className="fab-icon">⚡</span>
          <span className="fab-count">{actions.length}</span>
        </button>

        {/* Slide-up panel on click */}
      </div>
    );
  }

  return (
    <div className="desktop-action-widget">
      <ActionsWidget actions={actions} />
    </div>
  );
}

// =============================================================================
// COMPLETE CSS STYLING GUIDE
// =============================================================================

export const ACTIONABLE_AI_STYLES = `
/*
 * Action Cards & Lists
 */

.action-card {
  border-left: 4px solid #3b82f6;  /* Blue by default */
  padding: 16px;
  background: white;
  border-radius: 8px;
  margin-bottom: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.2s ease;
}

.action-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
}

.action-card.priority-critical {
  border-left-color: #dc2626;
  background: #fef2f2;
}

.action-card.priority-high {
  border-left-color: #ea580c;
  background: #fffbf4;
}

.action-card.priority-medium {
  border-left-color: #2563eb;
  background: #f0f9ff;
}

.action-card.priority-low {
  border-left-color: #65a30d;
  background: #fefce8;
}

.action-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 12px;
}

.action-title-section {
  display: flex;
  gap: 12px;
  flex: 1;
}

.action-icon {
  font-size: 24px;
  flex-shrink: 0;
}

.action-text {
  flex: 1;
}

.action-title {
  margin: 0 0 4px 0;
  font-size: 16px;
  font-weight: 600;
  color: #1f2937;
}

.action-description {
  margin: 0;
  font-size: 14px;
  color: #6b7280;
}

.action-footer {
  display: flex;
  gap: 8px;
  padding-top: 12px;
  border-top: 1px solid #e5e7eb;
}

.btn-action {
  flex: 1;
  padding: 8px 12px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  transition: all 0.2s;
}

.btn-execute {
  background: #3b82f6;
  color: white;
}

.btn-execute:hover:not(:disabled) {
  background: #2563eb;
  transform: translateY(-1px);
}

.btn-defer {
  background: #f3f4f6;
  color: #374151;
}

.btn-defer:hover:not(:disabled) {
  background: #e5e7eb;
}

.btn-dismiss {
  background: transparent;
  color: #9ca3af;
  border: 1px solid #e5e7eb;
}

.btn-dismiss:hover:not(:disabled) {
  background: #f9fafb;
}

.badge {
  display: inline-block;
  padding: 4px 8px;
  margin-left: 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
}

.badge-urgency {
  background: #fee2e2;
  color: #991b1b;
}

.badge-time {
  background: #dbeafe;
  color: #1e40af;
}

/*
 * Action Widget
 */

.actions-widget {
  position: relative;
}

.widget-button {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: #f3f4f6;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
}

.widget-icon {
  font-size: 18px;
}

.widget-count {
  font-size: 16px;
  font-weight: 700;
  color: #3b82f6;
}

.widget-label {
  font-size: 12px;
  color: #6b7280;
  text-transform: uppercase;
}

.widget-badge {
  position: absolute;
  top: -8px;
  right: -8px;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 700;
  color: white;
}

.widget-badge.critical {
  background: #dc2626;
}

.widget-badge.high {
  background: #ea580c;
}

/*
 * Mobile Responsive
 */

@media (max-width: 768px) {
  .action-card {
    padding: 12px;
  }

  .action-title {
    font-size: 14px;
  }

  .action-footer {
    gap: 4px;
  }

  .btn-action {
    padding: 6px 8px;
    font-size: 12px;
  }

  .floating-action-button {
    position: fixed;
    bottom: 20px;
    right: 20px;
    width: 56px;
    height: 56px;
    border-radius: 50%;
    background: #3b82f6;
    color: white;
    border: none;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
  }

  .fab-icon {
    font-size: 24px;
  }

  .fab-count {
    position: absolute;
    top: -8px;
    right: -8px;
    width: 24px;
    height: 24px;
    border-radius: 50%;
    background: #dc2626;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    font-weight: 700;
  }
}
`;

export default {
  DashboardPage,
  AppHeader,
  ClientsPage,
  DashboardWithAutoRefresh,
  ActionAnalyticsPage,
  buildSmartContext,
  usePeriodicActionGeneration,
  FilteredActionsList,
  ResponsiveActionWidget,
  executeUrgentActionsAuto
};
