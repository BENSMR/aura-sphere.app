// functions/src/invoicing/generateInvoicePdf.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import PDFDocument from "pdfkit";
import * as stream from "stream";

// Initialize Firebase (if not already done in index.ts)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const storage = admin.storage();

export const generateInvoicePdf = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Requesting user must be authenticated."
    );
  }

  const userId = context.auth.uid;
  const invoiceId = data.invoiceId as string;

  if (!invoiceId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing invoiceId"
    );
  }

  try {
    // Fetch invoice
    const invSnap = await db.collection("users").doc(userId).collection("invoices").doc(invoiceId).get();
    if (!invSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Invoice not found");
    }

    const invoice = invSnap.data() as any;

    // Fetch business profile
    const businessRef = db
      .collection("users")
      .doc(userId)
      .collection("meta")
      .doc("business");
    const bizSnap = await businessRef.get();
    const business = bizSnap.exists ? bizSnap.data() : {};

    const invoiceNumber = invoice.invoiceNumber || `INV-${Date.now()}`;
    const filename = `invoices/${userId}/${invoiceNumber}.pdf`;

    // Create PDF with PDFKit
    const doc = new PDFDocument({ size: "A4", margin: 50 });
    const passthrough = new stream.PassThrough();
    const bucket = storage.bucket();
    const file = bucket.file(filename);
    const writeStream = file.createWriteStream({
      resumable: false,
      metadata: { contentType: "application/pdf" },
    });

    // Write content to PDF
    const brandColor = (business?.brandColor || "#ff6600").replace("#", "");
    
    doc
      .fontSize(20)
      .fillColor(`#${brandColor}`)
      .text(business?.businessName || "Your Business", { align: "left" });
    
    if (business?.address) {
      doc.fontSize(10).text(business.address as string);
    }

    doc.moveDown();

    // Invoice number and date
    doc
      .fontSize(16)
      .fillColor("#000")
      .text(`Invoice: ${invoiceNumber}`, { align: "left" });
    
    doc
      .fontSize(10)
      .text(`Date: ${new Date().toISOString().slice(0, 10)}`, { align: "right" });
    
    if (invoice.dueDate) {
      const dueDate = invoice.dueDate instanceof admin.firestore.Timestamp
        ? invoice.dueDate.toDate()
        : new Date(invoice.dueDate);
      doc.text(`Due: ${dueDate.toISOString().slice(0, 10)}`);
    }

    doc.moveDown();

    // Items table
    doc.fontSize(12).text("Items:", { underline: true });
    
    (invoice.items || []).forEach((item: any) => {
      const itemTotal = item.quantity * item.unitPrice;
      doc
        .fontSize(10)
        .text(
          `${item.description} — ${item.quantity} x ${item.unitPrice.toFixed(2)} = ${itemTotal.toFixed(2)}`
        );
    });

    doc.moveDown();

    // Totals
    doc
      .fontSize(12)
      .fillColor("#000")
      .text(`Total: ${invoice.amount.toFixed(2)} ${invoice.currency || "USD"}`, {
        align: "right",
      });

    // Payment status
    if (invoice.paymentStatus === "paid") {
      doc.fontSize(11).fillColor("green").text("PAID", { align: "right" });
    }

    // Footer
    if (business?.documentFooter) {
      doc.moveDown();
      doc.fontSize(10).fillColor("#666").text(business.documentFooter as string, {
        align: "center",
      });
    }

    doc.end();

    // Pipe to storage
    doc.pipe(writeStream);

    // Wait for completion
    await new Promise<void>((resolve, reject) => {
      writeStream.on("finish", () => resolve());
      writeStream.on("error", (err: Error) => reject(err));
      doc.on("error", (err: Error) => reject(err));
    });

    // Generate signed URL (7 days)
    const [url] = await file.getSignedUrl({
      action: "read",
      expires: Date.now() + 1000 * 60 * 60 * 24 * 7,
    });

    // Save URL in invoice document
    await invSnap.ref.set(
      { exportPdfUrl: url, exportPdfPath: filename, exportPdfGeneratedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );

    return { success: true, url, path: filename };
  } catch (error) {
    console.error("PDF generation error:", error);
    throw new functions.https.HttpsError(
      "internal",
      `PDF generation failed: ${error instanceof Error ? error.message : String(error)}`
    );
  }
});
