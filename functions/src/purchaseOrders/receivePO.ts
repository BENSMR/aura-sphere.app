import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();

interface ReceivedItem {
  itemIndex?: number;
  sku?: string;
  inventoryItemId?: string;
  name?: string;
  qtyReceived: number;
  costPrice?: number;
}

interface ReceivePOData {
  poId: string;
  receivedItems: ReceivedItem[];
  notes?: string;
}

/**
 * Receive Purchase Order
 * - Updates inventory quantities from PO items
 * - Creates stock movement records
 * - Updates PO status (partially_received → received)
 * - Links inventory items to PO items
 * 
 * Input:
 *   poId: string — Purchase order ID
 *   receivedItems: Array of { itemIndex?, sku?, inventoryItemId?, name?, qtyReceived, costPrice? }
 *   notes?: string — Optional receiving notes
 */
export const receivePurchaseOrder = functions.https.onCall(
  async (data: ReceivePOData, context) => {
    // Auth check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required'
      );
    }

    const uid = context.auth.uid;
    const { poId, receivedItems, notes } = data;

    // Validation
    if (!poId || !Array.isArray(receivedItems) || receivedItems.length === 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'poId and receivedItems array required'
      );
    }

    const db = admin.firestore();
    const poRef = db.collection('users').doc(uid).collection('purchase_orders').doc(poId);
    const poSnap = await poRef.get();

    if (!poSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Purchase order not found');
    }

    const po = poSnap.data()!;

    // Begin batch write
    const batch = db.batch();
    const movements: any[] = [];
    const inventoryRefBase = db.collection('users').doc(uid).collection('inventory_items');
    const movementRefBase = db.collection('users').doc(uid).collection('stock_movements');

    // Process each received item
    for (const rItem of receivedItems) {
      let poItemIndex = rItem.itemIndex;
      let poItem;

      // Find PO item by index, SKU, or name
      if (typeof poItemIndex === 'number' && poItemIndex >= 0 && poItemIndex < po.items.length) {
        poItem = po.items[poItemIndex];
      } else if (rItem.sku) {
        poItem = po.items.find((i: any) => (i.sku || '').toLowerCase() === (rItem.sku || '').toLowerCase());
      } else if (rItem.name) {
        poItem = po.items.find((i: any) => (i.name || '').toLowerCase() === (rItem.name || '').toLowerCase());
      }

      // If no PO item found, create new inventory item
      if (!poItem) {
        const newInvRef = inventoryRefBase.doc();
        const newInv = {
          name: rItem.name || rItem.sku || 'Imported Item',
          sku: rItem.sku || null,
          quantity: Number(rItem.qtyReceived || 0),
          costPrice: rItem.costPrice ?? null,
          sellingPrice: null,
          category: null,
          brand: null,
          supplierId: po.supplierId || null,
          supplierName: po.supplierName || null,
          barcode: null,
          imageUrl: null,
          minimumStock: 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        batch.set(newInvRef, newInv);

        const movementId = `mov_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        movements.push({
          movementId,
          itemId: newInvRef.id,
          qty: Number(rItem.qtyReceived || 0),
          costPrice: newInv.costPrice,
        });

        continue;
      }

      // PO item exists — update or create inventory
      let inventoryItemId = poItem.inventoryItemId ?? rItem.inventoryItemId;
      const qtyToReceive = Number(rItem.qtyReceived || 0);

      if (inventoryItemId) {
        // Inventory item already linked
        const invRef = inventoryRefBase.doc(inventoryItemId);
        const invSnap = await invRef.get();

        if (invSnap.exists) {
          // Update existing inventory
          const inv = invSnap.data()!;
          const newQty = (inv.quantity || 0) + qtyToReceive;

          batch.update(invRef, {
            quantity: newQty,
            costPrice: rItem.costPrice ?? poItem.costPrice ?? inv.costPrice ?? null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          const movementId = `mov_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
          movements.push({
            movementId,
            itemId: inventoryItemId,
            qty: qtyToReceive,
            costPrice: rItem.costPrice ?? poItem.costPrice ?? inv.costPrice,
          });

          // Update PO item qty received
          const itemIdx = po.items.indexOf(poItem);
          if (itemIdx >= 0) {
            po.items[itemIdx].qtyReceived = (po.items[itemIdx].qtyReceived || 0) + qtyToReceive;
          }
        } else {
          // Referenced inventory item not found — create new
          const newInvRef = inventoryRefBase.doc();
          const newInv = {
            name: poItem.name || rItem.name || 'Imported Item',
            sku: poItem.sku || rItem.sku || null,
            quantity: qtyToReceive,
            costPrice: rItem.costPrice ?? poItem.costPrice ?? null,
            sellingPrice: null,
            category: null,
            brand: null,
            supplierId: po.supplierId || null,
            supplierName: po.supplierName || null,
            barcode: null,
            imageUrl: null,
            minimumStock: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          };
          batch.set(newInvRef, newInv);

          const movementId = `mov_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
          movements.push({
            movementId,
            itemId: newInvRef.id,
            qty: qtyToReceive,
            costPrice: newInv.costPrice,
          });

          // Update PO item
          const itemIdx = po.items.indexOf(poItem);
          if (itemIdx >= 0) {
            po.items[itemIdx].inventoryItemId = newInvRef.id;
            po.items[itemIdx].qtyReceived = (po.items[itemIdx].qtyReceived || 0) + qtyToReceive;
          }
        }
      } else {
        // No inventory item linked — try to match by SKU or name
        let invQuery;

        if (poItem.sku) {
          invQuery = await inventoryRefBase
            .where('sku', '==', poItem.sku)
            .limit(1)
            .get();
        }

        if (!invQuery || invQuery.empty) {
          invQuery = await inventoryRefBase
            .where('name', '==', poItem.name)
            .limit(1)
            .get();
        }

        if (invQuery && !invQuery.empty) {
          // Found matching inventory
          const invDoc = invQuery.docs[0];
          const invRef = invDoc.ref;
          const inv = invDoc.data();
          const newQty = (inv.quantity || 0) + qtyToReceive;

          batch.update(invRef, {
            quantity: newQty,
            costPrice: rItem.costPrice ?? poItem.costPrice ?? inv.costPrice ?? null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          const movementId = `mov_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
          movements.push({
            movementId,
            itemId: invRef.id,
            qty: qtyToReceive,
            costPrice: rItem.costPrice ?? poItem.costPrice ?? inv.costPrice,
          });

          // Update PO item
          const itemIdx = po.items.indexOf(poItem);
          if (itemIdx >= 0) {
            po.items[itemIdx].inventoryItemId = invRef.id;
            po.items[itemIdx].qtyReceived = (po.items[itemIdx].qtyReceived || 0) + qtyToReceive;
          }
        } else {
          // Create new inventory item
          const newInvRef = inventoryRefBase.doc();
          const newInv = {
            name: poItem.name || rItem.name || 'Imported Item',
            sku: poItem.sku || rItem.sku || null,
            quantity: qtyToReceive,
            costPrice: rItem.costPrice ?? poItem.costPrice ?? null,
            sellingPrice: null,
            category: null,
            brand: null,
            supplierId: po.supplierId || null,
            supplierName: po.supplierName || null,
            barcode: null,
            imageUrl: null,
            minimumStock: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          };
          batch.set(newInvRef, newInv);

          const movementId = `mov_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
          movements.push({
            movementId,
            itemId: newInvRef.id,
            qty: qtyToReceive,
            costPrice: newInv.costPrice,
          });

          // Update PO item
          const itemIdx = po.items.indexOf(poItem);
          if (itemIdx >= 0) {
            po.items[itemIdx].inventoryItemId = newInvRef.id;
            po.items[itemIdx].qtyReceived = (po.items[itemIdx].qtyReceived || 0) + qtyToReceive;
          }
        }
      }
    }

    // Determine new PO status
    let allReceived = true;
    let anyReceived = false;

    for (const item of po.items) {
      const ordered = Number(item.qtyOrdered || 0);
      const received = Number(item.qtyReceived || 0);
      if (received < ordered) allReceived = false;
      if (received > 0) anyReceived = true;
    }

    const newStatus = allReceived ? 'received' : anyReceived ? 'partially_received' : 'pending';

    // Update PO
    batch.update(poRef, {
      items: po.items,
      status: newStatus,
      receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      receivedBy: uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create stock movement documents
    const linkedMovements: any[] = [];

    for (const m of movements) {
      const mvRef = movementRefBase.doc();
      const mvDoc = {
        itemId: m.itemId,
        qty: m.qty,
        costPrice: m.costPrice ?? null,
        type: 'inbound',
        reference: {
          type: 'purchase_order',
          poId,
          poNumber: po.poNumber,
        },
        notes: notes || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      batch.set(mvRef, mvDoc);

      linkedMovements.push({
        movementId: mvRef.id,
        itemId: m.itemId,
        qty: m.qty,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Update PO with linked movements (second update)
    batch.update(poRef, {
      linkedStockMovements: linkedMovements,
    });

    // Commit all changes
    await batch.commit();

    return {
      success: true,
      message: 'Purchase order received successfully',
      poId,
      newStatus,
      movementsCreated: movements.length,
      itemsReceived: receivedItems.length,
    };
  }
);
