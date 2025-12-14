// Web RBAC Integration Examples
// These examples show how to use the role-based access control system in your React components

import React, { useState, Suspense } from 'react';
import { lazy } from 'react';
import { useNavigate } from 'react-router-dom';

// ============================================================================
// EXAMPLE 1: Using useRole Hook for Basic Role Checking
// ============================================================================

export function UserGreeting() {
  const { role, loading } = useRole();

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      <h1>Welcome, {role === 'owner' ? 'Owner' : 'Employee'}!</h1>
      <p>Your role: <strong>{role}</strong></p>
    </div>
  );
}

// ============================================================================
// EXAMPLE 2: Conditional Feature Rendering Based on Role
// ============================================================================

export function Dashboard() {
  const { role } = useRole();

  return (
    <div className="dashboard">
      <h1>Dashboard</h1>

      {/* Show main features for all authenticated users */}
      <section className="main-features">
        <FeatureCard title="Tasks" icon="📋" />
        <FeatureCard title="Expenses" icon="💰" />
        <FeatureCard title="Clients" icon="👥" />
      </section>

      {/* Show advanced section only for owners */}
      {role === 'owner' && (
        <section className="advanced-features">
          <h2>Advanced Features</h2>
          <FeatureCard title="Suppliers" icon="🏭" />
          <FeatureCard title="Purchase Orders" icon="📦" />
          <FeatureCard title="Inventory" icon="📊" />
          <FeatureCard title="Finance" icon="💹" />
          <FeatureCard title="Admin Panel" icon="⚙️" />
        </section>
      )}
    </div>
  );
}

// ============================================================================
// EXAMPLE 3: Using useFeatureAccess for Detailed Permission Checks
// ============================================================================

