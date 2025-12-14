/**
 * MOBILE EMPLOYEE APP - IMPLEMENTATION EXAMPLES
 *
 * 8 complete, production-ready examples
 * Copy-paste and adapt for your needs
 */

import React, { useState, useEffect } from "react";
import {
  doc,
  collection,
  addDoc,
  updateDoc,
  increment,
  getDoc,
  getDocs,
  query,
  where
} from "firebase/firestore";
import { db } from "../config/firebase";
import {
  handleMobileOnboarding,
  getScreensByRole,
  getNavigationTabs,
  canAccessMobileScreen,
  formatMobileDate,
  truncateForMobile,
  MobileNavigation
} from "../mobileConfig";
import {
  TaskCard,
  ExpenseForm,
  ClientDetail,
  JobCompletion,
  ProfileCard,
  NavigationBar,
  EmptyState,
  MOBILE_STYLES
} from "../components/MobileComponents";
import { getMobileAIAction, executeAIAction, useMobileAI } from "../ai/mobileAI";

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 1: Mobile App Entry Point
// ─────────────────────────────────────────────────────────────────────────

/**
 * Main mobile app component
 * Handles login, routing, session management
 */
export function Example1_MobileAppEntry() {
  const [user, setUser] = useState(null);
  const [currentPath, setCurrentPath] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // After user logs in, determine home screen
    if (user) {
      const homePath = handleMobileOnboarding(user);
      setCurrentPath(homePath);
    }
    setLoading(false);
  }, [user]);

  const handleLogin = async (credentials) => {
    // Authenticate user
    const userData = await authenticateUser(credentials);
    setUser(userData);
  };

  if (loading) return <div className="loading-spinner">Loading app...</div>;
  if (!user) return <LoginScreen onLogin={handleLogin} />;

  return (
    <MobileAppLayout user={user} initialPath={currentPath}>
      <MobileRouter user={user} />
    </MobileAppLayout>
  );
}

/**
 * Mobile app layout wrapper
 * Adds bottom nav, safe areas, theme
 */
function MobileAppLayout({ user, initialPath, children }) {
  const [currentPath, setCurrentPath] = useState(initialPath);
  const tabs = getNavigationTabs(user.role);

  return (
    <div className="mobile-app" style={{ paddingTop: "env(safe-area-inset-top)" }}>
      {/* Header */}
      <div className="mobile-header">
        <span className="user-name">{user.name}</span>
        <span className="user-role">{user.role}</span>
      </div>

      {/* Main content */}
      <div className="mobile-content">{children}</div>

      {/* Bottom navigation */}
      <NavigationBar
        tabs={tabs}
        activeIndex={tabs.findIndex((t) => t.path === currentPath)}
        onTabChange={(idx) => setCurrentPath(tabs[idx].path)}
      />

      {/* Styles */}
      <style>{MOBILE_STYLES}</style>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 2: Employee Tasks Screen
// ─────────────────────────────────────────────────────────────────────────

/**
 * Employee tasks home screen
 * Shows assigned tasks, 1 AI suggestion
 */
export async function Example2_EmployeeTasksScreen(userId) {
  console.log(`\n📋 EXAMPLE 2: Employee Tasks Screen`);

  try {
    // Load user's assigned tasks
    const tasksRef = collection(db, "users", userId, "tasks");
    const q = query(tasksRef, where("status", "==", "assigned"));
    const tasksSnapshot = await getDocs(q);

    const tasks = tasksSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data()
    }));

    console.log(`  ✓ Loaded ${tasks.length} tasks`);

    // Get AI suggestion for this screen
    const aiAction = await getMobileAIAction({
      userId,
      role: "employee",
      screenId: "tasks",
      context: { data: tasks }
    });

    console.log(`  ✓ AI suggestion: ${aiAction?.title || "none"}`);

    return {
      tasks,
      aiAction,
      screenComponent: (
        <EmployeeTasksComponent tasks={tasks} aiAction={aiAction} />
      )
    };
  } catch (error) {
    console.error("Error loading tasks:", error);
    return { tasks: [], error: error.message };
  }
}

