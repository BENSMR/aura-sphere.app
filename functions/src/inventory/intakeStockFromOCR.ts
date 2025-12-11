import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

/**
 * Callable: intakeStockFromOCR
 * payload:
 * {
 *   items: [
 *     { sku?, name, quantity, costPrice?, supplierId? }
 *   ],
 *   referenceId?, note?
 * }
 *
 * Behavior: for each parsed item:
 *  - try to find existing inventory item by SKU or name
 *  - if found: increment stock (purchase)
 *  - if not found: create a new inventory item with given fields
 */
export const intakeStockFromOCR = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

  const items = Array.isArray(data.items) ? data.items : [];
  if (items.length === 0) throw new functions.https.HttpsError('invalid-argument', 'items required');

  const results: any[] = [];
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (const parsed of items) {
    const sku = parsed.sku?.toString?.().trim() ?? null;
    const name = parsed.name?.toString?.trim() ?? null;
    const qty = Number(parsed.quantity ?? parsed.qty ?? 0);
    const costPrice = Number(parsed.costPrice ?? 0);
    const supplierId = parsed.supplierId ?? parsed.supplier ?? null;

    // Try find by SKU if provided
    let itemQuery;
    if (sku) {
      itemQuery = await db
        .collection('users')
        .doc(uid)
        .collection('inventory_items')
        .where('sku', '==', sku)
        .limit(1)
        .get();
    }
    // else try find by name
    if ((!itemQuery || itemQuery.empty) && name) {
      itemQuery = await db
        .collection('users')
        .doc(uid)
        .collection('inventory_items')
        .where('name', '==', name)
        .limit(1)
        .get();
    }

    if (itemQuery && !itemQuery.empty) {
      const itemDoc = itemQuery.docs[0];
      const itemRef = itemDoc.ref;
      const item = itemDoc.data() as any;
      const beforeQty = Number(item.stockQuantity ?? 0);
      const afterQty = beforeQty + qty;

      // movement and update
      const movementRef = itemRef.collection('stock_movements').doc();
      await movementRef.set({
        itemId: itemRef.id,
        type: 'purchase',
        quantity: qty,
        before: beforeQty,
        after: afterQty,
        referenceId: data.referenceId || null,
        note: data.note || 'OCR intake',
        createdAt: now,
      });

      await itemRef.update({
        stockQuantity: afterQty,
        updatedAt: now,
        costPrice: costPrice > 0 ? costPrice : item.costPrice ?? 0,
      });

      results.push({ itemId: itemRef.id, before: beforeQty, after: afterQty, method: 'updated' });
    } else {
      // create item
      const itemRef = db.collection('users').doc(uid).collection('inventory_items').doc();
      const itemData = {
        name: name || `Unnamed item ${Date.now()}`,
        sku: sku || '',
        barcode: null,
        category: null,
        brand: null,
        supplierId: supplierId,
        costPrice: costPrice,
        sellingPrice: parsed.sellingPrice ?? 0,
        tax: parsed.tax ?? 0,
        stockQuantity: qty,
        minimumStock: parsed.minimumStock ?? 0,
        imageUrl: null,
        createdAt: now,
        updatedAt: now,
      };
      await itemRef.set(itemData);

      const movementRef = itemRef.collection('stock_movements').doc();
      await movementRef.set({
        itemId: itemRef.id,
        type: 'purchase',
        quantity: qty,
        before: 0,
        after: qty,
        referenceId: data.referenceId || null,
        note: data.note || 'OCR created item',
        createdAt: now,
      });

      results.push({ itemId: itemRef.id, before: 0, after: qty, method: 'created' });
    }
  }

  // Optionally trigger an aggregate recompute? (left for future)
  return { success: true, results };
});
