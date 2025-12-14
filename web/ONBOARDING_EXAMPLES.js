/**
 * Onboarding Flow Examples
 * 10 complete, production-ready implementation examples
 * 
 * @file
 */

// =============================================================================
// EXAMPLE 1: Basic Employee Onboarding Integration
// =============================================================================

// In your auth/signup.js or auth callback
import { handleEmployeeOnboarding } from '../onboarding/employeeFlow';
import { useAuth } from '../hooks/useAuth';

function SignupCallback() {
  const { user } = useAuth();

  useEffect(() => {
    const completeOnboarding = async () => {
      if (user && user.role === 'employee') {
        try {
          await handleEmployeeOnboarding(user, {
            showTooltip: true,
            redirectPath: "/tasks/assigned",
            redirectDelay: 500
          });
        } catch (error) {
          console.error('Onboarding failed:', error);
          // Fallback: Navigate manually
          window.location.href = "/tasks/assigned";
        }
      }
    };

    completeOnboarding();
  }, [user]);

  return <LoadingSpinner />;
}

// =============================================================================
// EXAMPLE 2: Employee Onboarding with Custom Welcome Modal
// =============================================================================

import React, { useState, useEffect } from 'react';
import { handleEmployeeOnboarding } from '../onboarding/employeeFlow';

