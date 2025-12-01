import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as PDFDocument from "pdfkit";
import * as StreamBuffers from "stream-buffers";

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Callable function: generateInvoiceReceipt
 * Inputs: { invoiceId: string, uid?: string }
 * Behavior:
 *  - Fetch invoice, business profile, payments
 *  - Generate PDF receipt using pdfkit
 *  - Upload to default storage bucket
 *  - Save signed URL to invoice.receiptPdfUrl
 *  - Return { url }
 */
export const generateInvoiceReceipt = functions
  .runWith({ memory: "1GB", timeoutSeconds: 120 })
  .https.onCall(async (data, context) => {
    try {
      if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
      }

      const uid = data?.uid || context.auth.uid;
      const invoiceId = data?.invoiceId;
      if (!invoiceId) {
        throw new functions.https.HttpsError("invalid-argument", "invoiceId is required");
      }

      const db = admin.firestore();
      const invoiceRef = db.collection("users").doc(uid).collection("invoices").doc(invoiceId);
      const invoiceSnap = await invoiceRef.get();
      if (!invoiceSnap.exists) {
        throw new functions.https.HttpsError("not-found", "Invoice not found");
      }
      const invoice = invoiceSnap.data() as any;

      // Load business profile if exists
      const businessRef = db.collection("users").doc(uid).collection("meta").doc("business");
      const businessSnap = await businessRef.get();
      const business = businessSnap.exists ? (businessSnap.data() as any) : {};

      // Load payments (optional)
      const paymentsSnap = await invoiceRef.collection("payments").orderBy("createdAt", "asc").get();
      const payments = paymentsSnap.docs.map(d => ({ id: d.id, ...d.data() }));

      // Create PDF in memory
      const doc: any = new (PDFDocument as any)({ size: "A4", margin: 40 });
      const stream = new StreamBuffers.WritableStreamBuffer({
        initialSize: 200 * 1024,
        incrementAmount: 10 * 1024
      });
      doc.pipe(stream);

      // Header: logo (if available), business name & contact
      const logoUrl = business?.logoUrl;
      if (logoUrl) {
        try {
          // Try to fetch logo bytes via storage or external URL
          // If it's a storage gs:// url, download from storage
          if (logoUrl.startsWith("gs://")) {
            const bucketPath = logoUrl.replace("gs://", "");
            const [bucketName, ...rest] = bucketPath.split("/");
            const filePath = rest.join("/");
            const bucket = admin.storage().bucket(bucketName);
            const file = bucket.file(filePath);
            const [buf] = await file.download();
            doc.image(buf, 40, 45, { width: 120 });
          } else {
            // external http(s) url (PDFKit supports buffer)
            const axios = require("axios");
            const resp = await axios.get(logoUrl, { responseType: "arraybuffer" });
            doc.image(resp.data, 40, 45, { width: 120 });
          }
        } catch (e: any) {
          console.warn("Logo load failed:", e?.message || e);
        }
      }

      // Business name & invoice title
      const businessName = business?.businessName || business?.company || "AuraSphere";
      doc.fontSize(18).text(businessName, 160, 50, { align: "left" });
      doc.fontSize(10).text(business?.address ?? "", 160, 72);
      doc.moveDown(2);

      // Invoice title, number, dates
      doc.fontSize(20).text("Receipt", { align: "right" });
      doc.moveDown(0.5);
      const invoiceNumber = invoice?.invoiceNumber || invoiceId;
      doc.fontSize(10).text(`Invoice: ${invoiceNumber}`, { align: "right" });
      const createdAt = invoice?.createdAt ? invoice?.createdAt.toDate ? invoice.createdAt.toDate() : new Date(invoice.createdAt) : new Date();
      doc.text(`Date: ${createdAt.toLocaleDateString()}`, { align: "right" });
      doc.moveDown(1.2);

      // Customer block
      doc.fontSize(12).text("Bill to:", { underline: true });
      doc.fontSize(12).text((invoice?.customerName ?? invoice?.customer) || "Customer");
      if (invoice?.customerEmail) doc.text(invoice.customerEmail);
      if (invoice?.customerAddress) doc.text(invoice.customerAddress);
      doc.moveDown(1);

      // Table header
      doc.fontSize(11).text("Description", 40, doc.y, { continued: true });
      doc.text("Qty", 320, doc.y, { width: 50, align: "right", continued: true });
      doc.text("Unit", 380, doc.y, { width: 70, align: "right", continued: true });
      doc.text("Total", 0, doc.y, { align: "right" });
      doc.moveTo(40, doc.y + 2).lineTo(555, doc.y + 2).stroke();
      doc.moveDown(0.5);

      // Items
      const items = (invoice?.items ?? []);
      items.forEach((item: any) => {
        const name = item?.name ?? item?.description ?? "";
        const qty = item?.quantity ?? item?.qty ?? 1;
        const unit = (item?.unitPrice ?? item?.price ?? 0).toFixed(2);
        const lineTotal = ((item?.quantity ?? 1) * (item?.unitPrice ?? item?.price ?? 0)).toFixed(2);
        doc.fontSize(10).text(name, 40, doc.y, { continued: true });
        doc.text(qty.toString(), 320, doc.y, { width: 50, align: "right", continued: true });
        doc.text(unit, 380, doc.y, { width: 70, align: "right", continued: true });
        doc.text(lineTotal, 0, doc.y, { align: "right" });
        doc.moveDown(0.4);
      });

      doc.moveDown(1);
      // Totals block
      const subtotal = parseFloat((invoice?.subtotal ?? 0).toString());
      const vat = parseFloat((invoice?.totalVat ?? 0).toString());
      const total = parseFloat((invoice?.total ?? invoice?.amount ?? 0).toString());

      doc.text(`Subtotal: ${subtotal.toFixed(2)} ${invoice?.currency ?? ""}`, { align: "right" });
      doc.text(`VAT: ${vat.toFixed(2)} ${invoice?.currency ?? ""}`, { align: "right" });
      doc.fontSize(14).text(`Total: ${total.toFixed(2)} ${invoice?.currency ?? ""}`, { align: "right" });
      doc.moveDown(1);

      // Payments info
      if (payments.length > 0) {
        doc.fontSize(12).text("Payments", { underline: true });
        payments.forEach((p: any) => {
          const paidAt = p?.createdAt ? (p.createdAt.toDate ? p.createdAt.toDate() : new Date(p.createdAt)) : new Date();
          const amt = ((p.amount_cents ?? p.amount ?? 0) / 100).toFixed(2);
          doc.fontSize(10).text(`- ${amt} ${p.currency ?? invoice?.currency ?? ""} • ${paidAt.toLocaleString()} • ${p.provider ?? "stripe"}`);
        });
        doc.moveDown(1);
      }

      // Footer
      doc.fontSize(9).text(business?.documentFooter ?? "Thank you for your business.", 40, doc.page.height - 80, { align: "center", width: doc.page.width - 80 });

      // Paid watermark if invoice is paid
      if (invoice?.paymentStatus === "paid") {
        // simple rotated watermark
        doc.rotate(-45, { origin: [doc.page.width / 2, doc.page.height / 2] });
        doc.fontSize(60).opacity(0.08).text("PAID", doc.page.width / 4, doc.page.height / 2, { align: "center" });
        doc.rotate(45, { origin: [doc.page.width / 2, doc.page.height / 2] });
        doc.opacity(1);
      }

      doc.end();

      // Wait for buffer
      const pdfBuffer = stream.getContents() as Buffer;

      // Upload to storage
      const bucket = admin.storage().bucket(); // default bucket from project
      const filePath = `receipts/${uid}/${invoiceNumber || invoiceId}.pdf`;
      const file = bucket.file(filePath);
      await file.save(pdfBuffer, {
        metadata: { contentType: "application/pdf" },
        public: false,
        validation: "md5"
      });

      // Generate signed URL (long lived -> 10 years)
      const expires = Date.now() + 1000 * 60 * 60 * 24 * 365 * 10; // 10 years
      const [signedUrl] = await file.getSignedUrl({ action: "read", expires });

      // Save URL to invoice doc
      await invoiceRef.set({ receiptPdfUrl: signedUrl }, { merge: true });

      return { url: signedUrl };
    } catch (err: any) {
      console.error("generateInvoiceReceipt error:", err);
      throw new functions.https.HttpsError("internal", err?.message || "Internal error");
    }
  });
