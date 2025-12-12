import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Initializes a new user document in Firestore when a user is created via Firebase Auth.
 * Sets timezone, locale, and country to 'detect' placeholders that the app will replace
 * with actual detected values using device timezone and locale detection.
 */
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  const userRef = db.collection('users').doc(user.uid);

  try {
    await userRef.set({
      timezone: 'detect',   // placeholder — app will replace it with device timezone
      locale: 'detect',     // placeholder — app will replace it with device locale
      country: 'detect',    // placeholder — app will replace it with device country
      email: user.email || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log(`[onUserCreate] Initialized user document for ${user.uid}`);
  } catch (error) {
    console.error(`[onUserCreate] Error initializing user ${user.uid}:`, error);
    throw error;
  }
});
