# Actionable AI System - Complete Guide

**Status**: ✅ Production Ready  
**Created**: December 13, 2025  
**Total Files**: 6  
**Lines**: 2,200+  

---

## Overview

The Actionable AI System generates intelligent, context-triggered one-tap actions that help users accomplish business tasks instantly. It analyzes business context and recommends smart actions up to 3 at a time.

### Key Features
- ✅ **Context-Aware**: Analyzes 20+ business scenarios
- ✅ **Priority-Based**: Critical, High, Medium, Low priorities
- ✅ **Action Queue**: Manages execution order and retries
- ✅ **One-Tap Execution**: Single click to complete actions
- ✅ **Deferral Support**: Defer actions to later time
- ✅ **Rich History**: Track all executed actions
- ✅ **Firestore Integration**: Persist actions for audit trail
- ✅ **Analytics**: Track action completion rates

---

## System Architecture

### Core Components

```
User Context (business data)
         ↓
  getActionableAI()
         ↓
  Generate up to 3 actions
         ↓
  Sort by urgency/priority
         ↓
  ActionCard Component (UI)
         ↓
  ┌──────────────┬──────────────┬──────────────┐
  ↓              ↓              ↓
Execute        Defer          Dismiss
  ↓              ↓              ↓
actionProcessor deferAction   cancelAction
  ↓
Firestore History
```

### Files Overview

| File | Size | Purpose |
|------|------|---------|
| `src/ai/actionsOnly.js` | 12 KB | Action definitions & generation |
| `src/ai/actionProcessor.js` | 14 KB | Queue management & execution |
| `src/components/ActionableAIComponents.jsx` | 11 KB | React UI components |
| `ACTIONABLE_AI_DOCUMENTATION.md` | 18 KB | Complete reference |
| `ACTIONABLE_AI_EXAMPLES.js` | 16 KB | 10 implementation examples |
| `ACTIONABLE_AI_SUMMARY.md` | 10 KB | Quick overview |

---

## API Reference

### Action Generation

#### `getActionableAI(context, options)`

**Purpose**: Generate smart actions from business context

**Parameters**:
```javascript
{
  // Client management
  inactiveClient: boolean,        // Client hasn't responded
  clientName: string,
  clientId: string,
  days: number,                   // Days since contact
  
  // Proposals
  proposalPending: boolean,
  proposalAge: number,            // Days proposal pending
  proposalAmount: number,
  
  // Invoices
  overdueInvoice: boolean,
  invoiceNumber: string,
  invoiceId: string,
  amountDue: number,
  daysOverdue: number,
  
  // Inventory
  lowStock: boolean,
  item: string,
  itemId: string,
  currentStock: number,
  reorderPoint: number,
  supplier: string,
  supplierId: string,
  
  // Payments
  paymentReceived: boolean,
  paymentAmount: number,
  paymentId: string,
  
  // Expenses
  expenseApprovalPending: boolean,
  expenseAmount: number,
  expenseCategory: string,
  expenseId: string,
  
  // Tasks
  taskOverdue: boolean,
  taskId: string,
  taskName: string,
  daysOverdue: number,
  
  // Team
  hasUnassignedWork: boolean,
  unassignedCount: number,
  availableTeamMember: string,
  availableCapacity: number,
  
  // Data quality
  duplicateClientsFound: boolean,
  duplicateCount: number,
  duplicateClientIds: array
}
```

**Options**:
```javascript
{
  maxActions: 3,                  // Max actions to return
  priorityFilter: "critical",     // Filter by priority
  enabledTypes: [...]             // Enable specific action types
}
```

**Returns**:
```javascript
[
  {
    id: "remind_client",
    type: "remind_client",
    title: "Acme Corp hasn't replied in 14 days",
    description: "Last contact: 2025-11-29",
    priority: "high",              // critical|high|medium|low
    urgency: 6,                     // hours until due (Infinity for optional)
    icon: "📧",
    category: "clients",            // clients|inventory|finance|tasks|team|data
    metadata: {...},                // Action-specific data
    action: () => {...},            // Execute function
    estimatedTime: 30,              // Seconds to complete
    successMessage: "Reminder sent to Acme Corp"
  }
]
```

