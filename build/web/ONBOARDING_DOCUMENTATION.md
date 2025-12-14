# Onboarding Flow System
Complete employee and owner onboarding implementation for AuraSphere Pro

## Overview

The onboarding system provides a smooth first-time user experience:
- **Employee Onboarding**: Quick welcome → auto-redirect to tasks
- **Owner Onboarding**: Multi-step setup wizard with progress tracking
- **Role-Based Flows**: Different experiences for employees vs owners
- **Persistent State**: Uses Firestore + localStorage for reliability

## Quick Start

### Employee Onboarding
```javascript
import { handleEmployeeOnboarding } from './onboarding/employeeFlow';

const user = getAuth().currentUser;
await handleEmployeeOnboarding(user, {
  showTooltip: true,
  redirectPath: "/tasks/assigned",
  redirectDelay: 500
});
```

### Owner Onboarding
```javascript
import { handleOwnerOnboarding } from './onboarding/ownerFlow';

const user = getAuth().currentUser;
await handleOwnerOnboarding(user, {
  showWelcome: true,
  redirectPath: "/onboarding/owner"
});
```

## System Architecture

### Files Overview

#### 1. `src/onboarding/employeeFlow.js` (15 KB)
**Purpose**: Employee-specific onboarding flow
**Exports** (11 functions):
- `handleEmployeeOnboarding(user, options)` - Main flow
- `skipEmployeeOnboarding(user)` - Skip setup
- `isEmployeeOnboarded(user)` - Check status (Firestore)
- `getEmployeeOnboardingStatus(user)` - Detailed status
- `getOnboardingTooltipStatus(tooltipId)` - Tooltip state
- `shouldShowEmployeeOnboarding(user)` - Show check
- `setEmployeeOnboardingFlag(value)` - Set localStorage
- `isEmployeeOnboardedLocal()` - Quick check (localStorage)
- `setOnboardingTooltip(tooltipId, status)` - Set tooltip
- `clearOnboardingData()` - Reset all
- `logOnboardingEvent(userId, eventName, metadata)` - Analytics

**Key Features**:
- Auto-redirect to `/tasks/assigned`
- Optional welcome tooltip
- Firestore + localStorage sync
- Analytics integration points
- Error handling with try/catch

#### 2. `src/onboarding/ownerFlow.js` (17 KB)
**Purpose**: Owner multi-step onboarding
**Exports**:
- `OWNER_ONBOARDING_STEPS` - Const array of 6 steps
- `handleOwnerOnboarding(user, options)` - Initialize
- `completeOwnerOnboardingStep(user, stepId)` - Mark step done
- `skipOwnerOnboarding(user)` - Skip remaining
- `completeOwnerOnboarding(user)` - Finish all
- `getOwnerOnboardingStatus()` - Get status
- `getOnboardingStep(stepId)` - Fetch step by ID
- `getOnboardingStepsWithStatus(completedSteps)` - Steps + status
- `getEstimatedTimeRemaining(completedSteps)` - Time calc
- Plus 8 localStorage helpers and analytics

**Onboarding Steps**:
1. **Setup Profile** (5 min, required)
   - Business name, logo, contact info
2. **Add Team Members** (10 min, optional)
   - Invite employees
3. **Configure Invoices** (5 min, optional)
   - Templates, numbering
4. **Categorize Expenses** (10 min, optional)
   - Categories, budget limits
5. **Add First Client** (5 min, optional)
   - Create first client
6. **Create First Invoice** (10 min, optional)
   - Issue first invoice

#### 3. `src/components/OnboardingComponents.jsx` (12 KB)
**Purpose**: React components for onboarding UI
**Exports** (4 components):

**OnboardingGuard**
- Protects routes from unboarded users
- Role-aware (employee vs owner)
- Auto-redirects to appropriate flow
```jsx
<OnboardingGuard>
  <Dashboard />
</OnboardingGuard>
```

**EmployeeOnboardingScreen**
- Welcome UI with feature list
- Get started button + skip option
- Handles redirect on completion

**OwnerOnboardingProgress**
- Progress bar and step list
- Shows completion status
- Displays time remaining
- Visual step indicators

**OwnerOnboardingStep**
- Individual step card
- Shows description and time estimate
- Navigate or skip buttons
- Completion indicator

## API Reference

### Employee Flow

#### `handleEmployeeOnboarding(user, options)`
Main employee onboarding handler

**Parameters**:
| Name | Type | Default | Description |
|------|------|---------|-------------|
| user | Object | - | Firebase user object |
| options | Object | {} | Configuration |
| options.showTooltip | boolean | true | Show welcome tooltip |
| options.redirectPath | string | "/tasks/assigned" | Redirect destination |
| options.redirectDelay | number | 0 | Delay before redirect (ms) |

**Returns**: Promise<void>

