/**
 * MOBILE EMPLOYEE APP - AI INTEGRATION
 *
 * Context-aware actionable AI for mobile
 * Single suggestion per screen based on role and context
 * Integrates with role permissions and subscription tiers
 *
 * @module mobileAI
 */

import { getMobileAIContext } from "./mobileConfig";

// ─────────────────────────────────────────────────────────────────────────
// ROLE-BASED PERMISSIONS FOR MOBILE AI
// ─────────────────────────────────────────────────────────────────────────

export const MOBILE_ROLE_PERMISSIONS = {
  employee: ["tasks", "expenses:log", "clients:view", "jobs:complete"],
  manager: ["team", "tasks:manage", "clients:view", "expenses:review"],
  hr: ["team", "onboarding", "performance"],
  finance: ["invoices", "expenses:review", "reports"],
  sales: ["clients", "proposals", "deals"],
  owner: ["*"] // Full access
};

/**
 * Check if role can access feature on mobile
 * @param {string} role - User's role
 * @param {string} feature - Feature to access
 * @returns {boolean}
 */
export function canAccessFeature(role, feature) {
  const permissions = MOBILE_ROLE_PERMISSIONS[role] || [];
  if (permissions.includes("*")) return true;
  return permissions.includes(feature) || permissions.some(p => p.startsWith(feature + ":"));
}

// ─────────────────────────────────────────────────────────────────────────
// MOBILE AI ACTION TYPES
// ─────────────────────────────────────────────────────────────────────────

/**
 * Task-related AI suggestions
 */
export const TASK_ACTIONS = [
  {
    id: "task_reminder",
    type: "reminder",
    title: (task) => `Reminder: ${task.title} due ${task.dueSoon}`,
    description: "Complete this task before the deadline",
    icon: "⏰",
    requiredRole: ["employee", "manager"],
    actionHandler: (task) => ({
      action: "open_task",
      taskId: task.id,
      trackingEvent: "task_reminder_clicked"
    })
  },
  {
    id: "deadline_warning",
    type: "warning",
    title: (task) => `⚠️ ${task.title} is overdue!`,
    description: "This task needs immediate attention",
    icon: "🚨",
    requiredRole: ["employee", "manager"],
    actionHandler: (task) => ({
      action: "escalate_task",
      taskId: task.id,
      notifyManager: true
    })
  },
  {
    id: "delegation_opportunity",
    type: "opportunity",
    title: (task) => `Can you help ${task.assignedTo}?`,
    description: "They have high workload",
    icon: "🤝",
    requiredRole: ["manager"],
    actionHandler: (task) => ({
      action: "offer_help",
      targetUserId: task.assignedTo,
      trackingEvent: "delegation_offered"
    })
  }
];

/**
 * Expense-related AI suggestions
 */
export const EXPENSE_ACTIONS = [
  {
    id: "receipt_recognition",
    type: "suggestion",
    title: (expense) => `Receipt from ${expense.vendor}?`,
    description: "AI detected: Meals - $25.50",
    icon: "📸",
    requiredRole: ["employee", "finance"],
    actionHandler: (expense) => ({
      action: "confirm_category",
      expenseId: expense.id,
      suggestedCategory: expense.category
    })
  },
  {
    id: "duplicate_detection",
    type: "warning",
    title: (expense) => `Possible duplicate expense`,
    description: "Similar expense found from yesterday",
    icon: "⚠️",
    requiredRole: ["employee", "finance"],
    actionHandler: (expense) => ({
      action: "review_duplicate",
      expenseId: expense.id,
      duplicateId: expense.duplicateOf
    })
  },
  {
    id: "policy_violation",
    type: "alert",
    title: (expense) => `Expense policy violation`,
    description: "Amount exceeds per-transaction limit",
    icon: "⛔",
    requiredRole: ["finance", "manager"],
    actionHandler: (expense) => ({
      action: "review_policy",
      expenseId: expense.id,
      requiresApproval: true
    })
  }
];

/**
 * Client-related AI suggestions
 */
export const CLIENT_ACTIONS = [
  {
    id: "client_follow_up",
    type: "reminder",
    title: (client) => `Follow up with ${client.name}`,
    description: `Last contact: ${client.lastContact}`,
    icon: "📞",
    requiredRole: ["employee", "manager", "sales"],
    actionHandler: (client) => ({
      action: "send_message",
      clientId: client.id,
      templateId: "follow_up"
    })
  },
  {
    id: "payment_reminder",
    type: "alert",
    title: (client) => `${client.name} payment overdue`,
    description: `Due: ${client.paymentDueDate}`,
    icon: "💳",
    requiredRole: ["manager", "finance", "owner"],
    actionHandler: (client) => ({
      action: "send_payment_reminder",
      clientId: client.id,
      amount: client.outstandingBalance
    })
  },
  {
    id: "upsell_opportunity",
    type: "opportunity",
    title: (client) => `Upsell opportunity: ${client.name}`,
    description: "They use service X, might benefit from Y",
    icon: "📈",
    requiredRole: ["manager", "sales", "owner"],
    actionHandler: (client) => ({
      action: "create_proposal",
      clientId: client.id,
      productId: client.upsellProduct
    })
  }
];

