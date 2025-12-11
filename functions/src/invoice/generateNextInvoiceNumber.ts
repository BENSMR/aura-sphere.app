import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();

/**
 * generateNextInvoiceNumber
 *
 * Callable function that allocates a unique invoice number and writes an audit record.
 * Input: optional { context: { <any> } } - arbitrary metadata to store in audit record (e.g. "source": "mobile", "projectId": "...").
 * Auth: required
 *
 * Writes:
 *   - updates /users/{uid}/settings/invoice_settings.nextNumber (atomic)
 *   - writes an audit doc at /users/{uid}/invoice_sequence/{autoId}
 *
 * Returns: { invoiceNumber, number, nextNumber }
 */
export const generateNextInvoiceNumber = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  const uid = context.auth.uid;
  const db = admin.firestore();
  const settingsRef = db.collection('users').doc(uid).collection('settings').doc('invoice_settings');

  return await db.runTransaction(async (tx) => {
    const snap = await tx.get(settingsRef);
    const nowTs = admin.firestore.Timestamp.now();

    // Defaults
    let prefix = 'AURA-';
    let nextNumber = 1000;
    let resetRule: 'none' | 'monthly' | 'yearly' = 'none';
    let lastReset: admin.firestore.Timestamp | null = null;

    if (snap.exists) {
      const sdata = snap.data() as any;
      if (sdata.prefix) prefix = String(sdata.prefix);
      if (typeof sdata.nextNumber === 'number') nextNumber = sdata.nextNumber;
      if (sdata.resetRule) resetRule = sdata.resetRule;
      if (sdata.lastReset) lastReset = sdata.lastReset;
    } else {
      // initialize defaults (only if missing)
      tx.set(settingsRef, { prefix, nextNumber, resetRule, lastReset: null }, { merge: true });
    }

    // Determine reset behavior
    const shouldReset = (() => {
      if (resetRule === 'none') return false;
      if (!lastReset) return true;
      const last = lastReset.toDate();
      const current = new Date();
      if (resetRule === 'yearly') {
        return current.getFullYear() !== last.getFullYear();
      } else if (resetRule === 'monthly') {
        return current.getFullYear() !== last.getFullYear() || current.getMonth() !== last.getMonth();
      }
      return false;
    })();

    if (shouldReset) {
      // Reset to 1 (or change this base if you prefer)
      nextNumber = 1;
      tx.set(settingsRef, { nextNumber, lastReset: nowTs }, { merge: true });
    }

    // Allocate current number and increment
    const currentNumber = nextNumber;
    const incremented = nextNumber + 1;
    tx.set(settingsRef, { nextNumber: incremented }, { merge: true });

    // Format invoice number string
    const pad = (n: number, width: number) => String(n).padStart(width, '0');
    let formatted = `${prefix}${pad(currentNumber, 4)}`;
    if (resetRule === 'yearly') {
      const year = new Date().getFullYear();
      formatted = `${prefix}${year}-${pad(currentNumber, 4)}`;
    } else if (resetRule === 'monthly') {
      const nowDate = new Date();
      const y = nowDate.getFullYear();
      const m = String(nowDate.getMonth() + 1).padStart(2, '0');
      formatted = `${prefix}${y}${m}-${pad(currentNumber, 3)}`;
    }

    // Write audit record inside the transaction for atomicity
    const auditRef = db.collection('users').doc(uid).collection('invoice_sequence').doc();
    const auditPayload: any = {
      invoiceNumber: formatted,
      number: currentNumber,
      allocatedAt: nowTs,
      allocatedBy: uid,
      context: data?.context || null,
      invoiceId: data?.invoiceId || null
    };
    tx.set(auditRef, auditPayload);

    return { invoiceNumber: formatted, number: currentNumber, nextNumber: incremented };
  });
});
