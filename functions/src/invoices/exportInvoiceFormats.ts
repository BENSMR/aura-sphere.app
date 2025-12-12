import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as puppeteer from "puppeteer";
import { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, WidthType, AlignmentType } from "docx";
import AdmZip from "adm-zip";
import { logger } from "../utils/logger";

// Initialize admin if not already done
if (!admin.apps.length) {
  admin.initializeApp();
}

// Lazy-load bucket to avoid initialization errors
function getBucket() {
  try {
    return admin.storage().bucket();
  } catch (err) {
    logger.error('Failed to get storage bucket:', err);
    throw err;
  }
}

type InvoiceItem = {
  id: string;
  name: string;
  description?: string;
  quantity: number;
  unitPrice: number;
  vatRate: number;
  total: number;
};

interface ExportPayload {
  invoiceNumber: string;
  createdAt: string;
  dueDate: string;
  items: InvoiceItem[];
  currency: string;
  subtotal: number;
  totalVat: number;
  discount: number;
  total: number;
  businessName: string;
  businessAddress: string;
  clientName: string;
  clientEmail: string;
  clientAddress: string;
  userLogoUrl?: string;
  notes?: string;
  templateName?: string;
}

/**
 * Export invoice in multiple formats (PDF, PNG, DOCX, CSV, ZIP)
 * 
 * Parameters:
 * - invoiceNumber: string
 * - createdAt: string (ISO date)
 * - dueDate: string (ISO date)
 * - items: Array<{id, name, quantity, unitPrice, vatRate, total}>
 * - currency: string (USD, EUR, etc)
 * - subtotal: number
 * - totalVat: number
 * - discount: number
 * - total: number
 * - businessName: string
 * - businessAddress: string
 * - clientName: string
 * - clientEmail: string
 * - clientAddress: string
 * - userLogoUrl?: string (optional)
 * - notes?: string (optional)
 * - templateName?: string (optional)
 * 
 * Returns:
 * {
 *   success: true,
 *   urls: {
 *     pdf: string (signed URL),
 *     png: string (signed URL),
 *     docx: string (signed URL),
 *     csv: string (signed URL),
 *     zip: string (signed URL)
 *   },
 *   metadata: {
 *     invoiceNumber: string,
 *     generatedAt: string (ISO),
 *     fileSize: number (bytes),
 *     formats: string[]
 *   }
 * }
 */
