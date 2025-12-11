// functions/src/audit/anomalyScanner.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendSecurityAlert } from "../utils/alerts";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

/**
 * Anomaly scanner
 * - Scheduled every 6 hours (configurable)
 * - Uses heuristic rules to detect unusual patterns in invoices, expenses, inventory, and audit logs
 * - Writes anomalies to collection "anomalies/{id}"
 * - Sends Slack alert for high/critical severities
 *
 * Heuristics are intentionally simple and auditable:
 * - Amount compared to moving average for same vendor/user
 * - Duplicate invoice detection (same amount+vendor within short window)
 * - Rapid edit rate in audit logs for same entity
 * - Negative or large stock movements
 * - Unusual tax percentage for country (if tax field exists)
 *
 * This function is safe to run on production: it uses limits and batching.
 */

type Severity = "low" | "medium" | "high" | "critical";

const WINDOW_HOURS = Number(process.env.ANOMALY_WINDOW_HOURS || 72);
const MAX_DOCS = Number(process.env.ANOMALY_MAX_DOCS_PER_COLLECTION || 500);
const SLACK_THRESHOLD = Number(process.env.ANOMALY_SLACK_THRESHOLD || 2);
const DEBUG = process.env.ANOMALY_DEBUG === "true";

function severityToScore(s: Severity) {
  switch (s) {
    case "low": return 1;
    case "medium": return 2;
    case "high": return 3;
    case "critical": return 4;
  }
}

/** Utilities */
function chooseSeverity(score: number): Severity {
  if (score >= 9) return "critical";
  if (score >= 6) return "high";
  if (score >= 3) return "medium";
  return "low";
}

/** Heuristic scoring functions (explainable) */

/**
 * Score invoice by comparing amount to user's recent average for same vendor or same item.
 * Returns numeric points.
 */
async function scoreInvoice(doc: FirebaseFirestore.DocumentSnapshot): Promise<{score:number, reasons:string[]}> {
  const data = doc.data() as any;
  const reasons: string[] = [];
  let score = 0;

  if (!data) return { score, reasons };

  // 1) Large invoice (absolute threshold)
  const AMOUNT_CRITICAL = 50000; // currency units - tune per-market
  const AMOUNT_HIGH = 20000;
  if (data.amount >= AMOUNT_CRITICAL) { score += 5; reasons.push(`amount >= ${AMOUNT_CRITICAL}`); }
  else if (data.amount >= AMOUNT_HIGH) { score += 3; reasons.push(`amount >= ${AMOUNT_HIGH}`); }

  // 2) Relative to user's moving average (past WINDOW)
  try {
    const ownerId = data.ownerId || data.userId || data.uid;
    if (ownerId) {
      const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - WINDOW_HOURS * 3600 * 1000);
      const q = db.collectionGroup("invoices")
        .where("ownerId", "==", ownerId)
        .where("createdAt", ">=", cutoff)
        .orderBy("createdAt", "desc")
        .limit(50);
      const snap = await q.get();
      if (!snap.empty) {
        let sum = 0, cnt = 0;
        snap.docs.forEach(d => {
          const v = (d.data() as any).amount;
          if (typeof v === "number") { sum += v; cnt++; }
        });
        const avg = cnt > 0 ? sum / cnt : 0;
        if (avg > 0 && data.amount > avg * 4) {
          score += 4; reasons.push(`amount > 4x recent avg (${Math.round(avg)})`);
        } else if (avg > 0 && data.amount > avg * 2) {
          score += 2; reasons.push(`amount > 2x recent avg (${Math.round(avg)})`);
        }
      }
    }
  } catch (e) { if (DEBUG) console.warn("scoreInvoice avg failed", e); }

  // 3) Duplicate invoice detection: same vendor + amount within short window
  try {
    const vendor = data.vendor || data.supplier;
    if (vendor) {
      const cutoff2 = admin.firestore.Timestamp.fromMillis(Date.now() - 24 * 3600 * 1000);
      const dupQ = db.collectionGroup("invoices")
        .where("vendor", "==", vendor)
        .where("amount", "==", data.amount)
        .where("createdAt", ">=", cutoff2)
        .limit(5);
      const dupSnap = await dupQ.get();
      if (dupSnap.size >= 2) {
        score += 4; reasons.push(`duplicate invoices (${dupSnap.size}) for vendor ${vendor}`);
      }
    }
  } catch (e) { if (DEBUG) console.warn("dup check fail", e); }

  // 4) Tax mismatch heuristics (if taxRate present)
  if (typeof data.taxRate === "number") {
    if (data.taxRate === 0 && (data.country && data.country !== "US")) {
      score += 1; reasons.push(`zero tax for country ${data.country}`);
    } else if (data.taxRate > 50) {
      score += 3; reasons.push(`unusually high tax ${data.taxRate}%`);
    }
  }

  return { score, reasons };
}

