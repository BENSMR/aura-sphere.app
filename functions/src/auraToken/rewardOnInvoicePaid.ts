/**
 * functions/src/auraToken/rewardOnInvoicePaid.ts
 *
 * Rewards users with AuraTokens when an invoice is marked as paid
 * 
 * Triggers: onUpdate for users/{userId}/invoices/{invoiceId}
 * Rewards: 15 AuraTokens per paid invoice
 * Records: Transaction in auraTokenTransactions collection
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const rewardOnInvoicePaid = functions.firestore
  .document("users/{userId}/invoices/{invoiceId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { userId, invoiceId } = context.params;

    // Only reward if status changed TO "paid" (prevent duplicate rewards)
    if (before.status === "paid" || after.status !== "paid") {
      return;
    }

    const rewardAmount = 15;

    try {
      // Update user's AuraToken balance
      const walletRef = db
        .collection("users")
        .doc(userId)
        .collection("wallet")
        .doc("aura");

      // Check if wallet exists, create if not
      const walletSnap = await walletRef.get();
      if (!walletSnap.exists) {
        await walletRef.set({
          balance: rewardAmount,
          currency: "AURA",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        await walletRef.update({
          balance: admin.firestore.FieldValue.increment(rewardAmount),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Record transaction for audit trail
      const transactionRef = db
        .collection("users")
        .doc(userId)
        .collection("auraTokenTransactions")
        .doc();

      await transactionRef.set({
        type: "reward",
        amount: rewardAmount,
        reason: "invoice_paid",
        description: `Reward for paid invoice: ${after.invoiceNumber || invoiceId}`,
        metadata: {
          invoiceId,
          invoiceNumber: after.invoiceNumber || null,
          invoiceAmount: after.totals?.total || after.amount || 0,
          currency: after.currency || "USD",
        },
        balanceAfter: walletSnap.exists
          ? (walletSnap.data()?.balance || 0) + rewardAmount
          : rewardAmount,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `✅ ${rewardAmount} AuraTokens rewarded to user ${userId} for paid invoice ${invoiceId}`
      );
    } catch (error) {
      console.error(
        `❌ Error rewarding AuraTokens for invoice ${invoiceId}:`,
        error
      );
    }
  });
