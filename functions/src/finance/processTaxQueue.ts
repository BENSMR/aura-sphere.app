import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { determineTaxLogic } from './determineTaxLogic';

if (!admin.apps.length) admin.initializeApp();

/**
 * processTaxQueue.ts
 *
 * Scheduled worker that processes internal tax queue:
 * internal/tax_queue/requests/{requestId}
 *
 * Behaviour:
 * - Reads up to N unprocessed requests
 * - For each: loads entity (invoice/expense/po), calls determineTaxLogic(payload, uid)
 * - Writes authoritative tax/currency fields, audit entry & FX snapshot into the entity
 * - Marks queue request processed (or increments attempts+lastError)
 *
 * IMPORTANT: This worker uses ONLY the cached Firestore FX doc: config/fx_rates
 * (Option A - no external API calls)
 */

interface TaxQueueRequest {
  uid: string;
  entityPath: string;
  processed?: boolean;
  processedAt?: admin.firestore.Timestamp;
  lastError?: string;
  attempts?: number;
  createdAt?: admin.firestore.Timestamp;
  note?: string;
}

interface Entity {
  amount?: number;
  totalAmount?: number;
  subtotal?: number;
  total?: number;
  currency?: string;
  companyId?: string;
  sellerCompanyId?: string;
  contactId?: string;
  clientId?: string;
  country?: string;
  type?: string;
  category?: string;
  customerIsBusiness?: boolean;
  [key: string]: any;
}

interface ProcessResult {
  reqId: string;
  entity?: string;
  status: 'ok' | 'error';
  error?: string;
}

// Helper: safe number rounding (2 decimals)
function round2(n: number | undefined | null): number {
  if (n === null || n === undefined) return 0;
  return Math.round((Number(n) + Number.EPSILON) * 100) / 100;
}

const QUEUE_COLLECTION = 'internal/tax_queue/requests';
const FX_DOC_PATH = 'config/fx_rates';
const MAX_BATCH = 20; // process up to 20 items per run
const MAX_ATTEMPTS = 5; // after this, mark as failed for manual review

/**
 * Worker: scheduled every minute
 * Processes pending tax queue requests with error recovery and auditing
 */
