import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as puppeteer from "puppeteer";
import { logger } from "../utils/logger";

/**
 * Cloud Function: Generate invoice PDF with Puppeteer
 * 
 * Generates a professional PDF invoice from invoice data and linked expenses.
 * Uploads to Firebase Storage and returns signed download URL.
 * 
 * Data Parameters:
 *   - invoiceId: string (for audit trail)
 *   - invoiceNumber: string
 *   - createdAt: string (ISO format)
 *   - dueDate: string (ISO format)
 *   - items: Array<{name, quantity, unitPrice, vatRate, total}>
 *   - currency: string (e.g., "USD")
 *   - subtotal: number
 *   - totalVat: number
 *   - discount: number (0 if none)
 *   - total: number
 *   - businessName: string
 *   - businessAddress: string
 *   - clientName: string
 *   - clientEmail: string
 *   - clientAddress: string
 *   - userLogoUrl?: string (optional)
 *   - linkedExpenseIds?: string[] (optional, for tracking)
 */
export const generateInvoicePdf = functions
  .runWith({
    memory: "1GB",
    timeoutSeconds: 120,
  })
  .region("us-central1")
  .https.onCall(async (data, context) => {
    // Authentication check
    if (!context.auth) {
      logger.error("PDF generation attempted without authentication");
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const userId = context.auth.uid;
    const invoiceId = data.invoiceId || "unknown";

    try {
      logger.info(`Generating PDF for invoice: ${invoiceId}`, { userId });

      // Validate required fields
      const requiredFields = [
        "invoiceNumber",
        "createdAt",
        "dueDate",
        "items",
        "currency",
        "subtotal",
        "totalVat",
        "total",
        "businessName",
        "clientName",
        "clientEmail",
      ];

      for (const field of requiredFields) {
        if (!(field in data)) {
          throw new functions.https.HttpsError(
            "invalid-argument",
            `Missing required field: ${field}`
          );
        }
      }

      const {
        invoiceNumber,
        createdAt,
        dueDate,
        items,
        currency,
        subtotal,
        totalVat,
        discount = 0,
        total,
        businessName,
        businessAddress = "Address not provided",
        clientName,
        clientEmail,
        clientAddress = "Address not provided",
        userLogoUrl = null,
        paidDate = null,
        notes = null,
        linkedExpenseCount = 0,
      } = data;

      // Format dates
      const formatDate = (dateStr: string): string => {
        const date = new Date(dateStr);
        return date.toISOString().split("T")[0];
      };

      const invoiceDateFormatted = formatDate(createdAt);
      const dueDateFormatted = formatDate(dueDate);
      const paidDateFormatted = paidDate ? formatDate(paidDate) : null;

      // Build HTML template
      const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      color: #333;
      line-height: 1.6;
    }
    
    .container {
      max-width: 900px;
      margin: 0 auto;
      padding: 40px;
      background: white;
    }
    
    .header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 40px;
      border-bottom: 2px solid #f0f0f0;
      padding-bottom: 20px;
    }
    
    .header-left h1 {
      font-size: 32px;
      font-weight: bold;
      margin-bottom: 10px;
      color: #1565c0;
    }
    
    .header-left p {
      font-size: 12px;
      color: #666;
      margin: 4px 0;
    }
    
    .header-right {
      text-align: right;
    }
    
    .header-right img {
      max-width: 150px;
      max-height: 80px;
      margin-bottom: 12px;
    }
    
    .header-right p {
      font-size: 11px;
      color: #666;
      margin: 4px 0;
    }
    
    .status-badge {
      display: inline-block;
      background: #e3f2fd;
      color: #1565c0;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 11px;
      font-weight: bold;
      margin-top: 8px;
    }
    
    .info-section {
      display: flex;
      justify-content: space-between;
      margin-bottom: 30px;
    }
    
    .info-block {
      flex: 1;
    }
    
    .info-block h3 {
      font-size: 11px;
      font-weight: bold;
      text-transform: uppercase;
      color: #999;
      margin-bottom: 8px;
    }
    
    .info-block p {
      font-size: 12px;
      color: #333;
      margin: 4px 0;
    }
    
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 30px 0;
    }
    
    thead {
      background: #f5f5f5;
    }
    
    th {
      padding: 12px 8px;
      text-align: left;
      font-size: 11px;
      font-weight: bold;
      color: #333;
      border-bottom: 2px solid #e0e0e0;
    }
    
    td {
      padding: 10px 8px;
      font-size: 11px;
      border-bottom: 1px solid #f0f0f0;
    }
    
    tbody tr:hover {
      background: #fafafa;
    }
    
    .text-right {
      text-align: right;
    }
    
    .text-center {
      text-align: center;
    }
    
    .totals-section {
      display: flex;
      justify-content: flex-end;
      margin: 30px 0;
    }
    
    .totals-box {
      width: 300px;
    }
    
    .total-row {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      font-size: 11px;
      border-bottom: 1px solid #e0e0e0;
    }
    
    .total-row.grand-total {
      border-top: 2px solid #e0e0e0;
      border-bottom: none;
      padding-top: 12px;
      padding-bottom: 12px;
      font-size: 14px;
      font-weight: bold;
      color: #1565c0;
    }
    
    .total-label {
      font-weight: 500;
      color: #666;
    }
    
    .total-value {
      text-align: right;
      font-weight: 600;
    }
    
    .discount-negative {
      color: #d32f2f;
    }
    
    .notes-section {
      margin-top: 30px;
      padding-top: 20px;
      border-top: 1px solid #f0f0f0;
    }
    
    .notes-section h3 {
      font-size: 11px;
      font-weight: bold;
      text-transform: uppercase;
      color: #999;
      margin-bottom: 8px;
    }
    
    .notes-section p {
      font-size: 11px;
      color: #333;
      white-space: pre-wrap;
      word-break: break-word;
    }
    
    .linked-expenses-section {
      margin-top: 30px;
      padding: 16px;
      background: #f9f9f9;
      border-left: 4px solid #ffc107;
      border-radius: 2px;
    }
    
    .linked-expenses-section h3 {
      font-size: 11px;
      font-weight: bold;
      text-transform: uppercase;
      color: #666;
      margin-bottom: 8px;
    }
    
    .linked-expenses-section p {
      font-size: 10px;
      color: #999;
    }
    
    .footer {
      margin-top: 40px;
      padding-top: 20px;
      border-top: 1px solid #f0f0f0;
      text-align: center;
      font-size: 9px;
      color: #999;
    }
    
    .footer p {
      margin: 4px 0;
    }
  </style>
</head>
<body>
  <div class="container">
    
    <!-- Header -->
    <div class="header">
      <div class="header-left">
        <h1>INVOICE</h1>
        <p>Invoice #: <strong>${escapeHtml(invoiceNumber)}</strong></p>
        <p>Issue Date: ${invoiceDateFormatted}</p>
        <p>Due Date: ${dueDateFormatted}</p>
        ${paidDateFormatted ? `<p>Paid Date: ${paidDateFormatted}</p>` : ""}
      </div>
      <div class="header-right">
        ${userLogoUrl ? `<img src="${userLogoUrl}" alt="Logo"/>` : ""}
        <div class="status-badge">Generated on ${new Date().toISOString().split("T")[0]}</div>
      </div>
    </div>
    
    <!-- Client Info -->
    <div class="info-section">
      <div class="info-block">
        <h3>From:</h3>
        <p>${escapeHtml(businessName)}</p>
        <p>${escapeHtml(businessAddress)}</p>
      </div>
      <div class="info-block">
        <h3>Bill To:</h3>
        <p>${escapeHtml(clientName)}</p>
        <p>${escapeHtml(clientEmail)}</p>
        <p>${escapeHtml(clientAddress)}</p>
      </div>
    </div>
    
    <!-- Items Table -->
    <table>
      <thead>
        <tr>
          <th style="width: 40%;">Description</th>
          <th style="width: 12%; text-align: center;">Quantity</th>
          <th style="width: 16%; text-align: right;">Unit Price</th>
          <th style="width: 12%; text-align: center;">VAT Rate</th>
          <th style="width: 20%; text-align: right;">Total</th>
        </tr>
      </thead>
      <tbody>
        ${items
          .map(
            (item: any) => `
        <tr>
          <td>${escapeHtml(item.name)}</td>
          <td class="text-center">${formatNumber(item.quantity)}</td>
          <td class="text-right">${currency} ${formatCurrency(item.unitPrice)}</td>
          <td class="text-center">${formatPercent(item.vatRate)}</td>
          <td class="text-right">${currency} ${formatCurrency(item.total)}</td>
        </tr>`
          )
          .join("")}
      </tbody>
    </table>
    
    <!-- Totals -->
    <div class="totals-section">
      <div class="totals-box">
        <div class="total-row">
          <span class="total-label">Subtotal:</span>
          <span class="total-value">${currency} ${formatCurrency(subtotal)}</span>
        </div>
        <div class="total-row">
          <span class="total-label">Total VAT:</span>
          <span class="total-value">${currency} ${formatCurrency(totalVat)}</span>
        </div>
        ${
          discount > 0
            ? `
        <div class="total-row">
          <span class="total-label">Discount:</span>
          <span class="total-value discount-negative">-${currency} ${formatCurrency(discount)}</span>
        </div>`
            : ""
        }
        <div class="total-row grand-total">
          <span>TOTAL:</span>
          <span>${currency} ${formatCurrency(total)}</span>
        </div>
      </div>
    </div>
    
    <!-- Linked Expenses Info -->
    ${
      linkedExpenseCount > 0
        ? `
    <div class="linked-expenses-section">
      <h3>Linked Expenses</h3>
      <p>This invoice is linked to ${linkedExpenseCount} expense(s) for financial reconciliation.</p>
    </div>`
        : ""
    }
    
    <!-- Notes -->
    ${
      notes
        ? `
    <div class="notes-section">
      <h3>Notes</h3>
      <p>${escapeHtml(notes)}</p>
    </div>`
        : ""
    }
    
    <!-- Footer -->
    <div class="footer">
      <p>This is an automatically generated invoice. Please retain for your records.</p>
      <p>Generated on ${new Date().toISOString()}</p>
    </div>
    
  </div>
</body>
</html>
      `;

      // Launch Puppeteer with Cloud Run compatible settings
      const browser = await puppeteer.launch({
        headless: "new",
        args: [
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--disable-dev-shm-usage",
        ],
      });

      const page = await browser.newPage();
      await page.setContent(html, { waitUntil: "networkidle0" });

      const pdfBuffer = await page.pdf({
        format: "A4",
        printBackground: true,
        margin: {
          top: "0px",
          right: "0px",
          bottom: "0px",
          left: "0px",
        },
      });

      await browser.close();

      // Upload to Firebase Storage
      const bucket = admin.storage().bucket();
      const filePath = `invoices/${userId}/${invoiceNumber}_${Date.now()}.pdf`;
      const file = bucket.file(filePath);

      await file.save(pdfBuffer, {
        metadata: {
          contentType: "application/pdf",
          metadata: {
            invoiceId: invoiceId,
            invoiceNumber: invoiceNumber,
            userId: userId,
            generatedAt: new Date().toISOString(),
          },
        },
      });

      // Generate signed URL (valid for 30 days)
      const [downloadUrl] = await file.getSignedUrl({
        version: "v4",
        action: "read",
        expires: Date.now() + 30 * 24 * 60 * 60 * 1000, // 30 days
      });

      // Log successful generation
      logger.info(`PDF generated successfully`, {
        userId,
        invoiceId,
        filePath,
        size: pdfBuffer.length,
      });

      // Update invoice document with PDF URL
      try {
        await admin
          .firestore()
          .collection("invoices")
          .doc(invoiceId)
          .update({
            pdfUrl: downloadUrl,
            pdfGeneratedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
      } catch (updateError) {
        logger.warn(`Failed to update invoice document with PDF URL`, {
          userId,
          invoiceId,
          error: updateError,
        });
        // Don't throw - PDF was generated successfully
      }

      return {
        success: true,
        url: downloadUrl,
        filePath: filePath,
        fileName: `${invoiceNumber}.pdf`,
        size: pdfBuffer.length,
        message: "PDF generated successfully",
      };
    } catch (error: any) {
      logger.error(`PDF generation failed for invoice: ${invoiceId}`, {
        userId,
        error: error.message,
        stack: error.stack,
      });

      throw new functions.https.HttpsError(
        "internal",
        "PDF generation failed: " + error.message
      );
    }
  });

/**
 * Helper: Escape HTML special characters
 */
function escapeHtml(text: string): string {
  if (!text) return "";
  const map: { [key: string]: string } = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#039;",
  };
  return text.replace(/[&<>"']/g, (char) => map[char]);
}

/**
 * Helper: Format currency values
 */
function formatCurrency(value: number): string {
  return value.toFixed(2);
}

/**
 * Helper: Format percentage
 */
function formatPercent(value: number): string {
  return `${(value * 100).toFixed(0)}%`;
}

/**
 * Helper: Format number with 2 decimals
 */
function formatNumber(value: number): string {
  return value.toFixed(2);
}
