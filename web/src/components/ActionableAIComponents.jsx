/**
 * Actionable AI React Components
 * UI for displaying and executing one-tap actions
 * 
 * @component
 */

import React, { useState, useEffect } from 'react';
import { getActionableAI, ACTION_PRIORITY, ACTION_URGENCY } from '../ai/actionsOnly';
import { actionProcessor, ACTION_STATE } from '../ai/actionProcessor';

/**
 * ActionCard Component
 * Individual action display with execute/defer/dismiss
 * 
 * @param {Object} props
 * @param {Object} props.action - Action object from getActionableAI
 * @param {Function} props.onExecute - Callback when executed
 * @param {Function} props.onDefer - Callback when deferred
 * @param {Function} props.onDismiss - Callback when dismissed
 * @returns {JSX.Element}
 * 
 * @example
 * <ActionCard
 *   action={action}
 *   onExecute={() => console.log('Executed')}
 *   onDefer={() => console.log('Deferred')}
 *   onDismiss={() => console.log('Dismissed')}
 * />
 */
export const ActionCard = ({
  action,
  onExecute,
  onDefer,
  onDismiss
}) => {
  const [isExecuting, setIsExecuting] = useState(false);
  const [error, setError] = useState(null);

  const handleExecute = async () => {
    setIsExecuting(true);
    setError(null);

    try {
      // Queue and execute action
      await actionProcessor.queueAction(action, { immediate: true });

      if (onExecute) {
        onExecute();
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setIsExecuting(false);
    }
  };

  const handleDefer = () => {
    actionProcessor.deferAction(action.id, 3600000); // 1 hour
    if (onDefer) onDefer();
  };

  const handleDismiss = () => {
    actionProcessor.cancelAction(action.id);
    if (onDismiss) onDismiss();
  };

  // Get priority color
  const getPriorityColor = () => {
    switch (action.priority) {
      case ACTION_PRIORITY.CRITICAL:
        return '#dc2626'; // red
      case ACTION_PRIORITY.HIGH:
        return '#ea580c'; // orange
      case ACTION_PRIORITY.MEDIUM:
        return '#2563eb'; // blue
      case ACTION_PRIORITY.LOW:
        return '#65a30d'; // lime
      default:
        return '#6b7280'; // gray
    }
  };

  // Get urgency indicator
  const getUrgencyLabel = () => {
    if (action.urgency === ACTION_URGENCY.IMMEDIATE) return 'URGENT';
    if (action.urgency === ACTION_URGENCY.SOON) return 'SOON';
    if (action.urgency === ACTION_URGENCY.TODAY) return 'TODAY';
    if (action.urgency === ACTION_URGENCY.THIS_WEEK) return 'THIS WEEK';
    return 'OPTIONAL';
  };

  return (
    <div className="action-card" style={{ borderLeftColor: getPriorityColor() }}>
      <div className="action-header">
        <div className="action-title-section">
          <span className="action-icon">{action.icon}</span>
          <div className="action-text">
            <h3 className="action-title">{action.title}</h3>
            {action.description && (
              <p className="action-description">{action.description}</p>
            )}
          </div>
        </div>

        <div className="action-badges">
          <span className="badge badge-urgency">{getUrgencyLabel()}</span>
          {action.estimatedTime && (
            <span className="badge badge-time">
              ⏱️ {action.estimatedTime}s
            </span>
          )}
        </div>
      </div>

      {error && (
        <div className="action-error">
          ❌ {error}
        </div>
      )}

      <div className="action-footer">
        <button
          className="btn-action btn-execute"
          onClick={handleExecute}
          disabled={isExecuting}
        >
          {isExecuting ? (
            <>
              <span className="spinner"></span>
              Executing...
            </>
          ) : (
            <>
              {action.icon} Execute
            </>
          )}
        </button>

        <button
          className="btn-action btn-defer"
          onClick={handleDefer}
          disabled={isExecuting}
        >
          ⏱️ Defer
        </button>

        <button
          className="btn-action btn-dismiss"
          onClick={handleDismiss}
          disabled={isExecuting}
        >
          ✕ Dismiss
        </button>
      </div>
    </div>
  );
};

/**
 * ActionsList Component
 * Display multiple actions with filtering
 * 
 * @param {Object} props
 * @param {Array} props.actions - Array of action objects
 * @param {Function} props.onActionComplete - Callback when action completes
 * @param {string} [props.filterCategory] - Filter by category
 * @returns {JSX.Element}
 */
export const ActionsList = ({
  actions,
  onActionComplete,
  filterCategory
}) => {
  const [filteredActions, setFilteredActions] = useState(actions);
  const [dismissedIds, setDismissedIds] = useState(new Set());

  useEffect(() => {
    let filtered = actions.filter(a => !dismissedIds.has(a.id));

    if (filterCategory) {
      filtered = filtered.filter(a => a.category === filterCategory);
    }

    setFilteredActions(filtered);
  }, [actions, filterCategory, dismissedIds]);

  const handleDismiss = (actionId) => {
    setDismissedIds(prev => new Set([...prev, actionId]));
  };

  if (filteredActions.length === 0) {
    return (
      <div className="actions-empty">
        <p>✨ All caught up! No suggested actions at this time.</p>
      </div>
    );
  }

  return (
    <div className="actions-list">
      <div className="actions-header">
        <h2>Suggested Actions</h2>
        <span className="actions-count">{filteredActions.length}</span>
      </div>

      <div className="actions-container">
        {filteredActions.map(action => (
          <ActionCard
            key={action.id}
            action={action}
            onExecute={onActionComplete}
            onDismiss={() => handleDismiss(action.id)}
          />
        ))}
      </div>
    </div>
  );
};

/**
 * ActionsWidget Component
 * Compact widget showing action count and quick access
 * 
 * @param {Object} props
 * @param {Array} props.actions - Actions to display
 * @param {Function} props.onOpenActions - Callback to open actions panel
 * @returns {JSX.Element}
 */
export const ActionsWidget = ({ actions, onOpenActions }) => {
  const criticalCount = actions.filter(
    a => a.priority === ACTION_PRIORITY.CRITICAL
  ).length;

  const highCount = actions.filter(
    a => a.priority === ACTION_PRIORITY.HIGH
  ).length;

  return (
    <div className="actions-widget">
      <button
        className="widget-button"
        onClick={onOpenActions}
      >
        <span className="widget-icon">⚡</span>
        
        <div className="widget-content">
          <span className="widget-count">{actions.length}</span>
          <span className="widget-label">Actions</span>
        </div>

        {criticalCount > 0 && (
          <span className="widget-badge critical">{criticalCount}</span>
        )}

        {highCount > 0 && highCount > criticalCount && (
          <span className="widget-badge high">{highCount}</span>
        )}
      </button>

      {actions.length > 0 && (
        <div className="widget-preview">
          <p className="preview-title">{actions[0].title}</p>
          <p className="preview-time">
            {actions[0].estimatedTime}s to complete
          </p>
        </div>
      )}
    </div>
  );
};

/**
 * ActionPanel Component
 * Full-screen or modal panel for action management
 * 
 * @param {Object} props
 * @param {Array} props.actions - Actions to display
 * @param {boolean} [props.isOpen=false] - Panel open state
 * @param {Function} props.onClose - Callback to close
 * @returns {JSX.Element}
 */
export const ActionPanel = ({
  actions,
  isOpen = false,
  onClose
}) => {
  const [selectedCategory, setSelectedCategory] = useState(null);

  // Get unique categories
  const categories = [...new Set(actions.map(a => a.category))];

  const filteredActions = selectedCategory
    ? actions.filter(a => a.category === selectedCategory)
    : actions;

  if (!isOpen) return null;

  return (
    <div className="action-panel-overlay">
      <div className="action-panel">
        <div className="panel-header">
          <h2>AI-Suggested Actions</h2>
          <button className="btn-close" onClick={onClose}>✕</button>
        </div>

        <div className="panel-filters">
          <button
            className={`filter-btn ${!selectedCategory ? 'active' : ''}`}
            onClick={() => setSelectedCategory(null)}
          >
            All ({actions.length})
          </button>

          {categories.map(category => {
            const count = actions.filter(a => a.category === category).length;
            return (
              <button
                key={category}
                className={`filter-btn ${selectedCategory === category ? 'active' : ''}`}
                onClick={() => setSelectedCategory(category)}
              >
                {category} ({count})
              </button>
            );
          })}
        </div>

        <div className="panel-content">
          <ActionsList
            actions={filteredActions}
            filterCategory={selectedCategory}
          />
        </div>

        <div className="panel-footer">
          <p className="footer-text">
            💡 Tip: Actions are automatically queued and executed when possible
          </p>
        </div>
      </div>
    </div>
  );
};

/**
 * ActionQueue Component
 * Shows execution queue and history
 * 
 * @param {Object} props
 * @returns {JSX.Element}
 */
export const ActionQueue = (props) => {
  const [queueStatus, setQueueStatus] = useState(actionProcessor.getQueueStatus());
  const [history, setHistory] = useState(actionProcessor.getHistory(10));

  useEffect(() => {
    const interval = setInterval(() => {
      setQueueStatus(actionProcessor.getQueueStatus());
      setHistory(actionProcessor.getHistory(10));
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="action-queue">
      <div className="queue-section">
        <h3>Pending ({queueStatus.totalItems})</h3>
        {queueStatus.items.length === 0 ? (
          <p className="queue-empty">Queue is empty</p>
        ) : (
          <ul className="queue-list">
            {queueStatus.items.map(item => (
              <li key={item.id} className={`queue-item state-${item.state}`}>
                <span className="item-type">{item.actionType}</span>
                <span className="item-state">{item.state}</span>
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="queue-section">
        <h3>Recent History</h3>
        {history.length === 0 ? (
          <p className="queue-empty">No history yet</p>
        ) : (
          <ul className="history-list">
            {history.map(item => (
              <li key={item.id} className={`history-item state-${item.state}`}>
                <span className="item-type">{item.actionType}</span>
                <span className="item-state">{item.state}</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
};

/**
 * Hook for using actionable AI in components
 * 
 * @param {Object} context - Business context for action generation
 * @param {Object} [options={}] - Generation options
 * @returns {Object} Hook state and functions
 */
export const useActionableAI = (context, options = {}) => {
  const [actions, setActions] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  const generateActions = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const generated = getActionableAI(context, options);
      setActions(generated);
      return generated;
    } catch (err) {
      setError(err.message);
      return [];
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    generateActions();
  }, [context]);

  return {
    actions,
    isLoading,
    error,
    generateActions,
    actionCount: actions.length,
    criticalCount: actions.filter(a => a.priority === ACTION_PRIORITY.CRITICAL).length,
    highCount: actions.filter(a => a.priority === ACTION_PRIORITY.HIGH).length
  };
};

export default {
  ActionCard,
  ActionsList,
  ActionsWidget,
  ActionPanel,
  ActionQueue,
  useActionableAI
};