function EmployeeWelcomeModal({ user, onComplete }) {
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState(null);

  const handleGetStarted = async () => {
    setIsProcessing(true);
    setError(null);

    try {
      await handleEmployeeOnboarding(user, {
        showTooltip: true,
        redirectPath: "/tasks/assigned",
        redirectDelay: 1000
      });
      
      if (onComplete) onComplete();
    } catch (err) {
      setError(err.message);
      setIsProcessing(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <div className="modal-header">
          <h2>Welcome to AuraSphere Pro! 👋</h2>
          <p>You've been added as a team member</p>
        </div>

        <div className="modal-body">
          <div className="welcome-features">
            <div className="feature">
              <span className="icon">✓</span>
              <h4>View Your Tasks</h4>
              <p>See all tasks assigned to you</p>
            </div>

            <div className="feature">
              <span className="icon">✓</span>
              <h4>Collaborate with Your Team</h4>
              <p>Work together on projects</p>
            </div>

            <div className="feature">
              <span className="icon">✓</span>
              <h4>Track Your Time</h4>
              <p>Log hours and track progress</p>
            </div>
          </div>

          {error && (
            <div className="error-message">
              {error}
            </div>
          )}
        </div>

        <div className="modal-footer">
          <button
            className="btn btn-primary"
            onClick={handleGetStarted}
            disabled={isProcessing}
          >
            {isProcessing ? 'Setting up your account...' : 'Get Started'}
          </button>
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// EXAMPLE 3: Owner Onboarding Step Tracker
// =============================================================================

import {
  OWNER_ONBOARDING_STEPS,
  getOwnerOnboardingProgress,
  completeOwnerOnboardingStep,
  getEstimatedTimeRemaining
} from '../onboarding/ownerFlow';
import { OwnerOnboardingStep } from '../components/OnboardingComponents';

function OwnerOnboardingPage({ user }) {
  const [progress, setProgress] = useState(getOwnerOnboardingProgress());
  const [isUpdating, setIsUpdating] = useState(false);

  const handleStepComplete = async (stepId) => {
    setIsUpdating(true);
    
    try {
      await completeOwnerOnboardingStep(user, stepId);
      
      // Refresh progress
      const newProgress = getOwnerOnboardingProgress();
      setProgress(newProgress);
    } catch (error) {
      console.error('Error completing step:', error);
    } finally {
      setIsUpdating(false);
    }
  };

  const timeRemaining = getEstimatedTimeRemaining(progress.completedSteps);
  const progressPercent = progress.progressPercentage || 0;

  return (
    <div className="owner-onboarding-page">
      <div className="onboarding-container">
        <div className="onboarding-header">
          <h1>Complete Your Setup</h1>
          <p>Let's get your business ready in {timeRemaining} minutes</p>
        </div>

        {/* Progress Bar */}
        <div className="progress-section">
          <div className="progress-header">
            <span>Setup Progress</span>
            <span className="percentage">{progressPercent}%</span>
          </div>
          
          <div className="progress-bar-container">
            <div
              className="progress-bar"
              style={{ width: `${progressPercent}%` }}
            />
          </div>

          <div className="progress-details">
            <p>{progress.completedSteps.length} of {OWNER_ONBOARDING_STEPS.length} steps completed</p>
            <p className="time-remaining">~{timeRemaining} minutes remaining</p>
          </div>
        </div>

        {/* Steps */}
        <div className="steps-container">
          {OWNER_ONBOARDING_STEPS.map((step) => (
            <OwnerOnboardingStep
              key={step.id}
              step={step}
              isActive={step.id === progress.currentStep}
              isCompleted={progress.completedSteps.includes(step.id)}
              onComplete={() => handleStepComplete(step.id)}
            />
          ))}
        </div>

        {/* Skip Button */}
        <div className="skip-section">
          <button
            className="btn btn-ghost"
            onClick={() => window.location.href = '/dashboard'}
            disabled={isUpdating}
          >
            Skip for now
          </button>
          <p className="skip-text">You can complete these steps later from Settings</p>
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// EXAMPLE 4: Protected Routes with OnboardingGuard
// =============================================================================

import { OnboardingGuard } from '../components/OnboardingComponents';
import Dashboard from '../pages/Dashboard';
import TasksDashboard from '../pages/TasksDashboard';
import InvoicesPage from '../pages/InvoicesPage';

function ProtectedRoutes() {
  return (
    <Routes>
      {/* Protect all main routes with onboarding check */}
      
      <Route
        path="/dashboard"
        element={
          <OnboardingGuard>
            <Dashboard />
          </OnboardingGuard>
        }
      />

      <Route
        path="/tasks/*"
        element={
          <OnboardingGuard allowedRoles={["employee"]}>
            <TasksDashboard />
          </OnboardingGuard>
        }
      />

      <Route
        path="/invoices/*"
        element={
          <OnboardingGuard allowedRoles={["owner"]}>
            <InvoicesPage />
          </OnboardingGuard>
        }
      />

      {/* Onboarding routes - not protected */}
      <Route path="/onboarding/employee" element={<EmployeeOnboarding />} />
      <Route path="/onboarding/owner" element={<OwnerOnboarding />} />
    </Routes>
  );
}

// =============================================================================
// EXAMPLE 5: Checking Onboarding Status Before Navigation
// =============================================================================

import {
  isEmployeeOnboarded,
  getEmployeeOnboardingStatus,
  shouldShowEmployeeOnboarding
} from '../onboarding/employeeFlow';
import { getOwnerOnboardingStatus } from '../onboarding/ownerFlow';
import { useRole } from '../hooks/useRole';

function AuthenticatedApp() {
  const { user } = useAuth();
  const { role } = useRole();
  const [onboardingStatus, setOnboardingStatus] = useState(null);

  useEffect(() => {
    const checkStatus = async () => {
      if (!user) return;

      if (role === 'employee') {
        const status = await getEmployeeOnboardingStatus(user);
        setOnboardingStatus(status);
      } else if (role === 'owner') {
        const status = getOwnerOnboardingStatus();
        setOnboardingStatus(status);
      }
    };

    checkStatus();
  }, [user, role]);

  const handleNavigate = (path) => {
    // Check onboarding status before allowing navigation
    if (role === 'employee' && !onboardingStatus?.completed) {
      window.location.href = '/onboarding/employee';
      return;
    }

    if (role === 'owner' && !onboardingStatus?.completed) {
      window.location.href = '/onboarding/owner';
      return;
    }

    window.location.href = path;
  };

  if (!onboardingStatus) {
    return <LoadingSpinner />;
  }

  return (
    <div className="app">
      <Navigation onNavigate={handleNavigate} />
      <MainContent />
    </div>
  );
}

// =============================================================================
// EXAMPLE 6: Smart Tooltips on Employee First Visit
// =============================================================================

import {
  getOnboardingTooltipStatus,
  setOnboardingTooltip
} from '../onboarding/employeeFlow';

function TasksDashboard({ user }) {
  const [showTips, setShowTips] = useState(false);
  const tooltipStatus = getOnboardingTooltipStatus('employee_welcome');

  useEffect(() => {
    // Show tips only if just onboarded and hasn't dismissed
    if (tooltipStatus === 'shown') {
      const timer = setTimeout(() => {
        setShowTips(true);
      }, 1000); // Show after 1 second

      return () => clearTimeout(timer);
    }
  }, [tooltipStatus]);

  const dismissTip = () => {
    setShowTips(false);
    setOnboardingTooltip('employee_welcome', 'dismissed');
  };

  return (
    <div className="tasks-dashboard">
      {showTips && (
        <div className="welcome-tips">
          <div className="tip-card">
            <h4>🎯 Pro Tip</h4>
            <p>Click on any task to view details and update its status</p>
            <button onClick={dismissTip}>Got it</button>
          </div>

          <div className="tip-card">
            <h4>📝 Pro Tip</h4>
            <p>Use filters to show only tasks assigned to you</p>
            <button onClick={dismissTip}>Got it</button>
          </div>
        </div>
      )}

      <TasksList user={user} />
    </div>
  );
}

// =============================================================================
// EXAMPLE 7: Owner Setup with Progress Persistence
// =============================================================================

import {
  completeOwnerOnboardingStep,
  skipOwnerOnboarding,
  completeOwnerOnboarding,
  getOwnerOnboardingProgress
} from '../onboarding/ownerFlow';

function ProfileSetupPage({ user }) {
  const [formData, setFormData] = useState({
    businessName: '',
    businessLogo: null,
    businessPhone: '',
    businessEmail: '',
    businessAddress: ''
  });

  const [isSaving, setIsSaving] = useState(false);
  const [successMessage, setSuccessMessage] = useState('');

  const handleSave = async (e) => {
    e.preventDefault();
    setIsSaving(true);

    try {
      // Save profile to Firestore
      await updateUserProfile(user.uid, {
        businessName: formData.businessName,
        businessPhone: formData.businessPhone,
        businessEmail: formData.businessEmail,
        businessAddress: formData.businessAddress
      });

      // Handle logo upload if provided
      if (formData.businessLogo) {
        await uploadBusinessLogo(user.uid, formData.businessLogo);
      }

      // Mark setup step as complete
      await completeOwnerOnboardingStep(user, 'setup_profile');

      setSuccessMessage('✓ Profile saved! Moving to next step...');

      // Redirect to next step after delay
      setTimeout(() => {
        const progress = getOwnerOnboardingProgress();
        const nextStep = progress.currentStep;

        if (nextStep) {
          const stepRoute = `/onboarding/step/${nextStep}`;
          window.location.href = stepRoute;
        } else {
          // All done!
          window.location.href = '/dashboard';
        }
      }, 1500);

    } catch (error) {
      console.error('Error saving profile:', error);
      alert('Failed to save profile: ' + error.message);
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="profile-setup">
      <div className="setup-card">
        <h2>Setup Your Business Profile</h2>
        <p className="subtitle">This helps us personalize your experience</p>

        {successMessage && (
          <div className="success-message">{successMessage}</div>
        )}

        <form onSubmit={handleSave}>
          <div className="form-group">
            <label>Business Name *</label>
            <input
              type="text"
              required
              value={formData.businessName}
              onChange={(e) =>
                setFormData({ ...formData, businessName: e.target.value })
              }
              placeholder="Your business name"
            />
          </div>

          <div className="form-group">
            <label>Business Logo</label>
            <input
              type="file"
              accept="image/*"
              onChange={(e) =>
                setFormData({ ...formData, businessLogo: e.target.files[0] })
              }
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Phone</label>
              <input
                type="tel"
                value={formData.businessPhone}
                onChange={(e) =>
                  setFormData({ ...formData, businessPhone: e.target.value })
                }
                placeholder="+1 (555) 000-0000"
              />
            </div>

            <div className="form-group">
              <label>Email</label>
              <input
                type="email"
                value={formData.businessEmail}
                onChange={(e) =>
                  setFormData({ ...formData, businessEmail: e.target.value })
                }
                placeholder="business@example.com"
              />
            </div>
          </div>

          <div className="form-group">
            <label>Address</label>
            <input
              type="text"
              value={formData.businessAddress}
              onChange={(e) =>
                setFormData({ ...formData, businessAddress: e.target.value })
              }
              placeholder="123 Main St, City, State 12345"
            />
          </div>

          <div className="form-actions">
            <button
              type="submit"
              className="btn btn-primary"
              disabled={isSaving}
            >
              {isSaving ? 'Saving...' : 'Save & Continue'}
            </button>

            <button
              type="button"
              className="btn btn-secondary"
              onClick={() => skipOwnerOnboarding(user)}
            >
              Skip for now
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// =============================================================================
// EXAMPLE 8: Team Member Invitation with Onboarding Trigger
// =============================================================================

import { handleEmployeeOnboarding } from '../onboarding/employeeFlow';
import { sendInvitationEmail } from '../services/emailService';

async function inviteTeamMember(email, role, ownerUser) {
  try {
    // 1. Create user account
    const newUser = await createUserAccount({
      email,
      role: 'employee',
      status: 'invited'
    });

    // 2. Send invitation email
    await sendInvitationEmail({
      email,
      joinLink: `https://app.aurasphere.com/auth/accept-invite?code=${newUser.uid}`,
      invitedBy: ownerUser.businessName
    });

    // 3. When user accepts invite and completes auth, trigger onboarding
    // This happens in your auth callback
    if (newUser.isFirstLogin) {
      await handleEmployeeOnboarding(newUser, {
        showTooltip: true,
        redirectPath: '/tasks/assigned'
      });
    }

    return newUser;
  } catch (error) {
    console.error('Error inviting team member:', error);
    throw error;
  }
}

// =============================================================================
// EXAMPLE 9: Onboarding Analytics & Metrics
// =============================================================================

import {
  logOnboardingEvent,
  getEmployeeOnboardingStatus
} from '../onboarding/employeeFlow';
import {
  getOwnerOnboardingProgress,
  OWNER_ONBOARDING_STEPS
} from '../onboarding/ownerFlow';

function useOnboardingMetrics(user) {
  const trackEvent = (eventName, metadata = {}) => {
    logOnboardingEvent(user?.uid, eventName, {
      ...metadata,
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent
    });
  };

  // Track key events
  const trackEmployeeOnboardingStarted = () => {
    trackEvent('employee_onboarding_started', {
      route: window.location.pathname
    });
  };

  const trackOwnerStepCompleted = (stepId) => {
    const progress = getOwnerOnboardingProgress();
    trackEvent('owner_step_completed', {
      stepId,
      completedSteps: progress.completedSteps.length,
      totalSteps: OWNER_ONBOARDING_STEPS.length,
      progressPercent: progress.progressPercentage
    });
  };

  const trackOnboardingAbandoned = (stepId) => {
    trackEvent('onboarding_abandoned', {
      lastStep: stepId,
      source: document.referrer
    });
  };

  return {
    trackEmployeeOnboardingStarted,
    trackOwnerStepCompleted,
    trackOnboardingAbandoned,
    trackEvent
  };
}

// =============================================================================
// EXAMPLE 10: Mobile-Responsive Onboarding
// =============================================================================

import { useMediaQuery } from '../hooks/useMediaQuery';

function ResponsiveOnboarding({ user, role }) {
  const isMobile = useMediaQuery('(max-width: 768px)');

  if (isMobile) {
    return (
      <div className="onboarding-mobile">
        <div className="mobile-container">
          {role === 'employee' ? (
            <MobileEmployeeOnboarding user={user} />
          ) : (
            <MobileOwnerOnboarding user={user} />
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="onboarding-desktop">
      {role === 'employee' ? (
        <DesktopEmployeeOnboarding user={user} />
      ) : (
        <DesktopOwnerOnboarding user={user} />
      )}
    </div>
  );
}

function MobileEmployeeOnboarding({ user }) {
  return (
    <div className="mobile-onboarding-screen">
      <div className="mobile-header">
        <h1>Welcome! 👋</h1>
      </div>

      <div className="mobile-content">
        <div className="feature-list">
          <div className="feature-item">
            <span className="emoji">✓</span>
            <span>Quick task access</span>
          </div>
          <div className="feature-item">
            <span className="emoji">✓</span>
            <span>Team collaboration</span>
          </div>
          <div className="feature-item">
            <span className="emoji">✓</span>
            <span>Real-time updates</span>
          </div>
        </div>
      </div>

      <div className="mobile-cta">
        <button
          className="btn btn-primary btn-block"
          onClick={() => handleEmployeeOnboarding(user)}
        >
          Get Started
        </button>
      </div>
    </div>
  );
}

// =============================================================================
// COMPLETE CSS STYLING GUIDE
// =============================================================================

export const ONBOARDING_STYLES = `
/*
 * Base Styles
 */

.onboarding-loader {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100vh;
  background: #f5f7fa;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #e9ecef;
  border-top-color: #667eea;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/*
 * Employee Onboarding Screen
 */

.onboarding-screen {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.onboarding-content {
  background: white;
  border-radius: 12px;
  padding: 60px 40px;
  max-width: 600px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  text-align: center;
}

.onboarding-icon {
  font-size: 80px;
  margin-bottom: 30px;
}

.onboarding-content h1 {
  font-size: 32px;
  margin-bottom: 10px;
  color: #2d3748;
}

.onboarding-content > p {
  font-size: 16px;
  color: #718096;
  margin-bottom: 40px;
}

.onboarding-features {
  margin: 40px 0;
  text-align: left;
}

.feature {
  display: flex;
  gap: 15px;
  margin-bottom: 20px;
  padding: 15px;
  background: #f7fafc;
  border-radius: 8px;
}

.feature .icon {
  font-size: 20px;
  color: #48bb78;
  flex-shrink: 0;
}

.feature h3 {
  margin: 0 0 5px 0;
  font-size: 16px;
  color: #2d3748;
}

.feature p {
  margin: 0;
  font-size: 14px;
  color: #718096;
}

.onboarding-actions {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 40px;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: white;
  border: none;
  padding: 12px 30px;
  font-size: 16px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.btn-secondary {
  background: transparent;
  color: #667eea;
  border: 2px solid #667eea;
  padding: 10px 30px;
  font-size: 16px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-secondary:hover {
  background: #f0f4ff;
}

/*
 * Progress Bar
 */

.progress-bar {
  height: 8px;
  background: #e9ecef;
  border-radius: 4px;
  overflow: hidden;
  margin: 20px 0;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #667eea, #764ba2);
  transition: width 0.3s ease;
}

/*
 * Mobile Responsive
 */

@media (max-width: 768px) {
  .onboarding-content {
    padding: 40px 20px;
  }

  .onboarding-content h1 {
    font-size: 24px;
  }

  .onboarding-actions {
    gap: 10px;
  }

  .mobile-onboarding-screen {
    display: flex;
    flex-direction: column;
    height: 100vh;
  }

  .mobile-header {
    padding: 40px 20px 20px;
    text-align: center;
  }

  .mobile-content {
    flex: 1;
    padding: 20px;
    overflow-y: auto;
  }

  .mobile-cta {
    padding: 20px;
    background: white;
    border-top: 1px solid #e9ecef;
  }

  .btn-block {
    width: 100%;
  }
}
`;

export default {
  // Export all examples for reference
  SignupCallback,
  EmployeeWelcomeModal,
  OwnerOnboardingPage,
  ProtectedRoutes,
  AuthenticatedApp,
  TasksDashboard,
  ProfileSetupPage,
  inviteTeamMember,
  useOnboardingMetrics,
  ResponsiveOnboarding
};
