# MOBILE EMPLOYEE APP - DOCUMENTATION

**Complete mobile-optimized employee workflow system**

---

## 📱 Overview

A production-ready React mobile app optimized for field/on-site employees. Focuses on:
- **Quick task management** - See, claim, complete tasks fast
- **Expense capture** - Receipt photos, categorization, notes
- **Client engagement** - View profiles, send messages, track payments
- **AI suggestions** - Context-aware 1-per-screen recommendations
- **Role-based access** - Different screens for employees vs managers
- **Offline-first** - Works with limited connectivity

**Built for:** Employees, technicians, field service workers, managers

---

## 🎯 Key Features

### For Employees
✅ Quick task assignment and completion  
✅ Fast expense logging with photo capture  
✅ Client contact information  
✅ Job completion workflow  
✅ Profile and notifications  

### For Managers
✅ Team status overview  
✅ Task management and reassignment  
✅ Expense review and approval  
✅ Team member performance  
✅ Basic analytics  

### For Business
✅ Reduced app complexity (no desktop features)  
✅ Faster load times (mobile-optimized)  
✅ Lower data usage (image optimization)  
✅ Better engagement (smart suggestions)  
✅ Offline capability  

---

## 📁 Files Overview

| File | Size | Purpose |
|------|------|---------|
| `mobileConfig.js` | 20 KB | Core routing, screens, navigation |
| `MobileComponents.jsx` | 18 KB | 7 React components + CSS |
| `mobileAI.js` | 16 KB | AI action generation, scoring |
| `MOBILE_DOCUMENTATION.md` | 13 KB | Complete reference (this file) |
| `MOBILE_EXAMPLES.js` | 25 KB | 8 implementation examples |
| `MOBILE_QUICK_START.md` | 10 KB | 5-minute setup guide |

**Total: 102 KB, 2,500+ lines**

---

## 🗺️ Mobile Screen Structure

### Employee Screens

```
HOME (Tasks) ← Default on login
├── 📋 Tasks/Assigned (primary)
│   ├── Task Card (title, due, priority)
│   ├── Quick action (complete button)
│   └── AI suggestion (1)
├── 💰 Expenses (primary)
│   ├── Quick form (amount, category, receipt)
│   └── AI help (category detection)
├── 👥 Clients (primary)
│   ├── Client list
│   ├── Quick contact (email/call)
│   └── Payment status
├── 🔧 Jobs (secondary)
│   ├── Available jobs
│   ├── Multi-step completion
│   └── Photo + signature
└── 👤 Profile (secondary)
    ├── Info card
    ├── Quick settings
    └── Log out
```

### Manager Screens

```
TEAM (default) ← Different home screen
├── 👥 Team Status (primary)
│   ├── Member list with status
│   ├── Task assignments
│   └── AI workload suggestions
├── ✓ Task Management (primary)
├── 💰 Expense Review (primary)
├── 📋 Clients (secondary)
└── 📊 Dashboard (secondary)
```

### Owner Screens

```
DASHBOARD (default)
├── 📊 Business metrics
├── 👥 Full team management
├── 💳 Financial overview
├── 📋 All clients
└── ⚙️ Settings
```

---

## 🔧 API Reference

### Core Module (`mobileConfig.js`)

#### Screen Access

```javascript
import {
  MOBILE_SCREENS,
  getScreensByRole,
  getNavigationTabs,
  getHomeScreen,
  canAccessMobileScreen
} from './mobileConfig';

// Get screens for employee
const screens = getScreensByRole('employee');
// → { primary: [...5 screens], secondary: [...] }

// Get bottom nav tabs (5 max)
const tabs = getNavigationTabs('employee');

// Check if user can access screen
canAccessMobileScreen(user, 'expenses'); // → true
canAccessMobileScreen(user, 'dashboard'); // → false (employees can't access)
```

#### Navigation Management

```javascript
import { MobileNavigation } from './mobileConfig';

const nav = new MobileNavigation('employee');
nav.navigateTo('/mobile/tasks/assigned'); // true
nav.goBack(); // true if history > 1
nav.getState(); // { currentScreen, activeTabIndex, canGoBack, tabs }
```

#### Onboarding & Routing

