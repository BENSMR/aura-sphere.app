import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Scheduled Cloud Function that runs every 24 hours
 * Automatically marks unpaid and partially paid invoices as overdue
 * if their due date has passed
 */
export const markOverdueInvoices = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async (context) => {
    try {
      const now = new Date();
      const db = admin.firestore();

      // Query all invoices that are unpaid or partial with past due dates
      const snapshot = await db
        .collection("invoices")
        .where("status", "in", ["unpaid", "partial"])
        .where("dueDate", "<", admin.firestore.Timestamp.fromDate(now))
        .get();

      if (snapshot.empty) {
        console.log("No overdue invoices to update");
        return null;
      }

      // Use batch write for atomic updates
      const batch = db.batch();
      let updateCount = 0;

      snapshot.forEach((doc) => {
        batch.update(doc.ref, {
          status: "overdue",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        updateCount++;
      });

      await batch.commit();
      console.log(`Successfully marked ${updateCount} invoices as overdue`);

      return null;
    } catch (error) {
      console.error("Error in markOverdueInvoices:", error);
      throw error;
    }
  });
