import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import PDFDocument from 'pdfkit';
import { Readable } from 'stream';

const db = admin.firestore();
const storage = admin.storage();

interface InvoicePreviewRequest {
  invoiceId: string;
  templateId?: string;
  includeSignature?: boolean;
  watermarkText?: string;
}

interface InvoicePreviewResponse {
  success: boolean;
  pdfUrl?: string;
  message: string;
  generatedAt?: string;
}

/**
 * Generate invoice preview PDF with business branding
 * Can be used for preview before sending or for viewing in app
 */
export const generateInvoicePreview = functions
  .region('us-central1')
  .https.onCall(
    async (
      data: InvoicePreviewRequest,
      context: functions.https.CallableContext
    ): Promise<InvoicePreviewResponse> => {
      try {
        // Verify authentication
        if (!context.auth?.uid) {
          throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated'
          );
        }

        const userId = context.auth.uid;
        const { invoiceId, templateId = 'default', includeSignature = true, watermarkText } = data;

        if (!invoiceId) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'invoiceId is required'
          );
        }

        // Fetch invoice
        const invoiceDoc = await db
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .get();

        if (!invoiceDoc.exists) {
          throw new functions.https.HttpsError('not-found', 'Invoice not found');
        }

        const invoice = invoiceDoc.data() as any;

        // Fetch business branding
        const brandingDoc = await db
          .collection('users')
          .doc(userId)
          .collection('meta')
          .doc('businessBranding')
          .get();

        const branding = brandingDoc.exists ? brandingDoc.data() : null;

        // Fetch client details
        let clientDetails: any = {};
        if (invoice.clientId) {
          const clientDoc = await db
            .collection('users')
            .doc(userId)
            .collection('clients')
            .doc(invoice.clientId)
            .get();

          if (clientDoc.exists) {
            clientDetails = clientDoc.data();
          }
        }

        // Generate PDF
        const pdfBuffer = await generatePDF({
          invoice,
          branding,
          clientDetails,
          templateId,
          includeSignature,
          watermarkText,
        });

        // Upload to storage
        const filename = `invoice-preview-${invoiceId}-${Date.now()}.pdf`;
        const bucket = storage.bucket();
        const file = bucket.file(
          `users/${userId}/invoice-previews/${filename}`
        );

        await file.save(pdfBuffer);

        // Generate signed URL (1 hour expiry for preview)
        const [url] = await file.getSignedUrl({
          version: 'v4',
          action: 'read',
          expires: Date.now() + 60 * 60 * 1000, // 1 hour
        });

        // Record preview in Firestore
        await db
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .collection('previews')
          .add({
            filename,
            url,
            templateId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 60 * 60 * 1000),
          });

        return {
          success: true,
          pdfUrl: url,
          message: 'Invoice preview generated successfully',
          generatedAt: new Date().toISOString(),
        };
      } catch (error) {
        console.error('Error generating invoice preview:', error);
        throw new functions.https.HttpsError(
          'internal',
          `Failed to generate invoice preview: ${error instanceof Error ? error.message : 'Unknown error'}`
        );
      }
    }
  );

/**
 * Generate PDF document with invoice details and branding
 */
async function generatePDF(options: {
  invoice: any;
  branding: any;
  clientDetails: any;
  templateId: string;
  includeSignature: boolean;
  watermarkText?: string;
}): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const buffers: Buffer[] = [];

    const doc = new PDFDocument({
      size: 'A4',
      margin: 50,
      bufferPages: true,
    });

    doc.on('data', (buffer: Buffer) => buffers.push(buffer));
    doc.on('end', () => resolve(Buffer.concat(buffers)));
    doc.on('error', reject);

    // Apply template
    applyTemplate(doc, options);

    doc.end();
  });
}

/**
 * Apply template styling to invoice PDF
 */
