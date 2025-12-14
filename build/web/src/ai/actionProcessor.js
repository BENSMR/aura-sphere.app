/**
 * Action Processor & Queue System
 * Handles execution, tracking, and history of AI-triggered actions
 * 
 * @module ai/actionProcessor
 */

import { getFirestore, collection, addDoc, updateDoc, doc, getDocs, query, where, orderBy, limit } from 'firebase/firestore';
import { ACTION_TYPES } from './actionsOnly';

/**
 * Action execution states
 */
export const ACTION_STATE = {
  PENDING: "pending",         // Waiting to be executed
  EXECUTING: "executing",     // Currently running
  COMPLETED: "completed",     // Successfully executed
  FAILED: "failed",           // Execution failed
  CANCELLED: "cancelled",     // User cancelled
  DEFERRED: "deferred"        // User deferred
};

/**
 * Action execution result
 */
export const ACTION_RESULT = {
  SUCCESS: "success",
  FAILURE: "failure",
  CANCELLED: "cancelled",
  DEFERRED: "deferred"
};

/**
 * Action Processor
 * Singleton for managing action execution and queue
 */
class ActionProcessor {
  constructor() {
    this.queue = [];
    this.history = [];
    this.executing = false;
    this.maxQueueSize = 20;
    this.executionTimeout = 30000; // 30 seconds
  }

