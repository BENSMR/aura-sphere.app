/**
 * auditHelpers.ts
 *
 * Practical helpers for writing and managing audit trail entries
 *
 * Usage:
 * ```
 * const result = await writeAuditEntry('invoice', 'inv-001', {
 *   actor: { uid: 'user123', name: 'Alice' },
 *   action: 'invoice.tax_applied',
 *   source: 'server:processTaxQueue',
 *   before: oldInvoiceData,
 *   after: newInvoiceData,
 *   meta: { taxBreakdown, fxSnapshot },
 *   tags: ['tax', 'auto']
 * });
 * ```
 */

import * as admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();

const db = admin.firestore();

/**
 * Actor information for audit trail
 */
export interface AuditActor {
  uid: string;
  name?: string;
  email?: string;
  role?: string;
}

/**
 * Audit entry data (user-provided)
 */
export interface AuditEntryInput {
  actor?: AuditActor;
  action: string;
  source?: string;
  ip?: string | null;
  before?: Record<string, any>;
  after?: Record<string, any>;
  meta?: Record<string, any>;
  tags?: string[];
}

/**
 * Audit entry as stored in Firestore
 */
export interface AuditEntryStored {
  actor: AuditActor | null;
  action: string;
  entityType: string;
  entityId: string;
  timestamp: admin.firestore.Timestamp;
  source: string;
  ip: string | null;
  before: Record<string, any> | null;
  after: Record<string, any> | null;
  meta: Record<string, any> | null;
  tags: string[];
  immutable: true;
}

/**
 * Audit index entry (denormalized for fast lookups)
 */
export interface AuditIndexStored {
  entityType: string;
  entityId: string;
  latestEntryId: string;
  latestAt: admin.firestore.Timestamp;
  summary: {
    action: string;
    actorName: string | null;
  };
}

/**
 * Write audit entry to Firestore
 *
 * Creates two documents:
 * 1. /audit/{compositeId}/entries/{entryId} — Full audit entry (immutable)
 * 2. /audit_index/{compositeId} — Denormalized index (for fast lookups)
 *
 * Composite ID format: `{entityType}_{entityId}` (underscore-separated)
 *
 * @param entityType — e.g., 'invoice', 'expense', 'payment'
 * @param entityId — Document ID in user's collection
 * @param entry — Audit entry data
 * @returns { id, ref } — Entry document ID and reference
 */
export async function writeAuditEntry(
  entityType: string,
  entityId: string,
  entry: AuditEntryInput,
): Promise<{ id: string; ref: admin.firestore.DocumentReference }> {
  // Composite ID format: entity_type_entity_id
  const compositeId = `${entityType}_${entityId}`;

  // Create entry document
  const entryRef = db.collection('audit').doc(compositeId).collection('entries').doc();

  const entryData: AuditEntryStored = {
    actor: entry.actor || null,
    action: entry.action,
    entityType,
    entityId,
    timestamp: admin.firestore.FieldValue.serverTimestamp() as any,
    source: entry.source || 'server',
    ip: entry.ip || null,
    before: entry.before ?? null,
    after: entry.after ?? null,
    meta: entry.meta ?? null,
    tags: entry.tags ?? [],
    immutable: true,
  };

  await entryRef.set(entryData, { merge: false });

  // Update audit index for quick lookup
  const indexRef = db.collection('audit_index').doc(compositeId);

  const indexData: AuditIndexStored = {
    entityType,
    entityId,
    latestEntryId: entryRef.id,
    latestAt: admin.firestore.FieldValue.serverTimestamp() as any,
    summary: {
      action: entry.action,
      actorName:
        entry.actor?.name ||
        entry.actor?.email ||
        entry.actor?.uid ||
        null,
    },
  };

  await indexRef.set(indexData, { merge: true });

  return { id: entryRef.id, ref: entryRef };
}

