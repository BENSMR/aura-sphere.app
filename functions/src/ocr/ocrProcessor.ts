import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import vision from '@google-cloud/vision';
import { findAmounts, findDates, guessMerchant, guessCurrency } from '../expenses/parseHelpers';

if (!admin.apps.length) admin.initializeApp();
const client = new vision.ImageAnnotatorClient();
const db = admin.firestore();

type OCRResult = {
  rawText: string;
  amounts: { raw: string; value: number }[];
  dates: string[];
  merchant: string;
  currency?: string | null;
  confidence?: number | null;
};

export const visionOcr = functions.https.onCall(async (data: any, context: any) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const uid = context.auth.uid;
  const { imageUrl, imageBase64, storagePath, useOpenAI } = data;

  if (!imageUrl && !imageBase64 && !storagePath) {
    throw new functions.https.HttpsError('invalid-argument', 'imageUrl, imageBase64, or storagePath required');
  }

  let visionResultText = '';
  try {
    let res;
    if (imageBase64) {
      const content = Buffer.from(imageBase64, 'base64');
      res = await client.documentTextDetection({ image: { content } });
    } else if (storagePath) {
      // Use GCS URI for files in Cloud Storage
      const bucketName = admin.storage().bucket().name;
      const gcsUri = `gs://${bucketName}/${storagePath}`;
      res = await client.documentTextDetection({
        image: { source: { imageUri: gcsUri } }
      });
    } else if (imageUrl) {
      res = await client.documentTextDetection({
        image: { source: { imageUri: imageUrl } }
      });
    }

    visionResultText = (res?.[0]?.fullTextAnnotation?.text) || '';
  } catch (error: any) {
    console.error('Vision API error:', error);
    throw new functions.https.HttpsError('internal', `Failed to process receipt: ${error.message}`);
  }

  if (!visionResultText) {
    throw new functions.https.HttpsError('internal', 'No text extracted from image');
  }

  // Use helper functions for structured parsing
  const amounts = findAmounts(visionResultText);
  const dates = findDates(visionResultText);
  const merchant = guessMerchant(visionResultText);
  const currency = guessCurrency(visionResultText);

  const parsed: any = {
    merchant,
    total: amounts.length ? amounts[0].value : null,
    currency: currency,
    date: dates.length ? dates[0] : null,
    items: [],
    rawText: visionResultText,
    amounts,
    dates
  };

  // Optionally refine with OpenAI
  if (useOpenAI && functions.config().openai?.key) {
    try {
      const OpenAI = require('openai');
      const openai = new OpenAI({ apiKey: functions.config().openai.key });
      const prompt = `Extract structured data from this receipt:\n\nText:\n${visionResultText}\n\nReturn JSON with: merchant (str), date (YYYY-MM-DD), total_amount (number), currency (3-letter code), items (array of {name, quantity, unit_price}). Be precise.`;
      const response = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 800,
        temperature: 0
      });

      const text = response.choices?.[0]?.message?.content || '{}';
      try {
        const parsedAI = JSON.parse(text);
        if (parsedAI.merchant) parsed.merchant = parsedAI.merchant;
        if (parsedAI.total_amount) parsed.total = Number(parsedAI.total_amount);
        if (parsedAI.currency) parsed.currency = parsedAI.currency;
        if (parsedAI.date) parsed.date = parsedAI.date;
        if (Array.isArray(parsedAI.items)) parsed.items = parsedAI.items;
        parsed.refinedByAI = true;
      } catch (e) {
        console.warn('OpenAI JSON parse failed:', e);
      }
    } catch (openErr) {
      console.warn('OpenAI refinement failed (non-critical):', openErr);
    }
  }

  return {
    success: true,
    rawText: visionResultText,
    parsed,
    amounts,
    dates,
    merchant,
    currency,
    timestamp: new Date().toISOString()
  };
});