export const exportInvoiceFormats = functions
  .runWith({
    memory: "2GB",
    timeoutSeconds: 300,
  })
  .region("us-central1")
  .https.onCall(async (data: ExportPayload, context) => {
    if (!context.auth) {
      logger.error("Export formats - unauthenticated", {});
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const userId = context.auth.uid;
    const startTime = Date.now();

    try {
      // Validate required fields
      const {
        invoiceNumber,
        createdAt,
        dueDate,
        items,
        currency,
        subtotal,
        totalVat,
        discount,
        total,
        businessName,
        businessAddress,
        clientName,
        clientEmail,
        clientAddress,
        userLogoUrl,
        notes,
      } = data;

      if (!invoiceNumber || !items || !Array.isArray(items)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Missing required fields: invoiceNumber, items (array)"
        );
      }

      if (items.length === 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Invoice must have at least one item"
        );
      }

      logger.info("Export formats - starting", {
        invoiceNumber,
        userId,
        itemCount: items.length,
      });

      // Build HTML template for PDF/PNG
      const html = buildInvoiceHtml({
        invoiceNumber,
        createdAt,
        dueDate,
        items,
        currency,
        subtotal,
        totalVat,
        discount,
        total,
        businessName,
        businessAddress,
        clientName,
        clientEmail,
        clientAddress,
        userLogoUrl,
        notes,
      });

      // Generate PDF and PNG using Puppeteer
      logger.info("Export formats - launching browser", { invoiceNumber });
      const browser = await puppeteer.launch({
        headless: true,
        args: [
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--disable-dev-shm-usage",
        ],
      });

      const page = await browser.newPage();
      await page.setContent(html, { waitUntil: "networkidle0" });

      // Generate PDF
      const pdfBuffer = await page.pdf({
        format: "A4",
        printBackground: true,
        margin: { top: 10, right: 10, bottom: 10, left: 10 },
      });

      // Generate PNG screenshot
      const pngBuffer = await page.screenshot({
        fullPage: true,
        type: "png",
      });

      await browser.close();

      logger.info("Export formats - PDF/PNG generated", {
        invoiceNumber,
        pdfSize: pdfBuffer.length,
        pngSize: pngBuffer.length,
      });

      // Generate DOCX
      const docxBuffer = await generateDocx({
        invoiceNumber,
        createdAt,
        dueDate,
        items,
        currency,
        subtotal,
        totalVat,
        discount,
        total,
        businessName,
        businessAddress,
        clientName,
        clientEmail,
        clientAddress,
        notes,
      });

      logger.info("Export formats - DOCX generated", {
        invoiceNumber,
        docxSize: docxBuffer.length,
      });

      // Generate CSV
      const csvBuffer = generateCsv(items, invoiceNumber, currency, subtotal, totalVat, discount, total);

      logger.info("Export formats - CSV generated", {
        invoiceNumber,
        csvSize: csvBuffer.length,
      });

      // Create ZIP archive with all formats
      const zip = new AdmZip();
      zip.addFile(`${invoiceNumber}.pdf`, pdfBuffer);
      zip.addFile(`${invoiceNumber}.png`, pngBuffer);
      zip.addFile(`${invoiceNumber}.docx`, docxBuffer);
      zip.addFile(`${invoiceNumber}.csv`, csvBuffer);

      const zipBuffer = zip.toBuffer();

      logger.info("Export formats - ZIP created", {
        invoiceNumber,
        zipSize: zipBuffer.length,
      });

      // Upload all files to Firebase Storage
      const basePath = `exports/${userId}/${invoiceNumber}`;
      const files: { name: string; buffer: Buffer; mimeType: string }[] = [
        {
          name: `${basePath}/${invoiceNumber}.pdf`,
          buffer: pdfBuffer,
          mimeType: "application/pdf",
        },
        {
          name: `${basePath}/${invoiceNumber}.png`,
          buffer: pngBuffer,
          mimeType: "image/png",
        },
        {
          name: `${basePath}/${invoiceNumber}.docx`,
          buffer: docxBuffer,
          mimeType:
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        },
        {
          name: `${basePath}/${invoiceNumber}.csv`,
          buffer: csvBuffer,
          mimeType: "text/csv",
        },
        {
          name: `${basePath}/${invoiceNumber}.zip`,
          buffer: zipBuffer,
          mimeType: "application/zip",
        },
      ];

      const uploadedUrls: Record<string, string> = {};
      const uploadPromises = files.map(async (f) => {
        const file = getBucket().file(f.name);
        await file.save(f.buffer, {
          metadata: { contentType: f.mimeType },
        });

        // Generate signed URL (valid for 30 days)
        const [url] = await file.getSignedUrl({
          action: "read",
          expires: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
        });

        const filename = f.name.split("/").pop() || f.name;
        uploadedUrls[filename] = url;

        logger.info("Export formats - file uploaded", {
          invoiceNumber,
          filename,
          size: f.buffer.length,
        });
      });

      await Promise.all(uploadPromises);

      const duration = Date.now() - startTime;

      // Atomically increment invoice counter in business profile
      try {
        const businessProfileRef = admin
          .firestore()
          .collection("users")
          .doc(userId)
          .collection("meta")
          .doc("business");

        await businessProfileRef.update({
          invoiceCounter: admin.firestore.FieldValue.increment(1),
          lastInvoiceExportedAt: new Date().toISOString(),
        });

        logger.info("Export formats - invoice counter incremented", {
          invoiceNumber,
          userId,
        });
      } catch (err: any) {
        logger.warn("Export formats - failed to increment counter", {
          invoiceNumber,
          userId,
          error: err?.message,
        });
        // Don't throw - counter increment failure shouldn't block export
      }

      logger.info("Export formats - completed successfully", {
        invoiceNumber,
        userId,
        duration,
        formats: Object.keys(uploadedUrls),
      });

      return {
        success: true,
        urls: uploadedUrls,
        metadata: {
          invoiceNumber,
          generatedAt: new Date().toISOString(),
          totalSize: files.reduce((sum, f) => sum + f.buffer.length, 0),
          formats: ["pdf", "png", "docx", "csv", "zip"],
          processingTime: `${duration}ms`,
        },
      };
    } catch (err: any) {
      logger.error("Export formats - failed", {
        invoiceNumber: data?.invoiceNumber,
        error: err?.message,
        code: err?.code,
      });

      throw new functions.https.HttpsError(
        "internal",
        "Failed to export invoice formats",
        err?.message
      );
    }
  });