```javascript
import { handleMobileOnboarding } from './mobileConfig';

// Route based on role, subscription, setup status
const path = handleMobileOnboarding(user);
// → "/mobile/tasks/assigned" (employee)
// → "/mobile/team/status" (manager)
// → "/onboarding/owner-wizard" (owner, not setup)
```

#### AI Context

```javascript
import { getMobileAIContext } from './mobileConfig';

const context = getMobileAIContext('tasks', userId);
// → { focus, priority, maxSuggestions: 1, actionTypes: [...] }
```

#### Mobile Utilities

```javascript
import {
  isMobileDevice,
  isSmallScreen,
  optimizeMobileImage,
  truncateForMobile,
  formatMobileDate,
  vibrateDevice,
  getSafeAreaInsets
} from './mobileConfig';

truncateForMobile("Long task title", 40); // "Long task title..." (truncated)
formatMobileDate(new Date()); // "Jan 15, 2:30 PM"
vibrateDevice(100); // Haptic feedback
optimizeMobileImage(url, 400); // Mobile-optimized image URL
getSafeAreaInsets(); // { top, bottom, left, right } (notch safe areas)
```

### Components (`MobileComponents.jsx`)

```javascript
import {
  TaskCard,
  ExpenseForm,
  ClientDetail,
  JobCompletion,
  ProfileCard,
  NavigationBar,
  EmptyState
} from './components/MobileComponents';

// Task Card
<TaskCard
  task={{ id, title, description, dueDate, priority, assignedTo }}
  onComplete={async (taskId) => { /* mark complete */ }}
  onView={(taskId) => { /* open detail */ }}
/>

// Expense Form
<ExpenseForm
  userId={userId}
  onSubmit={async (expense) => { /* save to Firestore */ }}
  onCancel={() => { /* close */ }}
/>

// Client Detail (side panel)
<ClientDetail
  client={{ name, email, phone, address, paymentStatus }}
  onContact={(type, value) => { /* call/email */ }}
  onClose={() => { /* close panel */ }}
/>

// Job Completion (3-step wizard)
<JobCompletion
  job={{ id, title, requirements }}
  onSubmit={async (data) => { /* mark job done */ }}
  onCancel={() => { /* cancel */ }}
/>

// Profile Card
<ProfileCard
  user={{ name, avatar, role, email, phone, team }}
  onEdit={() => { /* edit profile */ }}
  onLogout={() => { /* logout */ }}
/>

// Bottom Navigation
<NavigationBar
  tabs={navigationTabs}
  activeIndex={currentTabIndex}
  onTabChange={(index) => { /* navigate */ }}
/>

// Empty State
<EmptyState
  icon="📭"
  title="No tasks today"
  message="Check back later or ask your manager for work"
  ctaLabel="Create Task"
  onCTA={() => { /* new task */ }}
/>
```

### Mobile AI (`mobileAI.js`)

#### Check Role Permissions

```javascript
import { canAccessFeature, MOBILE_ROLE_PERMISSIONS } from './ai/mobileAI';

// Check if role can access feature
canAccessFeature('employee', 'expenses:log'); // true
canAccessFeature('employee', 'team'); // false

// View all permissions
MOBILE_ROLE_PERMISSIONS.employee; // ['tasks', 'expenses:log', 'clients:view', 'jobs:complete']
```

#### Get AI Action

```javascript
import { getMobileAIAction } from './ai/mobileAI';

// Generate 1 contextual AI action
const action = await getMobileAIAction({
  userId: 'emp-123',
  role: 'employee',
  screenId: 'tasks', // Current screen
  context: { data: tasksData }, // Screen data
  subscription: 'team' // User's subscription
});

// Returns:
// {
//   id: 'deadline_warning',
//   type: 'warning',
//   title: '⚠️ Fix sink is overdue!',
//   icon: '🚨',
//   action: { /* handler function */ },
//   dismissible: true
// }
```

#### Execute & Dismiss Actions

```javascript
import { executeAIAction, dismissAIAction } from './ai/mobileAI';

// User tapped action
await executeAIAction(action, (result) => {
  if (result.success) {
    // Navigate or show feedback
  }
});

// User dismissed action
await dismissAIAction(action.id, userId); // Logged for ML training
```

