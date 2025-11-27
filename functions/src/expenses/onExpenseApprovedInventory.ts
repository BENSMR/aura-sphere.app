// Cloud Function: Handle inventory changes when expense is approved
// Detects expenses with category 'Inventory' and updates stock accordingly

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Cloud Function: onExpenseApprovedInventory
 * 
 * Triggers when an expense with category 'Inventory' is approved
 * Updates inventory stock movements and balances
 * 
 * Workflow:
 * 1. Check if expense category is 'Inventory'
 * 2. Create stock movement record
 * 3. Update inventory project totals
 * 4. Update warehouse/location balances
 * 5. Create audit trail
 * 
 * Firestore paths:
 * - Expense: users/{userId}/expenses/{expenseId}
 * - Inventory: users/{userId}/inventory/{itemId}
 * - Stock movements: users/{userId}/inventory/{itemId}/movements/{movementId}
 */
export const onExpenseApprovedInventory = functions.firestore
  .document('users/{userId}/expenses/{expenseId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return null;

    // Only process if status changed to 'approved'
    if (before.status !== 'approved' && after.status === 'approved') {
      // Only process inventory-related expenses
      if (after.category !== 'Inventory') {
        return null;
      }

      const userId = context.params.userId;
      const expenseId = context.params.expenseId;

      try {
        await _processInventoryExpense(userId, expenseId, after);
        console.log(
          `Inventory expense ${expenseId} processed for user ${userId}`
        );
      } catch (error) {
        console.error(
          `Failed to process inventory expense ${expenseId}:`,
          error
        );
        throw error;
      }
    }

    return null;
  });

/**
 * Process inventory expense: create stock movement and update balances
 */
async function _processInventoryExpense(
  userId: string,
  expenseId: string,
  expense: any
): Promise<void> {
  // Extract inventory details from expense
  const {
    merchant,
    amount,
    currency,
    date,
    vat,
    projectId,
    invoiceId,
  } = expense;

  try {
    // 1. Create stock movement record
    const movementId = db.collection('dummy').doc().id;
    const movementData = {
      expenseId: expenseId,
      type: 'purchase', // or 'return', 'adjustment'
      merchant: merchant,
      amount: amount,
      currency: currency,
      vat: vat || 0,
      date: date || admin.firestore.FieldValue.serverTimestamp(),
      projectId: projectId,
      invoiceId: invoiceId,
      status: 'completed',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: userId,
      description: `Purchase from ${merchant} - Invoice #${invoiceId || expenseId}`,
    };

    // Save movement to audit collection
    await db
      .collection('users')
      .doc(userId)
      .collection('inventory_movements')
      .doc(movementId)
      .set(movementData);

    // 2. Update inventory project totals
    if (projectId) {
      await _updateProjectInventory(userId, projectId, amount, vat);
    }

    // 3. Create audit entry in expense
    await db
      .collection('users')
      .doc(userId)
      .collection('expenses')
      .doc(expenseId)
      .collection('audit')
      .add({
        action: 'inventory_movement_created',
        movementId: movementId,
        ts: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.log(`Inventory movement created: ${movementId}`);
  } catch (error) {
    console.error(`Error processing inventory expense:`, error);
    throw error;
  }
}

/**
 * Update project inventory totals
 */
async function _updateProjectInventory(
  userId: string,
  projectId: string,
  amount: number,
  vat: number
): Promise<void> {
  const projectRef = db
    .collection('users')
    .doc(userId)
    .collection('projects')
    .doc(projectId);

  await projectRef.update({
    'inventory.totalSpent': admin.firestore.FieldValue.increment(amount),
    'inventory.totalVAT': admin.firestore.FieldValue.increment(vat || 0),
    'inventory.lastUpdated': admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * (Optional) Create warehouse/location stock update function
 * This would need additional fields in the expense like:
 * - warehouseId
 * - itemId
 * - quantity
 * - unit
 */
async function _updateWarehouseStock(
  userId: string,
  warehouseId: string,
  itemId: string,
  quantity: number
): Promise<void> {
  const stockRef = db
    .collection('users')
    .doc(userId)
    .collection('warehouses')
    .doc(warehouseId)
    .collection('stock')
    .doc(itemId);

  await stockRef.update({
    quantity: admin.firestore.FieldValue.increment(quantity),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  });
}
