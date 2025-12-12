import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as PDFDocument from "pdfkit";
import * as StreamBuffers from "stream-buffers";
import sgMail from "@sendgrid/mail";
import * as path from "path";
import * as os from "os";
import * as fs from "fs";

if (!admin.apps.length) {
  admin.initializeApp();
}

const sendgridKey = functions.config()?.sendgrid?.key || "";
const sendgridSender = functions.config()?.sendgrid?.sender || "";
if (sendgridKey) {
  sgMail.setApiKey(sendgridKey);
} else {
  console.warn("SendGrid not configured (sendgrid.key/sendgrid.sender). Receipt emails will be skipped.");
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

      // Load branding settings if exists
      const brandingRef = db.collection("users").doc(uid).collection("branding").doc("settings");
      const brandingSnap = await brandingRef.get();
      const branding = brandingSnap.exists ? (brandingSnap.data() as any) : {};

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

      // Template-specific styling configuration
      const templateId = branding?.templateId || "TEMPLATE_CLASSIC";
      const templateStyles = {
        "TEMPLATE_CLASSIC": {
          businessNameSize: 18,
          invoiceTitleSize: 20,
          headerMargin: 2,
          itemFontSize: 10,
          totalFontSize: 14,
          addressFontSize: 10,
          logoWidth: 120
        },
        "TEMPLATE_MODERN": {
          businessNameSize: 20,
          invoiceTitleSize: 24,
          headerMargin: 3,
          itemFontSize: 11,
          totalFontSize: 16,
          addressFontSize: 9,
          logoWidth: 140
        },
        "TEMPLATE_MINIMAL": {
          businessNameSize: 16,
          invoiceTitleSize: 18,
          headerMargin: 1.5,
          itemFontSize: 9,
          totalFontSize: 12,
          addressFontSize: 9,
          logoWidth: 100
        },
        "TEMPLATE_ELEGANT": {
          businessNameSize: 19,
          invoiceTitleSize: 22,
          headerMargin: 2.5,
          itemFontSize: 10,
          totalFontSize: 15,
          addressFontSize: 10,
          logoWidth: 125
        },
        "TEMPLATE_BUSINESS": {
          businessNameSize: 18,
          invoiceTitleSize: 20,
          headerMargin: 2,
          itemFontSize: 10,
          totalFontSize: 14,
          addressFontSize: 10,
          logoWidth: 120
        }
      };
      const styles = (templateStyles as any)[templateId] || (templateStyles as any)["TEMPLATE_CLASSIC"];

      // Header: prefer branding.logoUrl, fallback to business.logoUrl
      const logoUrl = (branding?.logoUrl) || (business?.logoUrl);
      if (logoUrl) {
        try {
          // Try to fetch logo bytes via storage or external URL
          // If it's a storage gs:// url, download from storage
          if (logoUrl.startsWith("gs://")) {
            const bucketPath = logoUrl.replace("gs://", "");
            const [bucketName, ...rest] = bucketPath.split("/");
            const filePath = rest.join("/");
            const bucket = admin.storage().bucket(bucketName);
            const file = getBucket().file(filePath);
            const [buf] = await file.download();
            doc.image(buf, 40, 45, { width: styles.logoWidth });
          } else {
            // external http(s) url (PDFKit supports buffer)
            const axios = require("axios");
            const resp = await axios.get(logoUrl, { responseType: "arraybuffer" });
            doc.image(resp.data, 40, 45, { width: styles.logoWidth });
          }
        } catch (e: any) {
          console.warn("Logo load failed:", e?.message || String(e));
        }
      }

      // Business name & invoice title (use branding companyDetails if supplied)
      const businessName = (branding?.companyDetails?.name) || (business?.businessName) || (business?.company) || "AuraSphere";
      doc.fontSize(styles.businessNameSize).fillColor(branding?.primaryColor || "#000000").text(businessName, 160, 50, { align: "left" });
      const baddress = branding?.companyDetails?.address || business?.address || "";
      if (baddress) doc.fontSize(styles.addressFontSize).fillColor(branding?.textColor || "#333333").text(baddress, 160, 72);
      doc.moveDown(styles.headerMargin);

      // Invoice title, number, dates
      doc.fontSize(styles.invoiceTitleSize).text("Receipt", { align: "right" });
      doc.moveDown(0.5);
      const invoiceNumber = invoice?.invoiceNumber || invoiceId;
      doc.fontSize(styles.addressFontSize).text(`Invoice: ${invoiceNumber}`, { align: "right" });
      const createdAt = invoice?.createdAt ? invoice?.createdAt.toDate ? invoice.createdAt.toDate() : new Date(invoice.createdAt) : new Date();
      doc.text(`Date: ${createdAt.toLocaleDateString()}`, { align: "right" });
      doc.moveDown(1.2);

      // Customer block
      doc.fontSize(12).text("Bill to:", { underline: true });
      doc.fontSize(12).text(((invoice?.customerName ?? invoice?.customer) || "Customer") as string);
      if (invoice?.customerEmail) doc.text(invoice.customerEmail);
      if (invoice?.customerAddress) doc.text(invoice.customerAddress);
      doc.moveDown(1);

      // Table header
      doc.fontSize(styles.itemFontSize).text("Description", 40, doc.y, { continued: true });
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
        doc.fontSize(styles.itemFontSize).text(name, 40, doc.y, { continued: true });
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

      doc.fontSize(styles.itemFontSize).text(`Subtotal: ${subtotal.toFixed(2)} ${invoice?.currency ?? ""}`, { align: "right" });
      doc.text(`VAT: ${vat.toFixed(2)} ${invoice?.currency ?? ""}`, { align: "right" });
      doc.fontSize(styles.totalFontSize).text(`Total: ${total.toFixed(2)} ${invoice?.currency ?? ""}`, { align: "right" });
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
      const footerNote = branding?.footerNote || business?.documentFooter || "Thank you for your business.";
      doc.fontSize(9).fillColor(branding?.textColor || "#333333").text(footerNote, 40, doc.page.height - 80, { align: "center", width: doc.page.width - 80 });

      // Paid watermark if invoice is paid
      if (invoice?.paymentStatus === "paid") {
        // watermark text comes from branding or default
        const watermark = branding?.watermarkText || "PAID";
        doc.save();
        doc.rotate(-45, { origin: [doc.page.width / 2, doc.page.height / 2] });
        doc.fontSize(60).fillColor(branding?.primaryColor || "#0A84FF").opacity(0.08).text(watermark, doc.page.width / 4, doc.page.height / 2, { align: "center" });
        doc.restore();
        doc.opacity(1);
      }

      doc.end();

      // Wait for buffer
      const pdfBuffer = stream.getContents() as Buffer;

      // Upload to storage
      function getBucket() { return admin.storage().bucket() }; // default bucket from project
      const filePath = `receipts/${uid}/${invoiceNumber || invoiceId}.pdf`;
      const file = getBucket().file(filePath);
      await file.save(pdfBuffer, {
        metadata: { contentType: "application/pdf" },
        public: false,
        validation: "md5"
      });

      // Generate signed URL (long lived -> 10 years)
      const expires = Date.now() + 1000 * 60 * 60 * 24 * 365 * 10; // 10 years
      const [signedUrl] = await file.getSignedUrl({ action: "read", expires });

      // Save URL to invoice doc
      await invoiceRef.set({ receiptPdfUrl: signedUrl, brandingAppliedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });

      // Auto-send receipt email via SendGrid if configured and customer email exists
      const customerEmail = invoice?.customerEmail || invoice?.customer?.email || null;
      if (sendgridKey && sendgridSender && customerEmail) {
        try {
          // Prepare attachment (we have pdfBuffer in memory)
          const attachment = pdfBuffer.toString("base64");

          const msg: any = {
            to: customerEmail,
            from: sendgridSender,
            subject: `Receipt - ${invoiceNumber}`,
            text: `Thank you for your payment. Attached is your receipt for invoice ${invoiceNumber}.`,
            attachments: [
              {
                content: attachment,
                filename: `receipt-${invoiceNumber}.pdf`,
                type: "application/pdf",
                disposition: "attachment"
              }
            ]
          };

          await sgMail.send(msg);
          console.log(`Receipt emailed to ${customerEmail}`);
          // Optionally record that email was sent
          await invoiceRef.set({ receiptEmailSentAt: admin.firestore.FieldValue.serverTimestamp(), receiptEmailTo: customerEmail }, { merge: true });
        } catch (err) {
          console.error("Failed to send receipt email:", err);
        }
      } else {
        if (!customerEmail) console.warn("No customer email available; skipping send.");
        if (!sendgridKey || !sendgridSender) console.warn("SendGrid not configured; skipping email send.");
      }

      return { url: signedUrl };
    } catch (err: any) {
      console.error("generateInvoiceReceipt error:", err);
      throw new functions.https.HttpsError("internal", err?.message || "Internal error");
    }
  });