#### React Hook

```javascript
import { useMobileAI } from './ai/mobileAI';

function TasksScreen({ userId, role }) {
  const { action, loading, dismiss, refresh } = useMobileAI({
    userId,
    role,
    screenId: 'tasks',
    context: { data: tasksData },
    autoRefresh: true // Refresh every 30s
  });

  if (loading) return <Spinner />;
  if (!action) return <TaskList />;

  return (
    <>
      <AIActionBanner
        action={action}
        onDismiss={dismiss}
        onTap={() => executeAIAction(action)}
      />
      <TaskList />
    </>
  );
}
```

---

## 💡 Action Types (AI Suggestions)

### Task Actions
- **deadline_warning** - Overdue task alert
- **task_reminder** - Upcoming deadline
- **delegation_opportunity** - Help colleague with overload

### Expense Actions
- **receipt_recognition** - Auto-detect vendor/amount
- **duplicate_detection** - Warn about duplicate expense
- **policy_violation** - Amount exceeds limit

### Client Actions
- **client_follow_up** - Time to contact client
- **payment_reminder** - Invoice overdue
- **upsell_opportunity** - Recommend additional service

### Job Actions
- **job_suggestion** - Available work nearby
- **material_check** - Verify tools before job
- **safety_reminder** - High-risk job alert

### Team Actions (Managers)
- **workload_balance** - Member is overloaded
- **skill_match** - Best person for job
- **availability_check** - Check schedule

### Analytics Actions (Owners)
- **revenue_alert** - Revenue trend alert
- **performance_milestone** - Achievement celebration

---

## 🛠️ Implementation Steps

### Step 1: Create Mobile Folder Structure (30 min)

```
mobile/
├── src/
│   ├── mobileConfig.js (routing, screens)
│   ├── components/
│   │   └── MobileComponents.jsx (7 components)
│   └── ai/
│       └── mobileAI.js (AI engine)
├── MOBILE_DOCUMENTATION.md
├── MOBILE_EXAMPLES.js
├── MOBILE_QUICK_START.md
├── MOBILE_SUMMARY.md
└── package.json
```

### Step 2: Add Firestore Schema (30 min)

```javascript
// users/{userId}
{
  role: "employee",
  subscription: { tierId: "team" },
  mobile: {
    lastScreen: "/mobile/tasks/assigned",
    aiDismissals: ["action_id_1", "action_id_2"],
    pushToken: "..." // for notifications
  }
}

// mobileAuditLog/{logId}
{
  userId: "emp-123",
  action: "task_completed",
  actionId: "deadline_warning",
  timestamp: now,
  result: "success"
}
```

### Step 3: Create Mobile Routes (1 hour)

```javascript
// In main router
const MOBILE_ROUTES = {
  '/mobile/tasks/assigned': TasksScreen,
  '/mobile/expenses/log': ExpenseForm,
  '/mobile/clients/view': ClientsScreen,
  '/mobile/jobs/complete/:id': JobCompletionScreen,
  '/mobile/profile': ProfileScreen,
  '/mobile/team/status': TeamStatusScreen,
  // ... etc
};
```

### Step 4: Add Mobile Onboarding (1 hour)

```javascript
// After login
import { handleMobileOnboarding } from './mobileConfig';

function LoginCallback({ user }) {
  const redirectPath = handleMobileOnboarding(user);
  window.location.href = redirectPath;
}
```

### Step 5: Integrate AI Suggestions (2 hours)

```javascript
// In each screen component
import { useMobileAI, executeAIAction } from './ai/mobileAI';

function TasksScreen({ userId, role }) {
  const { action, dismiss } = useMobileAI({
    userId, role, screenId: 'tasks',
    context: { data: tasks }
  });

  return (
    <>
      {action && (
        <div className="ai-banner">
          <span>{action.icon} {action.title}</span>
          <button onClick={() => executeAIAction(action)}>
            {action.type === 'alert' ? 'Review' : 'OK'}
          </button>
          <button onClick={dismiss}>✕</button>
        </div>
      )}
      <TaskList />
    </>
  );
}
```

