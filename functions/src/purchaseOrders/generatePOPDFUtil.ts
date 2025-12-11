/**
 * functions/src/purchaseOrders/generatePOPDFUtil.ts
 *
 * Shared utility for generating Purchase Order PDFs
 * Used by both the generatePOPDF callable function and emailPurchaseOrder function
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { PDFDocument, StandardFonts, rgb } from "pdf-lib";
import { logger } from "../utils/logger";

type POItem = {
  name: string;
  sku?: string | null;
  qtyOrdered: number;
  costPrice?: number | null;
  unit?: string | null;
};

type POData = {
  poNumber?: string;
  createdAt?: { seconds: number } | Date;
  expectedDeliveryDate?: { seconds: number } | Date;
  supplierName?: string;
  supplierId?: string;
  supplierContact?: string;
  supplierEmail?: string;
  items?: any[];
  subtotals?: { tax?: number; shipping?: number };
  notes?: string;
};

/**
 * Helper: Format timestamp to date string
 */
function getDateString(timestamp: any): string {
  if (!timestamp) return new Date().toLocaleDateString();
  if (timestamp.seconds)
    return new Date(timestamp.seconds * 1000).toLocaleDateString();
  if (timestamp instanceof Date) return timestamp.toLocaleDateString();
  return new Date(timestamp).toLocaleDateString();
}

/**
 * Helper: Format currency
 */
function formatCurrency(value: number): string {
  return `$${value.toFixed(2)}`;
}

/**
 * Generate Purchase Order PDF and return as Buffer
 * Shared utility used by both callable functions
 */