/**
 * Build professional invoice HTML
 */
function buildInvoiceHtml(payload: any): string {
  const {
    invoiceNumber,
    createdAt,
    dueDate,
    items,
    currency,
    subtotal,
    totalVat,
    discount,
    total,
    businessName,
    businessAddress,
    clientName,
    clientEmail,
    clientAddress,
    userLogoUrl,
    notes,
  } = payload;

  const itemsRows = (items as InvoiceItem[])
    .map(
      (i) => `
    <tr>
      <td class="item-name">${escapeHtml(i.name)}</td>
      <td class="item-qty">${i.quantity}</td>
      <td class="item-price">${i.unitPrice.toFixed(2)}</td>
      <td class="item-vat">${(i.vatRate * 100).toFixed(1)}%</td>
      <td class="item-total">${i.total.toFixed(2)}</td>
    </tr>
  `
    )
    .join("");

  const discountRow =
    discount > 0
      ? `<tr class="summary-row"><td colspan="4" class="label">Discount</td><td class="value">-${discount.toFixed(2)}</td></tr>`
      : "";

  return `
  <!doctype html>
  <html>
    <head>
      <meta charset="utf-8"/>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          line-height: 1.6;
          color: #333;
          background: #f9f9f9;
        }
        .container {
          max-width: 8.5in;
          height: 11in;
          margin: 0 auto;
          padding: 28px;
          background: white;
          box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 32px;
          border-bottom: 2px solid #007bff;
          padding-bottom: 16px;
        }
        .header-left h2 {
          font-size: 32px;
          color: #007bff;
          margin-bottom: 8px;
        }
        .header-left p {
          margin: 4px 0;
          font-size: 14px;
          color: #666;
        }
        .logo {
          max-width: 150px;
          max-height: 80px;
          object-fit: contain;
        }
        .details-section {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 32px;
          margin-bottom: 32px;
        }
        .detail-block h3 {
          font-size: 12px;
          text-transform: uppercase;
          color: #007bff;
          margin-bottom: 8px;
          font-weight: 600;
        }
        .detail-block p {
          margin: 4px 0;
          font-size: 13px;
          color: #555;
        }
        table {
          width: 100%;
          border-collapse: collapse;
          margin: 24px 0;
          font-size: 13px;
        }
        th {
          background: #f0f0f0;
          border-bottom: 2px solid #007bff;
          padding: 10px 8px;
          text-align: left;
          font-weight: 600;
          color: #333;
        }
        td {
          padding: 10px 8px;
          border-bottom: 1px solid #ddd;
        }
        tr:last-child td {
          border-bottom: none;
        }
        .item-qty, .item-price, .item-vat, .item-total {
          text-align: right;
        }
        .summary {
          margin-top: 24px;
          text-align: right;
          width: 100%;
        }
        .summary-row {
          background: none;
        }
        .summary-row .label {
          text-align: right;
          font-weight: 500;
          padding: 6px 8px;
        }
        .summary-row .value {
          text-align: right;
          font-weight: 500;
          padding: 6px 8px;
        }
        .total-row {
          background: #f0f0f0;
          font-size: 16px;
          font-weight: bold;
          color: #007bff;
        }
        .notes {
          margin-top: 24px;
          padding-top: 16px;
          border-top: 1px solid #ddd;
          font-size: 12px;
          color: #666;
        }
        .footer {
          margin-top: 32px;
          padding-top: 16px;
          border-top: 1px solid #ddd;
          text-align: center;
          font-size: 11px;
          color: #999;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="header-left">
            <h2>INVOICE</h2>
            <p><strong>Invoice #:</strong> ${escapeHtml(invoiceNumber)}</p>
            <p><strong>Date:</strong> ${escapeHtml(createdAt)}</p>
            <p><strong>Due Date:</strong> ${escapeHtml(dueDate)}</p>
          </div>
          <div class="header-right">
            ${userLogoUrl ? `<img src="${userLogoUrl}" class="logo"/>` : `<div style="font-weight:bold; font-size:18px;">${escapeHtml(businessName || "")}</div>`}
          </div>
        </div>

        <div class="details-section">
          <div class="detail-block">
            <h3>From</h3>
            <p>${escapeHtml(businessName || "")}</p>
            <p>${escapeHtml(businessAddress || "")}</p>
          </div>
          <div class="detail-block">
            <h3>Bill To</h3>
            <p>${escapeHtml(clientName || "")}</p>
            <p>${escapeHtml(clientEmail || "")}</p>
            <p>${escapeHtml(clientAddress || "")}</p>
          </div>
        </div>

        <table>
          <thead>
            <tr>
              <th>Item Description</th>
              <th style="width: 10%; text-align: right;">Qty</th>
              <th style="width: 15%; text-align: right;">Unit Price</th>
              <th style="width: 10%; text-align: right;">VAT</th>
              <th style="width: 15%; text-align: right;">Total (${currency})</th>
            </tr>
          </thead>
          <tbody>
            ${itemsRows}
          </tbody>
        </table>

        <div class="summary">
          <table style="width: 100%; max-width: 350px; margin-left: auto;">
            <tr class="summary-row">
              <td style="text-align: right; width: 70%;">Subtotal</td>
              <td style="text-align: right; width: 30%; font-weight: 500;">${subtotal.toFixed(2)}</td>
            </tr>
            <tr class="summary-row">
              <td style="text-align: right;">Total VAT</td>
              <td style="text-align: right; font-weight: 500;">${totalVat.toFixed(2)}</td>
            </tr>
            ${discountRow}
            <tr class="total-row">
              <td style="text-align: right;">TOTAL DUE</td>
              <td style="text-align: right;">${total.toFixed(2)} ${currency}</td>
            </tr>
          </table>
        </div>

        ${notes ? `<div class="notes"><strong>Notes:</strong><br/>${escapeHtml(notes)}</div>` : ""}

        <div class="footer">
          Generated on ${new Date().toLocaleString()} | Invoice #${invoiceNumber}
        </div>
      </div>
    </body>
  </html>
  `;
}