export function InvoiceManager() {
  const { canAccess: canAccessInvoices, permissions } = useFeatureAccess('invoices');
  const [invoices, setInvoices] = useState([]);

  if (!canAccessInvoices) {
    return <div>You don't have permission to access invoices.</div>;
  }

  return (
    <div>
      <h2>Invoice Management</h2>
      
      <div className="actions">
        {permissions?.canCreate && (
          <button onClick={() => createInvoice()}>+ New Invoice</button>
        )}
        {permissions?.canExport && (
          <button onClick={() => exportInvoices()}>📥 Export</button>
        )}
      </div>

      <table>
        <thead>
          <tr>
            <th>Number</th>
            <th>Amount</th>
            <th>Status</th>
            {permissions?.canUpdate && <th>Actions</th>}
          </tr>
        </thead>
        <tbody>
          {invoices.map(invoice => (
            <tr key={invoice.id}>
              <td>{invoice.number}</td>
              <td>${invoice.amount}</td>
              <td>{invoice.status}</td>
              {permissions?.canUpdate && (
                <td>
                  <button>Edit</button>
                  {permissions?.canDelete && <button>Delete</button>}
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ============================================================================
// EXAMPLE 4: Using RoleBasedRender Component for Cleaner Conditional UI
// ============================================================================

export function DataPanel() {
  return (
    <div className="data-panel">
      <h2>Data Visibility</h2>

      {/* Show employee section only to employees */}
      <RoleBasedRender requiredRoles="employee">
        <section>
          <h3>Your Assigned Tasks</h3>
          <TaskList />
        </section>
      </RoleBasedRender>

      {/* Show owner-only data */}
      <RoleBasedRender 
        requiredRoles="owner"
        fallback={<div>Owner data - not available to you</div>}
      >
        <section>
          <h3>Business Analytics</h3>
          <AnalyticsCharts />
        </section>
      </RoleBasedRender>
    </div>
  );
}

// ============================================================================
// EXAMPLE 5: Using FeatureVisible Component for Feature Gating
// ============================================================================

export function SettingsPage() {
  return (
    <div className="settings">
      <h1>Settings</h1>

      {/* Basic settings - always available */}
      <section>
        <h2>Account Settings</h2>
        <SettingForm fields={['name', 'email', 'phone']} />
      </section>

      {/* Advanced billing - owner only */}
      <FeatureVisible feature="wallet">
        <section>
          <h2>Billing & Wallet</h2>
          <BillingForm />
        </section>
      </FeatureVisible>

      {/* Supplier management - owner only */}
      <FeatureVisible feature="suppliers">
        <section>
          <h2>Supplier Management</h2>
          <SupplierList />
        </section>
      </FeatureVisible>

      {/* Admin settings - owner only */}
      <FeatureVisible feature="admin">
        <section>
          <h2>Administration</h2>
          <AdminPanel />
        </section>
      </FeatureVisible>
    </div>
  );
}

// ============================================================================
// EXAMPLE 6: Using ResponsiveNavigation Component
// ============================================================================

export function AppLayout({ children }) {
  const [activePath, setActivePath] = useState('/dashboard');

  return (
    <div className="app-container">
      {/* Navigation automatically switches between mobile bottom nav and desktop sidebar */}
      <ResponsiveNavigation 
        onNavigate={setActivePath}
        activePath={activePath}
      />

      {/* Main content area */}
      <main className="main-content">
        {children}
      </main>
    </div>
  );
}

// ============================================================================
// EXAMPLE 7: Using useRouteGuard Hook for Route Protection
// ============================================================================

export function AdminPage() {
  const navigate = useNavigate();
  const { canAccess, redirectTo } = useRouteGuard('/admin', 'web');

  if (!canAccess) {
    return (
      <div>
        <p>Access Denied. Redirecting...</p>
        {redirectTo && navigate(redirectTo)}
      </div>
    );
  }

  return (
    <div>
      <h1>Admin Panel</h1>
      <AdminContent />
    </div>
  );
}

// ============================================================================
// EXAMPLE 8: Using useVisibleNavigation Hook for Dynamic Menu
// ============================================================================

export function NavigationMenu() {
  const { features, routes, categories } = useVisibleNavigation('web');

  return (
    <nav className="main-nav">
      {categories?.main?.map(feature => (
        <NavItem 
          key={feature.id}
          label={feature.name}
          icon={feature.icon}
          path={feature.route}
        />
      ))}

      {/* Collapsible advanced section */}
      {categories?.advanced?.length > 0 && (
        <CollapsibleSection title="Advanced">
          {categories.advanced.map(feature => (
            <NavItem 
              key={feature.id}
              label={feature.name}
              icon={feature.icon}
              path={feature.route}
              nested
            />
          ))}
        </CollapsibleSection>
      )}
    </nav>
  );
}

// ============================================================================
// EXAMPLE 9: Using useWatchRole Hook for Real-time Role Updates
// ============================================================================

export function UserRoleMonitor({ userId }) {
  const { role, loading } = useWatchRole(userId);

  return (
    <div className="role-monitor">
      <h3>Current Role</h3>
      {loading ? (
        <p>Watching for changes...</p>
      ) : (
        <p>
          User role: <strong>{role}</strong>
        </p>
      )}
    </div>
  );
}

// ============================================================================
// EXAMPLE 10: Using ProtectedRoute Component for Route Definition
// ============================================================================

// In your main router setup:
export function AppRoutes() {
  return (
    <Routes>
      {/* Public routes */}
      <Route path="/login" element={<LoginPage />} />
      <Route path="/signup" element={<SignupPage />} />

      {/* Employee routes */}
      <Route
        path="/tasks/assigned"
        element={
          <ProtectedRoute
            component={TaskListPage}
            requiredRoles={['owner', 'employee']}
            fallback={<UnauthorizedPage />}
          />
        }
      />

      <Route
        path="/expenses/log"
        element={
          <ProtectedRoute
            component={ExpenseLogPage}
            requiredRoles={['owner', 'employee']}
          />
        }
      />

      {/* Owner-only routes */}
      <Route
        path="/suppliers"
        element={
          <ProtectedRoute
            component={SupplierPage}
            requiredRoles="owner"
          />
        }
      />

      <Route
        path="/admin"
        element={
          <ProtectedRoute
            component={AdminPage}
            requiredRoles="owner"
          />
        }
      />

      {/* Catch-all */}
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}

// ============================================================================
// EXAMPLE 11: Using Permission Matrix for Complex Authorization
// ============================================================================

export function DocumentEditor({ docId }) {
  const { role } = useRole();
  const { permissions } = getFeaturePermissions(role, 'documents');

  const [document, setDocument] = useState(null);
  const [isEditing, setIsEditing] = useState(false);

  const handleSave = async () => {
    if (!permissions?.canUpdate) {
      alert('You do not have permission to edit this document');
      return;
    }
    // Save logic
  };

  const handleDelete = async () => {
    if (!permissions?.canDelete) {
      alert('You do not have permission to delete this document');
      return;
    }
    // Delete logic
  };

  return (
    <div>
      <h2>{document?.title}</h2>
      
      {permissions?.canRead ? (
        <div className="document-view">
          <textarea
            value={document?.content}
            disabled={!permissions?.canUpdate}
            onChange={(e) => setDocument({...document, content: e.target.value})}
          />
        </div>
      ) : (
        <p>You do not have permission to view this document</p>
      )}

      <div className="document-actions">
        {permissions?.canUpdate && (
          <button onClick={handleSave}>Save</button>
        )}
        {permissions?.canShare && (
          <button onClick={() => shareDocument()}>Share</button>
        )}
        {permissions?.canDelete && (
          <button onClick={handleDelete}>Delete</button>
        )}
      </div>
    </div>
  );
}

// ============================================================================
// EXAMPLE 12: Using Role Override for Testing (Development Only)
// ============================================================================

export function RoleTestingPanel() {
  const { role } = useRole();

  if (process.env.REACT_APP_ENV !== 'development') {
    return null;
  }

  return (
    <div className="testing-panel" style={{ border: '1px solid red', padding: '10px' }}>
      <h3>🧪 Role Testing (Development Only)</h3>
      <p>Current role: <strong>{role}</strong></p>
      
      <div className="role-buttons">
        <button onClick={() => overrideRoleForTesting('owner')}>
          Simulate Owner
        </button>
        <button onClick={() => overrideRoleForTesting('employee')}>
          Simulate Employee
        </button>
        <button onClick={() => overrideRoleForTesting(null)}>
          Clear Override
        </button>
      </div>
    </div>
  );
}

// ============================================================================
// EXAMPLE 13: Complete Page with All Features Combined
// ============================================================================

export function CompleteDashboardExample() {
  const { role, loading } = useRole();
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);

  if (loading) {
    return (
      <div className="loading-screen">
        <p>Initializing application...</p>
      </div>
    );
  }

  return (
    <div className="app-layout">
      {/* Top bar with role indicator */}
      <header className="app-header">
        <h1>AuraSphere Pro</h1>
        <div className="user-info">
          <span>{role === 'owner' ? '👑 Owner' : '👤 Employee'}</span>
          <button onClick={() => logout()}>Logout</button>
        </div>
      </header>

      <div className="app-body">
        {/* Responsive navigation */}
        <ResponsiveNavigation 
          onNavigate={(path) => navigate(path)}
          activePath={location.pathname}
        />

        {/* Main content */}
        <main className="main-content">
          <Routes>
            {/* Dashboard */}
            <Route path="/" element={<Dashboard />} />

            {/* Common routes for both roles */}
            <Route 
              path="/tasks/assigned" 
              element={<ProtectedRoute component={TaskList} requiredRoles={['owner', 'employee']} />} 
            />
            <Route 
              path="/expenses/log" 
              element={<ProtectedRoute component={ExpenseLog} requiredRoles={['owner', 'employee']} />} 
            />

            {/* Owner-only routes */}
            <Route 
              path="/suppliers" 
              element={<ProtectedRoute component={Suppliers} requiredRoles="owner" />} 
            />
            <Route 
              path="/admin" 
              element={<ProtectedRoute component={AdminPanel} requiredRoles="owner" />} 
            />
          </Routes>
        </main>
      </div>

      {/* Development tools */}
      {process.env.REACT_APP_ENV === 'development' && <RoleTestingPanel />}
    </div>
  );
}

// ============================================================================
// Helper Components (Implementation Examples)
// ============================================================================

function FeatureCard({ title, icon }) {
  return (
    <div className="feature-card">
      <span className="feature-icon">{icon}</span>
      <h3>{title}</h3>
    </div>
  );
}

function TaskList() {
  // Implementation using useFeatureAccess
  const { canAccess } = useFeatureAccess('tasks');
  if (!canAccess) return <div>Access Denied</div>;
  return <div>Task list content</div>;
}

function AnalyticsCharts() {
  return <div>Analytics charts here</div>;
}

function SettingForm({ fields }) {
  return (
    <form>
      {fields.map(field => (
        <div key={field}>
          <label>{field}</label>
          <input type="text" />
        </div>
      ))}
      <button type="submit">Save</button>
    </form>
  );
}

function BillingForm() {
  return <div>Billing form content</div>;
}

function SupplierList() {
  return <div>Supplier list content</div>;
}

function AdminPanel() {
  return <div>Admin panel content</div>;
}

function AdminContent() {
  return <div>Admin page content</div>;
}

function NavItem({ label, icon, path, nested = false }) {
  return (
    <a href={path} className={nested ? 'nav-item nested' : 'nav-item'}>
      <span className="icon">{icon}</span>
      <span className="label">{label}</span>
    </a>
  );
}

function CollapsibleSection({ title, children }) {
  const [isOpen, setIsOpen] = useState(false);
  return (
    <div className="collapsible">
      <button onClick={() => setIsOpen(!isOpen)}>
        {isOpen ? '▼' : '▶'} {title}
      </button>
      {isOpen && <div className="section-content">{children}</div>}
    </div>
  );
}

function LoginPage() {
  return <div>Login page</div>;
}

function SignupPage() {
  return <div>Signup page</div>;
}

function UnauthorizedPage() {
  return <div>Access Denied - You don't have permission to view this page</div>;
}

function NotFoundPage() {
  return <div>404 - Page not found</div>;
}

function TaskListPage() {
  return <div>Task list page</div>;
}

function ExpenseLogPage() {
  return <div>Expense log page</div>;
}

function SupplierPage() {
  return <div>Suppliers page</div>;
}

function AdminPage() {
  return <div>Admin page</div>;
}
