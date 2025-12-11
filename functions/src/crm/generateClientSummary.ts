import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { logger } from '../utils/logger';
import OpenAI from 'openai';

const db = admin.firestore();

// Initialize OpenAI with API key from environment (only if key is available)
const OPENAI_KEY = process.env.OPENAI_KEY || functions.config()?.openai?.key || null;
let openai: OpenAI | null = null;

if (OPENAI_KEY) {
  openai = new OpenAI({
    apiKey: OPENAI_KEY,
  });
}

/**
 * Trigger: Fires when a client document is updated
 * 
 * Purpose: Auto-generate AI-powered client relationship summaries
 * - Detects changes in key metrics (aiScore, churnRisk, lifetimeValue)
 * - Generates business-focused summary using GPT-4o-mini
 * - Updates aiSummary field with generated text
 * 
 * Preconditions:
 * - One of: aiScore, churnRisk, or lifetimeValue must change
 * - OpenAI API key must be configured in environment
 * 
 * Side Effects:
 * - Updates client's aiSummary field
 * - Calls OpenAI API (costs ~$0.001 per call)
 * - Updates updatedAt timestamp
 */
export const generateClientSummary = functions.firestore
  .document('clients/{clientId}')
  .onUpdate(async (change, context) => {
    const { clientId } = context.params;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    try {
      // Validate data exists
      if (!beforeData || !afterData) {
        logger.warn('Missing data in client update', { clientId });
        return { success: false, reason: 'Missing data' };
      }

      // Only regenerate summary if key metrics changed
      // This prevents unnecessary API calls and costs
      const metricsChanged =
        beforeData.aiScore !== afterData.aiScore ||
        beforeData.churnRisk !== afterData.churnRisk ||
        beforeData.lifetimeValue !== afterData.lifetimeValue;

      if (!metricsChanged) {
        logger.info('No metric changes detected, skipping summary regeneration', {
          clientId,
        });
        return { success: false, reason: 'No metric changes' };
      }

      // Skip if OpenAI is not configured
      if (!openai) {
        logger.warn('OpenAI API key not configured, skipping summary generation', {
          clientId,
        });
        return { success: false, reason: 'OpenAI not configured' };
      }

      logger.info('Metric changes detected, generating new summary', {
        clientId,
        aiScoreChanged: beforeData.aiScore !== afterData.aiScore,
        churnRiskChanged: beforeData.churnRisk !== afterData.churnRisk,
        lifetimeValueChanged: beforeData.lifetimeValue !== afterData.lifetimeValue,
      });

      // Extract client data for summary
      const {
        name = 'Unknown',
        company = '',
        lifetimeValue = 0,
        aiScore = 0,
        churnRisk = 0,
        totalInvoices = 0,
        sentiment = 'unknown',
        vipStatus = false,
        status = 'active',
        lastPaymentDate,
        lastActivityAt,
      } = afterData;

      // Calculate days since last payment
      let daysSincePayment = 'unknown';
      if (lastPaymentDate) {
        const lastPayment = lastPaymentDate?.toDate?.()
          ? lastPaymentDate.toDate()
          : new Date(lastPaymentDate);
        daysSincePayment = String(
          Math.floor((Date.now() - lastPayment.getTime()) / (1000 * 3600 * 24))
        );
      }

      // Calculate days since last activity
      let daysSinceActivity = 'unknown';
      if (lastActivityAt) {
        const lastActivity = lastActivityAt?.toDate?.()
          ? lastActivityAt.toDate()
          : new Date(lastActivityAt);
        daysSinceActivity = String(
          Math.floor((Date.now() - lastActivity.getTime()) / (1000 * 3600 * 24))
        );
      }

      // Build detailed prompt for OpenAI
      const prompt = `You are a business analyst. Summarize this client relationship in 2-3 sentences. Be concise, actionable, and highlight key business insights.

Client: ${name}${company ? ` at ${company}` : ''}

Metrics:
- Lifetime Value: $${lifetimeValue.toFixed(2)}
- AI Relationship Score: ${aiScore}/100
- Churn Risk: ${churnRisk}/100
- Total Invoices: ${totalInvoices}
- Sentiment: ${sentiment}
- VIP Status: ${vipStatus ? 'Yes' : 'No'}
- Current Status: ${status}
- Days Since Last Payment: ${daysSincePayment}
- Days Since Last Activity: ${daysSinceActivity}

Provide a business-focused summary highlighting engagement, value, and risks.`;

      logger.info('Calling OpenAI API', {
        clientId,
        name,
        company,
      });

      // Call OpenAI API to generate summary
      const response = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content:
              'You are a business analyst specializing in client relationship insights. Provide concise, actionable summaries.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        max_tokens: 150,
        temperature: 0.7,
      });

      // Extract summary from response
      const aiSummary =
        response.choices[0]?.message?.content?.trim() ||
        'Unable to generate summary';

      logger.info('Summary generated from OpenAI', {
        clientId,
        summaryLength: aiSummary.length,
        tokensUsed: response.usage?.total_tokens,
      });

      // Update client document with generated summary
      const clientRef = change.after.ref;
      await clientRef.update({
        aiSummary,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info('Client summary updated successfully', {
        clientId,
        name,
        summaryLength: aiSummary.length,
      });

      return {
        success: true,
        clientId,
        summaryLength: aiSummary.length,
        aiSummary,
      };
    } catch (error: any) {
      logger.error('generateClientSummary function failed', {
        clientId,
        error: error.message,
        code: error.code,
      });

      // Don't fail the update if summary generation fails
      // The client document will still be updated, just without the summary
      return {
        success: false,
        error: error.message || 'Failed to generate summary',
      };
    }
  });

