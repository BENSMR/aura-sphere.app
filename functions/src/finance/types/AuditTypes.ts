/**
 * AuditTypes.ts
 *
 * Comprehensive audit trail data structures for AuraSphere Pro
 *
 * Firestore Path: /audit/{entityCompositeId}/entries/{entryId}
 *
 * Design:
 * - Immutable audit entries (created only, never updated)
 * - Captures before/after snapshots for all changes
 * - Tracks source (server function, webhook, client)
 * - Includes metadata for compliance & debugging
 * - Composite entity ID enables cross-entity audit trails
 */

import * as admin from 'firebase-admin';

export interface AuditActor {
  /** Firebase UID */
  uid: string;
  /** User's display name */
  name?: string;
  /** User's email */
  email?: string;
  /** User role: 'admin', 'user', 'service', 'webhook' */
  role?: string;
}

export interface AuditMetadata {
  /** Request ID for tracing (Cloud Function invocation ID) */
  requestId?: string;
  /** FX rate snapshot at time of action */
  fxSnapshot?: {
    base: string;
    rates: Record<string, number>;
    provider?: string;
    updatedAt?: admin.firestore.Timestamp;
  };
  /** Tax calculation details */
  taxBreakdown?: {
    type: 'vat' | 'sales_tax' | 'none';
    rate: number;
    amount?: number;
    country?: string;
  };
  /** Reason for action (e.g., 'manual_override', 'auto_correction', 'admin_request') */
  reason?: string;
  /** Additional arbitrary metadata */
  [key: string]: any;
}

export interface AuditEntry {
  // Actor
  actor: AuditActor;

  // Action tracking
  action: string; // e.g., 'invoice.created', 'invoice.tax_applied', 'payment.received', 'expense.approved'
  entityType: string; // 'invoice' | 'expense' | 'po' | 'payment' | 'user' | 'company' | ...
  entityId: string; // actual document ID in user's collection

  // Timestamp
  timestamp: admin.firestore.Timestamp; // server timestamp

  // Source tracking
  source: string; // e.g., 'server:processTaxQueue', 'functions:paymentWebhook', 'client:ui', 'functions:onInvoiceCreate'

  // Network metadata
  ip?: string | null; // client IP (nullable)

  // Change snapshots
  before?: Record<string, any> | null; // minimal snapshot before (null for creates)
  after?: Record<string, any> | null; // snapshot after

  // Structured metadata
  meta?: AuditMetadata;

  // Searchable tags
  tags: string[]; // e.g., ['tax', 'auto', 'critical', 'payment', 'compliance']

  // Immutability flag
  immutable: true;
}

/**
 * Helper: Create an audit entry
 *
 * Usage:
 * ```
 * const entry = createAuditEntry({
 *   actor: { uid: 'user123', role: 'user' },
 *   action: 'invoice.tax_applied',
 *   entityType: 'invoice',
 *   entityId: 'inv-001',
 *   source: 'server:processTaxQueue',
 *   before: oldInvoiceData,
 *   after: newInvoiceData,
 *   meta: { taxBreakdown: {...}, fxSnapshot: {...} },
 *   tags: ['tax', 'auto']
 * });
 * ```
 */
export function createAuditEntry(
  input: Partial<AuditEntry> & {
    actor: AuditActor;
    action: string;
    entityType: string;
    entityId: string;
    source: string;
  },
): AuditEntry {
  return {
    actor: input.actor,
    action: input.action,
    entityType: input.entityType,
    entityId: input.entityId,
    timestamp: admin.firestore.FieldValue.serverTimestamp() as FirebaseFirestore.Timestamp,
    source: input.source,
    ip: input.ip ?? null,
    before: input.before ?? null,
    after: input.after ?? null,
    meta: input.meta,
    tags: input.tags ?? [],
    immutable: true,
  };
}

/**
 * Helper: Compute composite entity ID
 *
 * Pattern: {entityType}:{entityId}
 * Example: invoice:inv-001, payment:pay-123
 *
 * This allows grouping all audit entries for a single entity
 * across multiple action types.
 */
export function getCompositeEntityId(entityType: string, entityId: string): string {
  return `${entityType}:${entityId}`;
}

/**
 * Helper: Write audit entry to Firestore
 *
 * Path: /audit/{compositeId}/entries/{entryId}
 *
 * Usage:
 * ```
 * const entry = createAuditEntry({...});
 * await writeAuditEntry(uid, entry);
 * ```
 */
export async function writeAuditEntry(
  uid: string,
  entry: AuditEntry,
): Promise<string> {
  const db = admin.firestore();
  const compositeId = getCompositeEntityId(entry.entityType, entry.entityId);

  const entryRef = db
    .collection('audit')
    .doc(compositeId)
    .collection('entries')
    .doc(); // auto-generate entryId

  await entryRef.set(entry);
  return entryRef.id;
}

/**
 * Helper: Query audit trail for entity
 *
 * Usage:
 * ```
 * const entries = await getAuditTrail(compositeId, { limit: 50 });
 * ```
 */
