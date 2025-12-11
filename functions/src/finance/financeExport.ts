/**
 * functions/src/finance/financeExport.ts
 *
 * Finance summary export utilities (CSV, JSON, etc.)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Export finance summary as CSV
 * GET /exportFinanceSummary?userId=...
 */
export const exportFinanceSummary = functions.https.onRequest(
  async (req, res) => {
    // CORS headers
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      const userId = (req.query.userId as string) || null;
      if (!userId) {
        res.status(400).json({ error: "Missing userId parameter" });
        return;
      }

      // Fetch finance summary
      const summaryDoc = await db
        .collection("users")
        .doc(userId)
        .collection("analytics")
        .doc("financeSummary")
        .get();

      if (!summaryDoc.exists) {
        res.status(404).json({ error: "No finance summary found" });
        return;
      }

      const s = summaryDoc.data() as any;

      // Build CSV rows
      const rows = [
        ["Field", "Value"],
        ["Currency", s.currency || "N/A"],
        ["Revenue Total", s.revenueTotal || 0],
        ["Revenue This Month", s.revenueThisMonth || 0],
        ["Revenue Last 30 Days", s.revenueLast30 || 0],
        ["Expenses Total", s.expensesTotal || 0],
        ["Expenses This Month", s.expensesThisMonth || 0],
        ["Expenses Last 30 Days", s.expensesLast30 || 0],
        ["Profit This Month", s.profitThisMonth || 0],
        ["Profit Last 30 Days", s.profitLast30 || 0],
        ["Profit Margin This Month (%)", s.profitMarginThisMonth || 0],
        ["Unpaid Invoices Count", s.unpaidInvoicesCount || 0],
        ["Unpaid Invoices Amount", s.unpaidInvoicesAmount || 0],
        ["Overdue Invoices Count", s.overdueInvoicesCount || 0],
        ["Overdue Invoices Amount", s.overdueInvoicesAmount || 0],
        ["Tax Rate", `${(s.taxRate ?? 0.2) * 100}%`],
        ["Tax Estimate This Month", s.taxEstimateThisMonth || 0],
        ["Last Updated", s.updatedAt ? new Date(s.updatedAt.toDate()).toISOString() : "N/A"],
      ];

      // Convert to CSV string (with proper escaping)
      const csv = rows
        .map((r) => `"${r[0]}","${r[1]}"`)
        .join("\n");

      // Send as downloadable file
      res.setHeader("Content-Type", "text/csv; charset=utf-8");
      res.setHeader(
        "Content-Disposition",
        `attachment; filename="finance_summary_${userId}_${Date.now()}.csv"`
      );
      res.status(200).send(csv);
    } catch (error) {
      console.error("Error exporting finance summary:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  }
);

/**
 * Export finance summary as JSON
 * GET /exportFinanceSummaryJson?userId=...
 */
export const exportFinanceSummaryJson = functions.https.onRequest(
  async (req, res) => {
    // CORS headers
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      const userId = (req.query.userId as string) || null;
      if (!userId) {
        res.status(400).json({ error: "Missing userId parameter" });
        return;
      }

      // Fetch finance summary
      const summaryDoc = await db
        .collection("users")
        .doc(userId)
        .collection("analytics")
        .doc("financeSummary")
        .get();

      if (!summaryDoc.exists) {
        res.status(404).json({ error: "No finance summary found" });
        return;
      }

      const s = summaryDoc.data() as any;

      // Convert timestamps to ISO strings
      const jsonData = {
        ...s,
        updatedAt: s.updatedAt ? new Date(s.updatedAt.toDate()).toISOString() : null,
      };

      // Send as downloadable JSON
      res.setHeader("Content-Type", "application/json; charset=utf-8");
      res.setHeader(
        "Content-Disposition",
        `attachment; filename="finance_summary_${userId}_${Date.now()}.json"`
      );
      res.status(200).json(jsonData);
    } catch (error) {
      console.error("Error exporting finance summary JSON:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  }
);
