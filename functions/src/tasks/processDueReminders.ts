import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { logger } from '../utils/logger';

const db = admin.firestore();

/**
 * Scheduled function runs every 2 minutes (free tier friendly)
 * Finds tasks with status 'pending' and remindAt <= now
 * Automatically queues emails via Firebase Email Extension
 * Updates task status to 'email_sent' after queuing
 */
export const processDueReminders = functions.pubsub
  .schedule('every 2 minutes') // free tier friendly
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    const q = await db.collectionGroup('tasks')
      .where('status', '==', 'pending')
      .where('remindAt', '<=', now)
      .limit(30)
      .get();

    if (q.empty) {
      logger.info('processDueReminders: No pending tasks found');
      return { processed: 0 };
    }

    logger.info('processDueReminders: Found tasks to process', { count: q.docs.length });

    let count = 0;

    for (const doc of q.docs) {
      try {
        const task = doc.data();
        const userId = task.assignedTo;

        // fetch user's email
        const userDoc = await db.collection('users').doc(userId).get();
        const user = userDoc.data();
        const email = user?.email;

        if (!email) {
          logger.warn('processDueReminders: User has no email', { userId, taskId: task.id });
          continue;
        }

        // queue email for the free extension
        const mailRef = await db.collection('mail').add({
          to: email,
          message: {
            subject: `Task Reminder: ${task.title}`,
            text: `Reminder: ${task.description}`,
            html: `
              <h2>Task Reminder</h2>
              <p>${task.description}</p>
              <p><b>Due:</b> ${task.dueAt?.toDate()}</p>
              <hr/>
              <small>AuraSphere Pro – Intelligent Business System</small>
            `,
          },
          userId,
          taskId: task.id,
        });

        logger.info('processDueReminders: Email queued', {
          userId,
          taskId: task.id,
          mailId: mailRef.id,
          to: email,
        });

        // update task state
        await doc.ref.update({
          status: 'email_sent',
          emailedAt: admin.firestore.FieldValue.serverTimestamp(),
          emailQueueId: mailRef.id,
        });

        count++;
      } catch (err: any) {
        logger.error('processDueReminders: Error processing task', {
          error: err.message,
          taskId: doc.id,
        });
        // Continue processing other tasks even if one fails
      }
    }

    logger.info('processDueReminders: Completed', { sent: count });
    return { sent: count };
  });