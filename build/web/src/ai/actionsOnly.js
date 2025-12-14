/**
 * Actionable AI - Context-Triggered One-Tap Actions
 * Generates intelligent actions based on business context
 * 
 * @module ai/actionsOnly
 */

/**
 * Action type definitions
 * Define all possible action types in the system
 */
export const ACTION_TYPES = {
  // Client management
  REMIND_CLIENT: "remind_client",
  FOLLOW_UP_PROPOSAL: "follow_up_proposal",
  SEND_INVOICE_REMINDER: "send_invoice_reminder",
  UPDATE_CLIENT_STATUS: "update_client_status",

  // Inventory management
  REORDER_ITEM: "reorder_item",
  ALERT_LOW_STOCK: "alert_low_stock",
  PROCESS_INCOMING_STOCK: "process_incoming_stock",
  MARK_DAMAGED: "mark_damaged",

  // Finance
  RECORD_PAYMENT: "record_payment",
  CREATE_INVOICE: "create_invoice",
  SEND_PAYMENT_REMINDER: "send_payment_reminder",
  APPROVE_EXPENSE: "approve_expense",
  RECONCILE_ACCOUNT: "reconcile_account",

  // Tasks & Projects
  REASSIGN_TASK: "reassign_task",
  ESCALATE_TASK: "escalate_task",
  MARK_TASK_OVERDUE: "mark_task_overdue",
  CREATE_FOLLOWUP_TASK: "create_followup_task",

  // Team management
  ASSIGN_TO_AVAILABLE: "assign_to_available",
  REQUEST_TIME_OFF: "request_time_off",
  SCHEDULE_MEETING: "schedule_meeting",

  // Data quality
  DEDUPLICATE_CLIENT: "deduplicate_client",
  VALIDATE_INVOICE: "validate_invoice",
  VERIFY_PAYMENT: "verify_payment",

  // Automation
  RUN_WORKFLOW: "run_workflow",
  GENERATE_REPORT: "generate_report",
  EXPORT_DATA: "export_data"
};

/**
 * Priority levels for actions
 */
export const ACTION_PRIORITY = {
  CRITICAL: "critical",      // Financial risk, legal compliance
  HIGH: "high",              // Time-sensitive, revenue impact
  MEDIUM: "medium",          // Standard business operations
  LOW: "low"                 // Nice-to-have improvements
};

/**
 * Action urgency - how soon should it be done?
 */
export const ACTION_URGENCY = {
  IMMEDIATE: 0,              // < 1 hour
  SOON: 6,                   // < 6 hours
  TODAY: 24,                 // Today
  THIS_WEEK: 168,            // This week
  OPTIONAL: null             // No specific urgency
};

/**
 * Generate actionable AI suggestions based on context
 * Analyzes business state and recommends one-tap actions
 * 
 * MAX 3 actions returned at a time to avoid overwhelming user
 * 
 * @param {Object} context - Business context for analysis
 * @param {Object} [options={}] - Generation options
 * @param {number} [options.maxActions=3] - Max actions to return
 * @param {string} [options.priorityFilter] - Only actions of this priority
 * @param {Array<string>} [options.enabledTypes] - Only enabled action types
 * @returns {Array<Object>} Array of action objects
 * 
 * @example
 * const context = {
 *   inactiveClient: true,
 *   clientName: "Acme Corp",
 *   clientId: "client_123",
 *   days: 14,
 *   lowStock: true,
 *   item: "Widget A",
 *   supplier: "SupplierCo",
 *   itemId: "item_456"
 * };
 * 
 * const actions = getActionableAI(context);
 * // Returns: [action1, action2, ...]
 */
