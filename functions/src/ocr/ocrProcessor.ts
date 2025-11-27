import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import fetch from 'node-fetch';
import { CallableContext } from 'firebase-functions/v1/https';

const db = admin.firestore();

export const visionOcr = functions.https.onCall(async (data: any, context: CallableContext) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const { imageUrl } = data;
  if (!imageUrl) {
    throw new functions.https.HttpsError('invalid-argument', 'imageUrl required');
  }

  // Use Vision API (requires enabling & API key in functions env)
  const apiKey = process.env.GOOGLE_VISION_KEY || functions.config().vision?.key;
  if (!apiKey) {
    throw new functions.https.HttpsError('failed-precondition', 'Vision API not configured');
  }

  const body = {
    requests: [{
      image: { source: { imageUri: imageUrl } },
      features: [
        { type: 'DOCUMENT_TEXT_DETECTION', maxResults: 1 },
        { type: 'TEXT_DETECTION', maxResults: 10 },
      ]
    }]
  };

  try {
    const res = await fetch(`https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`, {
      method: 'POST',
      body: JSON.stringify(body),
      headers: { 'Content-Type': 'application/json' }
    });

    const json: any = await res.json();
    
    if (json.error) {
      console.error('Vision API error:', json.error);
      throw new functions.https.HttpsError('internal', 'Vision API failed');
    }

    // Extract full text from response
    const fullText = json.responses?.[0]?.fullTextAnnotation?.text || '';
    const textAnnotations = json.responses?.[0]?.textAnnotations || [];
    
    // Parse receipt data from text
    const parsed = parseReceipt(fullText);

    return {
      rawText: fullText,
      textAnnotations: textAnnotations.map((t: any) => ({
        text: t.description,
        confidence: t.confidence,
        bounds: t.boundingPoly,
      })),
      parsed,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error: any) {
    console.error('OCR processing error:', error);
    throw new functions.https.HttpsError('internal', `Failed to process receipt: ${error.message}`);
  }
});

interface ParsedReceipt {
  merchant: string;
  amount: number;
  vat?: number;
  currency: string;
  date?: string;
}

function parseReceipt(text: string): ParsedReceipt {
  const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 0);

  let merchant = 'Unknown';
  let amount = 0;
  let vat: number | undefined;
  let currency = 'EUR';
  let date: string | undefined;

  // Merchant: first line with letters (usually at top of receipt)
  merchant = lines.find(l => /[A-Za-z]{3,}/.test(l)) || 'Unknown';

  // Date: look for common patterns (dd/mm/yyyy, yyyy-mm-dd, etc)
  const dateRegex = /(\d{4}[-\/]\d{1,2}[-\/]\d{1,2})|(\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4})/;
  for (const line of lines) {
    const match = line.match(dateRegex);
    if (match) {
      try {
        const dateStr = match[0].replace(/\//g, '-');
        // Handle dd-mm-yy format
        const parts = dateStr.split('-').map(p => parseInt(p));
        let isoDate: string;
        
        if (parts[0] > 31) {
          // yyyy-mm-dd format
          isoDate = new Date(parts[0], parts[1] - 1, parts[2]).toISOString();
        } else if (parts[2] < 100) {
          // dd-mm-yy format (assume 20xx for yy >= 00)
          const year = parts[2] < 30 ? 2000 + parts[2] : 1900 + parts[2];
          isoDate = new Date(year, parts[1] - 1, parts[0]).toISOString();
        } else {
          // dd-mm-yyyy format
          isoDate = new Date(parts[2], parts[1] - 1, parts[0]).toISOString();
        }
        date = isoDate;
        break;
      } catch (e) {
        console.debug('Date parsing failed for:', match[0]);
      }
    }
  }

  // Amount: find largest currency-like number (usually total at bottom)
  const amountRegex = /([-+]?\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2}))/g;
  let maxVal = 0;
  for (const line of lines.reverse()) {
    const matches = line.match(amountRegex);
    if (matches) {
      for (const m of matches) {
        const raw = m.replace(/\./g, '').replace(/,/, '.');
        const val = parseFloat(raw);
        if (val > maxVal) maxVal = val;
      }
      if (maxVal > 0) break;
    }
  }
  amount = maxVal;

  // VAT: look for lines with vat/tax/tva/moms/iva labels
  for (const line of lines) {
    if (/\b(vat|tva|tax|tasse|moms|iva|tps|gst)\b/i.test(line)) {
      const match = line.match(amountRegex);
      if (match) {
        const raw = match[0].replace(/\./g, '').replace(/,/, '.');
        vat = parseFloat(raw);
        break;
      }
    }
  }

  // Currency detection (check symbols and codes)
  if (text.includes('€') || /\beur\b/i.test(text) || /\beuro\b/i.test(text)) {
    currency = 'EUR';
  } else if (text.includes('$') || /\busd\b/i.test(text) || /\bdollar\b/i.test(text)) {
    currency = 'USD';
  } else if (/\bgbp\b/i.test(text) || /\bpound\b/i.test(text) || text.includes('£')) {
    currency = 'GBP';
  } else if (/\bchf\b/i.test(text) || /\bswiss\b/i.test(text)) {
    currency = 'CHF';
  } else if (/\bjpy\b/i.test(text) || text.includes('¥')) {
    currency = 'JPY';
  } else if (/\bcad\b/i.test(text)) {
    currency = 'CAD';
  }

  return { merchant, amount, vat, currency, date };
}
