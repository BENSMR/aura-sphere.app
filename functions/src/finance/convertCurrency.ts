import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import fetch from 'node-fetch';

/**
 * Converts currency amounts using cached exchange rates
 * Falls back to external API if rates unavailable
 * 
 * data: { amount: number, from: string, to: string }
 * Returns: { success: true, converted: number, rate: number }
 */
export const convertCurrency = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  const { amount, from, to } = data;

  // Validate input
  if (typeof amount !== 'number' || !from || !to) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Required: amount (number), from (string), to (string)'
    );
  }

  // Same currency, no conversion needed
  if (from === to) {
    return { success: true, converted: amount, rate: 1 };
  }

  try {
    // Fetch cached FX rates from Firestore
    const fxDoc = await admin.firestore().doc('config/fx_rates').get();
    
    if (!fxDoc.exists) {
      throw new Error('FX rates document not found');
    }

    const fx = fxDoc.data() as { base?: string; rates?: Record<string, number> } | undefined;
    if (!fx) {
      throw new Error('FX rates data is empty');
    }

    const base = fx.base || 'USD';
    const rates = fx.rates || {};

    // Get rates for conversion
    const rateFrom = from === base ? 1 : rates[from];
    const rateTo = to === base ? 1 : rates[to];

    // If both rates exist, use cached rates
    if (rateFrom && rateTo) {
      const amountInBase = from === base ? amount : amount / rateFrom;
      const converted = amountInBase * rateTo;
      const effectiveRate = rateTo / rateFrom;

      return {
        success: true,
        converted: Number(converted.toFixed(6)),
        rate: Number(effectiveRate.toFixed(8)),
      };
    }

    // Fallback: Try external API
    console.warn(
      `Missing rate for ${from} or ${to}, attempting external API fallback`
    );

    const url = `https://api.exchangerate.host/convert?from=${encodeURIComponent(
      from
    )}&to=${encodeURIComponent(to)}&amount=${amount}`;

    const response = await fetch(url);
    const json = (await response.json()) as {
      result?: number;
      info?: { rate?: number };
    };

    if (json && json.result != null) {
      const rate = json.info?.rate ?? json.result / amount;
      return {
        success: true,
        converted: Number(json.result),
        rate: Number(rate),
      };
    }

    throw new Error('External API conversion failed');
  } catch (error) {
    console.error('Currency conversion error:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to convert ${from} to ${to}`
    );
  }
});