async function scoreExpense(doc: FirebaseFirestore.DocumentSnapshot): Promise<{score:number,reasons:string[]}> {
  const data = doc.data() as any;
  const reasons: string[] = [];
  let score = 0;
  if (!data) return { score, reasons };

  // absolute thresholds
  if (data.amount >= 20000) { score += 4; reasons.push("expense amount >= 20k"); }
  else if (data.amount >= 5000) { score += 2; reasons.push("expense amount >= 5k"); }

  // frequency: same merchant multiple times
  try {
    const merchant = data.merchant || data.vendor;
    if (merchant) {
      const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - WINDOW_HOURS * 3600 * 1000);
      const q = db.collectionGroup("expenses")
        .where("merchant", "==", merchant)
        .where("createdAt", ">=", cutoff)
        .limit(20);
      const snap = await q.get();
      if (snap.size >= 6) { score += 3; reasons.push(`high frequency for merchant ${merchant}: ${snap.size}`); }
    }
  } catch (e) { if (DEBUG) console.warn("expense freq fail", e); }

  // suspicious attachments or mismatched categories
  if (data.category && data.category === "travel" && data.amount > 3000) { score += 1; reasons.push("large travel expense"); }

  return { score, reasons };
}

async function scoreInventory(doc: FirebaseFirestore.DocumentSnapshot): Promise<{score:number,reasons:string[]}> {
  const data = doc.data() as any;
  const reasons: string[] = [];
  let score = 0;
  if (!data) return { score, reasons };

  // negative qty or very large adjustments
  if (typeof data.quantity === "number") {
    if (data.quantity < 0) { score += 4; reasons.push("negative quantity"); }
    else if (data.quantity > 1000) { score += 2; reasons.push("large addition >1000"); }
  }

  // check recent movements for same SKU
  try {
    const sku = data.sku || data.code;
    if (sku) {
      const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - WINDOW_HOURS * 3600 * 1000);
      const q = db.collectionGroup("inventory")
        .where("sku", "==", sku)
        .where("updatedAt", ">=", cutoff)
        .limit(50);
      const snap = await q.get();
      if (snap.size >= 20) { score += 3; reasons.push(`high movement for SKU ${sku}: ${snap.size}`); }
    }
  } catch (e) { if (DEBUG) console.warn("inventory freq fail", e); }

  return { score, reasons };
}

async function scoreAuditActivity(doc: FirebaseFirestore.DocumentSnapshot): Promise<{score:number,reasons:string[]}> {
  const data = doc.data() as any;
  const reasons: string[] = [];
  let score = 0;
  if (!data) return { score, reasons };

  // rapid edits: many audit entries for same entity in short time
  try {
    const entType = data.entityType;
    const entId = data.entityId;
    if (entType && entId) {
      const comp = `${entType}_${entId}`;
      const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - 2 * 3600 * 1000); // 2 hours
      const snap = await db.collection("audit").doc(comp).collection("entries")
        .where("timestamp", ">=", cutoff)
        .get();
      if (snap.size >= 10) { score += 4; reasons.push(`rapid edits ${snap.size} in 2h`); }
      else if (snap.size >= 5) { score += 2; reasons.push(`multiple edits ${snap.size} in 2h`); }
    }
  } catch (e) { if (DEBUG) console.warn("audit freq fail", e); }

  // suspicious actor (anonymous or new)
  const actorUid = data.actor?.uid;
  if (!actorUid) { score += 2; reasons.push("actor missing or anonymous"); }

  return { score, reasons };
}