### Action Execution

#### `actionProcessor.queueAction(action, options)`

Queue an action for execution

```javascript
const queueId = await actionProcessor.queueAction(action, {
  immediate: false,               // Execute immediately?
  priority: 0                     // Queue priority (higher = sooner)
});
```

#### `actionProcessor.processQueue()`

Process next item in queue

```javascript
await actionProcessor.processQueue();
// Automatically called after each execution
```

#### `actionProcessor.cancelAction(actionId)`

Cancel a pending action

```javascript
actionProcessor.cancelAction(queueId);
```

#### `actionProcessor.deferAction(actionId, delayMs)`

Defer action to later

```javascript
actionProcessor.deferAction(queueId, 3600000); // 1 hour
```

### Queue Status

#### `actionProcessor.getQueueStatus()`

Get current queue state

```javascript
{
  totalItems: 5,
  executing: false,
  items: [
    {
      id: "action_123",
      actionType: "remind_client",
      state: "pending",
      priority: 1,
      attempts: 0
    }
  ]
}
```

### History & Analytics

#### `actionProcessor.getHistory(count)`

Get recent actions

```javascript
const recent = actionProcessor.getHistory(20);
```

#### `getActionHistoryFromFirestore(userId, count)`

Fetch persistent history from Firestore

```javascript
const history = await getActionHistoryFromFirestore(user.uid, 50);
// Returns array of executed actions with metadata
```

#### `getActionStats(userId, days)`

Get action statistics

```javascript
const stats = await getActionStats(user.uid, 30);
// Returns:
// {
//   totalActions: 45,
//   successCount: 42,
//   failureCount: 2,
//   successRate: "93.3%",
//   byCategory: { clients: 15, inventory: 12, ... },
//   byType: { remind_client: 8, ... },
//   averageActionsPerDay: "1.5"
// }
```

---

## React Components

### ActionCard

Individual action display with execution options

```jsx
<ActionCard
  action={action}
  onExecute={() => console.log('Done')}
  onDefer={() => console.log('Deferred')}
  onDismiss={() => console.log('Dismissed')}
/>
```

**Features**:
- Priority color coding
- Urgency badges
- Execution/defer/dismiss buttons
- Error handling
- Loading states

### ActionsList

Display multiple actions with filtering

```jsx
<ActionsList
  actions={actions}
  onActionComplete={() => refreshActions()}
  filterCategory="clients"
/>
```

### ActionsWidget

Compact quick-access widget

```jsx
<ActionsWidget
  actions={actions}
  onOpenActions={() => setShowPanel(true)}
/>
```

Shows:
- Action count badge
- Critical/high counts
- First action preview
- Quick open button

### ActionPanel

Full-screen modal for action management

```jsx
<ActionPanel
  actions={actions}
  isOpen={showPanel}
  onClose={() => setShowPanel(false)}
/>
```

**Features**:
- Category filtering
- Full action list
- Execute/defer/dismiss for each
- Action count by category
- Tips and guidance

### ActionQueue

Live queue and history display

```jsx
<ActionQueue />
```

Shows:
- Current queue items
- Execution status
- Recent history (last 10)
- Real-time updates

### useActionableAI Hook

Generate actions with React integration

```javascript
const {
  actions,        // Generated actions array
  isLoading,      // Loading state
  error,          // Error message
  generateActions, // Manual regeneration function
  actionCount,    // Total count
  criticalCount,  // Critical actions
  highCount       // High priority actions
} = useActionableAI(context, options);
```

---

## Usage Examples

### Example 1: Generate Actions from Dashboard

