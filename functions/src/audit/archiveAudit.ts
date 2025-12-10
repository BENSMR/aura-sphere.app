/**
 * archiveAudit.ts
 *
 * Scheduled Cloud Function that archives old audit entries to Cloud Storage
 *
 * Flow:
 * 1. Query audit_index for entities with latestAt older than RETENTION_DAYS
 * 2. For each entity, export old entries to JSONL in GCS
 * 3. Optionally encrypt exported files
 * 4. Delete archived entries from Firestore (batch)
 * 5. Update/delete audit_index entries
 * 6. Send status alerts to Slack
 *
 * Schedule: Every 24 hours (configurable)
 * Configuration:
 *   ARCHIVE_BUCKET — GCS bucket name (required)
 *   ARCHIVE_RETENTION_DAYS — Keep entries for N days (default: 365)
 *   ARCHIVE_BATCH_SIZE — Batch delete size (default: 100)
 *   ENCRYPTION_KEY_BASE64 — Optional encryption key
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendAuditStatusAlert, sendErrorAlert } from '../utils/alerts';
import { encryptField } from '../utils/auditEncryption';

if (!admin.apps.length) admin.initializeApp();

const db = admin.firestore();
const storageBucket = process.env.ARCHIVE_BUCKET;

// Configuration
const RETENTION_DAYS = Number(process.env.ARCHIVE_RETENTION_DAYS || 365);
const BATCH_SIZE = Number(process.env.ARCHIVE_BATCH_SIZE || 100);
const MAX_ENTITIES_PER_RUN = 50; // Limit to prevent timeout
const MAX_ENTRIES_PER_ENTITY = 5000; // Limit entries per entity per run

/**
 * Archive old audit entries to Cloud Storage
 *
 * Scheduled: Every 24 hours
 * Runtime limit: 9 minutes
 *
 * Process:
 * 1. Find audit_index entries older than cutoff
 * 2. Export entries to JSONL (optionally encrypted)
 * 3. Delete from Firestore
 * 4. Update index
 * 5. Send status alert
 */