/** Main scheduled function - runs every 6 hours */
export const anomalyScanner = functions.pubsub.schedule("every 6 hours").onRun(async (context) => {
  const runId = `anomaly-${Date.now()}`;
  functions.logger.info(`[${runId}] Starting anomaly scan; window_hours=${WINDOW_HOURS}, max_docs=${MAX_DOCS}`);

  const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - WINDOW_HOURS * 3600 * 1000);

  try {
    // 1) Scan invoices (collectionGroup)
    const invoiceQuery = db.collectionGroup("invoices")
      .where("createdAt", ">=", cutoff)
      .orderBy("createdAt", "desc")
      .limit(MAX_DOCS);
    const invoiceSnap = await invoiceQuery.get();
    functions.logger.info(`[${runId}] scanned invoices: ${invoiceSnap.size}`);

    for (const doc of invoiceSnap.docs) {
      try {
        const { score, reasons } = await scoreInvoice(doc);
        if (score <= 0) continue;
        const sev = chooseSeverity(score);
        const severityScore = severityToScore(sev);
        const entity = doc.data();
        const anomaly = {
          runId,
          entityType: "invoice",
          entityId: doc.id,
          owner: (entity as any).ownerId || (entity as any).userId || null,
          score,
          severity: sev,
          reasons,
          recommendedAction: generateInvoiceRecommendation(score, reasons),
          sample: pickInvoiceSample(entity),
          detectedAt: admin.firestore.Timestamp.now(),
        };
        await writeAnomalyRecord(anomaly);
        if (severityScore >= SLACK_THRESHOLD) {
          await sendSecurityAlert("Anomaly detected (invoice)", `ID: ${doc.id}\nSeverity: ${sev}\nReasons: ${reasons.join("; ")}`, { severity: sev });
        }
      } catch (e) {
        functions.logger.error(`[${runId}] invoice processing error`, e);
      }
    }

    // 2) Scan expenses
    const expenseQuery = db.collectionGroup("expenses")
      .where("createdAt", ">=", cutoff)
      .orderBy("createdAt", "desc")
      .limit(MAX_DOCS);
    const expenseSnap = await expenseQuery.get();
    functions.logger.info(`[${runId}] scanned expenses: ${expenseSnap.size}`);

    for (const doc of expenseSnap.docs) {
      try {
        const { score, reasons } = await scoreExpense(doc);
        if (score <= 0) continue;
        const sev = chooseSeverity(score);
        const severityScore = severityToScore(sev);
        const entity = doc.data();
        const anomaly = {
          runId,
          entityType: "expense",
          entityId: doc.id,
          owner: (entity as any).ownerId || (entity as any).userId || null,
          score,
          severity: sev,
          reasons,
          recommendedAction: generateExpenseRecommendation(score, reasons),
          sample: pickExpenseSample(entity),
          detectedAt: admin.firestore.Timestamp.now(),
        };
        await writeAnomalyRecord(anomaly);
        if (severityScore >= SLACK_THRESHOLD) {
          await sendSecurityAlert("Anomaly detected (expense)", `ID: ${doc.id}\nSeverity: ${sev}\nReasons: ${reasons.join("; ")}`, { severity: sev });
        }
      } catch (e) {
        functions.logger.error(`[${runId}] expense processing error`, e);
      }
    }

    // 3) Scan inventory changes (recent items/updates)
    const inventoryQuery = db.collectionGroup("inventory")
      .where("updatedAt", ">=", cutoff)
      .orderBy("updatedAt", "desc")
      .limit(MAX_DOCS);
    const invSnap = await inventoryQuery.get();
    functions.logger.info(`[${runId}] scanned inventory: ${invSnap.size}`);

    for (const doc of invSnap.docs) {
      try {
        const { score, reasons } = await scoreInventory(doc);
        if (score <= 0) continue;
        const sev = chooseSeverity(score);
        const severityScore = severityToScore(sev);
        const entity = doc.data();
        const anomaly = {
          runId,
          entityType: "inventory",
          entityId: doc.id,
          owner: (entity as any).ownerId || (entity as any).userId || null,
          score,
          severity: sev,
          reasons,
          recommendedAction: generateInventoryRecommendation(score, reasons),
          sample: pickInventorySample(entity),
          detectedAt: admin.firestore.Timestamp.now(),
        };
        await writeAnomalyRecord(anomaly);
        if (severityScore >= SLACK_THRESHOLD) {
          await sendSecurityAlert("Anomaly detected (inventory)", `ID: ${doc.id}\nSeverity: ${sev}\nReasons: ${reasons.join("; ")}`, { severity: sev });
        }
      } catch (e) {
        functions.logger.error(`[${runId}] inventory processing error`, e);
      }
    }

    // 4) Scan audit entries for rapid edits / suspicious patterns
    const auditIndexQuery = db.collection("audit_index")
      .where("latestAt", ">=", cutoff)
      .orderBy("latestAt", "desc")
      .limit(MAX_DOCS);
    const auditIndexSnap = await auditIndexQuery.get();
    functions.logger.info(`[${runId}] scanned audit_index: ${auditIndexSnap.size}`);

    for (const idxDoc of auditIndexSnap.docs) {
      try {
        const d = idxDoc.data();
        // build a fake doc structure to feed scoring
        const latestSnap = await db.collection("audit").doc(`${d.entityType}_${d.entityId}`).collection("entries").doc(d.latestEntryId).get();
        if (!latestSnap.exists) continue;
        const { score, reasons } = await scoreAuditActivity(latestSnap);
        if (score <= 0) continue;
        const sev = chooseSeverity(score);
        const severityScore = severityToScore(sev);
        const anomaly = {
          runId,
          entityType: "audit",
          entityId: `${d.entityType}_${d.entityId}`,
          owner: null,
          score,
          severity: sev,
          reasons,
          recommendedAction: generateAuditRecommendation(score, reasons),
          sample: { index: d, latest: latestSnap.data() },
          detectedAt: admin.firestore.Timestamp.now(),
        };
        await writeAnomalyRecord(anomaly);
        if (severityScore >= SLACK_THRESHOLD) {
          await sendSecurityAlert("Anomaly detected (audit)", `Entity: ${anomaly.entityId}\nSeverity: ${sev}\nReasons: ${reasons.join("; ")}`, { severity: sev });
        }
      } catch (e) {
        functions.logger.error(`[${runId}] audit index processing error`, e);
      }
    }

    functions.logger.info(`[${runId}] Anomaly scan complete.`);
    return null;
  } catch (err) {
    functions.logger.error(`[${runId}] Anomaly scanner failed`, err);
    await sendSecurityAlert("Anomaly Scanner Failure", `Error: ${err instanceof Error ? err.message : String(err)}`, { severity: "critical" });
    return null;
  }
});