export const getActionableAI = (context, options = {}) => {
  const {
    maxActions = 3,
    priorityFilter = null,
    enabledTypes = Object.values(ACTION_TYPES)
  } = options;

  const actions = [];

  // ==========================================================================
  // CLIENT MANAGEMENT ACTIONS
  // ==========================================================================

  // Remind inactive clients
  if (context.inactiveClient && enabledTypes.includes(ACTION_TYPES.REMIND_CLIENT)) {
    const urgency = context.days > 30 ? ACTION_URGENCY.IMMEDIATE : ACTION_URGENCY.SOON;
    const priority = context.days > 30 ? ACTION_PRIORITY.HIGH : ACTION_PRIORITY.MEDIUM;

    actions.push({
      id: "remind_client",
      type: ACTION_TYPES.REMIND_CLIENT,
      title: `${context.clientName} hasn't replied in ${context.days} days`,
      description: `Last contact: ${context.lastContactDate || 'unknown'}`,
      priority,
      urgency,
      icon: "📧",
      category: "clients",
      metadata: {
        clientId: context.clientId,
        clientName: context.clientName,
        inactiveDays: context.days,
        lastContactDate: context.lastContactDate
      },
      action: () => sendClientReminder(context.clientId),
      estimatedTime: 30,  // seconds
      successMessage: `Reminder sent to ${context.clientName}`
    });
  }

  // Follow up on proposal
  if (context.proposalPending && enabledTypes.includes(ACTION_TYPES.FOLLOW_UP_PROPOSAL)) {
    actions.push({
      id: "followup_proposal",
      type: ACTION_TYPES.FOLLOW_UP_PROPOSAL,
      title: `Follow up on proposal to ${context.clientName} (${context.proposalAge} days old)`,
      description: `Proposal amount: $${context.proposalAmount}`,
      priority: ACTION_PRIORITY.HIGH,
      urgency: ACTION_URGENCY.SOON,
      icon: "📋",
      category: "clients",
      metadata: {
        clientId: context.clientId,
        proposalId: context.proposalId,
        proposalAmount: context.proposalAmount
      },
      action: () => sendProposalFollowUp(context.proposalId),
      estimatedTime: 45,
      successMessage: `Follow-up sent for proposal`
    });
  }

  // Send invoice reminder
  if (context.overdueInvoice && enabledTypes.includes(ACTION_TYPES.SEND_INVOICE_REMINDER)) {
    const priority = context.daysOverdue > 30 ? ACTION_PRIORITY.CRITICAL : ACTION_PRIORITY.HIGH;
    const urgency = context.daysOverdue > 30 ? ACTION_URGENCY.IMMEDIATE : ACTION_URGENCY.SOON;

    actions.push({
      id: "invoice_reminder",
      type: ACTION_TYPES.SEND_INVOICE_REMINDER,
      title: `Invoice #${context.invoiceNumber} is ${context.daysOverdue} days overdue`,
      description: `Amount due: $${context.amountDue}`,
      priority,
      urgency,
      icon: "💰",
      category: "finance",
      metadata: {
        invoiceId: context.invoiceId,
        invoiceNumber: context.invoiceNumber,
        clientId: context.clientId,
        amountDue: context.amountDue,
        daysOverdue: context.daysOverdue
      },
      action: () => sendInvoiceReminder(context.invoiceId),
      estimatedTime: 20,
      successMessage: `Payment reminder sent`
    });
  }

  // ==========================================================================
  // INVENTORY MANAGEMENT ACTIONS
  // ==========================================================================

  // Reorder low stock items
  if (context.lowStock && enabledTypes.includes(ACTION_TYPES.REORDER_ITEM)) {
    const stockPercentage = (context.currentStock / context.reorderPoint) * 100;
    const urgency = stockPercentage < 20 ? ACTION_URGENCY.IMMEDIATE : ACTION_URGENCY.SOON;

    actions.push({
      id: "reorder_item",
      type: ACTION_TYPES.REORDER_ITEM,
      title: `Low stock: ${context.item} — reorder from ${context.supplier}?`,
      description: `Current: ${context.currentStock} units, Reorder point: ${context.reorderPoint}`,
      priority: ACTION_PRIORITY.HIGH,
      urgency,
      icon: "📦",
      category: "inventory",
      metadata: {
        itemId: context.itemId,
        itemName: context.item,
        currentStock: context.currentStock,
        reorderPoint: context.reorderPoint,
        supplierId: context.supplierId,
        supplierName: context.supplier,
        suggestedQty: context.suggestedQty || context.reorderPoint * 2
      },
      action: () => createReorder(context.itemId, context.supplierId),
      estimatedTime: 60,
      successMessage: `Reorder created with ${context.supplier}`
    });
  }

  // Alert on damaged stock
  if (context.damagedStock && enabledTypes.includes(ACTION_TYPES.MARK_DAMAGED)) {
    actions.push({
      id: "mark_damaged",
      type: ACTION_TYPES.MARK_DAMAGED,
      title: `${context.damagedQty} units of ${context.item} marked as damaged`,
      description: `Write-off amount: $${context.writeOffAmount}`,
      priority: ACTION_PRIORITY.MEDIUM,
      urgency: ACTION_URGENCY.TODAY,
      icon: "⚠️",
      category: "inventory",
      metadata: {
        itemId: context.itemId,
        damagedQty: context.damagedQty,
        writeOffAmount: context.writeOffAmount
      },
      action: () => recordDamagedStock(context.itemId, context.damagedQty),
      estimatedTime: 30,
      successMessage: `Damage recorded and inventory updated`
    });
  }

  // ==========================================================================
  // FINANCE & PAYMENT ACTIONS
  // ==========================================================================

  // Record received payment
  if (context.paymentReceived && enabledTypes.includes(ACTION_TYPES.RECORD_PAYMENT)) {
    actions.push({
      id: "record_payment",
      type: ACTION_TYPES.RECORD_PAYMENT,
      title: `Record payment of $${context.paymentAmount} from ${context.clientName}`,
      description: `Invoice #${context.linkedInvoiceNumber}`,
      priority: ACTION_PRIORITY.HIGH,
      urgency: ACTION_URGENCY.IMMEDIATE,
      icon: "✅",
      category: "finance",
      metadata: {
        paymentId: context.paymentId,
        amount: context.paymentAmount,
        clientId: context.clientId,
        invoiceId: context.linkedInvoiceId
      },
      action: () => recordPayment(context.paymentId),
      estimatedTime: 25,
      successMessage: `Payment recorded successfully`
    });
  }

  // Approve expense
  if (context.expenseApprovalPending && enabledTypes.includes(ACTION_TYPES.APPROVE_EXPENSE)) {
    actions.push({
      id: "approve_expense",
      type: ACTION_TYPES.APPROVE_EXPENSE,
      title: `Approve expense: ${context.expenseCategory} ($${context.expenseAmount})`,
      description: `Submitted by ${context.submittedBy}`,
      priority: ACTION_PRIORITY.MEDIUM,
      urgency: ACTION_URGENCY.TODAY,
      icon: "💳",
      category: "finance",
      metadata: {
        expenseId: context.expenseId,
        amount: context.expenseAmount,
        category: context.expenseCategory,
        submittedBy: context.submittedByUserId
      },
      action: () => approveExpense(context.expenseId),
      estimatedTime: 15,
      successMessage: `Expense approved`
    });
  }

  // ==========================================================================
  // TASK & PROJECT ACTIONS
  // ==========================================================================

  // Reassign overdue task
  if (context.taskOverdue && enabledTypes.includes(ACTION_TYPES.REASSIGN_TASK)) {
    actions.push({
      id: "reassign_task",
      type: ACTION_TYPES.REASSIGN_TASK,
      title: `Task "${context.taskName}" is ${context.daysOverdue} days overdue`,
      description: `Currently assigned to ${context.assignedTo}`,
      priority: ACTION_PRIORITY.HIGH,
      urgency: ACTION_URGENCY.IMMEDIATE,
      icon: "🔄",
      category: "tasks",
      metadata: {
        taskId: context.taskId,
        taskName: context.taskName,
        currentAssigneeId: context.assignedToId,
        daysOverdue: context.daysOverdue
      },
      action: () => reassignTask(context.taskId),
      estimatedTime: 45,
      successMessage: `Task reassigned`
    });
  }

  // ==========================================================================
  // TEAM & RESOURCE ACTIONS
  // ==========================================================================

  // Assign to available team member
  if (context.hasUnassignedWork && enabledTypes.includes(ACTION_TYPES.ASSIGN_TO_AVAILABLE)) {
    actions.push({
      id: "assign_available",
      type: ACTION_TYPES.ASSIGN_TO_AVAILABLE,
      title: `${context.unassignedCount} items waiting — assign to ${context.availableTeamMember}?`,
      description: `Available capacity: ${context.availableCapacity} hours`,
      priority: ACTION_PRIORITY.MEDIUM,
      urgency: ACTION_URGENCY.SOON,
      icon: "👤",
      category: "team",
      metadata: {
        itemIds: context.unassignedItemIds,
        assignToUserId: context.availableTeamMemberId,
        availableCapacity: context.availableCapacity
      },
      action: () => assignToAvailableMember(context.availableTeamMemberId, context.unassignedItemIds),
      estimatedTime: 60,
      successMessage: `Items assigned to ${context.availableTeamMember}`
    });
  }

  // ==========================================================================
  // DATA QUALITY ACTIONS
  // ==========================================================================

  // Deduplicate clients
  if (context.duplicateClientsFound && enabledTypes.includes(ACTION_TYPES.DEDUPLICATE_CLIENT)) {
    actions.push({
      id: "deduplicate",
      type: ACTION_TYPES.DEDUPLICATE_CLIENT,
      title: `Found ${context.duplicateCount} duplicate client entries for "${context.clientName}"`,
      description: `Merge ${context.duplicateCount} records into 1?`,
      priority: ACTION_PRIORITY.MEDIUM,
      urgency: ACTION_URGENCY.THIS_WEEK,
      icon: "🔗",
      category: "data",
      metadata: {
        clientIds: context.duplicateClientIds,
        masterClientId: context.masterClientId,
        duplicateCount: context.duplicateCount
      },
      action: () => deduplicateClients(context.duplicateClientIds, context.masterClientId),
      estimatedTime: 120,
      successMessage: `Clients merged successfully`
    });
  }

  // ==========================================================================
  // SORT & LIMIT
  // ==========================================================================

  // Sort by priority and urgency
  const sortedActions = sortActionsByUrgency(actions);

  // Apply priority filter if specified
  let filteredActions = sortedActions;
  if (priorityFilter) {
    filteredActions = sortedActions.filter(a => a.priority === priorityFilter);
  }

  // Limit to maxActions
  return filteredActions.slice(0, maxActions);
};