function applyTemplate(
  doc: any,
  options: {
    invoice: any;
    branding: any;
    clientDetails: any;
    templateId: string;
    includeSignature: boolean;
    watermarkText?: string;
  }
): void {
  const { invoice, branding, clientDetails, templateId, includeSignature, watermarkText } =
    options;

  const primaryColor = branding?.primaryColor || '#1976D2';
  const accentColor = branding?.accentColor || '#FFC107';
  const textColor = branding?.textColor || '#000000';

  // Add watermark if provided
  if (watermarkText || branding?.watermarkText) {
    const watermark = watermarkText || branding.watermarkText;
    const pages = doc.bufferedPageRange().count;
    for (let i = 0; i < pages; i++) {
      doc.switchToPage(i);
      doc.opacity(0.1);
      doc.rotate(45, { origin: [doc.page.width / 2, doc.page.height / 2] });
      doc.fontSize(100).text(watermark, -100, doc.page.height / 2 - 50);
      doc.rotate(-45, { origin: [doc.page.width / 2, doc.page.height / 2] });
      doc.opacity(1);
    }
  }

  doc.switchToPage(0);

  // Header with logo
  if (branding?.logoUrl) {
    try {
      doc.image(branding.logoUrl, 50, 50, { width: 100, height: 80 });
    } catch (e) {
      // Logo failed to load, continue
    }
  }

  // Company details
  let startY = branding?.logoUrl ? 140 : 60;

  if (branding?.companyDetails) {
    const company = branding.companyDetails;
    doc
      .fontSize(18)
      .font('Helvetica-Bold')
      .text(company.name || 'Company', 50, startY);

    startY += 25;

    doc.fontSize(10).font('Helvetica');

    if (company.address) {
      doc.text(company.address, 50, startY);
      startY += 15;
    }
    if (company.phone) {
      doc.text(`Phone: ${company.phone}`, 50, startY);
      startY += 15;
    }
    if (company.email) {
      doc.text(`Email: ${company.email}`, 50, startY);
      startY += 15;
    }
    if (company.website) {
      doc.text(`Website: ${company.website}`, 50, startY);
      startY += 15;
    }
  }

  startY += 20;

  // Invoice title and status
  doc.fontSize(28).font('Helvetica-Bold').text('INVOICE', 50, startY);

  startY += 35;

  // Invoice details
  doc.fontSize(11);
  const detailsX = 350;

  doc
    .font('Helvetica-Bold')
    .text('Invoice #:', 50, startY)
    .font('Helvetica')
    .text(invoice.invoiceNumber || invoice.id, detailsX, startY);

  startY += 20;

  const issueDate = invoice.issueDate
    ? new Date(invoice.issueDate.toDate?.() || invoice.issueDate).toLocaleDateString()
    : new Date().toLocaleDateString();

  doc
    .font('Helvetica-Bold')
    .text('Date:', 50, startY)
    .font('Helvetica')
    .text(issueDate, detailsX, startY);

  startY += 20;

  const dueDate = invoice.dueDate
    ? new Date(invoice.dueDate.toDate?.() || invoice.dueDate).toLocaleDateString()
    : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toLocaleDateString();

  doc
    .font('Helvetica-Bold')
    .text('Due Date:', 50, startY)
    .font('Helvetica')
    .text(dueDate, detailsX, startY);

  startY += 20;

  const status = invoice.status || 'Draft';
  const statusColor =
    status === 'Paid' ? '#28a745' : status === 'Pending' ? '#ffc107' : '#6c757d';

  doc
    .font('Helvetica-Bold')
    .text('Status:', 50, startY)
    .fillColor(statusColor)
    .font('Helvetica-Bold')
    .text(status, detailsX, startY);

  doc.fillColor(textColor);

  startY += 35;

  // Bill To section
  doc.font('Helvetica-Bold').fontSize(12).text('BILL TO:', 50, startY);
  startY += 20;

  doc.fontSize(11).font('Helvetica');

  if (clientDetails.name) {
    doc.text(clientDetails.name, 50, startY);
    startY += 15;
  }

  if (clientDetails.email) {
    doc.text(clientDetails.email, 50, startY);
    startY += 15;
  }

  if (clientDetails.phone) {
    doc.text(clientDetails.phone, 50, startY);
    startY += 15;
  }

  if (clientDetails.address) {
    doc.text(clientDetails.address, 50, startY);
    startY += 15;
  }

  startY += 20;

  // Items table
  const tableY = startY;
  const tableX = 50;
  const col1 = 50;
  const col2 = 330;
  const col3 = 430;
  const col4 = 530;

  // Table header
  doc.rect(tableX, tableY, 500, 25).fillAndStroke(primaryColor, primaryColor);
  doc.fillColor('white').font('Helvetica-Bold').fontSize(11);

  doc.text('Description', col1 + 10, tableY + 8);
  doc.text('Qty', col2 + 10, tableY + 8);
  doc.text('Price', col3 + 10, tableY + 8);
  doc.text('Amount', col4 + 10, tableY + 8);

  doc.fillColor(textColor);

  // Items
  let itemY = tableY + 30;
  const items = invoice.items || [];
  let subtotal = 0;

  items.forEach((item: any) => {
    const quantity = item.quantity || 1;
    const price = item.price || 0;
    const amount = quantity * price;
    subtotal += amount;

    doc.fontSize(10).font('Helvetica');
    doc.text(item.description || 'Item', col1 + 10, itemY);
    doc.text(quantity.toString(), col2 + 10, itemY);
    doc.text(`$${price.toFixed(2)}`, col3 + 10, itemY);
    doc.text(`$${amount.toFixed(2)}`, col4 + 10, itemY);

    itemY += 25;
  });

  // Totals
  const totalsY = itemY + 10;

  doc
    .rect(tableX, totalsY - 5, 500, 1)
    .stroke(primaryColor);

  itemY = totalsY;

  // Subtotal
  doc.font('Helvetica');
  doc.text('Subtotal:', col3 + 10, itemY);
  doc.text(`$${subtotal.toFixed(2)}`, col4 + 10, itemY);

  itemY += 20;

  // Tax (if applicable)
  const tax = invoice.tax || 0;
  if (tax > 0) {
    doc.text(`Tax (${invoice.taxRate || 0}%):`, col3 + 10, itemY);
    doc.text(`$${tax.toFixed(2)}`, col4 + 10, itemY);
    itemY += 20;
  }

  // Total
  doc.font('Helvetica-Bold').fontSize(14);
  doc.text('TOTAL:', col3 + 10, itemY);
  doc.fillColor(primaryColor).text(`$${(subtotal + tax).toFixed(2)}`, col4 + 10, itemY);
  doc.fillColor(textColor);

  // Footer
  let footerY = doc.page.height - 150;

  if (branding?.footerNote) {
    doc
      .fontSize(10)
      .font('Helvetica-Italic')
      .text(branding.footerNote, 50, footerY, { align: 'center', width: 500 });

    footerY += 30;
  }

  // Signature
  if (includeSignature && branding?.showSignature && branding?.signatureUrl) {
    try {
      doc.text('Authorized By:', 50, footerY);
      doc.image(branding.signatureUrl, 50, footerY + 15, { width: 100, height: 40 });
    } catch (e) {
      // Signature image failed to load, continue
    }
  }

  // Page number and footer line
  doc
    .moveTo(50, doc.page.height - 50)
    .lineTo(doc.page.width - 50, doc.page.height - 50)
    .stroke(primaryColor);

  doc
    .fontSize(9)
    .font('Helvetica')
    .text('Generated by AuraSphere Pro', 50, doc.page.height - 40, {
      align: 'center',
      width: 500,
    });
}
