/**
 * Cloud Function: Setup User Role
 * 
 * Responsible for:
 * 1. Setting custom claims on user authentication
 * 2. Storing role in Firestore
 * 3. Initializing role-based permissions
 * 
 * Triggered by:
 * - User creation (onUserCreate)
 * - Admin role assignment (onCall)
 */

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

// Initialize Firebase Admin SDK
admin.initializeApp();

const auth = admin.auth();
const firestore = admin.firestore();

/**
 * Cloud Function: Triggered on user creation
 * Sets default 'owner' role and custom claims
 * 
 * @param user - Firebase Auth user object
 */
export const onUserCreate = functions
  .region('us-central1')
  .auth.user()
  .onCreate(async (user) => {
    try {
      console.log(`Creating new user: ${user.uid}`, {
        email: user.email,
        provider: user.providerData.map((p) => p.providerId),
      });

      // Set custom claims with default 'owner' role
      // NOTE: Change to 'employee' for employee sign-ups
      await auth.setCustomUserClaims(user.uid, {
        role: 'owner', // Default role
        createdAt: new Date().toISOString(),
      });

      console.log(`Custom claims set for user: ${user.uid}`, {
        role: 'owner',
      });

      // Create user document in Firestore
      const userDocRef = firestore.collection('users').doc(user.uid);

      await userDocRef.set(
        {
          role: 'owner',
          email: user.email,
          displayName: user.displayName || '',
          photoURL: user.photoURL || '',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          lastSignIn: admin.firestore.FieldValue.serverTimestamp(),
          status: 'active',
        },
        { merge: true }
      );

      console.log(`User document created: ${user.uid}`, {
        path: `users/${user.uid}`,
      });

      // Initialize user subcollections
      await initializeUserCollections(user.uid);

      console.log(`User setup complete: ${user.uid}`);
    } catch (error) {
      console.error(`Error creating user ${user.uid}:`, error);
      throw error;
    }
  });

/**
 * Cloud Function: Callable function to assign role to user
 * 
 * Security: Requires user to be admin
 * 
 * Parameters:
 * - targetUid: UID of user to assign role
 * - role: 'owner' or 'employee'
 * 
 * Returns:
 * - success: boolean
 * - message: string
 * - user: Updated user document
 */
export const assignUserRole = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    try {
      // Verify caller is authenticated
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const callerId = context.auth.uid;
      const { targetUid, role } = data;

      // Validate inputs
      if (!targetUid || !role) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'targetUid and role are required'
        );
      }

      if (!['owner', 'employee'].includes(role)) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Invalid role: ${role}. Must be 'owner' or 'employee'`
        );
      }

      // Check if caller is admin (for now, check if they're an owner)
      const callerDoc = await firestore.collection('users').doc(callerId).get();
      const callerRole = callerDoc.data()?.role;

      if (callerRole !== 'owner') {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only owners can assign roles'
        );
      }

      // Get target user
      const targetUser = await auth.getUser(targetUid);
      console.log(`Assigning role to user: ${targetUid}`, {
        currentRole: targetUser.customClaims?.role || 'owner',
        newRole: role,
        assignedBy: callerId,
      });

      // Update custom claims
      const currentClaims = targetUser.customClaims || {};
      await auth.setCustomUserClaims(targetUid, {
        ...currentClaims,
        role,
        updatedAt: new Date().toISOString(),
        updatedBy: callerId,
      });

      // Update Firestore user document
      const userDocRef = firestore.collection('users').doc(targetUid);
      await userDocRef.update({
        role,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: callerId,
      });

      // Log role change in audit collection
      await firestore.collection('audit_logs').add({
        action: 'ROLE_ASSIGNED',
        targetUid,
        role,
        assignedBy: callerId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Role assigned successfully: ${targetUid}`, {
        role,
      });

      return {
        success: true,
        message: `User ${targetUid} assigned role: ${role}`,
        user: {
          uid: targetUid,
          email: targetUser.email,
          role,
        },
      };
    } catch (error) {
      console.error('Error assigning role:', error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        'internal',
        `Error assigning role: ${(error as Error).message}`
      );
    }
  });

