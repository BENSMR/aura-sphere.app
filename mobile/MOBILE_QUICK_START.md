# MOBILE EMPLOYEE APP - QUICK START

**Get running in 5 minutes**

---

## 🚀 30-Second Overview

AuraSphere's mobile app gives your employees:
- ✅ Task assignment & completion (1-tap)
- ✅ Quick expense logging with photo
- ✅ Client contact info & payment status
- ✅ Job completion workflow with signature
- ✅ AI suggestions (1 per screen)
- ✅ Role-based screens (employee vs manager)

**No desktop complexity. Optimized for field.**

---

## ⚡ 5-Minute Setup

### Step 1: Import Core Module (30 seconds)

```javascript
import {
  MOBILE_SCREENS,
  handleMobileOnboarding,
  getScreensByRole,
  canAccessMobileScreen,
  getMobileAIContext
} from './mobile/mobileConfig';

import {
  TaskCard,
  ExpenseForm,
  ProfileCard,
  NavigationBar
} from './mobile/components/MobileComponents';

import { getMobileAIAction, useMobileAI } from './mobile/ai/mobileAI';
```

### Step 2: Create Mobile Routes (1 minute)

```javascript
// In your main router
import { handleMobileOnboarding } from './mobile/mobileConfig';

export const MOBILE_ROUTES = {
  '/mobile/tasks/assigned': TasksScreen,
  '/mobile/expenses/log': ExpenseScreen,
  '/mobile/clients/view': ClientsScreen,
  '/mobile/jobs/complete/:id': JobsScreen,
  '/mobile/profile': ProfileScreen,
  '/mobile/team/status': TeamScreen,
  '/mobile/dashboard': DashboardScreen
};

// Post-login routing
async function handleLogin(user) {
  const redirectPath = handleMobileOnboarding(user);
  navigate(redirectPath);
}
```

### Step 3: Add Bottom Navigation (1 minute)

```javascript
import { getNavigationTabs } from './mobile/mobileConfig';
import { NavigationBar } from './mobile/components/MobileComponents';

function MobileLayout({ user, children }) {
  const tabs = getNavigationTabs(user.role);
  const [activeTab, setActiveTab] = useState(0);

  return (
    <div className="mobile-container">
      {children}
      <NavigationBar 
        tabs={tabs}
        activeIndex={activeTab}
        onTabChange={setActiveTab}
      />
    </div>
  );
}
```

### Step 4: Add Task Cards (1 minute)

```javascript
import { TaskCard } from './mobile/components/MobileComponents';

function TasksScreen({ user }) {
  const [tasks, setTasks] = useState([]);

  return (
    <div className="tasks-screen">
      {tasks.map(task => (
        <TaskCard
          key={task.id}
          task={task}
          onComplete={(taskId) => completeTask(taskId)}
          onView={(taskId) => openTaskDetail(taskId)}
        />
      ))}
    </div>
  );
}
```

### Step 5: Add AI Suggestions (1.5 minutes)

```javascript
import { useMobileAI, executeAIAction } from './mobile/ai/mobileAI';

function TasksScreen({ user }) {
  const { action, dismiss } = useMobileAI({
    userId: user.id,
    role: user.role,
    screenId: 'tasks',
    context: { data: tasks }
  });

  return (
    <>
      {action && (
        <div className="ai-suggestion">
          <span>{action.icon} {action.title}</span>
          <button onClick={() => executeAIAction(action)}>
            {action.type === 'alert' ? '→' : 'OK'}
          </button>
          <button onClick={dismiss}>✕</button>
        </div>
      )}
      {/* Rest of screen */}
    </>
  );
}
```

---

## 🎯 API Cheat Sheet

### Screen Management

```javascript
import {
  MOBILE_SCREENS,
  getScreensByRole,
  getNavigationTabs,
  getHomeScreen,
  canAccessMobileScreen
} from './mobile/mobileConfig';

// Get screens for user
getScreensByRole('employee');
// → { primary: [tasks, expenses, clients, ...], secondary: [...] }

// Get tabs for bottom nav (max 5)
getNavigationTabs('employee');
// → [{ id: 'tasks', path: '/mobile/tasks/assigned', icon: '✓' }, ...]

// Check access
canAccessMobileScreen(user, 'dashboard'); // false for employees
canAccessMobileScreen(user, 'tasks'); // true
```

