import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

/**
 * Callable: adjust stock
 * payload:
 * {
 *   itemId,
 *   type: 'adjust' | 'damage' | 'transfer' | 'refund' | 'purchase',
 *   quantity,   // positive for incoming, negative for outgoing adjustment
 *   referenceId,
 *   note
 * }
 */
export const adjustStock = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'Auth required');

  const itemId = String(data.itemId || '');
  const type = String(data.type || 'adjust');
  let qty = Number(data.quantity ?? 0);
  if (!itemId) throw new functions.https.HttpsError('invalid-argument', 'itemId required');

  // load item
  const itemRef = db.collection('users').doc(uid).collection('inventory_items').doc(itemId);
  const itemSnap = await itemRef.get();
  if (!itemSnap.exists) throw new functions.https.HttpsError('not-found', 'Item not found');

  const item = itemSnap.data() as any;
  const before = Number(item.stockQuantity ?? 0);
  const after = before + qty;

  const now = admin.firestore.FieldValue.serverTimestamp();

  // write movement
  const movementRef = itemRef.collection('stock_movements').doc();
  await movementRef.set({
    itemId,
    type,
    quantity: qty,
    before,
    after,
    referenceId: data.referenceId || null,
    note: data.note || null,
    createdAt: now,
  });

  // update item quantity and updatedAt
  await itemRef.update({
    stockQuantity: after,
    updatedAt: now,
  });

  // low stock check
  await checkAndCreateLowStockAlert(uid, itemId);

  return { success: true, before, after };
});

// reuse the helper from createInventoryItem (duplicate to avoid import complexity)
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