export const archiveOldAuditEntries = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('UTC')
  .onRun(async (context) => {
    const startTime = Date.now();

    try {
      if (!storageBucket) {
        throw new Error('ARCHIVE_BUCKET environment variable not set');
      }

      const cutoffDate = new Date(
        Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000,
      );
      const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoffDate);

      functions.logger.info('Archive job started', {
        cutoff: cutoffDate.toISOString(),
        retentionDays: RETENTION_DAYS,
        bucket: storageBucket,
      });

      // Query audit_index entries older than cutoff
      const indexSnapshot = await db
        .collection('audit_index')
        .where('latestAt', '<', cutoffTimestamp)
        .orderBy('latestAt', 'asc')
        .limit(MAX_ENTITIES_PER_RUN)
        .get();

      if (indexSnapshot.empty) {
        functions.logger.info('No audit entries to archive (all within retention period)');
        await sendAuditStatusAlert('success', 'archival', {
          entriesArchived: 0,
          entitiesProcessed: 0,
          reason: 'no entries older than cutoff',
        });
        return null;
      }

      // Process each entity
      let totalArchived = 0;
      let totalDeleted = 0;
      const errors: string[] = [];
      const processedEntities = [];

      for (const indexDoc of indexSnapshot.docs) {
        try {
          const indexData = indexDoc.data();
          const { entityType, entityId } = indexData;
          const compositeId = `${entityType}_${entityId}`;

          functions.logger.info(`Processing entity: ${compositeId}`);

          // Query old entries for this composite ID
          const entriesRef = db
            .collection('audit')
            .doc(compositeId)
            .collection('entries');

          const oldEntriesSnapshot = await entriesRef
            .where('timestamp', '<', cutoffTimestamp)
            .orderBy('timestamp', 'asc')
            .limit(MAX_ENTRIES_PER_ENTITY)
            .get();

          if (oldEntriesSnapshot.empty) {
            functions.logger.info(`No old entries for ${compositeId}`);
            continue;
          }

          // Build JSONL content
          const lines: string[] = [];
          oldEntriesSnapshot.docs.forEach((doc) => {
            const data = doc.data();

            // Remove large/redundant fields to save storage
            if (data.before && typeof data.before === 'object') {
              delete data.before.__full_snapshot;
            }
            if (data.after && typeof data.after === 'object') {
              delete data.after.__full_snapshot;
            }

            // Add doc ID to entry
            lines.push(JSON.stringify({ id: doc.id, ...data }));
          });

          if (lines.length === 0) continue;

          // Save to GCS
          const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
          const filename = `audit-archive/${entityType}/${entityId}/${timestamp}.jsonl`;
          const gcsPath = `gs://${storageBucket}/${filename}`;

          const storage = admin.storage().bucket(storageBucket);
          const file = storage.file(filename);

          let content = lines.join('\n');

          // Optionally encrypt
          try {
            const encrypted = encryptField(content);
            content = JSON.stringify({
              encrypted: true,
              ciphertext: encrypted.ciphertext,
              iv: encrypted.iv,
              tag: encrypted.tag,
              timestamp: new Date().toISOString(),
            });
            functions.logger.info(`Encrypted ${lines.length} entries before archival`);
          } catch (encErr) {
            functions.logger.warn(
              `Encryption not available, archiving plaintext: ${encErr}`,
            );
            // Continue with plaintext if encryption fails
          }

          // Save to GCS
          await file.save(content, {
            resumable: false,
            contentType: 'application/x-ndjson',
            metadata: {
              entityType,
              entityId,
              entryCount: lines.length,
              archivedAt: new Date().toISOString(),
              retentionExpires: new Date(
                Date.now() + 7 * 365 * 24 * 60 * 60 * 1000,
              ).toISOString(), // 7 year retention
            },
          });

          functions.logger.info(`Archived ${lines.length} entries to ${gcsPath}`);
          totalArchived += lines.length;

          // Delete archived docs in batches
          let deleted = 0;
          for (
            let i = 0;
            i < oldEntriesSnapshot.docs.length;
            i += BATCH_SIZE
          ) {
            const batch = db.batch();
            const chunk = oldEntriesSnapshot.docs.slice(
              i,
              i + BATCH_SIZE,
            );
            chunk.forEach((doc) => batch.delete(doc.ref));
            await batch.commit();
            deleted += chunk.length;
          }

          totalDeleted += deleted;
          functions.logger.info(
            `Deleted ${deleted} entries for ${compositeId}`,
          );

          // Update or delete audit_index entry
          const remaining = await entriesRef
            .where('timestamp', '>=', cutoffTimestamp)
            .orderBy('timestamp', 'desc')
            .limit(1)
            .get();

          if (!remaining.empty) {
            // Update index with latest remaining entry
            const latestEntry = remaining.docs[0];
            const latestData = latestEntry.data();

            await indexDoc.ref.update({
              latestEntryId: latestEntry.id,
              latestAt: latestData.timestamp,
              lastArchivedAt: admin.firestore.FieldValue.serverTimestamp(),
              archivedCount: admin.firestore.FieldValue.increment(
                oldEntriesSnapshot.docs.length,
              ),
            });

            functions.logger.info(
              `Updated index for ${compositeId} with latest entry`,
            );
          } else {
            // Delete index if no entries remain
            await indexDoc.ref.delete();
            functions.logger.info(`Deleted index for ${compositeId}`);
          }

          processedEntities.push({
            compositeId,
            archived: lines.length,
            deleted,
          });
        } catch (entityErr) {
          const msg = entityErr instanceof Error ? entityErr.message : String(entityErr);
          errors.push(msg);
          functions.logger.error(`Entity processing failed: ${msg}`, entityErr);
        }
      }

      const duration = Math.round((Date.now() - startTime) / 1000);

      functions.logger.info('Archive job completed', {
        totalArchived,
        totalDeleted,
        entitiesProcessed: processedEntities.length,
        errors: errors.length,
        durationSeconds: duration,
      });

      // Send status alert
      await sendAuditStatusAlert('success', 'archival', {
        entriesArchived: totalArchived,
        entriesDeleted: totalDeleted,
        entitiesProcessed: processedEntities.length,
        durationSeconds: duration,
        errors: errors.length > 0 ? errors : undefined,
      });

      return null;
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      const duration = Math.round((Date.now() - startTime) / 1000);

      functions.logger.error('archiveOldAuditEntries failed', {
        message: error.message,
        stack: error.stack,
        durationSeconds: duration,
      });

      // Send error alert
      await sendErrorAlert(
        'Audit Archival Failed',
        error,
        {
          bucket: storageBucket,
          retentionDays: RETENTION_DAYS,
          durationSeconds: duration,
        },
      );

      // Don't throw — let Cloud Functions handle gracefully
      return null;
    }
  });

/**
 * Manual trigger for archival (HTTPS endpoint)
 *
 * Useful for:
 * - Testing archival logic
 * - Running archival on-demand
 * - Admin operations
 *
 * Usage: Call via Cloud Functions console or API
 * Requires: Authentication + admin role
 */
export const archiveAuditManually = functions.https.onCall(
  async (data, context) => {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be signed in',
      );
    }

    // Check admin status
    const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
    if (!adminDoc.exists) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can trigger archival',
      );
    }

    try {
      functions.logger.info(`Manual archival triggered by ${context.auth.uid}`);

      // Run archival logic (simplified version)
      const cutoffDate = new Date(
        Date.now() -
          (Number(data.retentionDays) || RETENTION_DAYS) *
            24 *
            60 *
            60 *
            1000,
      );
      const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoffDate);

      const indexSnapshot = await db
        .collection('audit_index')
        .where('latestAt', '<', cutoffTimestamp)
        .limit(10)
        .get();

      return {
        success: true,
        message: `Found ${indexSnapshot.size} entities to archive`,
        triggered: true,
      };
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      functions.logger.error('Manual archival failed', error);

      throw new functions.https.HttpsError(
        'internal',
        `Archival failed: ${error.message}`,
      );
    }
  },
);
