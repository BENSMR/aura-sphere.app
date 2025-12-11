import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as fetch from "node-fetch";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

interface AIInsight {
  summary: string; // 1-2 sentence executive summary
  analysis: string; // Detailed analysis
  recommendations: string[]; // 3-5 actionable recommendations
  riskLevel: "low" | "medium" | "high" | "critical";
  confidenceScore: number; // 0-100
  relatedAnomalies: number; // Count of related anomalies
  generatedAt: FirebaseFirestore.Timestamp;
}

/**
 * Generate AI-Powered Insights
 * 
 * Uses OpenAI to analyze anomaly patterns and generate:
 * - Executive summaries
 * - Detailed analysis with business context
 * - Actionable recommendations
 * - Risk assessment
 * 
 * Scheduled to run after dailyAnomalyCount and generateAnomalyInsights
 * (e.g., 8 AM UTC)
 */
export const generateAIInsights = functions.pubsub
  .schedule('8 0 * * *') // 8 AM UTC daily
  .timeZone('UTC')
  .onRun(async (context) => {
    if (!OPENAI_API_KEY) {
      console.error('OPENAI_API_KEY not set');
      return { success: false, error: 'API key not configured' };
    }

    try {
      const now = new Date();
      const today = now.toISOString().split('T')[0];

      // Fetch today's anomalies and insights
      const dailyCountDoc = await db
        .collection('analytics')
        .doc('anomalies_daily')
        .collection('days')
        .doc(today)
        .get();

      if (!dailyCountDoc.exists) {
        console.log('No daily count data for today');
        return { success: true, message: 'No data to analyze' };
      }

      const dailyData = dailyCountDoc.data();

      // Fetch insights for today
      const insightsDoc = await db
        .collection('analytics')
        .doc('anomaly_insights')
        .collection('daily')
        .doc(today)
        .get();

      const insightsList = insightsDoc.exists
        ? insightsDoc.data()?.insights || []
        : [];

      // Generate AI analysis
      const aiInsight = await generateAIAnalysis(dailyData, insightsList);

      // Store AI insights
      await db
        .collection('analytics')
        .doc('ai_insights')
        .collection('daily')
        .doc(today)
        .set(
          {
            date: today,
            insight: aiInsight,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

      console.log(`✓ Generated AI insights for ${today}`);
      return { success: true, insightGenerated: true };
    } catch (error) {
      console.error('Error generating AI insights:', error);
      throw error;
    }
  });

async function generateAIAnalysis(
  dailyData: any,
  insightsList: any[]
): Promise<AIInsight> {
  // Build context for OpenAI
  const context = `
Analyze the following anomaly data and provide insights for a business finance dashboard.

Daily Summary:
- Total anomalies: ${dailyData?.total || 0}
- By Severity: Critical=${dailyData?.severities?.critical || 0}, High=${dailyData?.severities?.high || 0}, Medium=${dailyData?.severities?.medium || 0}, Low=${dailyData?.severities?.low || 0}
- By Type: Invoices=${dailyData?.entityTypes?.invoice || 0}, Expenses=${dailyData?.entityTypes?.expense || 0}, Inventory=${dailyData?.entityTypes?.inventory || 0}, Audit=${dailyData?.entityTypes?.audit || 0}

Top Insights:
${insightsList.map((i) => `- ${i.title}: ${i.description}`).join('\n')}

Based on this data, provide:
1. A 1-2 sentence executive summary of the day's anomalies
2. Detailed analysis (2-3 sentences) explaining what's happening
3. 3-5 specific, actionable recommendations
4. Risk assessment (low/medium/high/critical)
5. Confidence score (0-100) in your analysis

Format your response as JSON with keys: summary, analysis, recommendations (array), riskLevel, confidenceScore
  `;

  try {
    const response = await (fetch as any).default(
      'https://api.openai.com/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${OPENAI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-3.5-turbo',
          messages: [
            {
              role: 'system',
              content:
                'You are a finance operations analyst. Provide concise, actionable insights about anomalies in business transactions. Always respond with valid JSON.',
            },
            {
              role: 'user',
              content: context,
            },
          ],
          temperature: 0.7,
          max_tokens: 500,
        }),
      }
    );

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;

    if (!content) {
      throw new Error('No response from OpenAI');
    }

    // Parse JSON response
    let parsed;
    try {
      // Extract JSON from response (may be wrapped in markdown code blocks)
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      parsed = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(content);
    } catch {
      parsed = JSON.parse(content);
    }

    return {
      summary: parsed.summary || 'Unable to generate summary',
      analysis: parsed.analysis || 'Unable to generate analysis',
      recommendations: Array.isArray(parsed.recommendations)
        ? parsed.recommendations.slice(0, 5)
        : ['Review anomalies for patterns', 'Check vendor relationships', 'Verify transaction amounts'],
      riskLevel: parsed.riskLevel || 'medium',
      confidenceScore: Math.min(100, Math.max(0, parsed.confidenceScore || 75)),
      relatedAnomalies: insightsList.length,
      generatedAt: admin.firestore.Timestamp.now(),
    };
  } catch (error) {
    console.error('OpenAI API error:', error);

    // Fallback analysis if API fails
    return {
      summary: `${dailyData?.total || 0} anomalies detected. Requires manual review.`,
      analysis:
        'Unable to generate AI analysis at this time. Please review the detailed anomaly list.',
      recommendations: [
        'Check critical and high-severity anomalies first',
        'Verify vendor information for duplicate transactions',
        'Review unusual transaction times',
      ],
      riskLevel: dailyData?.severities?.critical > 0 ? 'critical' : 'medium',
      confidenceScore: 0,
      relatedAnomalies: insightsList.length,
      generatedAt: admin.firestore.Timestamp.now(),
    };
  }
}

/**
 * Query endpoint for AI insights
 */
export const queryAIInsights = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
    }

    const { days = 7 } = data;

    try {
      const snapshot = await db
        .collection('analytics')
        .doc('ai_insights')
        .collection('daily')
        .orderBy('date', 'desc')
        .limit(Math.min(days, 30))
        .get();

      const results = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          date: data.date,
          insight: data.insight,
        };
      });

      return results;
    } catch (error) {
      console.error('Error querying AI insights:', error);
      throw new functions.https.HttpsError('internal', 'Failed to query insights');
    }
  }
);