**Behavior**:
1. Updates Firestore with `onboardingCompleted: true`
2. Sets localStorage flag `employeeOnboarded`
3. Sets tooltip state if enabled
4. Logs analytics event
5. Redirects after delay

**Example**:
```javascript
try {
  await handleEmployeeOnboarding(user, {
    showTooltip: true,
    redirectPath: "/tasks/assigned",
    redirectDelay: 500
  });
} catch (error) {
  console.error("Onboarding failed:", error);
}
```

#### `isEmployeeOnboarded(user)`
Check if employee is onboarded

**Parameters**:
- user: Firebase user object

**Returns**: Promise<boolean>

**Behavior**:
1. Checks localStorage first (quick)
2. Falls back to Firestore (authoritative)
3. Syncs localStorage if needed

**Example**:
```javascript
const isOnboarded = await isEmployeeOnboarded(user);
if (!isOnboarded) {
  // Show onboarding
}
```

#### `getEmployeeOnboardingStatus(user)`
Get detailed onboarding status

**Returns**:
```javascript
{
  completed: boolean,      // Onboarding done
  skipped: boolean,        // User skipped
  completedAt: Date|null,  // When completed
  skippedAt: Date|null     // When skipped
}
```

#### `shouldShowEmployeeOnboarding(user)`
Check if employee should see onboarding

**Returns**: Promise<boolean>
- true if not completed AND not skipped

### Owner Flow

#### `handleOwnerOnboarding(user, options)`
Initialize owner onboarding

**Parameters**:
| Name | Type | Default | Description |
|------|------|---------|-------------|
| user | Object | - | Firebase user object |
| options.showWelcome | boolean | true | Show welcome modal |
| options.redirectPath | string | "/onboarding/owner" | Redirect destination |

**Firestore Updates**:
```javascript
{
  onboardingStarted: true,
  onboardingStartedAt: Date,
  role: "owner",
  onboardingProgress: {
    completedSteps: [],
    currentStep: "setup_profile",
    progressPercentage: 0
  }
}
```

#### `completeOwnerOnboardingStep(user, stepId)`
Mark step as completed

**Parameters**:
- user: Firebase user object
- stepId: Step ID (e.g., "setup_profile")

**Updates**:
- Adds stepId to completedSteps
- Advances to next required step
- Recalculates progress percentage
- Updates Firestore and localStorage

**Example**:
```javascript
await completeOwnerOnboardingStep(user, "setup_profile");
// Owner automatically advances to next step
```

#### `getOwnerOnboardingStatus()`
Get current owner onboarding status

**Returns**:
```javascript
{
  started: boolean,          // Onboarding started
  completed: boolean,        // Onboarding completed
  currentStep: string|null,  // Current step ID
  progress: {
    completedSteps: string[],
    currentStep: string|null,
    progressPercentage: number
  }
}
```

#### `getOnboardingStepsWithStatus(completedSteps)`
Get all steps with completion status

**Parameters**:
- completedSteps: Array of completed step IDs

**Returns**: Array of step objects with `completed` property

**Example**:
```javascript
const steps = getOnboardingStepsWithStatus(["setup_profile", "add_team_members"]);
// [
//   { id: "setup_profile", completed: true, ... },
//   { id: "add_team_members", completed: true, ... },
//   { id: "configure_invoices", completed: false, ... },
//   ...
// ]
```

#### `getEstimatedTimeRemaining(completedSteps)`
Calculate remaining setup time

**Returns**: Number (minutes)

## Usage Examples

### Example 1: Employee Onboarding Flow

```javascript
// In auth/signup route
import { handleEmployeeOnboarding } from './onboarding/employeeFlow';

async function handleNewEmployeeSignup(user) {
  try {
    await handleEmployeeOnboarding(user, {
      showTooltip: true,
      redirectPath: "/tasks/assigned",
      redirectDelay: 500
    });
  } catch (error) {
    console.error("Onboarding failed:", error);
    // Show error modal
  }
}
```

### Example 2: Employee Welcome Tooltip

```javascript
import {
  getOnboardingTooltipStatus,
  setOnboardingTooltip
} from './onboarding/employeeFlow';

function TasksDashboard() {
  const tooltipStatus = getOnboardingTooltipStatus("employee_welcome");
  
  const shouldShowTooltip = tooltipStatus === "shown" && !userDismissed;

  return (
    <div>
      {shouldShowTooltip && (
        <Tooltip>
          <p>Welcome! Your assigned tasks appear here.</p>
          <button onClick={() => setOnboardingTooltip("employee_welcome", "dismissed")}>
            Got it
          </button>
        </Tooltip>
      )}
      <TaskList />
    </div>
  );
}
```

### Example 3: Owner Onboarding Progress

