import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

/**
 * Callable: create inventory item
 * payload:
 * {
 *   name, sku, barcode, category, brand, supplierId,
 *   costPrice, sellingPrice, tax,
 *   initialQuantity, minimumStock, imageUrl
 * }
 */
export const createInventoryItem = functions.https.onCall(
  async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

    // basic validation
    const name = String(data.name || '').trim();
    if (!name) throw new functions.https.HttpsError('invalid-argument', 'name required');

    const itemRef = db.collection('users').doc(uid).collection('inventory_items').doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const itemDoc = {
      name,
      sku: data.sku || '',
      barcode: data.barcode || null,
      category: data.category || null,
      brand: data.brand || null,
      supplierId: data.supplierId || null,
      costPrice: Number(data.costPrice ?? 0),
      sellingPrice: Number(data.sellingPrice ?? 0),
      tax: Number(data.tax ?? 0),
      stockQuantity: Number(data.initialQuantity ?? 0),
      minimumStock: Number(data.minimumStock ?? 0),
      imageUrl: data.imageUrl || null,
      createdAt: now,
      updatedAt: now,
    };

    await itemRef.set(itemDoc);

    // create initial stock movement if initialQuantity > 0
    const initialQty = Number(data.initialQuantity ?? 0);
    if (initialQty > 0) {
      const movementRef = itemRef.collection('stock_movements').doc();
      await movementRef.set({
        itemId: itemRef.id,
        type: 'purchase',
        quantity: initialQty,
        before: 0,
        after: initialQty,
        referenceId: data.referenceId || null,
        note: data.note || 'Initial stock',
        createdAt: now,
      });
    }

    // optionally trigger low stock check (will just create alerts if needed)
    await checkAndCreateLowStockAlert(uid, itemRef.id);

    return { success: true, id: itemRef.id };
  }
);

async function checkAndCreateLowStockAlert(userId: string, itemId: string) {
  const itemSnap = await db
    .collection('users')
    .doc(userId)
    .collection('inventory_items')
    .doc(itemId)
    .get();
  if (!itemSnap.exists) return;

  const item = itemSnap.data() as any;
  const minimum = Number(item.minimumStock ?? 0);
  const qty = Number(item.stockQuantity ?? 0);

  const alertsRef = db.collection('users').doc(userId).collection('analytics').doc('inventoryAlerts');

  if (minimum > 0 && qty <= minimum) {
    // create/update alert doc
    const alert = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      itemId,
      itemName: item.name,
      level: 'low_stock',
      message: `Low stock: ${item.name} (${qty}) <= minimum ${minimum}`,
    };
    await alertsRef.set({ lastAlert: alert }, { merge: true });
  }
}
