import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import fetch from 'node-fetch';

const FX_DOC = 'config/fx_rates';
const PROVIDER = 'https://api.exchangerate.host/latest'; // Free provider, no API key required

interface ExchangeRateResponse {
  rates?: Record<string, number>;
  base?: string;
  date?: string;
}

/**
 * Syncs foreign exchange rates daily from exchangerate.host
 * Stores rates in config/fx_rates document for use by convertCurrency function
 * 
 * Schedule: Every 24 hours
 * Base currency: USD (configurable)
 */
export const syncFxRates = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      const base = 'USD'; // Platform base currency - change as needed
      const url = `${PROVIDER}?base=${base}`;

      const response = await fetch(url);
      const json = (await response.json()) as ExchangeRateResponse;

      if (!json || !json.rates) {
        throw new Error('No exchange rates returned from provider');
      }

      const docRef = admin.firestore().doc(FX_DOC);
      await docRef.set(
        {
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          base,
          provider: 'exchangerate.host',
          rates: json.rates,
          fetchedAt: new Date().toISOString(),
        },
        { merge: true }
      );

      console.log(`✅ FX rates synced for base ${base}. ${Object.keys(json.rates).length} currencies updated.`);
      return null;
    } catch (error) {
      console.error('❌ syncFxRates error:', error);
      throw error;
    }
  });