/**
 * Generate DOCX document
 */
async function generateDocx(payload: any): Promise<Buffer> {
  const {
    invoiceNumber,
    createdAt,
    dueDate,
    items,
    currency,
    subtotal,
    totalVat,
    discount,
    total,
    businessName,
    businessAddress,
    clientName,
    clientEmail,
    clientAddress,
    notes,
  } = payload;

  const doc = new Document({
    sections: [
      {
        children: [
          new Paragraph({
            text: `Invoice ${invoiceNumber}`,
            heading: "Heading1",
            alignment: AlignmentType.CENTER,
          }),
          new Paragraph({
            children: [
              new TextRun({
                text: `Date: ${createdAt} | Due: ${dueDate}`,
                size: 22,
              }),
            ],
            alignment: AlignmentType.CENTER,
          }),
          new Paragraph({ text: "" }),

          new Paragraph({
            children: [
              new TextRun({
                text: "From:",
                bold: true,
              }),
            ],
          }),
          new Paragraph({
            text: businessName,
          }),
          new Paragraph({
            text: businessAddress,
          }),
          new Paragraph({ text: "" }),

          new Paragraph({
            children: [
              new TextRun({
                text: "Bill To:",
                bold: true,
              }),
            ],
          }),
          new Paragraph({
            text: clientName,
          }),
          new Paragraph({
            text: clientEmail,
          }),
          new Paragraph({
            text: clientAddress,
          }),
          new Paragraph({ text: "" }),

          buildDocxItemsTable(items as InvoiceItem[], currency),
          new Paragraph({ text: "" }),

          new Paragraph({
            text: `Subtotal: ${subtotal.toFixed(2)} ${currency}`,
            alignment: AlignmentType.RIGHT,
          }),
          new Paragraph({
            text: `Total VAT: ${totalVat.toFixed(2)} ${currency}`,
            alignment: AlignmentType.RIGHT,
          }),
          ...(discount > 0
            ? [
                new Paragraph({
                  text: `Discount: -${discount.toFixed(2)} ${currency}`,
                  alignment: AlignmentType.RIGHT,
                }),
              ]
            : []),
          new Paragraph({
            children: [
              new TextRun({
                text: `TOTAL: ${total.toFixed(2)} ${currency}`,
                bold: true,
                size: 28,
              }),
            ],
            alignment: AlignmentType.RIGHT,
          }),

          ...(notes
            ? [
                new Paragraph({ text: "" }),
                new Paragraph({
                  children: [
                    new TextRun({
                      text: "Notes:",
                      bold: true,
                    }),
                  ],
                }),
                new Paragraph({
                  text: notes,
                }),
              ]
            : []),
        ],
      },
    ],
  });

  return Packer.toBuffer(doc);
}