/**
 * Quick helper: write tax-specific audit entry
 *
 * Usage:
 * ```
 * await writeTaxAuditEntry('invoice', 'inv-001', {
 *   uid: 'user123',
 *   action: 'invoice.tax_applied',
 *   before: oldData,
 *   after: newData,
 *   taxBreakdown: result.taxBreakdown,
 *   fxSnapshot: fxData
 * });
 * ```
 */
export async function writeTaxAuditEntry(
  entityType: string,
  entityId: string,
  input: {
    uid: string;
    action: string;
    before?: Record<string, any>;
    after?: Record<string, any>;
    taxBreakdown?: any;
    fxSnapshot?: any;
    reason?: string;
  },
): Promise<{ id: string; ref: admin.firestore.DocumentReference }> {
  return writeAuditEntry(entityType, entityId, {
    actor: {
      uid: input.uid,
      role: 'system',
    },
    action: input.action,
    source: 'server:processTaxQueue',
    before: input.before,
    after: input.after,
    meta: {
      taxBreakdown: input.taxBreakdown,
      fxSnapshot: input.fxSnapshot,
      reason: input.reason,
    },
    tags: ['tax', 'auto', 'compliance'],
  });
}

/**
 * Get latest audit entry for entity (from index)
 *
 * Fast single-doc read (doesn't query entries)
 */
export async function getAuditIndexEntry(
  entityType: string,
  entityId: string,
): Promise<AuditIndexStored | null> {
  const compositeId = `${entityType}_${entityId}`;
  const doc = await db.collection('audit_index').doc(compositeId).get();
  return doc.exists ? (doc.data() as AuditIndexStored) : null;
}

/**
 * Get full audit trail for entity
 *
 * Returns all audit entries (ordered by latest first)
 */
export async function getAuditTrail(
  entityType: string,
  entityId: string,
  limit: number = 100,
): Promise<(AuditEntryStored & { id: string })[]> {
  const compositeId = `${entityType}_${entityId}`;
  const snap = await db
    .collection('audit')
    .doc(compositeId)
    .collection('entries')
    .orderBy('timestamp', 'desc')
    .limit(limit)
    .get();

  return snap.docs.map((doc) => ({
    id: doc.id,
    ...(doc.data() as AuditEntryStored),
  }));
}

/**
 * Get specific audit entry by ID
 */
export async function getAuditEntry(
  entityType: string,
  entityId: string,
  entryId: string,
): Promise<(AuditEntryStored & { id: string }) | null> {
  const compositeId = `${entityType}_${entityId}`;
  const doc = await db
    .collection('audit')
    .doc(compositeId)
    .collection('entries')
    .doc(entryId)
    .get();

  return doc.exists
    ? {
        id: doc.id,
        ...(doc.data() as AuditEntryStored),
      }
    : null;
}

/**
 * Query audit entries across all entities
 *
 * Supports filtering by action, tag, source, or actor
 */
export async function queryAuditEntries(options?: {
  action?: string;
  tag?: string;
  source?: string;
  actorUid?: string;
  limit?: number;
}): Promise<(AuditEntryStored & { id: string; compositeId: string })[]> {
  let query: admin.firestore.Query = db.collectionGroup('entries');

  if (options?.action) {
    query = query.where('action', '==', options.action);
  }

  if (options?.tag) {
    query = query.where('tags', 'array-contains', options.tag);
  }

  if (options?.source) {
    query = query.where('source', '==', options.source);
  }

  if (options?.actorUid) {
    query = query.where('actor.uid', '==', options.actorUid);
  }

  query = query.orderBy('timestamp', 'desc').limit(options?.limit ?? 100);

  const snap = await query.get();

  return snap.docs.map((doc) => {
    // Extract compositeId from path: audit/invoice_inv-001/entries/entry123
    const pathParts = doc.ref.path.split('/');
    const compositeId = pathParts[1];

    return {
      id: doc.id,
      compositeId,
      ...(doc.data() as AuditEntryStored),
    };
  });
}