/**
 * Cloud Function: Callable function to change user role
 * 
 * Security: Requires user to be owner
 * 
 * Parameters:
 * - targetUid: UID of user to change role
 * - newRole: 'owner' or 'employee'
 * 
 * Returns:
 * - success: boolean
 * - previousRole: string
 * - newRole: string
 */
export const changeUserRole = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const { targetUid, newRole } = data;

      if (!newRole || !['owner', 'employee'].includes(newRole)) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Invalid role: ${newRole}`
        );
      }

      // Verify caller is owner
      const callerDoc = await firestore
        .collection('users')
        .doc(context.auth.uid)
        .get();

      if (callerDoc.data()?.role !== 'owner') {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only owners can change roles'
        );
      }

      // Get current role
      const targetUser = await auth.getUser(targetUid);
      const previousRole = targetUser.customClaims?.role || 'owner';

      // Prevent changing last owner to employee
      if (previousRole === 'owner' && newRole === 'employee') {
        const ownersSnapshot = await firestore
          .collection('users')
          .where('role', '==', 'owner')
          .get();

        if (ownersSnapshot.size === 1) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Cannot change the last owner to employee'
          );
        }
      }

      // Update role
      await auth.setCustomUserClaims(targetUid, {
        ...targetUser.customClaims,
        role: newRole,
        updatedAt: new Date().toISOString(),
        updatedBy: context.auth.uid,
      });

      await firestore.collection('users').doc(targetUid).update({
        role: newRole,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: context.auth.uid,
      });

      console.log(`Role changed for user: ${targetUid}`, {
        previousRole,
        newRole,
      });

      return {
        success: true,
        previousRole,
        newRole,
        message: `Role changed from ${previousRole} to ${newRole}`,
      };
    } catch (error) {
      console.error('Error changing role:', error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        'internal',
        `Error changing role: ${(error as Error).message}`
      );
    }
  });

/**
 * Helper function: Initialize user subcollections
 * Creates empty subcollections for new users
 * 
 * @param uid - User ID
 */
async function initializeUserCollections(uid: string): Promise<void> {
  const userRef = firestore.collection('users').doc(uid);

  // Initialize subcollections with placeholder documents
  // (Firestore requires at least one document to show subcollections)
  const collections = [
    'expenses',
    'tasks',
    'clients',
    'invoices',
    'wallet',
    'inventory',
  ];

  for (const collectionName of collections) {
    await userRef
      .collection(collectionName)
      .doc('_placeholder')
      .set({
        _initialized: true,
        _timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.debug(`Initialized subcollection: users/${uid}/${collectionName}`);
  }
}

/**
 * Cloud Function: Get user role for display
 * 
 * Security: Public read, validates auth
 * 
 * Parameters: (none - uses auth context)
 * 
 * Returns:
 * - role: string
 * - email: string
 */
export const getUserRole = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const userDoc = await firestore
        .collection('users')
        .doc(context.auth.uid)
        .get();

      const userData = userDoc.data();

      return {
        uid: context.auth.uid,
        email: context.auth.token.email,
        role: userData?.role || 'owner',
        displayName: userData?.displayName || '',
      };
    } catch (error) {
      console.error('Error getting user role:', error);
      throw new functions.https.HttpsError(
        'internal',
        `Error getting user role: ${(error as Error).message}`
      );
    }
  });

/**
 * Cloud Function: List all users (admin only)
 * 
 * Security: Requires user to be admin
 * 
 * Returns:
 * - users: Array of user objects with role info
 */
export const listAllUsers = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      // Check if caller is admin/owner
      const callerDoc = await firestore
        .collection('users')
        .doc(context.auth.uid)
        .get();

      if (callerDoc.data()?.role !== 'owner') {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only owners can list users'
        );
      }

      const usersSnapshot = await firestore.collection('users').get();

      const users = usersSnapshot.docs.map((doc) => ({
        uid: doc.id,
        email: doc.data().email,
        displayName: doc.data().displayName,
        role: doc.data().role,
        createdAt: doc.data().createdAt?.toDate().toISOString(),
        status: doc.data().status,
      }));

      return {
        success: true,
        count: users.length,
        users,
      };
    } catch (error) {
      console.error('Error listing users:', error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        'internal',
        `Error listing users: ${(error as Error).message}`
      );
    }
  });
