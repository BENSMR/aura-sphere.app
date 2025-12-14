/**
 * Onboarding Guard Component
 * Protects routes and redirects to onboarding if needed
 * 
 * @component
 */

import React, { useEffect, useState } from 'react';
import { useAuth } from '../hooks/useAuth';
import { useRole } from '../hooks/useRole';
import {
  isEmployeeOnboarded,
  shouldShowEmployeeOnboarding
} from '../onboarding/employeeFlow';
import {
  getOwnerOnboardingStatus
} from '../onboarding/ownerFlow';

/**
 * OnboardingGuard Component
 * Redirects unboarded users to appropriate onboarding flow
 * 
 * @param {Object} props
 * @param {React.ReactNode} props.children - Content to render if onboarded
 * @param {Array<string>} [props.allowedRoles=["owner", "employee"]] - Roles to check
 * @returns {JSX.Element}
 * 
 * @example
 * <OnboardingGuard>
 *   <Dashboard />
 * </OnboardingGuard>
 */
export const OnboardingGuard = ({
  children,
  allowedRoles = ["owner", "employee"]
}) => {
  const { user, loading: authLoading } = useAuth();
  const { role, loading: roleLoading } = useRole();
  const [onboarded, setOnboarded] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkOnboarding = async () => {
      if (!user || !allowedRoles.includes(role)) {
        setLoading(false);
        return;
      }

      try {
        if (role === "employee") {
          const isOnboarded = await isEmployeeOnboarded(user);
          setOnboarded(isOnboarded);
        } else if (role === "owner") {
          const status = getOwnerOnboardingStatus();
          setOnboarded(status.completed);
        }
      } catch (error) {
        console.error("Error checking onboarding:", error);
        setOnboarded(false);
      } finally {
        setLoading(false);
      }
    };

    if (!authLoading && !roleLoading) {
      checkOnboarding();
    }
  }, [user, role, authLoading, roleLoading, allowedRoles]);

  if (authLoading || roleLoading || loading) {
    return (
      <div className="onboarding-loader">
        <div className="spinner"></div>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  if (!onboarded) {
    if (role === "employee") {
      window.location.href = "/onboarding/employee";
      return null;
    } else if (role === "owner") {
      window.location.href = "/onboarding/owner";
      return null;
    }
  }

  return <>{children}</>;
};

/**
 * EmployeeOnboardingScreen Component
 * Quick employee welcome and redirect
 * 
 * @param {Object} props
 * @param {Object} props.user - Current user
 * @param {Function} [props.onComplete] - Callback after onboarding
 * @returns {JSX.Element}
 */
export const EmployeeOnboardingScreen = ({ user, onComplete }) => {
  const [isProcessing, setIsProcessing] = useState(false);

  const handleGetStarted = async () => {
    setIsProcessing(true);
    try {
      const { handleEmployeeOnboarding } = await import('../onboarding/employeeFlow');
      await handleEmployeeOnboarding(user, {
        showTooltip: true,
        redirectPath: "/tasks/assigned",
        redirectDelay: 500
      });
      if (onComplete) onComplete();
    } catch (error) {
      console.error("Error in employee onboarding:", error);
      setIsProcessing(false);
    }
  };

  const handleSkip = async () => {
    setIsProcessing(true);
    try {
      const { skipEmployeeOnboarding } = await import('../onboarding/employeeFlow');
      await skipEmployeeOnboarding(user);
      window.location.href = "/tasks/assigned";
    } catch (error) {
      console.error("Error skipping onboarding:", error);
      setIsProcessing(false);
    }
  };

  return (
    <div className="onboarding-screen employee-onboarding">
      <div className="onboarding-content">
        <div className="onboarding-icon">👋</div>
        
        <h1>Welcome to AuraSphere Pro!</h1>
        <p>You've been invited to join a team on AuraSphere Pro.</p>

        <div className="onboarding-features">
          <div className="feature">
            <span className="icon">✓</span>
            <div>
              <h3>Assigned Tasks</h3>
              <p>View and manage tasks assigned to you</p>
            </div>
          </div>

          <div className="feature">
            <span className="icon">✓</span>
            <div>
              <h3>Team Collaboration</h3>
              <p>Work together with your team members</p>
            </div>
          </div>

          <div className="feature">
            <span className="icon">✓</span>
            <div>
              <h3>Real-time Updates</h3>
              <p>Stay synchronized with your team</p>
            </div>
          </div>
        </div>

        <div className="onboarding-actions">
          <button
            className="btn-primary"
            onClick={handleGetStarted}
            disabled={isProcessing}
          >
            {isProcessing ? "Setting up..." : "Get Started"}
          </button>
          
          <button
            className="btn-secondary"
            onClick={handleSkip}
            disabled={isProcessing}
          >
            Skip for now
          </button>
        </div>
      </div>
    </div>
  );
};

/**
 * OwnerOnboardingProgress Component
 * Shows progress through owner onboarding steps
 * 
 * @param {Object} props
 * @param {Array<string>} [props.completedSteps=[]] - Completed step IDs
 * @param {string} [props.currentStep] - Current step ID
 * @returns {JSX.Element}
 */
export const OwnerOnboardingProgress = ({
  completedSteps = [],
  currentStep
}) => {
  const { getOnboardingStepsWithStatus, getEstimatedTimeRemaining } = require('../onboarding/ownerFlow');
  
  const steps = getOnboardingStepsWithStatus(completedSteps);
  const timeRemaining = getEstimatedTimeRemaining(completedSteps);
  const progressPercentage = Math.round((completedSteps.length / steps.length) * 100);

  return (
    <div className="onboarding-progress">
      <div className="progress-header">
        <h3>Setup Progress</h3>
        <span className="progress-percentage">{progressPercentage}%</span>
      </div>

      <div className="progress-bar">
        <div
          className="progress-fill"
          style={{ width: `${progressPercentage}%` }}
        />
      </div>

      <div className="progress-steps">
        {steps.map((step, index) => (
          <div
            key={step.id}
            className={`step ${
              step.completed
                ? 'completed'
                : step.id === currentStep
                ? 'current'
                : 'pending'
            }`}
          >
            <div className="step-number">
              {step.completed ? '✓' : index + 1}
            </div>
            <div className="step-info">
              <p className="step-name">{step.name}</p>
              <p className="step-time">{step.estimatedTime} mins</p>
            </div>
          </div>
        ))}
      </div>

      {timeRemaining > 0 && (
        <div className="progress-estimate">
          <p>Estimated time remaining: <strong>{timeRemaining} minutes</strong></p>
        </div>
      )}
    </div>
  );
};

/**
 * OwnerOnboardingStep Component
 * Individual step in owner onboarding
 * 
 * @param {Object} props
 * @param {Object} props.step - Step configuration
 * @param {boolean} [props.isActive=false] - Whether step is active
 * @param {boolean} [props.isCompleted=false] - Whether step is completed
 * @param {Function} props.onComplete - Callback when step completes
 * @returns {JSX.Element}
 */
export const OwnerOnboardingStep = ({
  step,
  isActive = false,
  isCompleted = false,
  onComplete
}) => {
  const handleNavigate = () => {
    window.location.href = step.path;
  };

  const handleSkip = () => {
    if (onComplete) onComplete();
  };

  return (
    <div className={`onboarding-step ${isActive ? 'active' : ''} ${isCompleted ? 'completed' : ''}`}>
      <div className="step-header">
        <h2>{step.name}</h2>
        {step.required && <span className="required-badge">Required</span>}
      </div>

      <p className="step-description">{step.description}</p>

      <div className="step-meta">
        <span className="step-time">⏱️ ~{step.estimatedTime} minutes</span>
      </div>

      {!isCompleted && (
        <div className="step-actions">
          <button className="btn-primary" onClick={handleNavigate}>
            Start Step →
          </button>
          
          {!step.required && (
            <button className="btn-secondary" onClick={handleSkip}>
              Skip
            </button>
          )}
        </div>
      )}

      {isCompleted && (
        <div className="step-completed">
          <span className="checkmark">✓</span>
          <p>Step completed!</p>
        </div>
      )}
    </div>
  );
};

export default {
  OnboardingGuard,
  EmployeeOnboardingScreen,
  OwnerOnboardingProgress,
  OwnerOnboardingStep
};