/**
 * Callable function: Regenerate summary for a single client
 * 
 * Purpose: Manual trigger to regenerate client summary on demand
 * - Useful for testing or forcing regeneration
 * - Can be called from client app
 * - Respects OpenAI rate limits
 */
export const regenerateClientSummary = functions.https.onCall(
  async (data, context) => {
    try {
      // Verify user is authenticated
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const { clientId } = data;
      if (!clientId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'clientId is required'
        );
      }

      const userId = context.auth.uid;

      // Skip if OpenAI is not configured
      if (!openai) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'OpenAI API key is not configured'
        );
      }

      // Fetch client document
      const clientRef = db
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(clientId);

      const clientSnap = await clientRef.get();
      if (!clientSnap.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Client not found'
        );
      }

      const clientData = clientSnap.data() as any;

      // Build prompt
      const {
        name = 'Unknown',
        company = '',
        lifetimeValue = 0,
        aiScore = 0,
        churnRisk = 0,
        totalInvoices = 0,
        sentiment = 'unknown',
        vipStatus = false,
        status = 'active',
        lastPaymentDate,
        lastActivityAt,
      } = clientData;

      let daysSincePayment = 'unknown';
      if (lastPaymentDate) {
        const lastPayment = lastPaymentDate?.toDate?.()
          ? lastPaymentDate.toDate()
          : new Date(lastPaymentDate);
        daysSincePayment = String(
          Math.floor((Date.now() - lastPayment.getTime()) / (1000 * 3600 * 24))
        );
      }

      let daysSinceActivity = 'unknown';
      if (lastActivityAt) {
        const lastActivity = lastActivityAt?.toDate?.()
          ? lastActivityAt.toDate()
          : new Date(lastActivityAt);
        daysSinceActivity = String(
          Math.floor((Date.now() - lastActivity.getTime()) / (1000 * 3600 * 24))
        );
      }

      const prompt = `You are a business analyst. Summarize this client relationship in 2-3 sentences. Be concise, actionable, and highlight key business insights.

Client: ${name}${company ? ` at ${company}` : ''}

Metrics:
- Lifetime Value: $${lifetimeValue.toFixed(2)}
- AI Relationship Score: ${aiScore}/100
- Churn Risk: ${churnRisk}/100
- Total Invoices: ${totalInvoices}
- Sentiment: ${sentiment}
- VIP Status: ${vipStatus ? 'Yes' : 'No'}
- Current Status: ${status}
- Days Since Last Payment: ${daysSincePayment}
- Days Since Last Activity: ${daysSinceActivity}

Provide a business-focused summary highlighting engagement, value, and risks.`;

      logger.info('Manual summary regeneration triggered', {
        userId,
        clientId,
        name,
      });

      // Call OpenAI API
      const response = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content:
              'You are a business analyst specializing in client relationship insights. Provide concise, actionable summaries.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        max_tokens: 150,
        temperature: 0.7,
      });

      const aiSummary =
        response.choices[0]?.message?.content?.trim() ||
        'Unable to generate summary';

      // Update client document
      await clientRef.update({
        aiSummary,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info('Manual summary regeneration completed', {
        userId,
        clientId,
        summaryLength: aiSummary.length,
      });

      return {
        success: true,
        clientId,
        aiSummary,
      };
    } catch (error: any) {
      logger.error('regenerateClientSummary function failed', {
        error: error.message,
        code: error.code,
      });

      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Failed to regenerate summary'
      );
    }
  }
);

