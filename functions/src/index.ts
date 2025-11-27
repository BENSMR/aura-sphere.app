import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

// initialize admin once (safe even if called multiple times)
if (!admin.apps.length) {
  admin.initializeApp();
}

export const helloWorld = functions.https.onRequest((req, res) => {
  res.json({ message: 'Hello from AuraSphere Functions!' });
});

// Export your functions here
export { rewardUser } from './auraToken/rewards';
export { verifyUserTokenData } from './auraToken/verifyTokenData';
export { generateCrmInsights } from './crm/insights';
export { processDueReminders } from './tasks/processDueReminders';
export { sendTaskEmail } from './tasks/sendTaskEmail';
export { generateEmail } from './ai/generateEmail';
export { onInvoiceCreated, onInvoicePaid } from './invoice/onInvoiceCreated';
export { generateInvoicePdf } from './invoices/generateInvoicePdf';
export { exportInvoiceFormats } from './invoices/exportInvoiceFormats';
export { visionOcr } from './ocr/ocrProcessor';
export { onExpenseApproved } from './expenses/onExpenseApproved';
export { onExpenseApprovedInventory } from './expenses/onExpenseApprovedInventory';
// add other exports below as you add them, e.g.:
// export { someOtherFunction } from './finance/invoiceProcessor';