```javascript
import {
  OWNER_ONBOARDING_STEPS,
  getOwnerOnboardingProgress,
  completeOwnerOnboardingStep
} from './onboarding/ownerFlow';
import { OwnerOnboardingProgress } from './components/OnboardingComponents';

function OnboardingDashboard({ user }) {
  const progress = getOwnerOnboardingProgress();
  
  const handleStepComplete = async (stepId) => {
    await completeOwnerOnboardingStep(user, stepId);
    // Progress automatically updated
  };

  return (
    <div className="onboarding-dashboard">
      <OwnerOnboardingProgress
        completedSteps={progress.completedSteps}
        currentStep={progress.currentStep}
      />
      
      <div className="steps-container">
        {OWNER_ONBOARDING_STEPS.map(step => (
          <OwnerOnboardingStep
            key={step.id}
            step={step}
            isActive={step.id === progress.currentStep}
            isCompleted={progress.completedSteps.includes(step.id)}
            onComplete={() => handleStepComplete(step.id)}
          />
        ))}
      </div>
    </div>
  );
}
```

### Example 4: Onboarding Guard in Routes

```javascript
import { OnboardingGuard } from './components/OnboardingComponents';
import Dashboard from './pages/Dashboard';

function AppRoutes() {
  return (
    <Routes>
      <Route path="/dashboard" element={
        <OnboardingGuard>
          <Dashboard />
        </OnboardingGuard>
      } />
      
      <Route path="/tasks" element={
        <OnboardingGuard>
          <TasksDashboard />
        </OnboardingGuard>
      } />
    </Routes>
  );
}
```

### Example 5: Checking Onboarding Status

```javascript
import {
  isEmployeeOnboarded,
  getEmployeeOnboardingStatus
} from './onboarding/employeeFlow';

async function handleUserLogin(user) {
  const status = await getEmployeeOnboardingStatus(user);
  
  if (!status.completed) {
    if (status.skipped) {
      // User skipped onboarding, show optional setup in settings
      showOnboardingOptional();
    } else {
      // User hasn't started, show onboarding
      showOnboarding();
    }
  } else {
    // User is fully onboarded, proceed normally
    navigateToDashboard();
  }
}
```

## Firestore Schema Updates

The system requires the following fields on the `users` collection:

### Employee Onboarding Fields
```javascript
{
  onboardingCompleted: boolean,        // true when employee completes onboarding
  onboardingCompletedAt: timestamp,    // When completed
  onboardingSkipped: boolean,          // true if user skipped
  onboardingSkippedAt: timestamp,      // When skipped
}
```

### Owner Onboarding Fields
```javascript
{
  onboardingStarted: boolean,          // true when owner starts
  onboardingStartedAt: timestamp,      // When started
  onboardingCompleted: boolean,        // true when all required steps done
  onboardingCompletedAt: timestamp,    // When completed
  onboardingSkipped: boolean,          // true if skipped
  onboardingSkippedAt: timestamp,      // When skipped
  onboardingProgress: {
    completedSteps: [string],          // Array of completed step IDs
    currentStep: string,               // Current step ID
    progressPercentage: number,        // 0-100
    lastUpdatedAt: timestamp
  }
}
```

## Security Rules

Add to Firestore security rules to protect onboarding data:

```javascript
// Only users can read/write their own onboarding data
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
  
  // Specific rules for onboarding fields
  allow update: if request.auth.uid == userId && 
                   ('onboardingCompleted' in request.resource.data ||
                    'onboardingProgress' in request.resource.data);
}
```

## Local Storage Structure

The system uses the following localStorage keys:

### Employee
```javascript
"employeeOnboarded"              // "true" or "false"
"tooltip_employee_welcome"       // "shown", "skipped", or "dismissed"
"onboarding_dismissed"           // "true" if dismissed
```

### Owner
```javascript
"ownerOnboarding"                // "true" during onboarding
"ownerOnboarded"                 // "true" when completed
"ownerWelcome"                   // "true" to show welcome modal
"currentOnboardingStep"          // Current step ID
"ownerOnboardingProgress"        // JSON stringified progress object
```

## Styling & Customization

### CSS Classes

**Loader**:
- `.onboarding-loader` - Loading spinner
- `.spinner` - Spinner animation

**Employee Screen**:
- `.onboarding-screen` - Main container
- `.employee-onboarding` - Employee variant
- `.onboarding-content` - Content area
- `.onboarding-icon` - Welcome icon
- `.onboarding-features` - Feature list
- `.feature` - Individual feature
- `.onboarding-actions` - Button container

**Progress**:
- `.onboarding-progress` - Progress container
- `.progress-header` - Header section
- `.progress-bar` - Visual bar
- `.progress-fill` - Filled portion
- `.progress-steps` - Step list
- `.step` - Individual step
- `.step.completed` - Completed state
- `.step.current` - Active state
- `.step.pending` - Pending state

