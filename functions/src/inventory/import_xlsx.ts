import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
// @ts-ignore - exceljs doesn't export types properly
const ExcelJS = require('exceljs');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

export const importExcelInventory = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

  const { base64 } = data; // base64 string of file
  if (!base64) throw new functions.https.HttpsError('invalid-argument', 'base64 required');

  try {
    const buffer = Buffer.from(base64, 'base64');
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(buffer);
    const sheet = workbook.worksheets[0];
    // read header row
    const rows = sheet.getSheetValues();
    // Convert rows into array-of-objects using header row (first row)
    const headerRow = sheet.getRow(1).values as any[];
    const headers = headerRow.map((h: any) => (h ? h.toString().toLowerCase().trim() : null));
    const items: any[] = [];

    sheet.eachRow((row: any, rowNumber: number) => {
      if (rowNumber === 1) return; // skip header
      const values = row.values as any[];
      const obj: any = {};
      for (let i = 1; i < values.length; i++) {
        const key = headers[i] || `col${i}`;
        obj[key] = values[i];
      }
      // map common fields
      const name = obj['name'] ?? obj['product'] ?? obj['description'] ?? '';
      const sku = obj['sku'] ?? obj['code'] ?? obj['reference'];
      const qty = parseInt(obj['qty'] ?? obj['quantity'] ?? obj['amount'] ?? 0, 10) || 0;
      const costPrice = obj['cost'] ?? obj['costprice'] ?? undefined;
      const sellingPrice = obj['price'] ?? obj['unitprice'] ?? undefined;
      items.push({ name: name.toString().trim(), sku, quantity: qty, costPrice, sellingPrice });
    });

    return { success: true, items };
  } catch (err) {
    console.error('Excel parse error', err);
    throw new functions.https.HttpsError('internal', 'Excel parse failed');
  }
});