/**
 * Callable function: Generate summaries for all clients (batch operation)
 * 
 * Purpose: Bulk regenerate summaries for all user's clients
 * - Respects OpenAI rate limits
 * - Processes sequentially to avoid quota issues
 * - Returns statistics on generation
 * 
 * Warning: Can be expensive if user has many clients
 */
export const regenerateAllClientSummaries = functions.https.onCall(
  async (data, context) => {
    try {
      // Verify user is authenticated
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const userId = context.auth.uid;

      // Skip if OpenAI is not configured
      if (!openai) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'OpenAI API key is not configured'
        );
      }

      // Fetch all clients
      const clientsRef = db.collection('users').doc(userId).collection('clients');
      const snap = await clientsRef.get();

      logger.info('Starting batch summary regeneration', {
        userId,
        clientCount: snap.docs.length,
      });

      let generated = 0;
      let failed = 0;

      // Process clients sequentially to avoid rate limits
      for (const clientDoc of snap.docs) {
        try {
          const clientData = clientDoc.data();

          const {
            name = 'Unknown',
            company = '',
            lifetimeValue = 0,
            aiScore = 0,
            churnRisk = 0,
            totalInvoices = 0,
            sentiment = 'unknown',
            vipStatus = false,
            status = 'active',
            lastPaymentDate,
            lastActivityAt,
          } = clientData;

          let daysSincePayment = 'unknown';
          if (lastPaymentDate) {
            const lastPayment = lastPaymentDate?.toDate?.()
              ? lastPaymentDate.toDate()
              : new Date(lastPaymentDate);
            daysSincePayment = String(
              Math.floor(
                (Date.now() - lastPayment.getTime()) / (1000 * 3600 * 24)
              )
            );
          }

          let daysSinceActivity = 'unknown';
          if (lastActivityAt) {
            const lastActivity = lastActivityAt?.toDate?.()
              ? lastActivityAt.toDate()
              : new Date(lastActivityAt);
            daysSinceActivity = String(
              Math.floor(
                (Date.now() - lastActivity.getTime()) / (1000 * 3600 * 24)
              )
            );
          }

          const prompt = `You are a business analyst. Summarize this client relationship in 2-3 sentences. Be concise, actionable, and highlight key business insights.

Client: ${name}${company ? ` at ${company}` : ''}

Metrics:
- Lifetime Value: $${lifetimeValue.toFixed(2)}
- AI Relationship Score: ${aiScore}/100
- Churn Risk: ${churnRisk}/100
- Total Invoices: ${totalInvoices}
- Sentiment: ${sentiment}
- VIP Status: ${vipStatus ? 'Yes' : 'No'}
- Current Status: ${status}
- Days Since Last Payment: ${daysSincePayment}
- Days Since Last Activity: ${daysSinceActivity}

Provide a business-focused summary highlighting engagement, value, and risks.`;

          // Call OpenAI API
          const response = await openai.chat.completions.create({
            model: 'gpt-4o-mini',
            messages: [
              {
                role: 'system',
                content:
                  'You are a business analyst specializing in client relationship insights. Provide concise, actionable summaries.',
              },
              {
                role: 'user',
                content: prompt,
              },
            ],
            max_tokens: 150,
            temperature: 0.7,
          });

          const aiSummary =
            response.choices[0]?.message?.content?.trim() ||
            'Unable to generate summary';

          // Update client
          await clientDoc.ref.update({
            aiSummary,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          generated++;
          logger.info('Summary generated for client', {
            clientId: clientDoc.id,
            name,
          });

          // Add small delay to respect rate limits
          await new Promise((resolve) => setTimeout(resolve, 500));
        } catch (err: any) {
          logger.error('Failed to regenerate summary for client', {
            userId,
            clientId: clientDoc.id,
            error: err.message,
          });
          failed++;
        }
      }

      logger.info('Batch summary regeneration completed', {
        userId,
        generated,
        failed,
        total: snap.docs.length,
      });

      return {
        success: true,
        generated,
        failed,
        total: snap.docs.length,
      };
    } catch (error: any) {
      logger.error('regenerateAllClientSummaries function failed', {
        error: error.message,
        code: error.code,
      });

      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Failed to regenerate summaries'
      );
    }
  }
);
