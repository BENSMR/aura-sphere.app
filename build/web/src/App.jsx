/**
 * Web Application Setup Example
 * 
 * Shows how to integrate role-based access control in a React app
 */

import React, { useEffect, useState } from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";

// Role and Auth utilities
import { initializeRoleCache } from "./auth/roleGuard";
import { useRole } from "./hooks/useRole";

// Navigation
import { ResponsiveNavigation } from "./components/Navigation";
import { ProtectedRoute } from "./components/ProtectedRoute";

// Pages (examples - create these based on your needs)
import LoginPage from "./pages/LoginPage";
import DashboardPage from "./pages/DashboardPage";
import TasksPage from "./pages/TasksPage";
import ExpensesPage from "./pages/ExpensesPage";
import ClientsPage from "./pages/ClientsPage";
import JobsPage from "./pages/JobsPage";
import ProfilePage from "./pages/ProfilePage";

// Firebase initialization
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

/**
 * Initialize Firebase
 * Replace with your Firebase config
 */
const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY,
  authDomain: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID,
  storageBucket: process.env.REACT_APP_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.REACT_APP_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.REACT_APP_FIREBASE_APP_ID,
};

initializeApp(firebaseConfig);
getAuth();
getFirestore();

/**
 * Main App Component
 */
function App() {
  const { role, loading } = useRole();
  const [currentPath, setCurrentPath] = useState("/dashboard");

  useEffect(() => {
    // Initialize role cache on app startup
    initializeRoleCache();
  }, []);

  if (loading) {
    return (
      <div className="app-loading">
        <h1>Loading...</h1>
      </div>
    );
  }

  if (!role) {
    return (
      <Router>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </Router>
    );
  }

  // User is authenticated
  return (
    <Router>
      <div className="app-layout">
        <ResponsiveNavigation
          onNavigate={(path) => {
            setCurrentPath(path);
            // Handle navigation based on path
          }}
          activePath={currentPath}
        />

        <main className="app-content">
          <Routes>
            {/* Public routes (authenticated users) */}
            <Route path="/dashboard" element={<DashboardPage userRole={role} />} />
            <Route path="/profile" element={<ProfilePage userRole={role} />} />

            {/* Employee routes */}
            <Route
              path="/tasks/assigned"
              element={
                <ProtectedRoute
                  component={TasksPage}
                  requiredRoles={["owner", "employee"]}
                />
              }
            />
            <Route
              path="/expenses/log"
              element={
                <ProtectedRoute
                  component={ExpensesPage}
                  requiredRoles={["owner", "employee"]}
                />
              }
            />
            <Route
              path="/clients/view/:id"
              element={
                <ProtectedRoute
                  component={ClientsPage}
                  requiredRoles={["owner", "employee"]}
                />
              }
            />
            <Route
              path="/jobs/complete/:id"
              element={
                <ProtectedRoute
                  component={JobsPage}
                  requiredRoles={["owner", "employee"]}
                />
              }
            />

            {/* Owner-only routes */}
            <Route
              path="/invoices"
              element={
                <ProtectedRoute
                  component={() => <div>Invoices (Owner)</div>}
                  requiredRoles="owner"
                />
              }
            />
            <Route
              path="/suppliers"
              element={
                <ProtectedRoute
                  component={() => <div>Suppliers (Owner)</div>}
                  requiredRoles="owner"
                />
              }
            />
            <Route
              path="/purchase-orders"
              element={
                <ProtectedRoute
                  component={() => <div>Purchase Orders (Owner)</div>}
                  requiredRoles="owner"
                />
              }
            />
            <Route
              path="/inventory"
              element={
                <ProtectedRoute
                  component={() => <div>Inventory (Owner)</div>}
                  requiredRoles="owner"
                />
              }
            />
            <Route
              path="/finance"
              element={
                <ProtectedRoute
                  component={() => <div>Finance Dashboard (Owner)</div>}
                  requiredRoles="owner"
                />
              }
            />
            <Route
              path="/loyalty"
              element={
                <ProtectedRoute
                  component={() => <div>Loyalty Campaigns (Owner)</div>}
                  requiredRoles="owner"
                />
              }
            />
            <Route
              path="/wallet"
              element={
                <ProtectedRoute
                  component={() => <div>Wallet & Billing (Owner)</div>}
                  requiredRoles="owner"
                />
              }
            />
            <Route
              path="/anomalies"
              element={
                <ProtectedRoute
                  component={() => <div>Anomaly Detection (Owner)</div>}
                  requiredRoles="owner"
                />
              }
            />
            <Route
              path="/admin"
              element={
                <ProtectedRoute
                  component={() => <div>Admin Panel (Owner)</div>}
                  requiredRoles="owner"
                />
              }
            />
            <Route
              path="/crm"
              element={
                <ProtectedRoute
                  component={() => <div>CRM (Owner)</div>}
                  requiredRoles="owner"
                />
              }
            />

            {/* Catch-all */}
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