/**
 * Sort actions by urgency (most urgent first)
 * 
 * @param {Array<Object>} actions - Actions to sort
 * @returns {Array<Object>} Sorted actions
 */
export const sortActionsByUrgency = (actions) => {
  return [...actions].sort((a, b) => {
    // Handle null urgency (optional actions)
    const aUrgency = a.urgency === null ? Infinity : a.urgency;
    const bUrgency = b.urgency === null ? Infinity : b.urgency;

    // Sort by urgency (lower hours = more urgent)
    if (aUrgency !== bUrgency) {
      return aUrgency - bUrgency;
    }

    // Secondary sort by priority
    const priorityOrder = {
      [ACTION_PRIORITY.CRITICAL]: 0,
      [ACTION_PRIORITY.HIGH]: 1,
      [ACTION_PRIORITY.MEDIUM]: 2,
      [ACTION_PRIORITY.LOW]: 3
    };

    return (priorityOrder[a.priority] || 999) - (priorityOrder[b.priority] || 999);
  });
};

/**
 * Filter actions by category
 * 
 * @param {Array<Object>} actions - Actions to filter
 * @param {string} category - Category to filter by
 * @returns {Array<Object>} Filtered actions
 */
export const filterActionsByCategory = (actions, category) => {
  return actions.filter(action => action.category === category);
};

