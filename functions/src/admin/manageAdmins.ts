/**
 * manageAdmins.ts
 *
 * Cloud Functions for admin user management
 *
 * Endpoints:
 * - grantAdminRole(uid) — Grant admin access to user
 * - revokeAdminRole(uid) — Remove admin access
 * - listAdmins() — List all admin users
 * - getAdminStatus(uid) — Check if user is admin
 *
 * Authentication: Only existing admins can call these functions
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const auth = admin.auth();

/**
 * Check if caller is admin
 */
async function isCallerAdmin(uid: string): Promise<boolean> {
  try {
    const doc = await db.collection('admins').doc(uid).get();
    return doc.exists;
  } catch (e) {
    console.error('isCallerAdmin error:', e);
    return false;
  }
}

/**
 * Grant admin role to a user
 *
 * Callable: admin users only
 * Params: { targetUid: string }
 *
 * Does two things:
 * 1. Creates document in /admins/{uid}
 * 2. Sets custom claim admin: true in auth token
 */
export const grantAdminRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }

  const callerUid = context.auth.uid;
  const targetUid = data.targetUid as string;

  if (!targetUid) {
    throw new functions.https.HttpsError('invalid-argument', 'targetUid is required');
  }

  // Check if caller is admin
  const callerIsAdmin = await isCallerAdmin(callerUid);
  if (!callerIsAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can grant admin role');
  }

  try {
    // Create admin document
    await db.collection('admins').doc(targetUid).set(
      {
        uid: targetUid,
        grantedAt: admin.firestore.FieldValue.serverTimestamp(),
        grantedBy: callerUid,
      },
      { merge: true }
    );

    // Set custom claim
    await auth.setCustomUserClaims(targetUid, { admin: true });

    console.log(`[admin] ${targetUid} granted admin role by ${callerUid}`);

    return { success: true, message: `Admin role granted to ${targetUid}` };
  } catch (err) {
    console.error('grantAdminRole error:', err);
    throw new functions.https.HttpsError('internal', `Error: ${err}`);
  }
});

/**
 * Revoke admin role from a user
 *
 * Callable: admin users only
 * Params: { targetUid: string }
 *
 * Does two things:
 * 1. Deletes document from /admins/{uid}
 * 2. Removes custom claim from auth token
 */
export const revokeAdminRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }

  const callerUid = context.auth.uid;
  const targetUid = data.targetUid as string;

  if (!targetUid) {
    throw new functions.https.HttpsError('invalid-argument', 'targetUid is required');
  }

  // Prevent self-removal (safety check)
  if (callerUid === targetUid) {
    throw new functions.https.HttpsError('failed-precondition', 'Cannot revoke your own admin role');
  }

  // Check if caller is admin
  const callerIsAdmin = await isCallerAdmin(callerUid);
  if (!callerIsAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can revoke admin role');
  }

  try {
    // Delete admin document
    await db.collection('admins').doc(targetUid).delete();

    // Remove custom claim
    await auth.setCustomUserClaims(targetUid, { admin: false });

    console.log(`[admin] ${targetUid} admin role revoked by ${callerUid}`);

    return { success: true, message: `Admin role revoked for ${targetUid}` };
  } catch (err) {
    console.error('revokeAdminRole error:', err);
    throw new functions.https.HttpsError('internal', `Error: ${err}`);
  }
});

/**
 * List all admin users
 *
 * Callable: admin users only
 * Returns: List of admin UIDs with metadata
 */
export const listAdmins = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }

  const callerUid = context.auth.uid;

  // Check if caller is admin
  const callerIsAdmin = await isCallerAdmin(callerUid);
  if (!callerIsAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can list admins');
  }

  try {
    const adminsSnap = await db.collection('admins').get();
    const admins = adminsSnap.docs.map((doc) => ({
      uid: doc.id,
      ...doc.data(),
    }));

    return { success: true, admins, count: admins.length };
  } catch (err) {
    console.error('listAdmins error:', err);
    throw new functions.https.HttpsError('internal', `Error: ${err}`);
  }
});

/**
 * Get admin status for a user
 *
 * Callable: any authenticated user (but only admins see all users)
 * Params: { targetUid: string }
 * Returns: { isAdmin: boolean }
 */
export const getAdminStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }

  const targetUid = data.targetUid as string;

  if (!targetUid) {
    throw new functions.https.HttpsError('invalid-argument', 'targetUid is required');
  }

  try {
    const doc = await db.collection('admins').doc(targetUid).get();
    const isAdmin = doc.exists;

    return { success: true, uid: targetUid, isAdmin };
  } catch (err) {
    console.error('getAdminStatus error:', err);
    throw new functions.https.HttpsError('internal', `Error: ${err}`);
  }
});

/**
 * Boost: Get current user's admin status
 *
 * Callable: any authenticated user
 * Returns: { isAdmin: boolean }
 */
export const getMyAdminStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }

  const uid = context.auth.uid;

  try {
    const doc = await db.collection('admins').doc(uid).get();
    const isAdmin = doc.exists;

    return { success: true, isAdmin };
  } catch (err) {
    console.error('getMyAdminStatus error:', err);
    throw new functions.https.HttpsError('internal', `Error: ${err}`);
  }
});

/**
 * Migration: Set first admin (only if no admins exist)
 *
 * HTTP trigger - call once during setup
 * Query: ?uid=USER_UID&code=SETUP_CODE
 *
 * Usage:
 * ```
 * curl -X POST https://us-central1-project.cloudfunctions.net/setFirstAdmin \
 *   -H "Content-Type: application/json" \
 *   -d '{"uid": "user123", "setupCode": "INITIAL_SETUP_CODE"}'
 * ```
 */
export const setFirstAdmin = functions.https.onRequest(async (req, res) => {
  // Require POST
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const uid = req.body.uid as string;
  const setupCode = req.body.setupCode as string;

  // Verify setup code (should be a strong secret)
  const expectedSetupCode = process.env.SETUP_CODE || 'CHANGE_ME_IN_ENV';
  if (setupCode !== expectedSetupCode) {
    res.status(403).json({ error: 'Invalid setup code' });
    return;
  }

  // Check if any admins already exist
  try {
    const adminsSnap = await db.collection('admins').limit(1).get();
    if (!adminsSnap.empty) {
      res.status(409).json({ error: 'Admins already exist. Use grantAdminRole instead.' });
      return;
    }

    // Create first admin
    await db.collection('admins').doc(uid).set({
      uid,
      isFirstAdmin: true,
      grantedAt: admin.firestore.FieldValue.serverTimestamp(),
      grantedBy: 'system:setup',
    });

    // Set custom claim
    await auth.setCustomUserClaims(uid, { admin: true });

    console.log(`[admin] ${uid} set as first admin via setup`);

    res.status(200).json({
      success: true,
      message: `${uid} is now an admin`,
    });
  } catch (err) {
    console.error('setFirstAdmin error:', err);
    res.status(500).json({ error: `Error: ${err}` });
  }
});
