/**
 * functions/src/crm/auto_follow_up.ts
 *
 * NIGHTLY CRM AUTO FOLLOW-UP ENGINE
 * Scans all users & clients and creates AI follow-up reminders for:
 *  - High churn risk clients (churnRisk >= 60)
 *  - Dormant clients (no activity in 30+ days)
 *
 * Scheduled: Every 24 hours (UTC)
 * Prevents duplicates: 7-day window per client
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const crmAutoFollowUp = functions.pubsub
  .schedule("every 24 hours")
  .timeZone("UTC")
  .onRun(async () => {
    console.log("✅ CRM Auto Follow-Up Job Started");

    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;

      const clientsSnap = await db
        .collection("users")
        .doc(userId)
        .collection("clients")
        .get();

      for (const clientDoc of clientsSnap.docs) {
        const clientId = clientDoc.id;
        const client = clientDoc.data();

        const churnRisk = client.churnRisk ?? client.ai?.riskScore ?? 0;
        const lastActivityRaw = client.lastActivityAt;
        const lastActivity =
          lastActivityRaw?.toDate?.() ??
          (lastActivityRaw ? new Date(lastActivityRaw) : null);

        const daysSinceActivity = lastActivity
          ? Math.floor((Date.now() - lastActivity.getTime()) / 86400000)
          : 9999;

        const isHighRisk = churnRisk >= 60;
        const isDormant = daysSinceActivity >= 30;

        if (!isHighRisk && !isDormant) continue;

        // Prevent duplicate reminders in 7-day window
        const remindersRef = db
          .collection("users")
          .doc(userId)
          .collection("reminders");

        const recent = await remindersRef
          .where("clientId", "==", clientId)
          .where("source", "==", "auto_follow_up")
          .where(
            "createdAt",
            ">",
            admin.firestore.Timestamp.fromMillis(
              Date.now() - 7 * 24 * 60 * 60 * 1000
            )
          )
          .get();

        if (!recent.empty) {
          console.log(`⏭ Skipping duplicate reminder for ${clientId}`);
          continue;
        }

        // 🔔 CREATE REMINDER
        const reminderPayload = {
          title: isHighRisk
            ? "⚠ High risk client – follow up"
            : "⏳ Dormant client – revive relationship",
          description: isHighRisk
            ? "Client shows high churn risk. Immediate contact recommended."
            : "No activity for 30+ days. Send a re-engagement message.",
          clientId,
          status: "pending",
          priority: isHighRisk ? "high" : "medium",
          source: "auto_follow_up",
          createdBy: "ai",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        const reminderDoc = await remindersRef.add(reminderPayload);

        // 🧠 ADD TIMELINE EVENT
        const timelineRef = db
          .collection("users")
          .doc(userId)
          .collection("clients")
          .doc(clientId)
          .collection("timeline");

        await timelineRef.add({
          type: "ai",
          title: isHighRisk
            ? "AI flagged high churn risk"
            : "AI detected dormant client",
          description: reminderPayload.description,
          relatedReminderId: reminderDoc.id,
          createdBy: "ai",
          aiImpact: {
            riskDelta: isHighRisk ? +5 : 0,
            relationshipDelta: isDormant ? -2 : 0,
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ Auto follow-up created for ${clientId}`);
      }
    }

    console.log("✅ CRM Auto Follow-Up Job Completed");
    return null;
  });