/**
 * Get action metadata for display/analysis
 * 
 * @param {Object} action - Action object
 * @returns {Object} Metadata
 */
export const getActionMetadata = (action) => {
  return {
    type: action.type,
    id: action.id,
    title: action.title,
    description: action.description,
    category: action.category,
    priority: action.priority,
    urgency: action.urgency,
    icon: action.icon,
    metadata: action.metadata,
    estimatedTime: action.estimatedTime
  };
};

// =============================================================================
// ACTION EXECUTION STUBS
// These would be imported from actual service modules
// =============================================================================

const sendClientReminder = async (clientId) => {
  console.log(`Sending reminder to client ${clientId}`);
  // Actual implementation in clientService
};

const sendProposalFollowUp = async (proposalId) => {
  console.log(`Sending proposal follow-up for ${proposalId}`);
};

const sendInvoiceReminder = async (invoiceId) => {
  console.log(`Sending invoice reminder for ${invoiceId}`);
};

const createReorder = async (itemId, supplierId) => {
  console.log(`Creating reorder for item ${itemId} from supplier ${supplierId}`);
};

const recordDamagedStock = async (itemId, qty) => {
  console.log(`Recording ${qty} damaged units of item ${itemId}`);
};

const recordPayment = async (paymentId) => {
  console.log(`Recording payment ${paymentId}`);
};

const approveExpense = async (expenseId) => {
  console.log(`Approving expense ${expenseId}`);
};

const reassignTask = async (taskId) => {
  console.log(`Reassigning task ${taskId}`);
};

const assignToAvailableMember = async (userId, itemIds) => {
  console.log(`Assigning ${itemIds.length} items to user ${userId}`);
};

const deduplicateClients = async (clientIds, masterClientId) => {
  console.log(`Merging ${clientIds.length} clients into ${masterClientId}`);
};

export default {
  ACTION_TYPES,
  ACTION_PRIORITY,
  ACTION_URGENCY,
  getActionableAI,
  sortActionsByUrgency,
  filterActionsByCategory,
  getActionMetadata
};