/**
 * Job-related AI suggestions
 */
export const JOB_ACTIONS = [
  {
    id: "job_suggestion",
    type: "reminder",
    title: (job) => `Available job: ${job.title}`,
    description: `Pay: $${job.pay} • Location: ${job.location}`,
    icon: "🔧",
    requiredRole: ["employee"],
    actionHandler: (job) => ({
      action: "claim_job",
      jobId: job.id,
      trackingEvent: "job_suggested"
    })
  },
  {
    id: "material_check",
    type: "reminder",
    title: (job) => `Check materials for ${job.title}`,
    description: "Verify you have all required tools",
    icon: "🛠️",
    requiredRole: ["employee"],
    actionHandler: (job) => ({
      action: "open_materials_checklist",
      jobId: job.id
    })
  },
  {
    id: "safety_reminder",
    type: "alert",
    title: (job) => `Safety reminder for ${job.title}`,
    description: "High-risk job - review safety procedures",
    icon: "⚠️",
    requiredRole: ["employee", "manager"],
    actionHandler: (job) => ({
      action: "open_safety_guide",
      jobId: job.id,
      acknowledged: false
    })
  }
];

/**
 * Team management AI suggestions (managers)
 */
export const TEAM_ACTIONS = [
  {
    id: "workload_balance",
    type: "suggestion",
    title: (team) => `${team.overloadedMember} is overloaded`,
    description: `${team.taskCount} tasks, consider reassigning`,
    icon: "⚖️",
    requiredRole: ["manager", "owner"],
    actionHandler: (team) => ({
      action: "reassign_tasks",
      targetMemberId: team.overloadedMember,
      availableTasks: team.reassignableTasks
    })
  },
  {
    id: "skill_match",
    type: "opportunity",
    title: (team) => `${team.newTask} matches ${team.member} skills`,
    description: "Best fit for the job",
    icon: "✨",
    requiredRole: ["manager", "owner"],
    actionHandler: (team) => ({
      action: "assign_task",
      taskId: team.newTask,
      assignTo: team.member
    })
  },
  {
    id: "availability_check",
    type: "reminder",
    title: (team) => `Schedule check: ${team.member}`,
    description: `Available: ${team.availability}`,
    icon: "📅",
    requiredRole: ["manager", "owner"],
    actionHandler: (team) => ({
      action: "open_schedule",
      memberId: team.member
    })
  }
];

/**
 * Dashboard/analytics AI suggestions (owners)
 */
export const ANALYTICS_ACTIONS = [
  {
    id: "revenue_alert",
    type: "alert",
    title: (data) => `Revenue ${data.trend === "down" ? "declining" : "growing"}`,
    description: `${data.change}% from last period`,
    icon: "📊",
    requiredRole: ["owner", "manager", "finance"],
    actionHandler: (data) => ({
      action: "view_detailed_analytics",
      period: data.period,
      metric: "revenue"
    })
  },
  {
    id: "performance_milestone",
    type: "achievement",
    title: (data) => `${data.achievement}! 🎉`,
    description: data.description,
    icon: "🏆",
    requiredRole: ["owner", "manager"],
    actionHandler: (data) => ({
      action: "view_performance",
      celebrationId: data.achievement
    })
  }
];

// ─────────────────────────────────────────────────────────────────────────
// MOBILE AI ENGINE
// ─────────────────────────────────────────────────────────────────────────

/**
 * Generate single AI action for current mobile screen
 * @param {object} params - Configuration
 * @param {string} params.userId - User ID
 * @param {string} params.role - User's role
 * @param {string} params.screenId - Current screen
 * @param {object} params.context - Screen context (data, state)
 * @param {string} params.subscription - User's subscription tier
 * @returns {Promise<object>} Single AI action or null
 */
