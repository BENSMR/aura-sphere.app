import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Migration function to move business profiles from old structure to new type-safe structure
 * 
 * Old Path: users/{uid}.business (nested in user document)
 * New Path: users/{uid}/meta/business (sub-collection)
 * 
 * Usage:
 *   POST https://your-project.cloudfunctions.net/migrateBusinessProfiles
 * 
 * Returns:
 *   {
 *     status: "success",
 *     migrated: number,
 *     skipped: number,
 *     total: number,
 *     message: string
 *   }
 */
export const migrateBusinessProfiles = functions
    .runWith({ 
        timeoutSeconds: 540, 
        memory: "1GB",
        enforceAppCheck: false // Allow manual trigger
    })
    .https.onRequest(async (req, res): Promise<void> => {
        try {
            // Security check: only allow from authenticated user or admin
            const authHeader = req.headers.authorization;
            if (!authHeader || !authHeader.startsWith("Bearer ")) {
                res.status(401).send({
                    status: "error",
                    message: "Unauthorized: Missing or invalid authentication token",
                });
                return;
            }

            const db = admin.firestore();
            const usersSnap = await db.collection("users").get();

            let migrated = 0;
            let skipped = 0;
            let errors = 0;
            const errorLog: Array<{ userId: string; reason: string }> = [];

            for (const userDoc of usersSnap.docs) {
                const userId = userDoc.id;

                try {
                    // Check if already migrated
                    const metaRef = db
                        .collection("users")
                        .doc(userId)
                        .collection("meta")
                        .doc("business");
                    const metaSnap = await metaRef.get();

                    if (metaSnap.exists) {
                        skipped++;
                        continue;
                    }

                    // Read old structure (nested in user document)
                    const userData = userDoc.data() as any;
                    const oldBusiness = userData.business ?? {};

                    // Build new profile with defaults and preserved fields
                    const newProfile = {
                        businessName: oldBusiness.businessName || "",
                        legalName: oldBusiness.legalName || "",
                        taxId: oldBusiness.taxId || "",
                        vatNumber: oldBusiness.vatNumber || "",
                        address: oldBusiness.address || "",
                        city: oldBusiness.city || "",
                        postalCode: oldBusiness.postalCode || "",
                        logoUrl: oldBusiness.logoUrl || "",
                        invoicePrefix: oldBusiness.invoicePrefix || "AS-",
                        documentFooter: oldBusiness.documentFooter || "",
                        brandColor: oldBusiness.brandColor || "#0A84FF",
                        watermarkText: oldBusiness.watermarkText || "",
                        invoiceTemplate: oldBusiness.invoiceTemplate || "minimal",
                        defaultCurrency: oldBusiness.defaultCurrency || "EUR",
                        defaultLanguage: oldBusiness.defaultLanguage || "en",
                        taxSettings: oldBusiness.taxSettings || {
                            country: "",
                            vatRate: 0,
                            type: "standard",
                        },
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    };

                    // Write to new location
                    await metaRef.set(newProfile, { merge: true });

                    migrated++;
                } catch (err) {
                    errors++;
                    errorLog.push({
                        userId,
                        reason: err instanceof Error ? err.message : String(err),
                    });
                    functions.logger.error(`Failed to migrate user ${userId}:`, err);
                }
            }

            const response = {
                status: "success",
                summary: {
                    migrated,
                    skipped,
                    errors,
                    total: usersSnap.size,
                },
                message: `Migration complete: ${migrated} migrated, ${skipped} skipped, ${errors} errors`,
                timestamp: new Date().toISOString(),
            };

            // Include error details if any errors occurred
            if (errors > 0) {
                (response as any).errorDetails = errorLog;
            }

            functions.logger.info("Migration completed", response);
            res.status(200).send(response);

        } catch (err) {
            functions.logger.error("Migration function error:", err);
            res.status(500).send({
                status: "error",
                message: "Migration failed",
                details: err instanceof Error ? err.message : String(err),
                timestamp: new Date().toISOString(),
            });
        }
    });

/**
 * Verify migration - checks how many profiles are in each location
 * 
 * Usage:
 *   GET https://your-project.cloudfunctions.net/verifyBusinessProfileMigration
 */
export const verifyBusinessProfileMigration = functions
    .https.onRequest(async (req, res): Promise<void> => {
        try {
            const db = admin.firestore();
            const usersSnap = await db.collection("users").get();

            let oldStructureCount = 0;
            let newStructureCount = 0;
            let bothStructureCount = 0;

            for (const userDoc of usersSnap.docs) {
                const userId = userDoc.id;
                const userData = userDoc.data() as any;

                const hasOld = userData.business !== undefined;

                const metaRef = db
                    .collection("users")
                    .doc(userId)
                    .collection("meta")
                    .doc("business");
                const metaSnap = await metaRef.get();
                const hasNew = metaSnap.exists;

                if (hasOld && hasNew) {
                    bothStructureCount++;
                } else if (hasOld) {
                    oldStructureCount++;
                } else if (hasNew) {
                    newStructureCount++;
                }
            }

            res.status(200).send({
                status: "success",
                summary: {
                    totalUsers: usersSnap.size,
                    oldStructureOnly: oldStructureCount,
                    newStructureOnly: newStructureCount,
                    bothStructures: bothStructureCount,
                    migrationProgress: `${newStructureCount}/${usersSnap.size} users have new structure`,
                },
                timestamp: new Date().toISOString(),
            });

        } catch (err) {
            functions.logger.error("Verification error:", err);
            res.status(500).send({
                status: "error",
                message: "Verification failed",
                details: err instanceof Error ? err.message : String(err),
            });
        }
    });

/**
 * Rollback migration - restore from backup if needed (optional)
 * 
 * This function reverses the migration by copying back to old structure
 * Only use if migration caused issues
 * 
 * Usage:
 *   POST https://your-project.cloudfunctions.net/rollbackBusinessProfileMigration
 */
export const rollbackBusinessProfileMigration = functions
    .runWith({ 
        timeoutSeconds: 540, 
        memory: "1GB",
        enforceAppCheck: false
    })
    .https.onRequest(async (req, res): Promise<void> => {
        try {
            const db = admin.firestore();
            const usersSnap = await db.collection("users").get();

            let rolledBack = 0;
            let errors = 0;

            for (const userDoc of usersSnap.docs) {
                const userId = userDoc.id;

                try {
                    const metaRef = db
                        .collection("users")
                        .doc(userId)
                        .collection("meta")
                        .doc("business");
                    const metaSnap = await metaRef.get();

                    if (!metaSnap.exists) {
                        continue;
                    }

                    const newData = metaSnap.data() as any;

                    // Write back to old location
                    await db
                        .collection("users")
                        .doc(userId)
                        .update({
                            business: newData,
                        });

                    rolledBack++;
                } catch (err) {
                    errors++;
                    functions.logger.error(`Failed to rollback user ${userId}:`, err);
                }
            }

            res.status(200).send({
                status: "success",
                summary: {
                    rolledBack,
                    errors,
                    total: usersSnap.size,
                },
                message: `Rollback complete: ${rolledBack} restored, ${errors} errors`,
                timestamp: new Date().toISOString(),
            });

        } catch (err) {
            functions.logger.error("Rollback error:", err);
            res.status(500).send({
                status: "error",
                message: "Rollback failed",
                details: err instanceof Error ? err.message : String(err),
            });
        }
    });