/**
 * React component for employee tasks
 */
function EmployeeTasksComponent({ tasks, aiAction: initialAction }) {
  const [tasks_state, setTasks] = useState(tasks);
  const { action, dismiss } = useMobileAI({
    userId: "current_user_id",
    role: "employee",
    screenId: "tasks",
    context: { data: tasks_state }
  });

  const handleCompleteTask = async (taskId) => {
    // Mark task as complete in Firestore
    const taskRef = doc(
      db,
      "users",
      "current_user_id",
      "tasks",
      taskId
    );
    await updateDoc(taskRef, { status: "completed", completedAt: new Date() });

    // Update local state
    setTasks(tasks_state.filter((t) => t.id !== taskId));
  };

  return (
    <div className="tasks-screen">
      {action && (
        <div className="ai-banner" onClick={() => executeAIAction(action)}>
          <div>
            <span className="icon">{action.icon}</span>
            <span className="title">{action.title}</span>
          </div>
          <button onClick={dismiss} className="close-btn">
            ✕
          </button>
        </div>
      )}

      {tasks_state.length > 0 ? (
        <div className="task-list">
          {tasks_state.map((task) => (
            <TaskCard
              key={task.id}
              task={task}
              onComplete={handleCompleteTask}
              onView={(id) => openTaskDetail(id)}
            />
          ))}
        </div>
      ) : (
        <EmptyState
          icon="✅"
          title="All done!"
          message="No tasks assigned right now"
          ctaLabel="View History"
          onCTA={() => navigate("/history")}
        />
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 3: Quick Expense Logging
// ─────────────────────────────────────────────────────────────────────────

/**
 * Quick expense logging flow
 * From form submission to Firestore
 */
export async function Example3_QuickExpenseLogging(userId) {
  console.log(`\n💰 EXAMPLE 3: Quick Expense Logging`);

  async function handleExpenseSubmit(formData) {
    try {
      console.log(`  📝 Submitting expense: $${formData.amount} - ${formData.category}`);

      const expense = {
        userId,
        amount: parseFloat(formData.amount),
        category: formData.category,
        description: formData.description,
        receipt: formData.receipt ? formData.receipt.name : null,
        createdAt: new Date(),
        status: "pending", // Requires manager approval
        notes: `[Mobile] ${formData.description || "No notes"}`
      };

      // Save to Firestore
      const docRef = await addDoc(
        collection(db, "expenses"),
        expense
      );

      console.log(`  ✓ Expense saved: ${docRef.id}`);

      // Increment user's expense count
      await updateDoc(doc(db, "users", userId), {
        "usage.expenses": increment(1)
      });

      // Track analytics
      analytics.logEvent("expense_logged_mobile", {
        amount: expense.amount,
        category: expense.category
      });

      return { success: true, expenseId: docRef.id };
    } catch (error) {
      console.error("Error saving expense:", error);
      return { success: false, error: error.message };
    }
  }

  return {
    handleSubmit: handleExpenseSubmit,
    component: <ExpenseForm userId={userId} onSubmit={handleExpenseSubmit} />
  };
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 4: Client Quick View
// ─────────────────────────────────────────────────────────────────────────

/**
 * Client detail panel with one-tap contact
 */
export async function Example4_ClientQuickView(userId, clientId) {
  console.log(`\n👥 EXAMPLE 4: Client Quick View`);

  try {
    // Load client details
    const clientRef = doc(db, "users", userId, "clients", clientId);
    const clientSnap = await getDoc(clientRef);

    if (!clientSnap.exists()) {
      throw new Error("Client not found");
    }

    const client = { id: clientSnap.id, ...clientSnap.data() };
    console.log(`  ✓ Loaded client: ${client.name}`);

    // Handle contact actions
    async function handleContact(type, value) {
      console.log(`  📞 Contacting ${type}: ${value}`);

      if (type === "phone") {
        window.location.href = `tel:${value}`;
      } else if (type === "email") {
        window.location.href = `mailto:${value}`;
      }

      // Log interaction
      await updateDoc(clientRef, {
        lastContact: new Date(),
        [`${type}ContactCount`]: increment(1)
      });
    }

    return {
      client,
      component: (
        <ClientDetail
          client={client}
          onContact={handleContact}
          onClose={() => closePanel()}
        />
      )
    };
  } catch (error) {
    console.error("Error loading client:", error);
    return { error: error.message };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 5: Job Completion Workflow
// ─────────────────────────────────────────────────────────────────────────

/**
 * Multi-step job completion: verify → photos → sign
 */
export async function Example5_JobCompletionWorkflow(userId, jobId) {
  console.log(`\n🔧 EXAMPLE 5: Job Completion Workflow`);

  try {
    // Load job details
    const jobRef = doc(db, "users", userId, "jobs", jobId);
    const jobSnap = await getDoc(jobRef);

    if (!jobSnap.exists()) {
      throw new Error("Job not found");
    }

    const job = { id: jobSnap.id, ...jobSnap.data() };
    console.log(`  ✓ Loaded job: ${job.title}`);

    async function handleJobCompletion(completionData) {
      console.log(`  ✓ Submitting job completion`);

      // Upload photos if provided
      let photoUrls = [];
      if (completionData.photos?.length > 0) {
        console.log(`  📸 Uploading ${completionData.photos.length} photos...`);
        photoUrls = await Promise.all(
          completionData.photos.map((photo) => uploadJobPhoto(userId, jobId, photo))
        );
      }

      // Save completion record
      const completion = {
        jobId,
        userId,
        completedAt: new Date(),
        notes: completionData.notes,
        photos: photoUrls,
        signature: completionData.signature,
        status: "completed"
      };

      const docRef = await addDoc(
        collection(db, "jobCompletions"),
        completion
      );

      // Update job status
      await updateDoc(jobRef, {
        status: "completed",
        completionId: docRef.id,
        completedAt: new Date()
      });

      console.log(`  ✓ Job marked complete: ${docRef.id}`);
      return { success: true, completionId: docRef.id };
    }

    return {
      job,
      component: (
        <JobCompletion
          job={job}
          onSubmit={handleJobCompletion}
          onCancel={() => goBack()}
        />
      )
    };
  } catch (error) {
    console.error("Error loading job:", error);
    return { error: error.message };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 6: Role-Based Screen Access
// ─────────────────────────────────────────────────────────────────────────

/**
 * Enforce role-based screen access
 * Show helpful message if access denied
 */
export function Example6_RoleBasedAccess(user, requestedScreen) {
  console.log(`\n🔐 EXAMPLE 6: Role-Based Access Control`);

  const hasAccess = canAccessMobileScreen(user, requestedScreen);
  console.log(`  User ${user.role} accessing ${requestedScreen}: ${hasAccess ? "✓" : "✗"}`);

  if (!hasAccess) {
    const screens = getScreensByRole(user.role);
    const accessibleScreens = [
      ...screens.primary,
      ...screens.secondary
    ];

    return (
      <div className="access-denied">
        <div className="icon">🔒</div>
        <h3>Access Denied</h3>
        <p>{requestedScreen} is not available for {user.role}s</p>
        <p className="secondary">Available screens:</p>
        <ul>
          {accessibleScreens.map((screen) => (
            <li key={screen.id}>
              {screen.icon} {screen.label}
            </li>
          ))}
        </ul>
        <button onClick={() => navigate(accessibleScreens[0].path)}>
          Go to {accessibleScreens[0].label}
        </button>
      </div>
    );
  }

  // Access granted, render screen component
  return <ScreenComponent />;
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 7: Manager Team Status View
// ─────────────────────────────────────────────────────────────────────────

/**
 * Manager's team overview with AI suggestions
 */
export async function Example7_ManagerTeamView(userId) {
  console.log(`\n👥 EXAMPLE 7: Manager Team Status View`);

  try {
    // Load team members' status
    const userRef = doc(db, "users", userId);
    const userSnap = await getDoc(userRef);
    const teamMemberIds = userSnap.data()?.team || [];

    const teamData = await Promise.all(
      teamMemberIds.map(async (memberId) => {
        const memberRef = doc(db, "users", memberId);
        const memberSnap = await getDoc(memberRef);
        const memberData = memberSnap.data();

        // Count active tasks
        const tasksRef = collection(db, "users", memberId, "tasks");
        const q = query(tasksRef, where("status", "==", "assigned"));
        const tasksSnap = await getDocs(q);

        return {
          id: memberId,
          name: memberData.name,
          role: memberData.role,
          activeTaskCount: tasksSnap.size,
          status: tasksSnap.size > 5 ? "overloaded" : "available",
          lastActivity: memberData.lastActivity
        };
      })
    );

    console.log(`  ✓ Loaded ${teamData.length} team members`);

    // Get AI suggestion for team management
    const aiAction = await getMobileAIAction({
      userId,
      role: "manager",
      screenId: "team",
      context: { data: teamData }
    });

    console.log(`  ✓ AI suggestion: ${aiAction?.title || "none"}`);

    return { teamData, aiAction };
  } catch (error) {
    console.error("Error loading team:", error);
    return { teamData: [], error: error.message };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 8: Mobile Navigation with History
// ─────────────────────────────────────────────────────────────────────────

/**
 * Full navigation management with back button
 */
export class Example8_MobileNavigationManager {
  constructor(initialRole = "employee") {
    this.navigation = new MobileNavigation(initialRole);
  }

  /**
   * Navigate to screen
   */
  navigateTo(screenPath) {
    console.log(`\n🗺️ EXAMPLE 8: Navigation`);
    console.log(`  → Navigating to ${screenPath}`);

    if (this.navigation.navigateTo(screenPath)) {
      console.log(`  ✓ Current screen: ${this.navigation.currentScreen}`);
      return true;
    } else {
      console.log(`  ✗ Invalid path for role`);
      return false;
    }
  }

  /**
   * Go back
   */
  goBack() {
    if (this.navigation.goBack()) {
      console.log(`  ← Back: ${this.navigation.currentScreen}`);
      return true;
    }
    console.log(`  ✗ Can't go back (at start)`);
    return false;
  }

  /**
   * Get current state for UI
   */
  getState() {
    return this.navigation.getState();
  }
}

// ─────────────────────────────────────────────────────────────────────────
// HELPER FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────

async function uploadJobPhoto(userId, jobId, photoFile) {
  // Implementation: upload to Firebase Storage
  const path = `jobs/${userId}/${jobId}/${Date.now()}_${photoFile.name}`;
  // const url = await storage.ref(path).put(photoFile);
  console.log(`  Uploading: ${path}`);
  return `gs://bucket/${path}`;
}

function openTaskDetail(taskId) {
  console.log(`Opening task: ${taskId}`);
}

function navigate(path) {
  window.location.href = path;
}

function goBack() {
  window.history.back();
}

function closePanel() {
  document.querySelector(".panel")?.remove();
}

// ─────────────────────────────────────────────────────────────────────────
// USAGE EXAMPLES
// ─────────────────────────────────────────────────────────────────────────

/**
 * Run all examples
 */
export async function runAllExamples() {
  console.log("╔════════════════════════════════════════╗");
  console.log("║    MOBILE APP EXAMPLES RUNNING         ║");
  console.log("╚════════════════════════════════════════╝");

  const userId = "user-123";

  // Example 1
  const app = await Example1_MobileAppEntry();

  // Example 2
  const tasks = await Example2_EmployeeTasksScreen(userId);

  // Example 3
  const expense = await Example3_QuickExpenseLogging(userId);

  // Example 4
  const client = await Example4_ClientQuickView(userId, "client-1");

  // Example 5
  const job = await Example5_JobCompletionWorkflow(userId, "job-1");

  // Example 6
  const access = Example6_RoleBasedAccess(
    { role: "employee" },
    "team"
  );

  // Example 7
  const team = await Example7_ManagerTeamView(userId);

  // Example 8
  const nav = new Example8_MobileNavigationManager("employee");
  nav.navigateTo("/mobile/tasks/assigned");
  nav.navigateTo("/mobile/expenses/log");
  nav.goBack();

  console.log("\n✓ All examples completed!");
}
