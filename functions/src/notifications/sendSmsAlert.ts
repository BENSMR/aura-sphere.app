import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import fetch from 'node-fetch';

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

export const sendSmsAlert = functions.https.onCall(async (data, ctx) => {
  // protect call
  if (!ctx.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  // expected: { to: '+1234', body: '...' }
  const to = data?.to;
  const body = data?.body;
  if (!to || !body) throw new functions.https.HttpsError('invalid-argument', 'Missing fields');

  // Twilio
  const twSid = functions.config().twilio?.sid;
  const twToken = functions.config().twilio?.token;
  const twFrom = functions.config().twilio?.from;

  if (twSid && twToken && twFrom) {
    const url = `https://api.twilio.com/2010-04-01/Accounts/${twSid}/Messages.json`;
    const params = new URLSearchParams();
    params.append('To', to);
    params.append('From', twFrom);
    params.append('Body', body);

    const resp = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: 'Basic ' + Buffer.from(`${twSid}:${twToken}`).toString('base64'),
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: params
    });
    const json = await resp.json();
    await db.collection('notifications_audit').doc().set({
      type: 'sms',
      to,
      body,
      response: json,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      actor: ctx.auth.uid || 'system'
    });
    return { success: true, response: json };
  }

  // if Twilio not configured, return no-op
  await db.collection('notifications_audit').doc().set({
    type: 'sms',
    to,
    body,
    note: 'Twilio not configured',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    actor: ctx.auth.uid || 'system'
  });
  return { success: false, reason: 'twilio_not_configured' };
});
