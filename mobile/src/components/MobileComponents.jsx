/**
 * MOBILE EMPLOYEE APP - REACT COMPONENTS
 *
 * 7 mobile-optimized components for employee workflow
 * Touch-friendly, fast-loading, battery-efficient
 *
 * @module MobileComponents
 */

import React, { useState, useEffect } from "react";
import {
  MOBILE_SCREENS,
  SCREEN_CONFIG,
  truncateForMobile,
  formatMobileDate,
  vibrateDevice,
  getSafeAreaInsets
} from "./mobileConfig";

// ─────────────────────────────────────────────────────────────────────────
// 1. TASK CARD COMPONENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Task card for quick task overview
 * Shows: title, due date, priority, assigned to, completion button
 */
export function TaskCard({ task, onComplete, onView }) {
  const [isCompleting, setIsCompleting] = useState(false);

  const handleComplete = async () => {
    setIsCompleting(true);
    vibrateDevice(100);
    await onComplete?.(task.id);
    setIsCompleting(false);
  };

  const priorityColor = {
    high: "#ef4444",
    medium: "#f59e0b",
    low: "#10b981"
  }[task.priority] || "#6b7280";

  return (
    <div
      className="task-card"
      onClick={() => onView?.(task.id)}
      style={{ borderLeftColor: priorityColor }}
    >
      <div className="task-card-header">
        <h3 className="task-title">{truncateForMobile(task.title, 40)}</h3>
        <span className="task-priority" style={{ backgroundColor: priorityColor }}>
          {task.priority[0].toUpperCase()}
        </span>
      </div>

      <p className="task-description">{truncateForMobile(task.description, 60)}</p>

      <div className="task-meta">
        <span className="task-due">
          📅 {formatMobileDate(new Date(task.dueDate))}
        </span>
        <span className="task-assigned">👤 {task.assignedTo}</span>
      </div>

      <button
        className="btn-complete"
        onClick={(e) => {
          e.stopPropagation();
          handleComplete();
        }}
        disabled={isCompleting}
      >
        {isCompleting ? "Completing..." : "✓ Complete"}
      </button>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 2. EXPENSE FORM COMPONENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Quick expense logging form
 * Captures: amount, category, receipt, description
 * Optimized for mobile data entry
 */
export function ExpenseForm({ userId, onSubmit, onCancel }) {
  const [formData, setFormData] = useState({
    amount: "",
    category: "other",
    description: "",
    receipt: null
  });
  const [submitting, setSubmitting] = useState(false);

  const categories = ["meals", "transportation", "supplies", "other"];

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);

    const expense = {
      ...formData,
      userId,
      date: new Date(),
      status: "pending"
    };

    await onSubmit?.(expense);
    setSubmitting(false);
  };

  return (
    <form className="expense-form" onSubmit={handleSubmit}>
      <div className="form-group">
        <label>Amount ($)</label>
        <input
          type="number"
          placeholder="0.00"
          step="0.01"
          value={formData.amount}
          onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
          required
        />
      </div>

      <div className="form-group">
        <label>Category</label>
        <select
          value={formData.category}
          onChange={(e) => setFormData({ ...formData, category: e.target.value })}
        >
          {categories.map((cat) => (
            <option key={cat} value={cat}>
              {cat.charAt(0).toUpperCase() + cat.slice(1)}
            </option>
          ))}
        </select>
      </div>

      <div className="form-group">
        <label>Receipt (Photo)</label>
        <input
          type="file"
          accept="image/*"
          capture="environment"
          onChange={(e) => setFormData({ ...formData, receipt: e.target.files[0] })}
        />
      </div>

      <div className="form-group">
        <label>Notes</label>
        <textarea
          placeholder="What was this for?"
          value={formData.description}
          onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          rows="3"
        />
      </div>

      <div className="form-buttons">
        <button type="submit" disabled={submitting} className="btn-primary">
          {submitting ? "Saving..." : "Save Expense"}
        </button>
        <button type="button" onClick={onCancel} className="btn-secondary">
          Cancel
        </button>
      </div>
    </form>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 3. CLIENT DETAIL COMPONENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Client profile card with contact info
 * Shows: name, contact, email, phone, recent activity
 * One-tap call/email actions
 */
export function ClientDetail({ client, onContact, onClose }) {
  return (
    <div className="client-detail-panel">
      <div className="panel-header">
        <button className="btn-close" onClick={onClose}>
          ✕
        </button>
        <h2>{client.name}</h2>
      </div>

      <div className="client-info">
        <div className="info-section">
          <label>📧 Email</label>
          <p>{client.email}</p>
          <button
            className="btn-action"
            onClick={() => onContact?.("email", client.email)}
          >
            Send Email
          </button>
        </div>

        <div className="info-section">
          <label>📱 Phone</label>
          <p>{client.phone}</p>
          <button
            className="btn-action"
            onClick={() => onContact?.("phone", client.phone)}
          >
            Call
          </button>
        </div>

        <div className="info-section">
          <label>📍 Location</label>
          <p>{client.address}</p>
        </div>

        <div className="info-section">
          <label>💰 Status</label>
          <p className="status-badge">{client.paymentStatus}</p>
        </div>

        <div className="info-section">
          <label>📋 Recent Activity</label>
          <ul className="activity-list">
            {client.recentActivity?.slice(0, 3).map((activity, idx) => (
              <li key={idx}>{activity.action} — {formatMobileDate(new Date(activity.date))}</li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 4. JOB COMPLETION COMPONENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Job completion workflow
 * Steps: verify, photo/notes, signature, submit
 * For on-site technicians/workers
 */
export function JobCompletion({ job, onSubmit, onCancel }) {
  const [step, setStep] = useState(1);
  const [completionData, setCompletionData] = useState({
    notes: "",
    photos: [],
    signature: null,
    issues: []
  });

  const handleSubmit = async () => {
    const submission = {
      jobId: job.id,
      completedAt: new Date(),
      ...completionData
    };
    await onSubmit?.(submission);
  };

  return (
    <div className="job-completion-form">
      <div className="progress-bar" style={{ width: `${(step / 3) * 100}%` }} />

      {step === 1 && (
        <div className="step-content">
          <h3>✓ Verify Work</h3>
          <p>Has the work been completed as specified?</p>
          <div className="checklist">
            {job.requirements?.map((req, idx) => (
              <label key={idx} className="checkbox-item">
                <input type="checkbox" defaultChecked />
                <span>{req}</span>
              </label>
            ))}
          </div>
          <button className="btn-next" onClick={() => setStep(2)}>
            Continue →
          </button>
        </div>
      )}

      {step === 2 && (
        <div className="step-content">
          <h3>📸 Add Photos</h3>
          <input
            type="file"
            accept="image/*"
            capture="environment"
            multiple
            onChange={(e) =>
              setCompletionData({
                ...completionData,
                photos: Array.from(e.target.files)
              })
            }
          />
          <textarea
            placeholder="Any notes about the work?"
            value={completionData.notes}
            onChange={(e) =>
              setCompletionData({ ...completionData, notes: e.target.value })
            }
            rows="4"
          />
          <button className="btn-next" onClick={() => setStep(3)}>
            Continue →
          </button>
        </div>
      )}

      {step === 3 && (
        <div className="step-content">
          <h3>✍️ Sign Off</h3>
          <p>Confirm completion by signing below</p>
          <div className="signature-box">
            {/* In production, use signature pad library */}
            <p>(Signature pad would go here)</p>
          </div>
          <div className="form-buttons">
            <button className="btn-primary" onClick={handleSubmit}>
              Complete Job
            </button>
            <button className="btn-secondary" onClick={onCancel}>
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 5. PROFILE CARD COMPONENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Employee profile and settings
 * Shows: avatar, name, role, contact info, quick settings
 */
export function ProfileCard({ user, onEdit, onLogout }) {
  return (
    <div className="profile-card">
      <div className="profile-header">
        <img src={user.avatar} alt={user.name} className="profile-avatar" />
        <div className="profile-info">
          <h2>{user.name}</h2>
          <p className="profile-role">{user.role}</p>
        </div>
      </div>

      <div className="profile-details">
        <div className="detail-item">
          <span className="label">Email</span>
          <span className="value">{user.email}</span>
        </div>
        <div className="detail-item">
          <span className="label">Phone</span>
          <span className="value">{user.phone}</span>
        </div>
        <div className="detail-item">
          <span className="label">Team</span>
          <span className="value">{user.team}</span>
        </div>
      </div>

      <div className="profile-actions">
        <button className="btn-action-full" onClick={onEdit}>
          ✎ Edit Profile
        </button>
        <button className="btn-action-full secondary" onClick={onLogout}>
          🚪 Log Out
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 6. NAVIGATION BAR COMPONENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Bottom navigation bar
 * Role-specific tabs, active indicator, vibration feedback
 */
export function NavigationBar({ tabs, activeIndex, onTabChange }) {
  const insets = getSafeAreaInsets();

  return (
    <nav className="nav-bar" style={{ paddingBottom: insets.bottom + "px" }}>
      <div className="nav-tabs">
        {tabs.map((tab, idx) => (
          <button
            key={tab.id}
            className={`nav-tab ${idx === activeIndex ? "active" : ""}`}
            onClick={() => {
              vibrateDevice(50);
              onTabChange(idx);
            }}
          >
            <span className="nav-icon">{tab.icon}</span>
            <span className="nav-label">{truncateForMobile(tab.label, 12)}</span>
          </button>
        ))}
      </div>
    </nav>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 7. EMPTY STATE COMPONENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Empty state placeholder
 * Shows when no data is available
 * Encourages action with CTA button
 */
export function EmptyState({ icon, title, message, ctaLabel, onCTA }) {
  return (
    <div className="empty-state">
      <div className="empty-icon">{icon}</div>
      <h3>{title}</h3>
      <p>{message}</p>
      {ctaLabel && (
        <button className="btn-primary" onClick={onCTA}>
          {ctaLabel}
        </button>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// MOBILE CSS STYLES
// ─────────────────────────────────────────────────────────────────────────

export const MOBILE_STYLES = `
/* Safe Area & Viewport */
html, body {
  --safe-area-inset-top: max(0px, env(safe-area-inset-top));
  --safe-area-inset-right: max(0px, env(safe-area-inset-right));
  --safe-area-inset-bottom: max(0px, env(safe-area-inset-bottom));
  --safe-area-inset-left: max(0px, env(safe-area-inset-left));
  width: 100%;
  height: 100%;
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  -webkit-user-select: none;
  -webkit-touch-callout: none;
}

body {
  background: #f9fafb;
  color: #1f2937;
  padding-top: var(--safe-area-inset-top);
  padding-bottom: var(--safe-area-inset-bottom);
}

/* Task Card */
.task-card {
  background: white;
  border-radius: 12px;
  border-left: 4px solid;
  padding: 16px;
  margin-bottom: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.task-card:active {
  background: #f3f4f6;
  transform: scale(0.98);
}

.task-card-header {
  display: flex;
  justify-content: space-between;
  align-items: start;
  margin-bottom: 8px;
}

.task-title {
  font-size: 16px;
  font-weight: 600;
  margin: 0;
  flex: 1;
}

.task-priority {
  color: white;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 700;
  margin-left: 8px;
}

.task-description {
  font-size: 13px;
  color: #6b7280;
  margin: 8px 0;
}

.task-meta {
  display: flex;
  gap: 12px;
  font-size: 12px;
  color: #6b7280;
  margin-bottom: 12px;
}

.btn-complete {
  width: 100%;
  padding: 10px;
  background: #10b981;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-complete:active {
  background: #059669;
}

/* Expense Form */
.expense-form {
  padding: 16px;
  background: white;
  border-radius: 12px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  font-weight: 600;
  font-size: 14px;
  margin-bottom: 8px;
  color: #1f2937;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 16px;
  font-family: inherit;
}

.form-group textarea {
  resize: vertical;
}

.form-buttons {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

/* Client Detail Panel */
.client-detail-panel {
  position: fixed;
  inset: 0;
  background: white;
  z-index: 1000;
  overflow-y: auto;
  padding-top: 60px;
}

.panel-header {
  position: sticky;
  top: 0;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: white;
  border-bottom: 1px solid #e5e7eb;
}

.btn-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #6b7280;
}

.client-info {
  padding: 16px;
}

.info-section {
  margin-bottom: 24px;
}

.info-section label {
  display: block;
  font-weight: 600;
  font-size: 12px;
  color: #6b7280;
  text-transform: uppercase;
  margin-bottom: 4px;
}

.info-section p {
  font-size: 14px;
  margin: 4px 0 8px 0;
  word-break: break-word;
}

.btn-action {
  width: 100%;
  padding: 10px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  margin-top: 8px;
}

/* Job Completion */
.job-completion-form {
  padding: 16px;
  background: white;
}

.progress-bar {
  height: 4px;
  background: #667eea;
  border-radius: 2px;
  margin-bottom: 24px;
  transition: width 0.3s;
}

.step-content h3 {
  font-size: 18px;
  margin: 0 0 8px 0;
}

.step-content p {
  color: #6b7280;
  margin-bottom: 16px;
}

.checklist {
  margin-bottom: 20px;
}

.checkbox-item {
  display: flex;
  align-items: center;
  padding: 12px;
  background: #f9fafb;
  border-radius: 8px;
  margin-bottom: 8px;
  cursor: pointer;
}

.checkbox-item input {
  margin-right: 12px;
  cursor: pointer;
}

.signature-box {
  border: 2px dashed #e5e7eb;
  border-radius: 8px;
  height: 150px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f9fafb;
  margin: 16px 0;
}

/* Profile Card */
.profile-card {
  padding: 16px;
  background: white;
  border-radius: 12px;
}

.profile-header {
  display: flex;
  gap: 16px;
  margin-bottom: 24px;
}

.profile-avatar {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: #e5e7eb;
}

.profile-info h2 {
  margin: 0 0 4px 0;
  font-size: 18px;
}

.profile-role {
  margin: 0;
  color: #6b7280;
  font-size: 14px;
}

.profile-details {
  margin-bottom: 20px;
  padding-bottom: 20px;
  border-bottom: 1px solid #e5e7eb;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  padding: 12px 0;
  font-size: 14px;
}

.detail-item .label {
  color: #6b7280;
}

.btn-action-full {
  width: 100%;
  padding: 12px;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  margin-bottom: 8px;
}

.btn-action-full {
  background: #667eea;
  color: white;
}

.btn-action-full.secondary {
  background: #e5e7eb;
  color: #1f2937;
}

/* Navigation Bar */
.nav-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: white;
  border-top: 1px solid #e5e7eb;
  z-index: 100;
  padding-top: var(--safe-area-inset-bottom);
}

.nav-tabs {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 8px;
  padding: 8px;
}

.nav-tab {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  background: none;
  border: none;
  cursor: pointer;
  color: #6b7280;
  padding: 8px 4px;
  border-radius: 8px;
  transition: all 0.2s;
}

.nav-tab.active {
  color: #667eea;
  background: #f0f4ff;
}

.nav-icon {
  font-size: 20px;
}

.nav-label {
  font-size: 10px;
  font-weight: 500;
  text-transform: capitalize;
}

/* Empty State */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
  text-align: center;
}

.empty-icon {
  font-size: 64px;
  margin-bottom: 16px;
  opacity: 0.5;
}

.empty-state h3 {
  font-size: 18px;
  margin: 0 0 8px 0;
}

.empty-state p {
  color: #6b7280;
  margin-bottom: 24px;
}

/* Buttons */
.btn-primary,
.btn-secondary,
.btn-next {
  padding: 12px 20px;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary {
  background: #667eea;
  color: white;
}

.btn-primary:active {
  background: #5568d3;
}

.btn-secondary {
  background: #e5e7eb;
  color: #1f2937;
}

.btn-next {
  width: 100%;
  background: #667eea;
  color: white;
  margin-top: 20px;
}

/* Responsive */
@media (max-width: 480px) {
  body {
    font-size: 14px;
  }
  
  .nav-tabs {
    grid-template-columns: repeat(4, 1fr);
  }
}

/* Dark Mode Support */
@media (prefers-color-scheme: dark) {
  html, body {
    background: #111827;
    color: #f3f4f6;
  }
  
  .task-card,
  .expense-form,
  .profile-card {
    background: #1f2937;
  }
  
  .form-group input,
  .form-group select,
  .form-group textarea {
    background: #111827;
    border-color: #374151;
    color: #f3f4f6;
  }
  
  .nav-bar {
    background: #1f2937;
    border-top-color: #374151;
  }
}

/* Accessibility */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
`;

export default {
  TaskCard,
  ExpenseForm,
  ClientDetail,
  JobCompletion,
  ProfileCard,
  NavigationBar,
  EmptyState,
  MOBILE_STYLES
};
