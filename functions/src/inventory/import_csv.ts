import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
// @ts-ignore - csv-parse/sync doesn't have type declarations
const parse = require('csv-parse/sync').parse;

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

export const importCSVInventory = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

  const { csv } = data;
  if (!csv) throw new functions.https.HttpsError('invalid-argument', 'csv required');

  try {
    const records = parse(csv, { columns: true, skip_empty_lines: true });
    // heuristics: try to map common headers
    // header mapping helper
    function mapRowToItem(row: any) {
      const lowerKeys = Object.keys(row).reduce((acc: any, k: string) => { acc[k.toLowerCase().trim()] = row[k]; return acc; }, {});
      const get = (names: string[]) => {
        for (const n of names) {
          if (lowerKeys[n] !== undefined) return lowerKeys[n];
        }
        return undefined;
      };

      const name = get(['name', 'product', 'item', 'description']) ?? '';
      const sku = get(['sku', 'product code', 'code', 'reference']);
      const qty = parseInt(get(['qty', 'quantity', 'amount', 'count']) ?? '0', 10) || 0;
      const costPrice = parseFloat((get(['cost', 'costprice', 'unit cost']) ?? '0').toString()) || undefined;
      const sellingPrice = parseFloat((get(['price', 'unitprice', 'sellingprice']) ?? '0').toString()) || undefined;
      return { name: (name ?? '').toString().trim(), sku, quantity: qty, costPrice, sellingPrice };
    }

    const items = records.map((r: any) => mapRowToItem(r));
    return { success: true, items };
  } catch (err) {
    console.error('CSV parse error', err);
    throw new functions.https.HttpsError('invalid-argument', 'CSV parse failed');
  }
});