### Navigation

```javascript
import { MobileNavigation } from './mobile/mobileConfig';

const nav = new MobileNavigation('employee');
nav.navigateTo('/mobile/tasks/assigned'); // true
nav.goBack(); // true
nav.getState(); // { currentScreen, activeTabIndex, canGoBack, tabs }
```

### Mobile Utilities

```javascript
import {
  truncateForMobile,
  formatMobileDate,
  optimizeMobileImage,
  vibrateDevice
} from './mobile/mobileConfig';

truncateForMobile("Long task", 40); // "Long task..."
formatMobileDate(now); // "Jan 15, 2:30 PM"
optimizeMobileImage(url, 400); // Mobile-sized image
vibrateDevice(100); // Haptic feedback
```

### AI Actions

```javascript
import { 
  getMobileAIAction, 
  executeAIAction, 
  dismissAIAction,
  canAccessFeature 
} from './mobile/ai/mobileAI';

// Check role permissions
canAccessFeature('employee', 'tasks'); // true
canAccessFeature('employee', 'team'); // false

// Get single AI action
const action = await getMobileAIAction({
  userId: 'emp-123',
  role: 'employee',
  screenId: 'tasks',
  context: { data: tasksData }
});

// Execute action
await executeAIAction(action, (result) => {
  if (result.success) navigate(action.action.path);
});

// Dismiss (user ignored it)
await dismissAIAction(action.id, userId);
```

### React Hooks

```javascript
import { useMobileAI } from './mobile/ai/mobileAI';

// Hook auto-loads AI action
const { action, loading, dismiss } = useMobileAI({
  userId, role, screenId: 'tasks', context: { data }
});
```

---

## 📱 Component Library

### TaskCard
```javascript
<TaskCard
  task={{
    id: "task-1",
    title: "Fix sink",
    description: "Kitchen sink not draining",
    dueDate: "2024-01-20T14:00:00",
    priority: "high", // or "medium", "low"
    assignedTo: "Ali"
  }}
  onComplete={(taskId) => markTaskDone(taskId)}
  onView={(taskId) => openTaskDetail(taskId)}
/>
```

### ExpenseForm
```javascript
<ExpenseForm
  userId={user.id}
  onSubmit={async (expense) => {
    // Save to Firestore
    await db.collection('expenses').add(expense);
  }}
  onCancel={() => closeForm()}
/>
```

### ClientDetail
```javascript
<ClientDetail
  client={{
    name: "Ahmed",
    email: "ahmed@co.com",
    phone: "+1-555-0100",
    address: "123 Main St",
    paymentStatus: "Overdue"
  }}
  onContact={(type, value) => {
    if (type === 'phone') window.location.href = `tel:${value}`;
    if (type === 'email') window.location.href = `mailto:${value}`;
  }}
  onClose={() => closePanel()}
/>
```

### NavigationBar
```javascript
<NavigationBar
  tabs={[
    { id: 'tasks', path: '/mobile/tasks', label: 'Tasks', icon: '✓' },
    { id: 'expenses', path: '/mobile/expenses', label: 'Expenses', icon: '💰' }
  ]}
  activeIndex={0}
  onTabChange={(index) => navigate(tabs[index].path)}
/>
```

### ProfileCard
```javascript
<ProfileCard
  user={{
    name: "John",
    avatar: "https://...",
    role: "employee",
    email: "john@co.com",
    phone: "+1-555-0101",
    team: "Field Service"
  }}
  onEdit={() => openProfileEditor()}
  onLogout={() => logout()}
/>
```

### EmptyState
```javascript
<EmptyState
  icon="📭"
  title="No tasks today"
  message="Great work! You've completed all your tasks."
  ctaLabel="View History"
  onCTA={() => navigate('/history')}
/>
```

---

## 3️⃣ Common Scenarios

### Scenario 1: Employee App Home

