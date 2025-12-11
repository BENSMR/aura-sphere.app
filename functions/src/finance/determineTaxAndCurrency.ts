import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { determineTaxLogic } from './determineTaxLogic';

if (!admin.apps.length) admin.initializeApp();

/**
 * determineTaxAndCurrency.ts
 *
 * Cloud Function: HTTPS Callable
 * Purpose: Apply tax logic + currency selection for invoices, expenses, POs.
 *
 * This file delegates ALL calculation to:
 *    determineTaxLogic.ts
 *
 * That keeps the logic centralized & testable.
 *
 * Supports:
 * - EU B2B reverse charge (zero-rate for business-to-business within EU)
 * - Multi-currency transactions
 * - Flexible input (can override with contactId or explicit country)
 */
export const determineTaxAndCurrency = functions.https.onCall(
  async (
    payload: {
      entityType?: 'invoice' | 'expense' | 'po';
      amount?: number;
      fromCurrency?: string;
      companyId?: string;
      contactId?: string;
      country?: string;
      itemCategory?: string;
      direction?: 'sale' | 'purchase';
      customerIsBusiness?: boolean;
    },
    context: functions.https.CallableContext,
  ) => {
    try {
      // ---- AUTH CHECK ---- //
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'You must be logged in to determine tax.',
        );
      }

      const uid = context.auth.uid;

      // ---- LOGGING ---- //
      console.log(`[TAX] Callable invoked by ${uid}`, JSON.stringify(payload));

      // ---- MAIN LOGIC ---- //
      const result = await determineTaxLogic(payload, uid);

      // ---- RETURN ---- //
      return {
        source: 'determineTaxAndCurrency',
        calculatedBy: 'shared.determineTaxLogic',
        ...result,
      };
    } catch (err: any) {
      console.error('[TAX] Error:', err);
      throw new functions.https.HttpsError(
        'internal',
        err.message || 'Tax calculation failed.',
      );
    }
  },
);