export async function getAuditTrail(
  compositeId: string,
  options?: {
    limit?: number;
    startAfter?: admin.firestore.Timestamp;
  },
): Promise<AuditEntry[]> {
  const db = admin.firestore();
  let query: admin.firestore.Query = db
    .collection('audit')
    .doc(compositeId)
    .collection('entries')
    .orderBy('timestamp', 'desc');

  if (options?.limit) {
    query = query.limit(options.limit);
  }

  const snap = await query.get();
  return snap.docs.map((doc: admin.firestore.QueryDocumentSnapshot) => doc.data() as AuditEntry);
}

/**
 * Helper: Query all audit entries for a user (cross-entity)
 *
 * Usage:
 * ```
 * const allEntries = await getUserAuditTrail(uid, { limit: 100 });
 * ```
 */
export async function getUserAuditTrail(
  uid: string,
  options?: {
    limit?: number;
    entityType?: string;
    action?: string;
    tag?: string;
  },
): Promise<AuditEntry[]> {
  const db = admin.firestore();

  let query: admin.firestore.Query = db
    .collectionGroup('entries')
    .where('actor.uid', '==', uid)
    .orderBy('timestamp', 'desc');

  if (options?.entityType) {
    query = query.where('entityType', '==', options.entityType);
  }

  if (options?.action) {
    query = query.where('action', '==', options.action);
  }

  if (options?.tag) {
    query = query.where('tags', 'array-contains', options.tag);
  }

  if (options?.limit) {
    query = query.limit(options.limit);
  }

  const snap = await query.get();
  return snap.docs.map((doc: admin.firestore.QueryDocumentSnapshot) => doc.data() as AuditEntry);
}

/**
 * Helper: Log tax calculation audit entry
 *
 * Specialized helper for tax system audit logging
 *
 * Usage:
 * ```
 * await logTaxAudit(uid, {
 *   invoiceId: 'inv-001',
 *   action: 'invoice.tax_applied',
 *   before: oldData,
 *   after: newData,
 *   taxBreakdown: result.taxBreakdown,
 *   fxSnapshot: fxData,
 *   source: 'server:processTaxQueue'
 * });
 * ```
 */
export async function logTaxAudit(
  uid: string,
  input: {
    invoiceId?: string;
    expenseId?: string;
    poId?: string;
    action: string; // 'invoice.tax_applied', 'expense.tax_applied', etc.
    before?: Record<string, any>;
    after?: Record<string, any>;
    taxBreakdown?: any;
    fxSnapshot?: any;
    source: string;
    reason?: string;
  },
): Promise<string> {
  const entityId = input.invoiceId || input.expenseId || input.poId || 'unknown';
  const entityType = input.invoiceId
    ? 'invoice'
    : input.expenseId
      ? 'expense'
      : 'po';

  const entry = createAuditEntry({
    actor: { uid, role: 'system' },
    action: input.action,
    entityType,
    entityId,
    source: input.source,
    before: input.before,
    after: input.after,
    meta: {
      taxBreakdown: input.taxBreakdown,
      fxSnapshot: input.fxSnapshot,
      reason: input.reason,
    },
    tags: ['tax', 'auto', 'compliance'],
  });

  const entryId = await writeAuditEntry(uid, entry);

  // Update audit index for quick lookups
  await updateAuditIndex(uid, entry, entryId);

  return entryId;
}

/**
 * Audit Index Entry
 *
 * Denormalized index for fast audit queries
 * Path: /audit_index/{compositeId}
 *
 * Used for:
 * - Quick lookup of latest audit entry per entity
 * - Fast filtering and sorting without collectionGroup queries
 * - Real-time audit summary displays
 */
export interface AuditIndexEntry {
  entityType: string;
  entityId: string;
  compositeId: string; // derived from entityType:entityId
  latestEntryId: string; // reference to latest audit entry
  latestAt: admin.firestore.Timestamp;
  latestAction: string;
  latestActorUid: string;
  latestActorName?: string;
  entryCount: number; // total audit entries for this entity
  tags: string[]; // union of all tags from recent entries
}

/**
 * Helper: Update audit index when new entry is created
 *
 * Maintains denormalized index for fast queries
 */
export async function updateAuditIndex(
  uid: string,
  entry: AuditEntry,
  entryId: string,
): Promise<void> {
  const db = admin.firestore();
  const compositeId = getCompositeEntityId(entry.entityType, entry.entityId);

  const indexRef = db.collection('audit_index').doc(compositeId);

  await indexRef.set(
    {
      entityType: entry.entityType,
      entityId: entry.entityId,
      compositeId,
      latestEntryId: entryId,
      latestAt: entry.timestamp,
      latestAction: entry.action,
      latestActorUid: entry.actor.uid,
      latestActorName: entry.actor.name || null,
      tags: entry.tags,
      // Note: entryCount would require a transaction to read current value
      // This can be computed on-read from the entries subcollection if needed
    },
    { merge: true }, // Merge to preserve entryCount if it exists
  );
}

/**
 * Helper: Get audit index for entity (fast lookup)
 *
 * Usage:
 * ```
 * const index = await getAuditIndex('invoice:inv-001');
 * console.log(index.latestAction); // 'invoice.tax_applied'
 * ```
 */
export async function getAuditIndex(compositeId: string): Promise<AuditIndexEntry | null> {
  const db = admin.firestore();
  const doc = await db.collection('audit_index').doc(compositeId).get();
  return doc.exists ? (doc.data() as AuditIndexEntry) : null;
}
