import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import nodemailer from 'nodemailer';

const db = admin.firestore();

export const autoStatusAndReminder = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const now = new Date();

    // 1) Mark overdue invoices
    // Find all unpaid/partial invoices with dueDate in the past
    const overdueSnap = await db
      .collection('invoices')
      .where('status', 'in', ['unpaid', 'partial'])
      .where('dueDate', '<', now)
      .get();

    const batch = db.batch();
    overdueSnap.forEach((doc) => {
      batch.update(doc.ref, { status: 'overdue' });
    });
    await batch.commit();
    console.log(`Marked ${overdueSnap.size} invoices as overdue`);

    // 2) Send reminders for invoices with reminderEnabled = true
    //   - status in ['unpaid','overdue']
    //   - lastReminderAt is null or older than 3 days
    const threeDaysAgo = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);

    const remindSnap = await db
      .collection('invoices')
      .where('reminderEnabled', '==', true)
      .where('status', 'in', ['unpaid', 'overdue'])
      .get();

    // Configure SMTP once
    const mailConfig = functions.config().mail;
    const transporter = nodemailer.createTransport({
      host: mailConfig.host,
      port: mailConfig.port,
      secure: false,
      auth: {
        user: mailConfig.user,
        pass: mailConfig.pass,
      },
    });

    let remindersSent = 0;

    for (const doc of remindSnap.docs) {
      const inv = doc.data() as any;
      const lastReminderAt = inv.lastReminderAt
        ? (inv.lastReminderAt as admin.firestore.Timestamp).toDate()
        : null;

      // Skip if reminder was sent within the last 3 days
      if (lastReminderAt && lastReminderAt > threeDaysAgo) {
        continue;
      }

      const clientEmail = inv.clientEmail;
      if (!clientEmail) continue;

      try {
        const amount = inv.total?.toFixed(2) ?? '0.00';
        const invoiceNumber = inv.invoiceNumber ?? doc.id;
        const dueDateText = inv.dueDate
          ? (inv.dueDate as admin.firestore.Timestamp)
              .toDate()
              .toISOString()
              .split('T')[0]
          : 'N/A';

        // Find business owner for this invoice
        const userId = inv.userId;
        const userSnap = await db.collection('users').doc(userId).get();
        const user = userSnap.data() || {};
        const businessName = user.businessName || 'Your Business';

        const subject =
          inv.status === 'overdue'
            ? `Overdue reminder: ${invoiceNumber} from ${businessName}`
            : `Payment reminder: ${invoiceNumber} from ${businessName}`;

        const html = `
          <p>Hello,</p>
          <p>This is a friendly reminder about your invoice:</p>
          <p><b>${invoiceNumber}</b><br>
          <b>Amount:</b> €${amount}<br>
          <b>Due date:</b> ${dueDateText}</p>
          <p>Status: <b>${inv.status}</b></p>
          <p>If you already paid, please ignore this message.</p>
          <p>Best regards,<br>${businessName}</p>
        `;

        await transporter.sendMail({
          from: mailConfig.from || 'no-reply@aurasphere.app',
          to: clientEmail,
          subject,
          html,
        });

        // Update invoice tracking
        await doc.ref.update({
          lastReminderAt: admin.firestore.FieldValue.serverTimestamp(),
          reminderCount: admin.firestore.FieldValue.increment(1),
        });

        remindersSent++;
        console.log(`Reminder sent to ${clientEmail} for invoice ${invoiceNumber}`);
      } catch (error) {
        console.error(`Failed to send reminder for invoice ${doc.id}:`, error);
      }
    }

    console.log(`Completed: ${remindersSent} reminders sent`);
    return null;
  });