### Step 6: Add Images & Icons (1 hour)

```javascript
// Optimize images for mobile
import { optimizeMobileImage } from './mobileConfig';

<img src={optimizeMobileImage(url, 400)} alt="task" />
```

### Step 7: Test & Deploy (2 hours)

- Test on iOS and Android
- Check connectivity (offline mode)
- Monitor performance (Lighthouse)
- Deploy to App Store/Google Play

**Total: 8 hours**

---

## 🎨 Design Tokens

### Colors
- Primary: #667eea (purple)
- Success: #10b981 (green)
- Warning: #f59e0b (amber)
- Danger: #ef4444 (red)
- Neutral: #e5e7eb (gray)

### Spacing
- XS: 4px
- SM: 8px
- MD: 12px
- LG: 16px
- XL: 20px

### Typography
- Body: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto
- Size: 14px base
- Font weights: 400 (regular), 500 (medium), 600 (semibold)

### Components
- Border radius: 8px
- Touch target: 48px minimum
- Spacing between items: 12px

---

## 📊 Performance Optimization

### Image Optimization
```javascript
// Reduce image size for mobile bandwidth
optimizeMobileImage(url, 400); // 400px max width
// Result: faster loading, less data usage
```

### Code Splitting
```javascript
// Lazy load screen components
const TasksScreen = React.lazy(() => import('./screens/Tasks'));
const ExpensesScreen = React.lazy(() => import('./screens/Expenses'));
```

### State Management
- Use Context API for user/session
- Local state for UI (active tab, form data)
- Firestore for persistence

### Network Awareness
```javascript
// Handle offline/slow connections
if (!navigator.onLine) {
  // Queue actions, show cached data
  showOfflineBanner();
  queueAction(action);
}
```

---

## 🔐 Security & Permissions

### Firestore Rules
```javascript
// Users can only access their own data
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
}

// Managers can read team member data
match /users/{userId} {
  allow read: if isManager(request.auth.uid);
}
```

### Role-Based Access
```javascript
// Every screen checks canAccessMobileScreen()
canAccessMobileScreen(user, 'team'); // Returns false for employees
```

### AI Action Security
```javascript
// Actions respect role permissions
MOBILE_ROLE_PERMISSIONS.employee; // Limited to employee actions only
```

---

## 📈 Analytics Events

Automatically tracked:
- `mobile_screen_viewed` - Screen load
- `ai_action_shown` - AI suggestion displayed
- `ai_action_tapped` - User interacted
- `ai_action_dismissed` - User ignored
- `task_completed_mobile` - Task marked done
- `expense_logged_mobile` - Expense submitted
- `client_contacted` - Call/email sent

---

## ❓ FAQ

**Q: Will the app work offline?**  
A: Yes, with service workers. Actions queue, sync when online.

**Q: How often does AI suggest actions?**  
A: Every screen load + every 30s (configurable). Max 1 per screen.

**Q: Can employees see manager screens?**  
A: No. `canAccessMobileScreen()` blocks access with helpful message.

**Q: How do I customize colors?**  
A: Update `MOBILE_STYLES` CSS or create theme override.

**Q: Does it work on tablets?**  
A: Yes, responsive up to 1024px. Designed for phones first.

---

## 🚀 Next Steps

1. **Implement** - Follow 7-step implementation guide
2. **Test** - Use MOBILE_EXAMPLES.js for reference
3. **Deploy** - Push to App Store / Play Store
4. **Monitor** - Track analytics events
5. **Iterate** - Gather user feedback, improve AI

---

## 📚 Additional Resources

- [MOBILE_EXAMPLES.js](./MOBILE_EXAMPLES.js) - 8 complete implementation examples
- [MOBILE_QUICK_START.md](./MOBILE_QUICK_START.md) - 5-minute setup
- [MOBILE_SUMMARY.md](./MOBILE_SUMMARY.md) - Executive overview
- [mobileConfig.js](./src/mobileConfig.js) - Full API source code
- [MobileComponents.jsx](./src/components/MobileComponents.jsx) - Component source
- [mobileAI.js](./src/ai/mobileAI.js) - AI engine source

---

**Questions?** See the quick start guide or examples for working code.
