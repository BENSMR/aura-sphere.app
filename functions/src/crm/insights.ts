import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getOpenaiClient } from '../utils/openai';
import { logger } from '../utils/logger';

const db = admin.firestore();



export const generateCrmInsights = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Only authenticated users can request insights.');
  }

  const callerUid = context.auth.uid;
  const { userId, contactIds } = data;

  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing userId');
  }

  // Security: Validate permissions
  if (callerUid !== userId) {
    const adminDoc = await db.doc(`admins/${callerUid}`).get();
    if (!adminDoc.exists) {
      throw new functions.https.HttpsError('permission-denied', 'Not allowed to request insights for another user.');
    }
  }

  logger.info('Generating CRM insights', { userId, contactCount: contactIds?.length || 0 });

  const metaRef = db.doc(`users/${userId}/crm_insights_meta/lastRun`);
  const metaSnap = await metaRef.get();

  const NOW = Date.now();
  const LIMIT = 1000 * 60 * 60 * 3; // 3 hours cooldown

  // --------- 🌟 SMART CACHE CHECK ----------
  if (metaSnap.exists) {
    const lastData = metaSnap.data();
    const lastAt = lastData?.lastAt?.toDate?.();

    // If we have a cached version, return it instantly
    if (lastData?.cachedInsights) {
      const cached = lastData.cachedInsights;

      // Check cooldown period
      if (lastAt && NOW - lastAt.getTime() < LIMIT) {
        logger.info('Returning cached insights', { userId });
        return {
          success: true,
          source: "cache",
          cached: true,
          cooldown: true,
          insights: cached,
          nextAllowedAt: new Date(lastAt.getTime() + LIMIT).toISOString()
        };
      }
    }
  }

  // --------- 🔍 Load Contacts ----------
  const contactsRef = db.collection('users').doc(userId).collection('contacts');
  let contactsSnap;

  if (contactIds && Array.isArray(contactIds) && contactIds.length > 0) {
    const docs = await Promise.all(contactIds.map((id: string) => contactsRef.doc(id).get()));
    contactsSnap = { docs };
  } else {
    contactsSnap = await contactsRef.limit(80).get();
  }

  if (!contactsSnap || contactsSnap.docs.length === 0) {
    throw new functions.https.HttpsError('not-found', 'No contacts found.');
  }

  const contactsSummaryArray = contactsSnap.docs.map((d: any) => {
    const data = d.data();
    return `ID:${d.id} Name:${data.name || ''} Company:${data.company || ''} Status:${data.status || ''} Tags:${(data.tags || []).join(',')} Notes:${(data.notes || '').slice(0, 200)}`;
  });

  const contactsSummary = contactsSummaryArray.join('\n');

  const prompt = `
You are AuraSphere CRM Insights agent. Given the following summary of contacts and recent interactions, produce:
1) a short segmentation (3 suggested segments + rationale),
2) top 5 contacts most likely to convert with a numeric score 0-100 and why,
3) suggested next action for top 5 (template messages, subject lines, best channel),
4) one short sales outreach script (email) and one short follow-up SMS,
5) a short explanation of how confidence was assessed.

Contacts summary:
${contactsSummary}

Return a JSON object exactly with keys:
{
 "segments": [{"name":"", "reason":""}, ...],
 "topContacts": [{"id":"", "name":"", "score": 0, "reason": ""}, ...],
 "actions": [{"contactId":"", "title":"", "suggestion":"", "channel":"", "template":"", "dueDays": 2}, ...],
 "emailTemplate": {"subject":"", "body":""},
 "smsTemplate": {"body":""},
 "confidence": "low|medium|high",
 "explain": "short reasoning text"
}
Do not include any extra text outside JSON. Keep responses concise.
`;

  // --------- 🤖 AI CALL ----------
  let aiRaw;
  try {
    const openai = getOpenaiClient();
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: 'Return ONLY valid JSON.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.2,
      max_tokens: 800
    });

    aiRaw = completion.choices[0].message.content;
    logger.info('AI response received', { userId });
  } catch (err: any) {
    logger.error('OpenAI API failed', { error: err.message, userId });
    throw new functions.https.HttpsError('internal', `OpenAI failed: ${err.message}`);
  }

  // --------- 📦 Parse JSON ----------
  let parsed;
  try {
    parsed = JSON.parse(aiRaw ?? "{}");
    logger.info('JSON parsing successful', { userId });
  } catch (e: any) {
    logger.error('Failed to parse AI response', { error: e.message, userId });
    const match = aiRaw && aiRaw.match(/\{[\s\S]*\}$/);
    parsed = match ? JSON.parse(match[0]) : null;
  }

  if (!parsed) {
    throw new functions.https.HttpsError('internal', 'Failed to parse AI output.');
  }

  // --------- 💾 SAVE INSIGHTS + CREATE TASKS ----------
  const insightsRef = db.collection('users').doc(userId).collection('crm_insights').doc();

  await insightsRef.set({
    userId, // IMPORTANT: for security rules
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: callerUid,
    promptSummary: contactsSummaryArray.slice(0, 20),
    raw: parsed
  });

  // Create follow-up tasks automatically if actions exist
  try {
    const actions = Array.isArray(parsed.actions) ? parsed.actions : [];
    const batch = db.batch();
    const tasksCol = db.collection('users').doc(userId).collection('tasks');

    const defaultDueMs = 1000 * 60 * 60 * 24 * 2; // default 2 days
    const nowTs = admin.firestore.Timestamp.now();

    for (const action of actions) {
      const id = tasksCol.doc().id;
      // derive fields safely
      const contactId = action.contactId ?? action.contact_id ?? null;
      const suggestion = action.suggestion ?? action.template ?? 'Follow up';
      const channel = action.channel ?? 'email';
      // If AI suggested a schedule in metadata, use it; otherwise default
      let dueAt = admin.firestore.Timestamp.fromMillis(Date.now() + defaultDueMs);
      if (action.dueDays && Number.isFinite(Number(action.dueDays))) {
        dueAt = admin.firestore.Timestamp.fromMillis(Date.now() + Number(action.dueDays) * 24 * 60 * 60 * 1000);
      } else if (action.dueMillis && Number.isFinite(Number(action.dueMillis))) {
        dueAt = admin.firestore.Timestamp.fromMillis(Number(action.dueMillis));
      }

      const taskDocRef = tasksCol.doc(id);
      const taskPayload = {
        id,
        userId, // IMPORTANT: for security rules
        title: (action.title ?? (suggestion.length > 60 ? suggestion.substring(0, 60) + '...' : suggestion)),
        description: suggestion,
        contactId: contactId,
        channel,
        template: action.template ?? '',
        status: 'pending', // pending -> scheduled -> done
        autoGenerated: true,
        sourceInsightId: insightsRef.id,
        createdAt: nowTs,
        dueAt: dueAt,
        remindAt: dueAt, // client or scheduler can adjust
        assignedTo: userId
      };

      batch.set(taskDocRef, taskPayload);
    }

    await batch.commit();
    logger.info('Tasks created', { userId, count: actions.length });

    // --------- 🎯 UPDATE CRM CONTACT SCORES ----------
    try {
      const crmCol = db.collection('users').doc(userId).collection('crm');

      for (const action of actions) {
        if (!action.contactId && !action.contact_id) continue;

        const contactId = action.contactId ?? action.contact_id;
        const ref = crmCol.doc(contactId);

        await ref.set(
          {
            score: admin.firestore.FieldValue.increment(5),
            lastAiAction: action.title ?? '',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        logger.info('Updated CRM contact score', {
          userId,
          contactId,
          action: action.title,
        });
      }
    } catch (err: any) {
      logger.error('Failed to update CRM contact scores', { error: err.message, userId });
      // do not fail the whole function — insights still returned
    }
  } catch (err: any) {
    logger.error('Failed creating follow-up tasks', { error: err.message, userId });
    // do not fail the whole function — insights still returned
  }

  // Save smart cache
  await metaRef.set(
    {
      lastAt: admin.firestore.FieldValue.serverTimestamp(),
      cachedInsights: parsed
    },
    { merge: true }
  );

  return {
    success: true,
    source: "openai",
    cached: false,
    insights: parsed
  };
});