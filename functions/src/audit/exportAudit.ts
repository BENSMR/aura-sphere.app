import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { stringify } from 'csv-stringify/sync';
import { sendAlert } from '../utils/alerts';

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const storageBucket = admin.storage().bucket(process.env.ARCHIVE_BUCKET);
const SIGNED_URL_EXPIRATION = Number(process.env.SIGNED_URL_EXPIRATION_SECONDS || 3600);

async function verifyAdminFromRequest(req: functions.https.Request) {
  const authHeader = req.headers.authorization || '';
  if (!authHeader.startsWith('Bearer ')) throw new functions.https.HttpsError('unauthenticated', 'Missing auth token');
  const idToken = authHeader.split('Bearer ')[1];
  const decoded = await admin.auth().verifyIdToken(idToken);
  if (!decoded.admin) throw new functions.https.HttpsError('permission-denied', 'Admin claim required');
  return decoded;
}

export const exportAudit = functions.https.onRequest(async (req, res) => {
  try {
    // Only POST
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    const user = await verifyAdminFromRequest(req);
    const { entityType, entityId, startDate, endDate, format } = req.body;

    if (!entityType) throw new functions.https.HttpsError('invalid-argument', 'entityType required');

    // Build range query
    const start = startDate ? new Date(startDate) : new Date(0);
    const end = endDate ? new Date(endDate) : new Date();

    const compositeId = entityId ? `${entityType}_${entityId}` : null;

    let docs: FirebaseFirestore.QueryDocumentSnapshot[] = [];

    if (compositeId) {
      const snap = await db.collection('audit').doc(compositeId).collection('entries')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(start))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(end))
        .orderBy('timestamp', 'asc')
        .get();
      docs = snap.docs;
    } else {
      // If no entityId provided, use collectionGroup query (may be slow)
      const snap = await db.collectionGroup('entries')
        .where('entityType', '==', entityType)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(start))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(end))
        .orderBy('timestamp', 'asc')
        .limit(5000) // cap
        .get();
      docs = snap.docs;
    }

    if (docs.length === 0) {
      res.status(200).json({ ok: true, url: null, message: 'No entries found' });
      return;
    }

    // Build payload
    const rows = docs.map(d => {
      const data = d.data();
      return {
        id: d.id,
        timestamp: data.timestamp?.toDate?.()?.toISOString?.() || null,
        actor_uid: data.actor?.uid || null,
        action: data.action || null,
        entityType: data.entityType || null,
        entityId: data.entityId || null,
        summary: JSON.stringify({
          before: data.before || null,
          after: data.after || null,
          meta: data.meta || null
        })
      };
    });

    const now = Date.now();
    const filename = `audit-exports/${entityType}/${entityId || 'all'}/${now}.${format === 'csv' ? 'csv' : 'json'}`;
    const file = storageBucket.file(filename);

    if (format === 'csv') {
      const csv = stringify(rows, { header: true });
      await file.save(csv, { resumable: false, contentType: 'text/csv' });
    } else {
      // JSON array
      await file.save(JSON.stringify(rows, null, 2), { resumable: false, contentType: 'application/json' });
    }

    // generate signed url
    const [url] = await file.getSignedUrl({ action: 'read', expires: Date.now() + SIGNED_URL_EXPIRATION * 1000 });

    functions.logger.info(`Audit export ${filename} created by ${user.uid}`);
    res.status(200).json({ ok: true, url, filename, count: rows.length });
  } catch (err: any) {
    functions.logger.error('exportAudit error', err);
    await sendAlert('Audit export failed', `exportAudit failed: ${err?.message || err}`, { body: req.body });
    if (err instanceof functions.https.HttpsError) {
      res.status(400).json({ ok: false, message: err.message });
    } else {
      res.status(500).json({ ok: false, message: 'Internal error' });
    }
  }
});
