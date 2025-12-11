import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

/**
 * Trigger: when invoice gets updated - if status becomes 'paid' -> deduct stock
 * Path: users/{userId}/invoices/{invoiceId}
 */
export const deductStockOnInvoicePaid = functions.firestore
  .document('users/{userId}/invoices/{invoiceId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { userId, invoiceId } = context.params;

    if (!before || !after) return;

    // only act when status changed to paid
    const prevStatus = before.status || before.paymentStatus || '';
    const newStatus = after.status || after.paymentStatus || '';

    if (prevStatus === 'paid' || newStatus !== 'paid') {
      return;
    }

    // verify items exist
    const items = Array.isArray(after.items) ? after.items : [];
    if (items.length === 0) {
      console.log(`Invoice ${invoiceId} has no items to deduct`);
      return;
    }

    const batch = db.batch();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    for (const it of items) {
      // require itemId and quantity
      const itemId = it.itemId || it.productId || null;
      const qty = Number(it.quantity ?? it.qty ?? 0);
      if (!itemId || qty === 0) continue;

      const itemRef = db
        .collection('users')
        .doc(userId)
        .collection('inventory_items')
        .doc(itemId);
      const itemSnap = await itemRef.get();
      if (!itemSnap.exists) continue;

      const item = itemSnap.data() as any;
      const beforeQty = Number(item.stockQuantity ?? 0);
      const afterQty = beforeQty - Math.abs(qty); // sales decrease stock

      // set item new quantity (batched)
      batch.update(itemRef, { stockQuantity: afterQty, updatedAt: timestamp });

      // add movement doc
      const movementRef = itemRef.collection('stock_movements').doc();
      batch.set(movementRef, {
        itemId,
        type: 'sale',
        quantity: -Math.abs(qty),
        before: beforeQty,
        after: afterQty,
        referenceId: invoiceId,
        note: `Auto-deduct from paid invoice ${invoiceId}`,
        createdAt: timestamp,
      });

      // low stock alert check (non-blocking: write simple doc)
      if (item.minimumStock !== undefined && afterQty <= Number(item.minimumStock)) {
        const alertsRef = db.collection('users').doc(userId).collection('analytics').doc('inventoryAlerts');
        batch.set(
          alertsRef,
          {
            lastAlert: {
              updatedAt: timestamp,
              itemId,
              itemName: item.name,
              level: 'low_stock',
              message: `Low stock after sale: ${item.name} (${afterQty}) <= minimum ${item.minimumStock}`,
            },
          },
          { merge: true }
        );
      }
    }

    await batch.commit();
    console.log(`✅ Deducted stock for invoice ${invoiceId}`);
  });