```javascript
import { getActionableAI } from './ai/actionsOnly';
import { ActionsList } from './components/ActionableAIComponents';

function DashboardPage({ user, business }) {
  // Build context from business data
  const context = {
    inactiveClient: business.clients.some(c => 
      Date.now() - c.lastContact > 14 * 24 * 60 * 60 * 1000
    ),
    clientName: "Acme Corp",
    clientId: "client_123",
    days: 14,
    lowStock: business.inventory.some(i => i.quantity < i.reorderPoint),
    item: "Widget A",
    itemId: "item_123",
    supplier: "SupplierCo"
  };

  const actions = getActionableAI(context, { maxActions: 3 });

  return (
    <div className="dashboard">
      <ActionsList actions={actions} />
    </div>
  );
}
```

### Example 2: Execute Action Immediately

```javascript
import { actionProcessor } from './ai/actionProcessor';
import { ActionCard } from './components/ActionableAIComponents';

async function handleQuickAction(action) {
  try {
    const queueId = await actionProcessor.queueAction(action, {
      immediate: true  // Execute right away
    });
    
    console.log('Action executed:', queueId);
  } catch (error) {
    console.error('Failed to execute:', error);
  }
}
```

### Example 3: Use Hook in Component

```javascript
import { useActionableAI } from './components/ActionableAIComponents';

function ClientsPage() {
  const [showActions, setShowActions] = useState(false);

  const businessContext = {
    inactiveClient: true,
    clientName: "Acme Corp",
    clientId: "client_123",
    days: 21
  };

  const {
    actions,
    actionCount,
    criticalCount
  } = useActionableAI(businessContext);

  return (
    <div>
      {criticalCount > 0 && (
        <div className="alert alert-critical">
          {criticalCount} critical actions needed
        </div>
      )}

      <button onClick={() => setShowActions(true)}>
        View {actionCount} Suggested Actions
      </button>

      {showActions && (
        <ActionsList
          actions={actions}
          onActionComplete={() => {
            // Refresh data
            refetchClients();
          }}
        />
      )}
    </div>
  );
}
```

### Example 4: Track with Analytics

```javascript
import { executeAndLogAction } from './ai/actionProcessor';

async function executeActionWithTracking(userId, action) {
  const result = await executeAndLogAction(userId, action, true);

  // Get stats
  const stats = await getActionStats(userId, 30);
  console.log(`Success rate: ${stats.successRate}`);
}
```

### Example 5: Defer for Later

```javascript
import { actionProcessor } from './ai/actionProcessor';

function ActionCardWithDefer({ action, queueId }) {
  const handleDefer = () => {
    // Defer 1 hour
    actionProcessor.deferAction(queueId, 1 * 60 * 60 * 1000);
    console.log('Action deferred 1 hour');
  };

  return (
    <div>
      <button onClick={handleDefer}>Remind me in 1 hour</button>
    </div>
  );
}
```

---

## Firestore Schema

### Action History Collection

```firestore
collection: actionHistory
document: {
  userId: string,
  actionType: string,        // from ACTION_TYPES
  actionId: string,
  title: string,
  category: string,
  result: string,            // success|failure|cancelled
  resultDetails: object,
  error: string|null,
  metadata: object,
  executedAt: timestamp,
  timestamp: timestamp
}

// Index: userId + executedAt (desc) for queries
```

---

## Action Categories

| Category | Actions | Use Case |
|----------|---------|----------|
| **clients** | Remind, follow up, status updates | Client relationship management |
| **inventory** | Reorder, alert, reconcile | Stock management |
| **finance** | Record payment, approve, invoice | Financial operations |
| **tasks** | Reassign, escalate, mark overdue | Project management |
| **team** | Assign work, schedule, manage capacity | Resource allocation |
| **data** | Deduplicate, validate, verify | Data quality |

---

## Priority Levels