export async function generatePOPDFBuffer(
  uid: string,
  poId: string,
  saveToStorage: boolean = false
): Promise<Buffer> {
  const db = admin.firestore();

  // Fetch PO document
  const poRef = db
    .collection("users")
    .doc(uid)
    .collection("purchase_orders")
    .doc(poId);
  const poSnap = await poRef.get();

  if (!poSnap.exists) {
    throw new functions.https.HttpsError("not-found", "PO not found");
  }

  const po = poSnap.data() as POData;

  // Fetch business profile (optional)
  const profileSnap = await db
    .collection("users")
    .doc(uid)
    .collection("profile")
    .doc("business")
    .get();
  const profile = profileSnap.exists ? profileSnap.data() : null;

  logger.info("Generating PO PDF Buffer", {
    uid,
    poId,
    poNumber: po.poNumber,
  });

  // Build PDF using pdf-lib
  const pdfDoc = await PDFDocument.create();
  let page = pdfDoc.addPage([595, 842]); // A4 portrait

  const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const bold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
  const { width, height } = page.getSize();

  const margin = 40;
  let y = height - margin;

  // ===== HEADER: Business Info =====
  const businessName =
    profile?.name || profile?.businessName || "Your Business";
  page.drawText(businessName, {
    x: margin,
    y: y,
    size: 18,
    font: bold,
    color: rgb(0.05, 0.05, 0.05),
  });
  y -= 24;

  if (profile?.address) {
    page.drawText(profile.address, {
      x: margin,
      y: y,
      size: 10,
      font,
      color: rgb(0.2, 0.2, 0.2),
    });
    y -= 14;
  }

  if (profile?.email) {
    page.drawText(`Email: ${profile.email}`, {
      x: margin,
      y: y,
      size: 10,
      font,
      color: rgb(0.2, 0.2, 0.2),
    });
    y -= 18;
  }

  if (profile?.phone) {
    page.drawText(`Phone: ${profile.phone}`, {
      x: margin,
      y: y,
      size: 10,
      font,
      color: rgb(0.2, 0.2, 0.2),
    });
    y -= 14;
  }

  // ===== PO META: Right side =====
  const metaX = width - margin - 180;
  page.drawText(`PURCHASE ORDER`, {
    x: metaX,
    y: height - margin - 8,
    size: 14,
    font: bold,
    color: rgb(0.0, 0.38, 0.8),
  });

  page.drawText(`PO #: ${po.poNumber || poId}`, {
    x: metaX,
    y: height - margin - 28,
    size: 10,
    font,
  });

  page.drawText(`Date: ${getDateString(po.createdAt)}`, {
    x: metaX,
    y: height - margin - 44,
    size: 10,
    font,
  });

  if (po.expectedDeliveryDate) {
    page.drawText(`Expected: ${getDateString(po.expectedDeliveryDate)}`, {
      x: metaX,
      y: height - margin - 60,
      size: 10,
      font,
    });
  }

  // ===== SUPPLIER BLOCK =====
  y -= 10;
  page.drawText(`Supplier: ${po.supplierName || ""}`, {
    x: margin,
    y: y,
    size: 12,
    font: bold,
  });
  y -= 16;

  if (po.supplierContact) {
    page.drawText(`Contact: ${po.supplierContact}`, {
      x: margin,
      y: y,
      size: 10,
      font,
    });
    y -= 12;
  }

  if (po.supplierEmail) {
    page.drawText(`Email: ${po.supplierEmail}`, {
      x: margin,
      y: y,
      size: 10,
      font,
    });
    y -= 12;
  }

  if (!po.supplierContact && !po.supplierEmail) {
    y -= 6;
  }

  // ===== TABLE HEADER =====
  y -= 8;
  page.drawLine({
    start: { x: margin, y },
    end: { x: width - margin, y },
    thickness: 1,
    color: rgb(0.85, 0.85, 0.85),
  });

  y -= 14;
  page.drawText("Item", { x: margin + 2, y, size: 10, font: bold });
  page.drawText("SKU", { x: margin + 200, y, size: 10, font: bold });
  page.drawText("Qty", { x: margin + 280, y, size: 10, font: bold });
  page.drawText("Unit", { x: margin + 330, y, size: 10, font: bold });
  page.drawText("Unit Price", { x: margin + 380, y, size: 10, font: bold });
  page.drawText("Total", {
    x: width - margin - 60,
    y,
    size: 10,
    font: bold,
  });

  y -= 12;
  page.drawLine({
    start: { x: margin, y },
    end: { x: width - margin, y },
    thickness: 0.5,
    color: rgb(0.9, 0.9, 0.9),
  });

  // ===== TABLE ROWS =====
  const items: POItem[] = (po.items || []).map((i: any) => ({
    name: i.name || "",
    sku: i.sku || null,
    qtyOrdered: Number(i.qtyOrdered || 0),
    costPrice: i.costPrice != null ? Number(i.costPrice) : null,
    unit: i.unit || null,
  }));

  y -= 8;
  const rowHeight = 16;
  let subtotal = 0;

  for (const it of items) {
    // Check if need new page
    if (y < margin + 80) {
      page = pdfDoc.addPage([595, 842]); // Update page reference!
      y = 842 - margin;
    }

    const itemTotal = (it.qtyOrdered || 0) * (it.costPrice || 0);
    subtotal += itemTotal;

    page.drawText(it.name, {
      x: margin + 2,
      y,
      size: 10,
      font,
    });

    page.drawText(it.sku || "-", {
      x: margin + 200,
      y,
      size: 10,
      font,
    });

    page.drawText(it.qtyOrdered.toString(), {
      x: margin + 280,
      y,
      size: 10,
      font,
    });

    page.drawText(it.unit || "-", {
      x: margin + 330,
      y,
      size: 10,
      font,
    });

    page.drawText(
      it.costPrice != null ? formatCurrency(it.costPrice) : "-",
      {
        x: margin + 380,
        y,
        size: 10,
        font,
      }
    );

    page.drawText(formatCurrency(itemTotal), {
      x: width - margin - 60,
      y,
      size: 10,
      font,
    });

    y -= rowHeight;
  }

  // ===== TOTALS BLOCK =====
  y -= 6;
  page.drawLine({
    start: { x: width - margin - 220, y },
    end: { x: width - margin, y },
    thickness: 0.5,
    color: rgb(0.85, 0.85, 0.85),
  });

  y -= 12;

  const tax = Number(po.subtotals?.tax || 0);
  const shipping = Number(po.subtotals?.shipping || 0);
  const total = subtotal + tax + shipping;

  page.drawText(`Subtotal:`, {
    x: width - margin - 160,
    y,
    size: 10,
    font,
  });
  page.drawText(formatCurrency(subtotal), {
    x: width - margin - 60,
    y,
    size: 10,
    font,
  });

  y -= 14;
  page.drawText(`Tax:`, {
    x: width - margin - 160,
    y,
    size: 10,
    font,
  });
  page.drawText(formatCurrency(tax), {
    x: width - margin - 60,
    y,
    size: 10,
    font,
  });

  y -= 14;
  page.drawText(`Shipping:`, {
    x: width - margin - 160,
    y,
    size: 10,
    font,
  });
  page.drawText(formatCurrency(shipping), {
    x: width - margin - 60,
    y,
    size: 10,
    font,
  });

  y -= 14;
  page.drawText(`Total:`, {
    x: width - margin - 160,
    y,
    size: 12,
    font: bold,
  });
  page.drawText(formatCurrency(total), {
    x: width - margin - 60,
    y,
    size: 12,
    font: bold,
  });

  // ===== FOOTER / NOTES =====
  y -= 30;
  if (po.notes) {
    page.drawText(`Notes: ${po.notes}`, {
      x: margin,
      y,
      size: 9,
      font,
    });
  }

  // ===== SERIALIZE PDF =====
  const pdfBytes = await pdfDoc.save();

  // ===== SAVE TO STORAGE (optional) =====
  if (saveToStorage) {
    const bucketName =
      admin.storage().bucket().name ||
      functions.config().firebase?.storageBucket;

    if (bucketName) {
      const bucket = admin.storage().bucket(bucketName);
      const filePath = `users/${uid}/purchase_orders/${poId}/po-${poId}.pdf`;
      const file = bucket.file(filePath);

      await file.save(pdfBytes, {
        contentType: "application/pdf",
        metadata: {
          metadata: {
            poId,
            poNumber: po.poNumber,
            generatedAt: new Date().toISOString(),
          },
        },
      });

      logger.info("PO PDF saved to storage", {
        uid,
        poId,
        filePath,
        size: pdfBytes.length,
      });
    }
  }

  logger.info("PO PDF Buffer generated successfully", {
    uid,
    poId,
    size: pdfBytes.length,
  });

  return Buffer.from(pdfBytes);
}