/**
 * Build DOCX items table
 */
function buildDocxItemsTable(items: InvoiceItem[], currency: string): Table {
  const headerRow = new TableRow({
    children: [
      new TableCell({
        children: [
          new Paragraph({
            children: [new TextRun({ text: "Item", bold: true })],
          }),
        ],
        width: { size: 40, type: WidthType.PERCENTAGE },
      }),
      new TableCell({
        children: [
          new Paragraph({
            children: [new TextRun({ text: "Qty", bold: true })],
          }),
        ],
        width: { size: 10, type: WidthType.PERCENTAGE },
      }),
      new TableCell({
        children: [
          new Paragraph({
            children: [new TextRun({ text: "Unit Price", bold: true })],
          }),
        ],
        width: { size: 20, type: WidthType.PERCENTAGE },
      }),
      new TableCell({
        children: [
          new Paragraph({
            children: [new TextRun({ text: "VAT", bold: true })],
          }),
        ],
        width: { size: 10, type: WidthType.PERCENTAGE },
      }),
      new TableCell({
        children: [
          new Paragraph({
            children: [new TextRun({ text: `Total (${currency})`, bold: true })],
          }),
        ],
        width: { size: 20, type: WidthType.PERCENTAGE },
      }),
    ],
  });

  const itemRows = items.map(
    (i) =>
      new TableRow({
        children: [
          new TableCell({
            children: [new Paragraph(i.name)],
          }),
          new TableCell({
            children: [new Paragraph(i.quantity.toString())],
          }),
          new TableCell({
            children: [new Paragraph(i.unitPrice.toFixed(2))],
          }),
          new TableCell({
            children: [new Paragraph(`${(i.vatRate * 100).toFixed(1)}%`)],
          }),
          new TableCell({
            children: [new Paragraph(i.total.toFixed(2))],
          }),
        ],
      })
  );

  return new Table({
    rows: [headerRow, ...itemRows],
    width: { size: 100, type: WidthType.PERCENTAGE },
  });
}

/**
 * Generate CSV content
 */
function generateCsv(
  items: InvoiceItem[],
  invoiceNumber: string,
  currency: string,
  subtotal: number,
  totalVat: number,
  discount: number,
  total: number
): Buffer {
  const rows = [];

  // Header
  rows.push(["INVOICE EXPORT", invoiceNumber].join(","));
  rows.push(["Generated", new Date().toISOString()].join(","));
  rows.push([]);

  // Items section
  rows.push(["ITEMS"]);
  rows.push(["Name", "Quantity", "Unit Price", "VAT Rate", "VAT Amount", "Total"].join(","));

  items.forEach((item) => {
    const vatAmount = item.total * item.vatRate;
    rows.push(
      [
        escapeCsv(item.name),
        item.quantity,
        item.unitPrice.toFixed(2),
        (item.vatRate * 100).toFixed(1),
        vatAmount.toFixed(2),
        item.total.toFixed(2),
      ].join(",")
    );
  });

  rows.push([]);

  // Summary section
  rows.push(["SUMMARY"]);
  rows.push(["Subtotal", subtotal.toFixed(2)].join(","));
  rows.push(["Total VAT", totalVat.toFixed(2)].join(","));
  if (discount > 0) {
    rows.push(["Discount", `-${discount.toFixed(2)}`].join(","));
  }
  rows.push(["Total", `${total.toFixed(2)} ${currency}`].join(","));

  return Buffer.from(rows.join("\n"), "utf-8");
}

/**
 * Escape HTML special characters
 */
function escapeHtml(s: any): string {
  if (s == null) return "";
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

/**
 * Escape CSV special characters
 */
function escapeCsv(s: any): string {
  if (s == null) return "";
  const str = String(s);
  if (str.includes(",") || str.includes('"') || str.includes("\n")) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}
