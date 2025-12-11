import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();

interface InvoiceData {
  taxCalculatedBy?: string;
  currency?: string;
  taxStatus?: string;
  amount?: number;
  totalAmount?: number;
  [key: string]: any;
}

/**
 * Auto-Assign Tax Calculation on Invoice Create
 *
 * Trigger: Fires whenever a new invoice is created under users/{uid}/invoices/{invoiceId}
 *
 * Behavior:
 * 1. Check if invoice already has tax info (skip if so)
 * 2. Create a queue request in internal/tax_queue/requests
 * 3. Mark invoice as taxStatus: "queued"
 * 4. processTaxQueue will pick this up and calculate in ~1 minute
 *
 * This decouples invoice creation (real-time) from tax calculation (async).
 * Client sees immediate invoice creation, tax updates automatically once calculated.
 */
export const onInvoiceCreateAutoAssign = functions.firestore
  .document('users/{uid}/invoices/{invoiceId}')
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    try {
      const data = snap.data() as InvoiceData;
      const uid = (context.params as Record<string, string>).uid;
      const invoiceId = (context.params as Record<string, string>).invoiceId;

      // Skip if invoice already has tax info calculated
      if (data?.taxCalculatedBy || data?.currency) {
        console.log(
          `✓ Invoice ${invoiceId} already has tax info; skipping queue`,
        );
        return null;
      }

      // Skip if no amount
      if (!data?.amount && !data?.totalAmount) {
        console.log(`⚠️ Invoice ${invoiceId} has no amount; skipping queue`);
        return null;
      }

      // Create queue request for background processing
      const queueRef = admin
        .firestore()
        .collection('internal')
        .doc('tax_queue')
        .collection('requests')
        .doc();

      await queueRef.set({
        uid,
        entityPath: snap.ref.path,
        entityType: 'invoice',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        processed: false,
        attempts: 0,
      });

      console.log(`⏳ Queued tax calculation for invoice ${invoiceId}`);

      // Update invoice to indicate it's queued for tax calculation
      await snap.ref.update({
        taxStatus: 'queued',
        taxQueueRequestId: queueRef.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        audit: admin.firestore.FieldValue.arrayUnion({
          action: 'tax_calculation_queued',
          queueRequestId: queueRef.id,
          at: admin.firestore.FieldValue.serverTimestamp(),
        }),
      });

      console.log(
        `✔️ Invoice ${invoiceId} marked as queued for tax calculation`,
      );
      return null;
    } catch (err) {
      console.error(
        `❌ Error in onInvoiceCreateAutoAssign for invoice ${(context.params as Record<string, string>).invoiceId}:`,
        err,
      );
      // Don't rethrow - allow invoice creation to succeed even if queueing fails
      // Admin can manually trigger tax calculation via UI
      return null;
    }
  });

/**
 * Auto-Assign Tax Calculation on Expense Create
 *
 * Trigger: Fires whenever a new expense is created under users/{uid}/expenses/{expenseId}
 *
 * Similar to invoices, but direction = 'purchase' for tax calculation.
 */
export const onExpenseCreateAutoAssign = functions.firestore
  .document('users/{uid}/expenses/{expenseId}')
  .onCreate(
    async (
      snap: functions.firestore.QueryDocumentSnapshot,
      context: functions.EventContext,
    ) => {
      try {
        const data = snap.data() as InvoiceData;
        const uid = (context.params as Record<string, string>).uid;
        const expenseId = (context.params as Record<string, string>).expenseId;

        // Skip if expense already has tax info calculated
        if (data?.taxCalculatedBy || data?.currency) {
          console.log(`✓ Expense ${expenseId} already has tax info; skipping`);
          return null;
        }

        // Skip if no amount
        if (!data?.amount && !data?.totalAmount) {
          console.log(`⚠️ Expense ${expenseId} has no amount; skipping`);
          return null;
        }

        // Create queue request
        const queueRef = admin
          .firestore()
          .collection('internal')
          .doc('tax_queue')
          .collection('requests')
          .doc();

        await queueRef.set({
          uid,
          entityPath: snap.ref.path,
          entityType: 'expense',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          processed: false,
          attempts: 0,
        });

        console.log(`⏳ Queued tax calculation for expense ${expenseId}`);

        // Update expense
        await snap.ref.update({
          taxStatus: 'queued',
          taxQueueRequestId: queueRef.id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          audit: admin.firestore.FieldValue.arrayUnion({
            action: 'tax_calculation_queued',
            queueRequestId: queueRef.id,
            at: admin.firestore.FieldValue.serverTimestamp(),
          }),
        });

        console.log(
          `✔️ Expense ${expenseId} marked as queued for tax calculation`,
        );
        return null;
      } catch (err) {
        console.error(
          `❌ Error in onExpenseCreateAutoAssign for expense ${(context.params as Record<string, string>).expenseId}:`,
          err,
        );
        return null;
      }
    },
  );

/**
 * Auto-Assign Tax Calculation on PurchaseOrder Create
 *
 * Similar pattern for purchase orders.
 */
export const onPurchaseOrderCreateAutoAssign = functions.firestore
  .document('users/{uid}/purchaseOrders/{poId}')
  .onCreate(
    async (
      snap: functions.firestore.QueryDocumentSnapshot,
      context: functions.EventContext,
    ) => {
      try {
        const data = snap.data() as InvoiceData;
        const uid = (context.params as Record<string, string>).uid;
        const poId = (context.params as Record<string, string>).poId;

        // Skip if PO already has tax info
        if (data?.taxCalculatedBy || data?.currency) {
          console.log(`✓ PO ${poId} already has tax info; skipping`);
          return null;
        }

        // Skip if no amount
        if (!data?.amount && !data?.totalAmount) {
          console.log(`⚠️ PO ${poId} has no amount; skipping`);
          return null;
        }

        // Create queue request
        const queueRef = admin
          .firestore()
          .collection('internal')
          .doc('tax_queue')
          .collection('requests')
          .doc();

        await queueRef.set({
          uid,
          entityPath: snap.ref.path,
          entityType: 'purchaseOrder',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          processed: false,
          attempts: 0,
        });

        console.log(`⏳ Queued tax calculation for PO ${poId}`);

        // Update PO
        await snap.ref.update({
          taxStatus: 'queued',
          taxQueueRequestId: queueRef.id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          audit: admin.firestore.FieldValue.arrayUnion({
            action: 'tax_calculation_queued',
            queueRequestId: queueRef.id,
            at: admin.firestore.FieldValue.serverTimestamp(),
          }),
        });

        console.log(
          `✔️ PO ${poId} marked as queued for tax calculation`,
        );
        return null;
      } catch (err) {
        console.error(
          `❌ Error in onPurchaseOrderCreateAutoAssign for PO ${(context.params as Record<string, string>).poId}:`,
          err,
        );
        return null;
      }
    },
  );