| Priority | Use Case | Response Time |
|----------|----------|----------------|
| **CRITICAL** | Legal/compliance risks, major financial issues | Immediate (< 1 hour) |
| **HIGH** | Time-sensitive, revenue impact | Soon (< 6 hours) |
| **MEDIUM** | Standard operations | Today |
| **LOW** | Nice-to-have, optimization | This week |

---

## CSS Styling

### Action Card Classes

```css
.action-card {
  border-left: 4px solid;    /* Color by priority */
  padding: 20px;
  background: white;
  border-radius: 8px;
  margin-bottom: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.action-card[style*="red"] {
  /* Critical priority */
}

.action-card[style*="orange"] {
  /* High priority */
}

.action-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 12px;
}

.action-title {
  margin: 0 0 4px 0;
  font-size: 16px;
  font-weight: 600;
}

.action-description {
  margin: 0;
  font-size: 14px;
  color: #666;
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

.btn-action {
  padding: 8px 16px;
  margin-right: 8px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.2s;
}

.btn-execute {
  background: #3b82f6;
  color: white;
}

.btn-execute:hover:not(:disabled) {
  background: #2563eb;
}

.btn-defer {
  background: #f3f4f6;
  color: #374151;
}

.btn-dismiss {
  background: transparent;
  color: #9ca3af;
  border: 1px solid #e5e7eb;
}
```

---

## Best Practices

1. **Generate at Strategic Points**
   - Dashboard load
   - User navigation
   - Background refresh (every 5 minutes)

2. **Limit to 3 Actions**
   - Prevents overwhelm
   - Focuses on most important
   - Better UX

3. **Always Provide Escape Routes**
   - Defer button (not now)
   - Dismiss button (not interested)
   - Cancel anytime

4. **Show Progress**
   - Loading state while executing
   - Success confirmation
   - Error messages with retry

5. **Persist & Track**
   - Save all executions
   - Monitor success rates
   - Adjust based on feedback

6. **Smart Queuing**
   - Higher priority first
   - Respect deferral timing
   - Automatic retry on failure

7. **Mobile Friendly**
   - Touch-friendly buttons
   - Compact cards
   - Swipe to dismiss

---

## Troubleshooting

### Actions Not Generating
- Verify context has correct field names
- Check action generation logic
- Enable specific action types in options

### Execution Failures
- Check action function is callable
- Verify Firestore permissions
- Check execution timeout (30s default)

### Queue Not Processing
- Verify actionProcessor is initialized
- Check browser console for errors
- Monitor with ActionQueue component

### History Not Persisting
- Check Firestore write permissions
- Verify userId is correct
- Check actionHistory collection exists

---

## Performance Tips

1. **Debounce Context Changes**
   - Don't regenerate on every keystroke
   - Regenerate every 5-10 seconds
   - Manual refresh button

2. **Lazy Load Components**
   - Load ActionPanel only when needed
   - Don't render all actions at once
   - Use pagination for large lists

3. **Cache Results**
   - Cache generated actions for 30 seconds
   - Invalidate on context change
   - Reduce API calls

4. **Optimize Firestore Queries**
   - Limit history to recent 50
   - Add composite indexes
   - Use offline persistence

---

## Next Steps

1. Copy files to project
2. Wire up business context
3. Add components to UI
4. Configure Firestore
5. Test with sample data
6. Deploy to staging
7. Gather user feedback
8. Iterate on actions

---

## File Manifest

- `web/src/ai/actionsOnly.js` (12 KB) — Action definitions
- `web/src/ai/actionProcessor.js` (14 KB) — Queue & execution
- `web/src/components/ActionableAIComponents.jsx` (11 KB) — React UI
- `web/ACTIONABLE_AI_DOCUMENTATION.md` (18 KB) — This file
- `web/ACTIONABLE_AI_EXAMPLES.js` (16 KB) — 10 code examples
- `web/ACTIONABLE_AI_SUMMARY.md` (10 KB) — Quick reference

**Total**: 6 files, 2,200+ lines, production-ready

---

**Created**: December 13, 2025  
**Status**: ✅ Production Ready
