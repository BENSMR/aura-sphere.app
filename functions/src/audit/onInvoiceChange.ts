/**
 * onInvoiceChange.ts
 *
 * Firestore trigger that captures all invoice changes in the audit trail
 *
 * Triggers on: create, update, delete
 * Writes to: /audit/invoice_{invoiceId}/entries/{entryId}
 *           /audit_index/invoice_{invoiceId}
 *
 * Patterns:
 * - Detects action type (create/update/delete) from change state
 * - Extracts actor from __actor embedded field (set by server writes)
 * - Skips audit writes triggered by audit system (prevents loops)
 * - Captures trimmed before/after snapshots (not full documents)
 * - Graceful error handling (logs but doesn't crash)
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { writeAuditEntry } from './auditHelpers';

if (!admin.apps.length) admin.initializeApp();

/**
 * Trigger: When any invoice is created, updated, or deleted
 *
 * Path: users/{uid}/invoices/{invoiceId}
 */
export const onInvoiceWriteAudit = functions.firestore
  .document('users/{uid}/invoices/{invoiceId}')
  .onWrite(async (change, context) => {
    const uid = context.params.uid;
    const invoiceId = context.params.invoiceId;

    // Extract before/after snapshots
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.exists ? change.after.data() : null;

    // Determine action type from change state
    let action = 'invoice.updated';
    if (!before && after) {
      action = 'invoice.created';
    } else if (before && !after) {
      action = 'invoice.deleted';
    }

    /**
     * Extract actor information
     *
     * Priority:
     * 1. __actor field set by server write (recommended: embed when calling determineTaxAndCurrency)
     * 2. Fall back to null (audit shows system action)
     *
     * Example server write pattern:
     * ```
     * await db.collection('users').doc(uid).collection('invoices').doc(id).set({
     *   __actor: { uid: 'user123', name: 'Alice' },
     *   ...invoiceData
     * }, { merge: true });
     * ```
     */
    const actor =
      after?.__actor ||
      before?.__actor ||
      {
        uid: null,
        name: null,
      };

    /**
     * Skip audit trigger if this write originated from audit system
     *
     * Prevents infinite loops when audit system updates entities.
     * Usage pattern in audit helper:
     * ```
     * await db.collection('users').doc(uid).collection('invoices').doc(id).set(
     *   { __isAuditUpdate: true, ...changes },
     *   { merge: true }
     * );
     * ```
     */
    if (after?.__isAuditUpdate) {
      console.log(`[audit-skip] invoice_${invoiceId}: originated from audit system`);
      return null;
    }

    /**
     * Build audit entry
     *
     * Captures only essential fields (not full documents) to keep
     * audit logs manageable and readable
     */
    const entry = {
      actor,
      action,
      source: 'functions:onInvoiceWrite',
      before: before
        ? {
            id: before.id || invoiceId,
            status: before.status,
            amount: before.amount,
            currency: before.currency,
            taxRate: before.taxRate,
            taxCalculatedAt: before.taxCalculatedAt,
          }
        : undefined,
      after: after
        ? {
            id: after.id || invoiceId,
            status: after.status,
            amount: after.amount,
            currency: after.currency,
            taxRate: after.taxRate,
            taxCalculatedAt: after.taxCalculatedAt,
          }
        : undefined,
      meta: {
        uid,
        triggeredBy: 'firestore:onWrite',
      },
      tags: ['invoice', action.split('.')[1]], // ['invoice', 'created'] or ['invoice', 'updated']
    };

    try {
      const result = await writeAuditEntry('invoice', invoiceId, entry);
      console.log(`[audit] invoice_${invoiceId}: ${action} (entry: ${result.id})`);
      return null;
    } catch (err) {
      console.error(`[audit-error] invoice_${invoiceId}: ${action}`, err);
      // Don't throw — allow write to succeed even if audit fails
      return null;
    }
  });

/**
 * Trigger: When invoice status specifically changes
 *
 * Useful for tracking status transitions separately
 * Examples: draft → sent → paid → archived
 */
export const onInvoiceStatusChange = functions.firestore
  .document('users/{uid}/invoices/{invoiceId}')
  .onUpdate(async (change, context) => {
    const uid = context.params.uid;
    const invoiceId = context.params.invoiceId;

    const before = change.before.data();
    const after = change.after.data();

    // Only trigger if status actually changed
    if (before.status === after.status) {
      return null;
    }

    const entry = {
      actor: after?.__actor || { uid: null, name: null },
      action: 'invoice.status_changed',
      source: 'functions:onInvoiceStatusChange',
      before: {
        status: before.status,
      } as Record<string, any>,
      after: {
        status: after.status,
      } as Record<string, any>,
      meta: {
        uid,
        oldStatus: before.status,
        newStatus: after.status,
      },
      tags: ['invoice', 'status', `status:${after.status}`],
    };

    try {
      await writeAuditEntry('invoice', invoiceId, entry);
      console.log(
        `[audit] invoice_${invoiceId}: status changed ${before.status} → ${after.status}`,
      );
      return null;
    } catch (err) {
      console.error(`[audit-error] invoice_${invoiceId}: status change`, err);
      return null;
    }
  });