export async function getMobileAIAction({
  userId,
  role,
  screenId,
  context = {},
  subscription = "team"
}) {
  // Verify role permissions for this screen
  if (!canAccessFeature(role, screenId)) {
    return null; // Role cannot access this screen
  }

  // Get screen-specific AI context
  const aiContext = getMobileAIContext(screenId, userId);

  // Load actions based on screen
  let availableActions = [];

  switch (screenId) {
    case "tasks":
      availableActions = TASK_ACTIONS.filter(a =>
        a.requiredRole.includes(role)
      );
      break;
    case "expenses":
      availableActions = EXPENSE_ACTIONS.filter(a =>
        a.requiredRole.includes(role)
      );
      break;
    case "clients":
      availableActions = CLIENT_ACTIONS.filter(a =>
        a.requiredRole.includes(role)
      );
      break;
    case "jobs":
      availableActions = JOB_ACTIONS.filter(a =>
        a.requiredRole.includes(role)
      );
      break;
    case "team":
      availableActions = TEAM_ACTIONS.filter(a =>
        a.requiredRole.includes(role)
      );
      break;
    case "dashboard":
      availableActions = ANALYTICS_ACTIONS.filter(a =>
        a.requiredRole.includes(role)
      );
      break;
    default:
      return null;
  }

  // Score and rank actions
  const scoredActions = availableActions
    .map(action => ({
      ...action,
      score: scoreAction(action, context, aiContext)
    }))
    .filter(a => a.score > 0)
    .sort((a, b) => b.score - a.score);

  // Return single top action (mobile limit)
  if (scoredActions.length > 0) {
    const topAction = scoredActions[0];
    
    // Prepare action with context data
    return {
      id: topAction.id,
      type: topAction.type,
      title: typeof topAction.title === "function" 
        ? topAction.title(context.data || {}) 
        : topAction.title,
      description: topAction.description,
      icon: topAction.icon,
      action: topAction.actionHandler?.(context.data || {}),
      score: topAction.score,
      timestamp: new Date(),
      dismissible: true
    };
  }

  return null;
}

/**
 * Score action relevance and importance
 * @private
 */
function scoreAction(action, context, aiContext) {
  let score = 50; // Base score

  // Type scoring
  const typeScores = {
    alert: 100,
    warning: 80,
    reminder: 60,
    opportunity: 40,
    achievement: 30,
    suggestion: 20
  };
  score += typeScores[action.type] || 0;

  // Context relevance
  if (context.data) {
    if (action.id.includes("overdue")) score += 40;
    if (action.id.includes("payment")) score += 35;
    if (action.id.includes("opportunity")) score += 25;
  }

  // Frequency dampening (don't suggest same action twice)
  if (context.lastAction === action.id) score -= 50;

  return Math.max(0, score);
}

/**
 * Handle AI action execution
 * @param {object} action - Action to execute
 * @param {function} callback - Completion callback
 */
export async function executeAIAction(action, callback) {
  try {
    // Track analytics
    trackAIActionEvent(action);

    // Execute action handler
    const result = await action.action?.();

    // Call completion callback
    if (callback) {
      callback({ success: true, result });
    }

    return result;
  } catch (error) {
    console.error("AI action failed:", error);
    if (callback) {
      callback({ success: false, error: error.message });
    }
  }
}

/**
 * Dismiss AI action without executing
 * @param {string} actionId - Action to dismiss
 * @param {string} userId - User ID
 */
export async function dismissAIAction(actionId, userId) {
  // Log dismissal for ML model
  trackAIActionEvent({
    id: actionId,
    event: "dismissed",
    userId,
    timestamp: new Date()
  });
}

/**
 * Track AI action events for analytics and ML
 * @private
 */
function trackAIActionEvent(action) {
  const event = {
    actionId: action.id,
    actionType: action.type,
    event: action.event || "shown",
    timestamp: action.timestamp || new Date(),
    userId: action.userId,
    screenId: action.screenId
  };

  // Send to analytics service
  // sendAnalytics(event);
  console.log("[AI Action]", event);
}

// ─────────────────────────────────────────────────────────────────────────
// MOBILE AI HOOKS (for React components)
// ─────────────────────────────────────────────────────────────────────────

/**
 * React hook for mobile AI suggestions
 * @param {object} params - Hook configuration
 * @returns {object} { action, loading, error, dismiss }
 */
export function useMobileAI({
  userId,
  role,
  screenId,
  context,
  subscription,
  autoRefresh = false
}) {
  const [action, setAction] = React.useState(null);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState(null);
  const [dismissed, setDismissed] = React.useState(false);

  React.useEffect(() => {
    loadAction();
    
    if (autoRefresh) {
      const interval = setInterval(loadAction, 30000); // Refresh every 30s
      return () => clearInterval(interval);
    }
  }, [userId, role, screenId, context]);

  async function loadAction() {
    setLoading(true);
    try {
      const result = await getMobileAIAction({
        userId,
        role,
        screenId,
        context,
        subscription
      });
      setAction(result);
      setDismissed(false);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function dismiss() {
    if (action?.id) {
      await dismissAIAction(action.id, userId);
      setDismissed(true);
      setAction(null);
    }
  }

  return { action: !dismissed ? action : null, loading, error, dismiss, refresh: loadAction };
}

export default {
  MOBILE_ROLE_PERMISSIONS,
  TASK_ACTIONS,
  EXPENSE_ACTIONS,
  CLIENT_ACTIONS,
  JOB_ACTIONS,
  TEAM_ACTIONS,
  ANALYTICS_ACTIONS,
  canAccessFeature,
  getMobileAIAction,
  executeAIAction,
  dismissAIAction,
  useMobileAI
};
