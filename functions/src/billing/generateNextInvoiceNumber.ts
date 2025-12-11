import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface InvoiceSettings {
  prefix: string;
  nextNumber: number;
  resetRule: 'none' | 'monthly' | 'yearly';
  lastReset: admin.firestore.Timestamp;
}

/**
 * Generate the next invoice number with auto-increment and optional reset
 * 
 * Request:
 * {
 *   userId: string (from auth context)
 * }
 * 
 * Response:
 * {
 *   invoiceNumber: string (e.g., "AURA-1001")
 *   nextNumber: number (1002 for next call)
 *   prefix: string ("AURA-")
 *   resetRule: string ("yearly", "monthly", or "none")
 * }
 */
export const generateNextInvoiceNumber = functions.https.onCall(
  async (data, context) => {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;
    const docRef = db.collection('users').doc(userId).collection('settings').doc('invoice_settings');

    try {
      // Get current settings
      const snap = await docRef.get();
      let settings: InvoiceSettings;

      if (snap.exists) {
        settings = snap.data() as InvoiceSettings;
      } else {
        // Create default settings if not exists
        settings = {
          prefix: 'AURA-',
          nextNumber: 1001,
          resetRule: 'yearly',
          lastReset: admin.firestore.Timestamp.now(),
        };
      }

      // Extract current values
      let prefix = settings.prefix || 'AURA-';
      let nextNumber = settings.nextNumber || 1001;
      const resetRule = settings.resetRule || 'yearly';
      let lastReset = settings.lastReset || admin.firestore.Timestamp.now();

      // Check if reset is needed
      if (resetRule !== 'none') {
        if (shouldReset(lastReset.toDate(), resetRule)) {
          nextNumber = 1001;
          lastReset = admin.firestore.Timestamp.now();
        }
      }

      // Generate invoice number
      const invoiceNumber = `${prefix}${nextNumber.toString().padStart(4, '0')}`;

      // Increment counter and save
      await docRef.set(
        {
          prefix,
          nextNumber: nextNumber + 1,
          resetRule,
          lastReset,
        },
        { merge: true }
      );

      return {
        success: true,
        invoiceNumber,
        nextNumber: nextNumber + 1,
        prefix,
        resetRule,
      };
    } catch (error) {
      console.error('Error generating invoice number:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to generate invoice number'
      );
    }
  }
);

/**
 * Get current invoice settings without incrementing
 */
export const getInvoiceSettings = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;
    const docRef = db.collection('users').doc(userId).collection('settings').doc('invoice_settings');

    try {
      const snap = await docRef.get();

      if (snap.exists) {
        const settings = snap.data() as InvoiceSettings;
        return {
          success: true,
          settings: {
            prefix: settings.prefix || 'AURA-',
            nextNumber: settings.nextNumber || 1001,
            resetRule: settings.resetRule || 'yearly',
            lastReset: settings.lastReset?.toDate().toISOString(),
          },
        };
      }

      // Return defaults if not set
      return {
        success: true,
        settings: {
          prefix: 'AURA-',
          nextNumber: 1001,
          resetRule: 'yearly',
          lastReset: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('Error getting invoice settings:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to get invoice settings'
      );
    }
  }
);

/**
 * Update invoice settings (prefix, reset rule, etc.)
 */
export const updateInvoiceSettings = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;
    const { prefix, resetRule, nextNumber } = data;

    // Validate input
    if (prefix && typeof prefix !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'prefix must be a string'
      );
    }

    if (resetRule && !['none', 'monthly', 'yearly'].includes(resetRule)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'resetRule must be "none", "monthly", or "yearly"'
      );
    }

    if (nextNumber && !Number.isInteger(nextNumber)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'nextNumber must be an integer'
      );
    }

    const docRef = db.collection('users').doc(userId).collection('settings').doc('invoice_settings');

    try {
      const update: any = {};
      if (prefix) update.prefix = prefix;
      if (resetRule) update.resetRule = resetRule;
      if (nextNumber) update.nextNumber = nextNumber;

      await docRef.set(update, { merge: true });

      return {
        success: true,
        message: 'Invoice settings updated',
      };
    } catch (error) {
      console.error('Error updating invoice settings:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to update invoice settings'
      );
    }
  }
);

/**
 * Helper function to check if counter should reset
 */
function shouldReset(lastReset: Date, resetRule: string): boolean {
  const now = new Date();

  if (resetRule === 'monthly') {
    return (
      now.getFullYear() !== lastReset.getFullYear() ||
      now.getMonth() !== lastReset.getMonth()
    );
  } else if (resetRule === 'yearly') {
    return now.getFullYear() !== lastReset.getFullYear();
  }

  return false;
}