**Step Card**:
- `.onboarding-step` - Container
- `.step-header` - Header section
- `.required-badge` - Required indicator
- `.step-description` - Description text
- `.step-actions` - Button area
- `.step-completed` - Completion indicator

### Customization Example

```css
.onboarding-screen {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
}

.onboarding-content {
  background: white;
  border-radius: 12px;
  padding: 40px;
  max-width: 600px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
}

.progress-bar {
  height: 8px;
  background: #e9ecef;
  border-radius: 4px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #667eea, #764ba2);
  transition: width 0.3s ease;
}
```

## Testing

### Unit Tests (Jest)

```javascript
import {
  handleEmployeeOnboarding,
  isEmployeeOnboarded,
  getEmployeeOnboardingStatus
} from '../employeeFlow';

describe('Employee Onboarding', () => {
  it('should complete employee onboarding', async () => {
    const user = { uid: 'test-user-123' };
    
    await handleEmployeeOnboarding(user);
    
    const status = await getEmployeeOnboardingStatus(user);
    expect(status.completed).toBe(true);
  });

  it('should check onboarding status from localStorage', () => {
    localStorage.setItem('employeeOnboarded', 'true');
    
    const isOnboarded = isEmployeeOnboardedLocal();
    expect(isOnboarded).toBe(true);
  });
});
```

### Component Tests (React Testing Library)

```javascript
import { render, screen, fireEvent } from '@testing-library/react';
import { EmployeeOnboardingScreen } from '../OnboardingComponents';

describe('EmployeeOnboardingScreen', () => {
  it('should render welcome message', () => {
    render(<EmployeeOnboardingScreen user={{ uid: '123' }} />);
    
    expect(screen.getByText('Welcome to AuraSphere Pro!')).toBeInTheDocument();
  });

  it('should handle get started click', async () => {
    const { getByText } = render(
      <EmployeeOnboardingScreen user={{ uid: '123' }} />
    );
    
    fireEvent.click(getByText('Get Started'));
    
    expect(getByText('Setting up...')).toBeInTheDocument();
  });
});
```

## Troubleshooting

### User stuck in onboarding loop
1. Check localStorage: `localStorage.getItem('employeeOnboarded')`
2. Check Firestore: Verify `onboardingCompleted: true` in user doc
3. Clear and retry: `localStorage.clear()` then refresh

### Progress not updating
1. Verify Firestore write permissions
2. Check network tab for failed updates
3. Ensure userId matches in Firestore rules
4. Clear localStorage and sync with Firestore

### Tooltip not showing
1. Check localStorage key: `tooltip_employee_welcome`
2. Verify showTooltip option: `{ showTooltip: true }`
3. Check if dismissed: `localStorage.getItem('onboarding_dismissed')`

### Owner steps not advancing
1. Verify step IDs match OWNER_ONBOARDING_STEPS
2. Check currentStep in localStorage
3. Confirm completeOwnerOnboardingStep is called
4. Review Firestore progress object structure

## Best Practices

1. **Always Handle Errors**: Wrap onboarding calls in try/catch
2. **Show Loading States**: Disable buttons during processing
3. **Sync Firestore & Local**: Use OnboardingGuard for protection
4. **Track Analytics**: Use logOnboardingEvent for metrics
5. **Test Both Flows**: Test employee and owner paths
6. **Check Role**: Verify user role before starting onboarding
7. **Clear on Logout**: Reset localStorage on user logout
8. **Timeout Handling**: Add timeouts for redirect delays
9. **Mobile Responsive**: Ensure onboarding works on mobile
10. **Accessibility**: Use ARIA labels, keyboard navigation

## Migration from Old System

If you have an existing onboarding system:

```javascript
// 1. Keep old flags for backward compatibility
const isOldOnboarded = localStorage.getItem('hasOnboarded') === 'true';

// 2. Call migration on first load
if (isOldOnboarded && !isEmployeeOnboardedLocal()) {
  setEmployeeOnboardingFlag(true);
}

// 3. Update Firestore records with a Cloud Function
```

## Next Steps

1. **Install**: Copy files to your project
2. **Configure**: Update Firestore schema with onboarding fields
3. **Update Routes**: Add OnboardingGuard to protected routes
4. **Customize UI**: Style components to match your design
5. **Test**: Verify both employee and owner flows
6. **Analytics**: Wire up logOnboardingEvent to your service
7. **Deploy**: Push to staging and test with real users

---

**File Manifest**:
- `src/onboarding/employeeFlow.js` (15 KB)
- `src/onboarding/ownerFlow.js` (17 KB)
- `src/components/OnboardingComponents.jsx` (12 KB)
- `ONBOARDING_DOCUMENTATION.md` (This file, 14 KB)

**Total**: 4 files, ~58 KB of production-ready code