export const processTaxQueue = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async (context: functions.EventContext) => {
    console.log('[processTaxQueue] Starting run', new Date().toISOString());

    const db = admin.firestore();
    const results: ProcessResult[] = [];

    try {
      // Fetch up to MAX_BATCH unprocessed requests, ordered by creation
      const queueRef = db
        .collection('internal')
        .doc('tax_queue')
        .collection('requests')
        .where('processed', '==', false)
        .orderBy('createdAt', 'asc')
        .limit(MAX_BATCH);

      const queueSnap = await queueRef.get();

      if (queueSnap.empty) {
        console.log('[processTaxQueue] No queued requests found.');
        return null;
      }

      console.log(`[processTaxQueue] Processing ${queueSnap.docs.length} tax queue items`);

      // Preload FX snapshot to include in audits (cached doc)
      const fxDocSnap = await db.doc(FX_DOC_PATH).get();
      const fxSnapshot = fxDocSnap.exists ? (fxDocSnap.data() as any) : null;

      const batch = db.batch();

      for (const doc of queueSnap.docs) {
        const req = doc.data() as TaxQueueRequest;
        const reqRef = doc.ref;

        // Basic validation
        if (!req || !req.entityPath || !req.uid) {
          console.warn('[processTaxQueue] Invalid request, marking processed:', doc.id);
          batch.update(reqRef, {
            processed: true,
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
            lastError: 'invalid_request',
          });
          continue;
        }

        // Prevent runaway attempts
        const attempts = req.attempts || 0;
        if (attempts >= MAX_ATTEMPTS) {
          console.warn(
            `[processTaxQueue] Max attempts reached for ${doc.id}. Marking failed.`,
          );
          batch.update(reqRef, {
            processed: true,
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
            lastError: 'max_attempts_reached',
          });
          continue;
        }

        try {
          // Load target entity (invoice/expense/po)
          const entityRef = db.doc(req.entityPath);
          const entitySnap = await entityRef.get();

          if (!entitySnap.exists) {
            console.warn(
              '[processTaxQueue] Entity missing, marking request processed:',
              req.entityPath,
            );
            batch.update(reqRef, {
              processed: true,
              processedAt: admin.firestore.FieldValue.serverTimestamp(),
              lastError: 'entity_missing',
            });
            continue;
          }

          const entity = entitySnap.data() as Entity;

          // Build payload for determineTaxLogic based on entity contents
          const payload = {
            amount: entity.amount || entity.subtotal || entity.total || 0,
            fromCurrency: entity.currency || null,
            companyId: entity.companyId || entity.sellerCompanyId || null,
            contactId: entity.contactId || entity.clientId || null,
            country: entity.country || null,
            direction:
              entity.type === 'expense' || req.entityPath.includes('/expenses/')
                ? ('purchase' as const)
                : ('sale' as const),
            itemCategory: entity.category || null,
            customerIsBusiness: entity.customerIsBusiness || false,
          };

          // Call the shared logic (pure function)
          const determination = await determineTaxLogic(payload, req.uid);

          if (!determination || determination.success !== true) {
            throw new Error('determineTaxLogic returned invalid result');
          }

          // Prepare authoritative update
          const updateData: Record<string, any> = {
            // canonical financial fields
            currency: determination.currency || entity.currency || null,
            taxRate: round2(determination.taxRate ?? 0),
            taxAmount: round2(determination.taxAmount ?? 0),
            total: round2(
              determination.total ?? payload.amount + (determination.taxAmount || 0),
            ),

            // server-only metadata (authoritative)
            taxCalculatedBy: 'server:determineTaxLogic',
            taxCalculationAt: admin.firestore.FieldValue.serverTimestamp(),
            taxBreakdown: determination.taxBreakdown || null,
            taxNote: determination.note || null,

            // FX snapshot for audit + reproducibility
            fxSnapshot: fxSnapshot
              ? {
                  base: fxSnapshot.base || null,
                  provider: fxSnapshot.provider || null,
                  rates: fxSnapshot.rates || null,
                  fxUpdatedAt: fxSnapshot.updatedAt || null,
                }
              : null,

            // audit array append
            audit: admin.firestore.FieldValue.arrayUnion({
              action: 'tax_auto_applied',
              who: 'server',
              by: 'processTaxQueue',
              at: admin.firestore.FieldValue.serverTimestamp(),
              requestId: doc.id,
              summary: {
                country: determination.country,
                currency: determination.currency,
                taxRate: determination.taxRate,
                taxAmount: determination.taxAmount,
                total: determination.total,
              },
            }),

            // Clear any queued flags
            taxStatus: 'calculated',

            // Keep a copy of raw determination for later inspection
            lastDetermination: determination,
          };

          // Update entity and queue doc in same batch
          batch.update(entityRef, updateData);
          batch.update(reqRef, {
            processed: true,
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
            attempts: attempts + 1,
            lastResult: determination,
          });

          results.push({ reqId: doc.id, entity: req.entityPath, status: 'ok' });
          console.log(`[processTaxQueue] ✅ Processed tax for ${req.entityPath}`);
        } catch (err) {
          console.error(`[processTaxQueue] ❌ Error processing ${doc.id}:`, err);

          // Increment attempts and store lastError
          batch.update(reqRef, {
            attempts: attempts + 1,
            lastError: (err as Error).message || String(err),
            lastTriedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          results.push({
            reqId: doc.id,
            status: 'error',
            error: (err as Error).message || String(err),
          });
        }
      } // end for

      // Commit the batch
      await batch.commit();
      console.log('[processTaxQueue] Batch committed. Processed:', results.length);
      return { success: true, processed: results.length, details: results };
    } catch (outerErr) {
      console.error('[processTaxQueue] Fatal error', outerErr);
      // Do not throw to avoid crash loops; Cloud Scheduler will re-run on schedule.
      return {
        success: false,
        error: (outerErr as Error).message || String(outerErr),
      };
    }
  });
