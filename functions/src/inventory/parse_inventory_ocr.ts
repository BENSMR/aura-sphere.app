import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { ImageAnnotatorClient } from '@google-cloud/vision';
import OpenAI from 'openai';

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const visionClient = new ImageAnnotatorClient();
const openai = new OpenAI({ apiKey: process.env.OPENAI_KEY });

type ParsedItem = {
  name: string;
  sku?: string | null;
  quantity?: number;
  costPrice?: number;
  sellingPrice?: number;
  tax?: number;
  supplier?: string | null;
};

function buildPrompt(ocrText: string) {
  return `
You are a precise data extraction engine. Given raw OCR text from a supplier delivery note or product list, extract an array of items with fields: name, sku (if present), quantity (integer), costPrice (optional numeric), sellingPrice (optional numeric), tax (optional numeric), supplier (optional).  
Return JSON only with the array under key "items", and optionally "supplier" and "notes".  
If quantity not found, set quantity to 0. If price not found, skip numeric fields.

Example output:
{"supplier":"ACME Ltd","items":[{"name":"Widget A","sku":"W-A-01","quantity":12,"costPrice":1.25},{"name":"Sprocket","quantity":5}]}
  
Now extract from this OCR text:
"""${ocrText}"""
`;
}

export const parseInventoryOCR = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

  const { imageUrl, b64 } = data;
  if (!imageUrl && !b64) throw new functions.https.HttpsError('invalid-argument', 'imageUrl or b64 required');

  // 1) Run Vision OCR
  let text = '';
  try {
    if (imageUrl) {
      const [result] = await visionClient.textDetection(imageUrl);
      text = result.fullTextAnnotation?.text || '';
    } else {
      // b64 (base64 string)
      const [result] = await visionClient.textDetection({ image: { content: b64 } });
      text = result.fullTextAnnotation?.text || '';
    }
  } catch (err) {
    console.error('Vision error', err);
    throw new functions.https.HttpsError('internal', 'Vision OCR failed');
  }

  // 2) Ask OpenAI to parse into structured JSON
  try {
    const prompt = buildPrompt(text);
    const resp = await openai.chat.completions.create({
      model: 'gpt-4o-mini', // or gpt-4, pick available model in your account
      messages: [{ role: 'system', content: 'You are a JSON extraction assistant.' }, { role: 'user', content: prompt }],
      temperature: 0,
      max_tokens: 800,
    });

    const content = resp.choices?.[0]?.message?.content;
    if (!content) throw new Error('Empty OpenAI response');

    // sanitize content — try parse JSON directly
    let parsed;
    try {
      parsed = JSON.parse(content);
    } catch (e) {
      // fallback: attempt to extract the first {...} block
      const match = content.match(/\{[\s\S]*\}/);
      if (match) parsed = JSON.parse(match[0]);
      else throw e;
    }

    // Validate items array
    const items = Array.isArray(parsed.items) ? parsed.items : [];
    // normalize items
    const normalized: ParsedItem[] = items.map((it: any) => ({
      name: (it.name || '').toString().trim(),
      sku: it.sku ?? null,
      quantity: parseInt(it.quantity ?? 0, 10) || 0,
      costPrice: it.costPrice !== undefined ? Number(it.costPrice) : undefined,
      sellingPrice: it.sellingPrice !== undefined ? Number(it.sellingPrice) : undefined,
      tax: it.tax !== undefined ? Number(it.tax) : undefined,
      supplier: parsed.supplier ?? it.supplier ?? null,
    }));

    return { success: true, rawText: text, parsed: { supplier: parsed.supplier ?? null, items: normalized, notes: parsed.notes ?? null } };
  } catch (err) {
    console.error('OpenAI parse error', err);
    throw new functions.https.HttpsError('internal', 'Parsing failed');
  }
});
