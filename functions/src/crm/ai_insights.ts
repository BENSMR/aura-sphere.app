/**
 * functions/src/crm/ai_insights.ts
 *
 * Generate per-client AI insights and write them under:
 * /users/{userId}/clients/{clientId}.ai
 *
 * Triggers:
 *  - onWrite for invoices (users/{userId}/invoices/{invoiceId})
 *  - onWrite for clients (users/{userId}/clients/{clientId})
 *
 * Requirements:
 *  - npm install firebase-admin firebase-functions openai
 *  - Set environment variable OPENAI_API_KEY (or use functions:config:set)
 *
 * Notes:
 *  - This function uses a lightweight rule-based scoring engine first (zero-cost).
 *  - If OPENAI_API_KEY is set, it will also call OpenAI to generate a short summary
 *    and 2-3 suggested actions (costs apply).
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import OpenAI from "openai";

// Initialize admin safely (only once across all imports)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Read OpenAI key from functions config or process.env
const OPENAI_KEY =
  functions.config()?.openai?.key || process.env.OPENAI_API_KEY || null;

// Init OpenAI client if key exists
let openai: OpenAI | null = null;
if (OPENAI_KEY) {
  openai = new OpenAI({ apiKey: OPENAI_KEY });
}

// Utility: safe read numeric path
function num(v: any) {
  if (v === undefined || v === null) return 0;
  if (typeof v === "number") return v;
  if (typeof v === "string") return parseFloat(v) || 0;
  return 0;
}

// Core scoring function (rule-based, cheap)
async function computeScores(userId: string, clientId: string) {
  const clientRef = db.collection("users").doc(userId).collection("clients").doc(clientId);
  const clientSnap = await clientRef.get();
  if (!clientSnap.exists) return null;
  const client = clientSnap.data() as any;

  // Gather metrics (safe defaults)
  const totalInvoices = num(client.totalInvoices);
  const lifetimeValue = num(client.lifetimeValue);
  const lastInvoiceAmount = num(client.lastInvoiceAmount);
  const timeline = Array.isArray(client.timeline) ? client.timeline : [];
  const lastActivityTs = client.lastActivityAt ? client.lastActivityAt.toDate?.() ?? new Date(client.lastActivityAt) : null;
  const lastPaymentTs = client.lastPaymentDate ? client.lastPaymentDate.toDate?.() ?? new Date(client.lastPaymentDate) : null;

  const daysSinceActivity = lastActivityTs ? Math.max(0, Math.floor((Date.now() - lastActivityTs.getTime()) / (1000 * 60 * 60 * 24))) : 9999;
  const daysSincePayment = lastPaymentTs ? Math.max(0, Math.floor((Date.now() - lastPaymentTs.getTime()) / (1000 * 60 * 60 * 24))) : 9999;

  // RULES to compute scores (tweakable)
  // relationshipScore base
  let relationshipScore = 50;
  relationshipScore += Math.min(30, totalInvoices * 4); // invoices add up to +30
  relationshipScore += Math.min(25, Math.floor(lifetimeValue / 200)); // value contributes
  relationshipScore -= Math.min(30, Math.floor(daysSinceActivity / 7)); // inactivity penalizes
  relationshipScore -= Math.min(25, Math.floor(daysSincePayment / 30)); // late payments penalize

  // valueScore (0-100)
  let valueScore = Math.min(100, Math.floor(Math.log10(Math.max(1, lifetimeValue)) * 10 + totalInvoices * 2));

  // riskScore is inverse of relationshipScore (normalized)
  let riskScore = Math.max(0, 100 - relationshipScore);

  // Opportunity score (estimate ability to upsell)
  let opportunityScore = 20 + Math.min(60, Math.floor((totalInvoices / Math.max(1, Math.log10(Math.max(10, lifetimeValue))) ) * 5));
  if (relationshipScore > 75) opportunityScore += 10;
  if (daysSinceActivity > 60) opportunityScore = Math.max(0, opportunityScore - 30);
  opportunityScore = Math.max(0, Math.min(100, opportunityScore));

  // Derive textual labels
  const relationshipLabel =
    relationshipScore >= 80 ? "Strong relationship" :
    relationshipScore >= 60 ? "Healthy relationship" :
    relationshipScore >= 40 ? "At risk — needs attention" :
    "High risk — immediate action recommended";

  const riskLabel =
    riskScore >= 75 ? "Very high risk" :
    riskScore >= 50 ? "High risk" :
    riskScore >= 25 ? "Moderate risk" :
    "Low risk";

  const valueLabel =
    valueScore >= 80 ? "Top client" :
    valueScore >= 50 ? "Key client" :
    valueScore >= 20 ? "Growing client" :
    "Low value client";

  // Quick suggestions (rule-based) - fallback cheap suggestions
  const suggestions: string[] = [];
  if (riskScore > 60) suggestions.push("Schedule urgent follow-up call within 48 hours.");
  if (riskScore > 40) suggestions.push("Send a personalized email and offer a small discount.");
  if (opportunityScore > 70) suggestions.push("Offer an annual plan with a discount — high upsell chance.");
  if (totalInvoices === 0) suggestions.push("Welcome onboarding email — start the relationship.");
  if (daysSinceActivity > 30) suggestions.push("Nudge: No activity in 30+ days. Consider outreach.");

  // Compose ai object
  const aiPayload: any = {
    relationshipScore: Math.max(0, Math.min(100, Math.round(relationshipScore))),
    relationshipLabel,
    valueScore: Math.max(0, Math.min(100, Math.round(valueScore))),
    valueLabel,
    riskScore: Math.max(0, Math.min(100, Math.round(riskScore))),
    riskLabel,
    opportunityScore: Math.max(0, Math.min(100, Math.round(opportunityScore))),
    suggestions,
    summary: null, // to be optionally filled by OpenAI
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // If openai client available AND important changes, call OpenAI to generate a short summary + 2-3 suggestions
  // To reduce cost: only call OpenAI if lifetimeValue or relationshipScore changed significantly or if a new invoice was paid.
  try {
    if (openai) {
      // Optional: compute a cheap trigger decision to avoid too many calls
      const shouldCallOpenAI = (lifetimeValue > 500 && relationshipScore >= 50) || (riskScore > 60) || (totalInvoices > 5);
      if (shouldCallOpenAI) {
        // Prepare a short prompt using safe fields
        const prompt = [
          "You are a concise business assistant. Summarize the client relationship in two sentences and propose 3 short actionable suggestions (one-line each).",
          `Client basic info: name=${client.name || "unknown"}, company=${client.company || "unknown"}`,
          `Metrics: lifetimeValue=${lifetimeValue}, totalInvoices=${totalInvoices}, lastInvoiceAmount=${lastInvoiceAmount}, daysSinceActivity=${daysSinceActivity}, daysSincePayment=${daysSincePayment}`,
          `Current derived scores: relationshipScore=${aiPayload.relationshipScore}, riskScore=${aiPayload.riskScore}, opportunityScore=${aiPayload.opportunityScore}.`,
          "Return JSON with: summary (string), suggestions (array of strings). Keep suggestions short (max 80 characters)."
        ].join("\n\n");

        // Call OpenAI (use a small model to keep costs lower)
        const completion = await openai.chat.completions.create({
          model: "gpt-4o-mini", // change to model available in your account; fallback will work
          messages: [
            { role: "system", content: "You are a concise business insights assistant." },
            { role: "user", content: prompt }
          ],
          temperature: 0.2,
          max_tokens: 200
        });

        const raw = completion.choices?.[0]?.message?.content ?? "";
        // Expect user-friendly text — try to parse JSON from response; fallback to plain text
        // We'll attempt to extract JSON object in the text; otherwise put the raw text into summary
        let summaryText = raw;
        let openAiSuggestions: string[] = [];

        // attempt to find a JSON block
        const jsonMatch = raw.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          try {
            const parsed = JSON.parse(jsonMatch[0]);
            if (parsed.summary) summaryText = parsed.summary;
            if (Array.isArray(parsed.suggestions)) openAiSuggestions = parsed.suggestions;
          } catch (e) {
            // ignore parse error, use raw
            summaryText = raw;
          }
        } else {
          // If no JSON, split into lines to get suggestions heuristically
          const lines = raw.split("\n").map((l: string) => l.trim()).filter(Boolean);
          // first line(s) as summary, following as suggestions
          if (lines.length > 0) summaryText = lines[0] + (lines.length > 1 ? " " + (lines[1] || "") : "");
          if (lines.length > 2) openAiSuggestions = lines.slice(2).slice(0,3);
        }

        if (summaryText) aiPayload.summary = summaryText;
        if (openAiSuggestions.length > 0) aiPayload.suggestions = openAiSuggestions;
      }
    }
  } catch (err) {
    console.error("OpenAI call failed:", err);
    // keep rule-based suggestions if OpenAI fails
  }

  // Write aiPayload into client doc under root (ai object) so UI can read /clients/{clientId}.ai or under top-level fields
  // We'll write to top-level fields for simplicity (ai.*)
  await clientRef.update({
    ai: aiPayload,
    // also maintain top-level mirrors for easier queries
    aiScore: aiPayload.relationshipScore,
    churnRisk: aiPayload.riskScore,
    opportunityScore: aiPayload.opportunityScore,
    aiTags: admin.firestore.FieldValue.arrayUnion(...(generateTagsFromPayload(aiPayload) || []))
  });

  return aiPayload;
}

function generateTagsFromPayload(aiPayload: any) {
  const tags: string[] = [];
  if (!aiPayload) return tags;
  if (aiPayload.relationshipScore >= 85) tags.push("VIP");
  if (aiPayload.riskScore >= 60) tags.push("AT_RISK");
  if (aiPayload.opportunityScore >= 70) tags.push("HIGH_OPPORTUNITY");
  if (aiPayload.valueScore >= 80) tags.push("TOP_CLIENT");
  return tags;
}

// Triggers:
//  A) On invoice create/update -> recalc client
export const onInvoiceWrite = functions.firestore
  .document("users/{userId}/invoices/{invoiceId}")
  .onWrite(async (change, context) => {
    const userId = context.params.userId as string;
    const after = change.after.exists ? change.after.data() : null;
    if (!after) return null;

    const clientId = after.clientId || after.client?.id;
    if (!clientId) return null;

    try {
      await computeScores(userId, clientId);
    } catch (err) {
      console.error("computeScores onInvoiceWrite error:", err);
    }
    return null;
  });

//  B) On client write -> recalc client (so manual edits trigger recompute)
export const onClientWrite = functions.firestore
  .document("users/{userId}/clients/{clientId}")
  .onWrite(async (change, context) => {
    const userId = context.params.userId as string;
    const clientId = context.params.clientId as string;

    try {
      await computeScores(userId, clientId);
    } catch (err) {
      console.error("computeScores onClientWrite error:", err);
    }
    return null;
  });
