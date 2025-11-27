import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { logger } from '../utils/logger';

const db = admin.firestore();

async function getTaskDoc(taskRef: admin.firestore.DocumentReference) {
  const snap = await taskRef.get();
  if (!snap.exists) return null;
  return snap.data();
}

export const sendTaskEmail = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const callerUid = context.auth.uid;
  const { userId, taskId } = data;
  
  if (!userId || !taskId) {
    throw new functions.https.HttpsError('invalid-argument', 'userId and taskId required');
  }

  logger.info('sendTaskEmail called', { userId, taskId, callerUid });

  // security: only owner or admin can send
  if (callerUid !== userId) {
    const adminDoc = await db.doc(`admins/${callerUid}`).get();
    if (!adminDoc.exists) {
      logger.error('Permission denied for non-owner', { userId, taskId, callerUid });
      throw new functions.https.HttpsError('permission-denied', 'Not allowed');
    }
  }

  const taskRef = db.collection('users').doc(userId).collection('tasks').doc(taskId);
  const taskData = await getTaskDoc(taskRef);
  
  if (!taskData) {
    logger.error('Task not found', { userId, taskId });
    throw new functions.https.HttpsError('not-found', 'Task not found');
  }

  // Only send if status is ready_to_send or pending (owner may preview)
  if (!(taskData.status === 'ready_to_send' || taskData.status === 'pending')) {
    logger.error('Task status not ready for sending', { userId, taskId, status: taskData.status });
    throw new functions.https.HttpsError('failed-precondition', `Task status is ${taskData.status}`);
  }

  // Build email
  // Determine recipient: if task.contactId exists, try to read contact email
  let toEmail = data.overrideEmail ?? null;
  if (!toEmail && taskData.contactId) {
    try {
      const contactRef = db.collection('users').doc(userId).collection('contacts').doc(taskData.contactId);
      const contactSnap = await contactRef.get();
      if (contactSnap.exists) {
        const contact = contactSnap.data();
        toEmail = contact?.email ?? null;
      }
    } catch (err: any) {
      logger.warn('Failed to load contact email', { userId, contactId: taskData.contactId, error: err.message });
    }
  }

  if (!toEmail) {
    logger.error('No recipient email found', { userId, taskId, contactId: taskData.contactId });
    throw new functions.https.HttpsError('failed-precondition', 'No recipient email found');
  }

  // Template: prefer task.template, otherwise simple constructed body
  const subject = data.overrideSubject ?? taskData.title;
  const message = data.overrideBody ?? (taskData.template || `${taskData.description}`);

  try {
    // Write to /mail collection for Firebase Email Extension
    const mailRef = db.collection('mail').doc();
    
    await mailRef.set({
      to: toEmail,
      message: {
        subject: subject,
        text: message,
        html: `
          <div style="font-family:sans-serif;padding:20px;max-width:600px;">
            <h2>${subject}</h2>
            <p>${message}</p>
            <br><hr>
            <p style="font-size:12px;color:#777;">
              Sent automatically by AuraSphere Pro ✨
            </p>
          </div>
        `,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: callerUid,
      userId: userId,
      taskId: taskId,
    });

    logger.info('Email queued for delivery', { userId, taskId, to: toEmail, subject, mailId: mailRef.id });

    // Update task status -> sent and add audit
    await taskRef.update({
      status: 'sent',
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      lastSentBy: callerUid,
      emailQueueId: mailRef.id
    });

    const auditRef = db.collection('users').doc(userId).collection('task_audit').doc();
    await auditRef.set({
      action: 'email_sent',
      taskId,
      to: toEmail,
      subject,
      mailId: mailRef.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      sentBy: callerUid,
      userId
    });

    return { success: true, message: 'Email queued for delivery', emailQueueId: mailRef.id };
  } catch (err: any) {
    logger.error('Failed to queue email', { userId, taskId, error: err.message });
    
    // write error audit
    try {
      await db.collection('users').doc(userId).collection('task_audit').add({
        action: 'email_failed',
        taskId,
        error: err.toString(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        attemptBy: callerUid,
        userId
      });
    } catch (auditErr) {
      logger.error('Failed to log email failure', { error: auditErr });
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to queue email for delivery');
  }
});