/** Helper: write anomaly with minimal searchable fields */
async function writeAnomalyRecord(payload: any): Promise<string> {
  try {
    const ref = db.collection("anomalies").doc();
    const doc = {
      entityType: payload.entityType,
      entityId: payload.entityId,
      owner: payload.owner || null,
      score: payload.score,
      severity: payload.severity,
      reasons: payload.reasons,
      recommendedAction: payload.recommendedAction,
      sample: payload.sample || null,
      runId: payload.runId,
      detectedAt: payload.detectedAt || admin.firestore.Timestamp.now(),
      acknowledged: false,
    };
    await ref.set(doc);
    return ref.id;
  } catch (e) {
    functions.logger.error("writeAnomalyRecord failed", e);
    throw e;
  }
}

/** Small helpers to pick sample fields for listing */
function pickInvoiceSample(entity: any) {
  return {
    number: entity.number || entity.invoiceNumber || null,
    amount: entity.amount || null,
    currency: entity.currency || null,
    vendor: entity.vendor || entity.supplier || null,
    createdAt: entity.createdAt || null
  };
}

function pickExpenseSample(entity: any) {
  return {
    merchant: entity.merchant || entity.vendor || null,
    amount: entity.amount || null,
    category: entity.category || null,
    createdAt: entity.createdAt || null
  };
}

function pickInventorySample(entity: any) {
  return {
    sku: entity.sku || entity.code || null,
    quantity: entity.quantity || null,
    location: entity.location || null,
    updatedAt: entity.updatedAt || null
  };
}

/** Recommendation generators (explainable suggestions) */
function generateInvoiceRecommendation(score: number, reasons: string[]): string {
  if (score >= 9) return "Hold payment; review invoice and vendor KYC; confirm with client.";
  if (score >= 6) return "Flag for finance review; request verification from vendor.";
  if (score >= 3) return "Notify account owner and request quick confirmation.";
  return "No action required.";
}

function generateExpenseRecommendation(score: number, reasons: string[]): string {
  if (score >= 7) return "Trigger expense approval workflow; require receipts & manager sign-off.";
  if (score >= 4) return "Send alert to owner; request justification.";
  return "No action required.";
}

function generateInventoryRecommendation(score: number, reasons: string[]): string {
  if (score >= 7) return "Run physical stock check and freeze shipments for this SKU.";
  if (score >= 4) return "Notify inventory manager and verify incoming/outgoing logs.";
  return "No action required.";
}

function generateAuditRecommendation(score: number, reasons: string[]): string {
  if (score >= 7) return "Lock entity for edits and escalate to security operations.";
  if (score >= 4) return "Require re-authentication and audit the recent editor's activity.";
  return "Monitor the activity.";
}
