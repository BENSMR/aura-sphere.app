import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getOpenaiClient } from '../utils/openai';
import { logger } from '../utils/logger';

const db = admin.firestore();

interface EmailRequest {
  type: string; // 'follow_up', 'proposal', 'intro', 'closing', etc.
  contactName: string;
  details: string; // context about the contact or situation
  goal: string; // what you want to achieve
}

interface GeneratedEmail {
  subject: string;
  text: string;
  html: string;
  raw?: any;
}

export const generateEmail = functions.https.onCall(
  async (data: EmailRequest, context: functions.https.CallableContext): Promise<GeneratedEmail> => {
    // ========== AUTHENTICATION ==========
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'You must be logged in to generate emails.');
    }

    const userId = context.auth.uid;
    logger.info('Email generation requested', { userId, type: data.type });

    // ========== INPUT VALIDATION ==========
    const { type, contactName, details, goal } = data;

    if (!type || !contactName || !goal) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: type, contactName, goal'
      );
    }

    // ========== AI CALL WITH ERROR HANDLING ==========
    let aiRaw: string | null = null;
    try {
      const openai = getOpenaiClient();
      if (!openai) {
        throw new Error(
          'OpenAI client not initialized. Check OPENAI_API_KEY in Firebase config.'
        );
      }

      const prompt = `You are a professional email writer. Generate a ${type} email.

Context:
- Recipient Name: ${contactName}
- Goal: ${goal}
- Details: ${details || 'No additional details provided'}

Write a professional, concise, and personalized email.

Return ONLY valid JSON with no markdown wrapping:
{
  "subject": "email subject line",
  "text": "plain text version of email body",
  "html": "<html><body>html formatted version</body></html>"
}`;

      const completion = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content:
              'You are a professional business email writer. Always return valid JSON only, no markdown wrapping.'
          },
          { role: 'user', content: prompt }
        ],
        response_format: { type: 'json_object' },
        temperature: 0.5,
        max_tokens: 800
      });

      aiRaw = completion.choices[0].message.content;
      logger.info('Email AI response received', { userId, contentLength: aiRaw?.length || 0 });
    } catch (err: any) {
      logger.error('OpenAI API failed for email generation', {
        error: err.message,
        code: err.code,
        userId,
        type
      });
      throw new functions.https.HttpsError(
        'internal',
        `Failed to generate email: ${err.message}. Please try again.`
      );
    }

    // ========== JSON PARSING WITH FALLBACK ==========
    let parsed: GeneratedEmail | null = null;

    try {
      parsed = JSON.parse(aiRaw ?? '{}');
      if (parsed && parsed.subject) {
        logger.info('Email JSON parsed successfully', { userId, hasSubject: !!parsed.subject });
      }
    } catch (e: any) {
      logger.error('Failed to parse email JSON', { error: e.message, userId, rawLength: aiRaw?.length });

      // Try extracting JSON from markdown wrapping
      const match = aiRaw && aiRaw.match(/\{[\s\S]*\}/);
      if (match) {
        try {
          parsed = JSON.parse(match[0]);
          logger.info('Email JSON extracted from raw response', { userId });
        } catch (e2) {
          parsed = null;
        }
      }
    }

    // ========== VALIDATION ==========
    if (!parsed || !parsed.subject || !parsed.text) {
      logger.error('Invalid email response from AI', { userId, parsed, aiLength: aiRaw?.length });
      throw new functions.https.HttpsError(
        'internal',
        'Failed to generate valid email content. Please try again.'
      );
    }

    // ========== AUDIT TRAIL (OPTIONAL) ==========
    try {
      await db.collection('users').doc(userId).collection('emailGenHistory').add({
        type,
        contactName,
        goal,
        subjectGenerated: parsed.subject,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (auditErr: any) {
      // Log but don't fail the function for audit trail errors
      logger.warn('Failed to save email generation audit trail', { error: auditErr.message, userId });
    }

    // ========== RESPONSE ==========
    return {
      subject: parsed.subject,
      text: parsed.text,
      html: parsed.html || parsed.text // Fallback to text if no HTML
    };
  }
);