  /**
   * Add action to queue
   * 
   * @param {Object} action - Action to queue
   * @param {Object} [options={}] - Queue options
   * @param {boolean} [options.immediate=false] - Execute immediately
   * @param {number} [options.priority=0] - Queue priority
   * @returns {Promise<string>} Action ID
   */
  async queueAction(action, options = {}) {
    const {
      immediate = false,
      priority = 0
    } = options;

    try {
      // Create queue entry
      const queueEntry = {
        id: `action_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        action,
        state: ACTION_STATE.PENDING,
        priority,
        createdAt: new Date(),
        updatedAt: new Date(),
        attempts: 0,
        maxAttempts: 3,
        result: null,
        error: null
      };

      // Add to queue
      this.queue.push(queueEntry);

      // Sort by priority
      this.queue.sort((a, b) => b.priority - a.priority);

      // Execute immediately if requested
      if (immediate) {
        await this.processQueue();
      }

      return queueEntry.id;

    } catch (error) {
      console.error('Error queuing action:', error);
      throw error;
    }
  }

  /**
   * Process next action in queue
   * 
   * @returns {Promise<Object>} Execution result
   */
  async processQueue() {
    if (this.executing || this.queue.length === 0) {
      return null;
    }

    this.executing = true;
    const queueEntry = this.queue[0];

    try {
      // Update to executing state
      queueEntry.state = ACTION_STATE.EXECUTING;
      queueEntry.updatedAt = new Date();

      // Execute action with timeout
      const result = await Promise.race([
        this._executeAction(queueEntry),
        this._createTimeout(this.executionTimeout)
      ]);

      // Mark as completed
      queueEntry.state = ACTION_STATE.COMPLETED;
      queueEntry.result = result;
      queueEntry.updatedAt = new Date();

      // Record in history
      this._recordHistory(queueEntry);

      // Remove from queue
      this.queue.shift();

      // Process next item
      setImmediate(() => this.processQueue());

      return {
        state: ACTION_STATE.COMPLETED,
        result
      };

    } catch (error) {
      queueEntry.attempts++;
      queueEntry.error = error.message;
      queueEntry.updatedAt = new Date();

      if (queueEntry.attempts >= queueEntry.maxAttempts) {
        // Max retries reached
        queueEntry.state = ACTION_STATE.FAILED;
        this._recordHistory(queueEntry);
        this.queue.shift();
      } else {
        // Retry
        queueEntry.state = ACTION_STATE.PENDING;
      }

      // Process next
      setImmediate(() => this.processQueue());

      return {
        state: ACTION_STATE.FAILED,
        error: error.message
      };

    } finally {
      this.executing = false;
    }
  }

  /**
   * Execute single action
   * 
   * @private
   */
  async _executeAction(queueEntry) {
    const { action } = queueEntry;

    try {
      // Execute the action function
      const result = await action.action();

      return {
        message: action.successMessage,
        timestamp: new Date(),
        details: result
      };

    } catch (error) {
      throw new Error(`Action execution failed: ${error.message}`);
    }
  }

  /**
   * Create execution timeout promise
   * 
   * @private
   */
  _createTimeout(ms) {
    return new Promise((_, reject) =>
      setTimeout(() => reject(new Error(`Action execution timeout after ${ms}ms`)), ms)
    );
  }

  /**
   * Record action in history
   * 
   * @private
   */
  _recordHistory(queueEntry) {
    const historyEntry = {
      id: queueEntry.id,
      actionType: queueEntry.action.type,
      actionId: queueEntry.action.id,
      state: queueEntry.state,
      result: queueEntry.result,
      error: queueEntry.error,
      attempts: queueEntry.attempts,
      executedAt: queueEntry.updatedAt,
      metadata: queueEntry.action.metadata
    };

    this.history.unshift(historyEntry);

    // Keep only last 100 items
    if (this.history.length > 100) {
      this.history.pop();
    }
  }

  /**
   * Cancel pending action
   * 
   * @param {string} actionId - Queue action ID
   */
  cancelAction(actionId) {
    const index = this.queue.findIndex(e => e.id === actionId);
    if (index !== -1) {
      const queueEntry = this.queue[index];
      queueEntry.state = ACTION_STATE.CANCELLED;
      this._recordHistory(queueEntry);
      this.queue.splice(index, 1);
      return true;
    }
    return false;
  }

  /**
   * Defer action to later
   * 
   * @param {string} actionId - Queue action ID
   * @param {number} delayMs - Delay in milliseconds
   */
  deferAction(actionId, delayMs = 3600000) { // 1 hour default
    const index = this.queue.findIndex(e => e.id === actionId);
    if (index !== -1) {
      const queueEntry = this.queue[index];
      queueEntry.state = ACTION_STATE.DEFERRED;
      queueEntry.deferredUntil = new Date(Date.now() + delayMs);

      // Re-queue after delay
      setTimeout(() => {
        queueEntry.state = ACTION_STATE.PENDING;
        this.queue.push(queueEntry);
        this.processQueue();
      }, delayMs);

      this.queue.splice(index, 1);
      return true;
    }
    return false;
  }

  /**
   * Get queue status
   * 
   * @returns {Object} Status object
   */
  getQueueStatus() {
    return {
      totalItems: this.queue.length,
      executing: this.executing,
      items: this.queue.map(e => ({
        id: e.id,
        actionType: e.action.type,
        state: e.state,
        priority: e.priority,
        attempts: e.attempts
      }))
    };
  }

  /**
   * Get action history
   * 
   * @param {number} count - Number of items to return
   * @returns {Array<Object>} History items
   */
  getHistory(count = 20) {
    return this.history.slice(0, count);
  }

  /**
   * Get history by action type
   * 
   * @param {string} actionType - Action type to filter
   * @param {number} count - Items to return
   * @returns {Array<Object>} Filtered history
   */
  getHistoryByType(actionType, count = 20) {
    return this.history
      .filter(h => h.actionType === actionType)
      .slice(0, count);
  }

  /**
   * Clear queue and history
   * 
   * @param {string} [keep='history'] - Keep 'history' or 'queue' or 'both' or 'none'
   */
  clear(keep = 'history') {
    if (keep !== 'history') {
      this.queue = [];
    }
    if (keep !== 'queue') {
      this.history = [];
    }
  }
}

// Singleton instance
export const actionProcessor = new ActionProcessor();

/**
 * Persist action to Firestore
 * For audit trail and analytics
 * 
 * @param {string} userId - User ID
 * @param {Object} action - Action object
 * @param {Object} result - Execution result
 * @returns {Promise<string>} Document ID
 */
export const persistAction = async (userId, action, result) => {
  try {
    const db = getFirestore();
    const docRef = await addDoc(collection(db, 'actionHistory'), {
      userId,
      actionType: action.type,
      actionId: action.id,
      title: action.title,
      category: action.category,
      result: result.state,
      resultDetails: result.result,
      error: result.error,
      metadata: action.metadata,
      executedAt: new Date(),
      timestamp: new Date()
    });

    return docRef.id;

  } catch (error) {
    console.error('Error persisting action:', error);
    throw error;
  }
};

/**
 * Get action history from Firestore
 * 
 * @param {string} userId - User ID
 * @param {number} count - Number of items to return
 * @returns {Promise<Array>} History items
 */
export const getActionHistoryFromFirestore = async (userId, count = 50) => {
  try {
    const db = getFirestore();
    const q = query(
      collection(db, 'actionHistory'),
      where('userId', '==', userId),
      orderBy('executedAt', 'desc'),
      limit(count)
    );

    const querySnapshot = await getDocs(q);
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

  } catch (error) {
    console.error('Error fetching action history:', error);
    return [];
  }
};

/**
 * Get action statistics
 * 
 * @param {string} userId - User ID
 * @param {number} days - Number of days to analyze
 * @returns {Promise<Object>} Statistics
 */
export const getActionStats = async (userId, days = 30) => {
  try {
    const db = getFirestore();
    const sinceDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    const q = query(
      collection(db, 'actionHistory'),
      where('userId', '==', userId),
      where('executedAt', '>=', sinceDate),
      orderBy('executedAt', 'desc')
    );

    const querySnapshot = await getDocs(q);
    const actions = querySnapshot.docs.map(doc => doc.data());

    // Calculate stats
    const total = actions.length;
    const successful = actions.filter(a => a.result === ACTION_RESULT.SUCCESS).length;
    const failed = actions.filter(a => a.result === ACTION_RESULT.FAILURE).length;

    // By category
    const byCategory = {};
    actions.forEach(action => {
      const cat = action.category || 'other';
      byCategory[cat] = (byCategory[cat] || 0) + 1;
    });

    // By type
    const byType = {};
    actions.forEach(action => {
      byType[action.actionType] = (byType[action.actionType] || 0) + 1;
    });

    return {
      period: `${days} days`,
      totalActions: total,
      successCount: successful,
      failureCount: failed,
      successRate: total > 0 ? ((successful / total) * 100).toFixed(1) + '%' : 'N/A',
      byCategory,
      byType,
      averageActionsPerDay: (total / days).toFixed(1)
    };

  } catch (error) {
    console.error('Error calculating stats:', error);
    return null;
  }
};

/**
 * Execute action with automatic persistence
 * Combines execution and logging
 * 
 * @param {string} userId - User ID
 * @param {Object} action - Action to execute
 * @param {boolean} [persist=true] - Persist to Firestore
 * @returns {Promise<Object>} Execution result
 */
export const executeAndLogAction = async (userId, action, persist = true) => {
  try {
    // Queue and execute
    await actionProcessor.queueAction(action, { immediate: true });

    // Get result from history
    const result = actionProcessor.getHistory(1)[0];

    // Persist if enabled
    if (persist && result) {
      await persistAction(userId, action, {
        state: result.state,
        result: result.result,
        error: result.error
      });
    }

    return result;

  } catch (error) {
    console.error('Error executing and logging action:', error);
    throw error;
  }
};

export default {
  ACTION_STATE,
  ACTION_RESULT,
  actionProcessor,
  persistAction,
  getActionHistoryFromFirestore,
  getActionStats,
  executeAndLogAction
};