```jsx
function EmployeeHome({ user }) {
  const [tasks, setTasks] = useState([]);
  const [activeTab, setActiveTab] = useState(0);
  const { action, dismiss } = useMobileAI({
    userId: user.id,
    role: user.role,
    screenId: 'tasks',
    context: { data: tasks }
  });

  const tabs = getNavigationTabs(user.role);

  return (
    <div className="mobile-home">
      {action && (
        <div className="ai-banner" onClick={() => executeAIAction(action)}>
          <span>{action.icon} {action.title}</span>
          <button onClick={dismiss}>✕</button>
        </div>
      )}

      {tasks.length > 0 ? (
        <div className="task-list">
          {tasks.map(task => (
            <TaskCard
              key={task.id}
              task={task}
              onComplete={(id) => completeTask(id)}
              onView={(id) => openDetail(id)}
            />
          ))}
        </div>
      ) : (
        <EmptyState
          icon="✅"
          title="All done!"
          message="No tasks assigned right now"
          ctaLabel="View Profile"
          onCTA={() => setActiveTab(4)}
        />
      )}

      <NavigationBar
        tabs={tabs}
        activeIndex={activeTab}
        onTabChange={setActiveTab}
      />
    </div>
  );
}
```

### Scenario 2: Manager Team View

```jsx
function ManagerTeamScreen({ user }) {
  const [team, setTeam] = useState([]);
  const { action, dismiss } = useMobileAI({
    userId: user.id,
    role: user.role,
    screenId: 'team',
    context: { data: team }
  });

  return (
    <>
      {action && (
        <div className="ai-banner">
          <div>
            {action.icon} {action.title}
            <p>{action.description}</p>
          </div>
          <button onClick={() => executeAIAction(action)}>→</button>
        </div>
      )}

      <div className="team-status">
        {team.map(member => (
          <div key={member.id} className="member-card">
            <div>
              <strong>{member.name}</strong>
              <p>{member.activeTask} tasks</p>
            </div>
            <span className={`status ${member.status}`}>
              {member.status}
            </span>
          </div>
        ))}
      </div>
    </>
  );
}
```

### Scenario 3: Expense Quick Log

```jsx
function ExpenseQuickLog({ user, onDone }) {
  const handleSubmit = async (expense) => {
    await db.collection('expenses').add({
      userId: user.id,
      ...expense,
      createdAt: new Date()
    });
    onDone();
  };

  return (
    <ExpenseForm
      userId={user.id}
      onSubmit={handleSubmit}
      onCancel={onDone}
    />
  );
}
```

---

## ✅ Testing Checklist

- [ ] All navigation tabs work and show correct screens
- [ ] AI suggestions appear (1 per screen max)
- [ ] Task cards show and complete button works
- [ ] Expense form captures photo, amount, category
- [ ] Client detail panel opens and contact buttons work
- [ ] Profile card displays and logout works
- [ ] Bottom nav highlights active tab with vibration
- [ ] Images load (optimized for mobile)
- [ ] Works on iPhone and Android
- [ ] App works offline (with service worker)
- [ ] Performance: Lighthouse score > 80
- [ ] Accessibility: No WCAG violations

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| AI action not showing | Check `canAccessFeature()` returns true for role |
| Bottom nav has wrong tabs | Verify `MOBILE_SCREENS[role]` in config |
| Screen shows "Access denied" | Ensure `canAccessMobileScreen()` allows it |
| Images load slow | Use `optimizeMobileImage()` to resize |
| Component style issues | Check `MOBILE_STYLES` CSS is imported |
| AI actions not updating | Verify `useMobileAI()` has correct screenId |

---

## 📚 Full Documentation

For complete API reference, architecture, and advanced usage:

→ [MOBILE_DOCUMENTATION.md](./MOBILE_DOCUMENTATION.md)

---

## 💡 Pro Tips

✅ Use **vibration feedback** when user taps buttons - feels more responsive

✅ **Truncate text** to 40-50 chars with `truncateForMobileDate()` - better on small screens

✅ **Optimize images** to 400px width max - saves bandwidth, loads faster

✅ **Cache AI actions** - don't regenerate on every render, refresh every 30s

✅ **Show empty states** - users feel confident when no data is normal (no tasks = good!)

✅ **Test on real devices** - simulator doesn't catch performance issues

---

## 🎓 Examples

For 8 complete implementation examples with Firestore integration:

→ [MOBILE_EXAMPLES.js](./MOBILE_EXAMPLES.js)

---

**Ready to build?** Start with Step 1 above. Should take ~5 minutes to get basic app running!
