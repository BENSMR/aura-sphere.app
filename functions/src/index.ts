import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

// initialize admin once (safe even if called multiple times)
if (!admin.apps.length) {
  admin.initializeApp({
    storageBucket: 'aurasphere-pro.appspot.com',
  });
}

export const helloWorld = functions.https.onRequest((req, res) => {
  res.json({ message: 'Hello from AuraSphere Functions!' });
});

// Export your functions here
export { setUserTimezoneCallable } from './timezone/setUserTimezoneCallable';
export { getUserLocaleDoc, setUserLocaleDoc, formatDateForUser, defaultCurrencyForCountry } from './locale/localeHelpers';
export { rewardUser } from './auraToken/rewards';
export { verifyUserTokenData } from './auraToken/verifyTokenData';
export { rewardOnInvoicePaid } from './auraToken/rewardOnInvoicePaid';
export { generateCrmInsights } from './crm/insights';
export { onClientInvoiceCreated, onClientInvoicePaid, onTopLevelInvoiceCreated, onTopLevelInvoicePaid } from './crm/onClientInvoiceCreated';
export { onNestedInvoiceCreated, onNestedInvoicePaid, onTopLevelInvoiceCreated as onTopLevelInvoiceCreatedSync, onTopLevelInvoicePaid as onTopLevelInvoicePaidSync } from './crm/onInvoiceSync';
export { onInvoicePaid as onClientInvoicePaidStatus, onInvoiceOverdue, onInvoiceCancelled, onInvoiceRefunded, onInvoiceEngagement } from './crm/onInvoiceStatusChange';
export { updateClientAIScore, recalculateAllClientScores, dailyScoreRefresh } from './crm/updateClientAIScore';
export { calculateClientAIScore, updateClientAIScore as updateClientAIScoreV2, recalculateAllClientScores as recalculateAllClientScoresV2, dailyScoreRefresh as dailyScoreRefreshV2 } from './crm/calculateAIScore';
export { generateClientSummary, regenerateClientSummary, regenerateAllClientSummaries } from './crm/generateClientSummary';
export { onClientWrite } from './crm/ai_insights';
export * from './crm/timeline_triggers';
export * from './crm/auto_follow_up';
export { autoCreateInvoiceOnWonDeal } from './crm/auto_invoice_on_deal_won';
export {
  onInvoiceFinanceSummary,
  onExpenseFinanceSummary,
  financeDailyRecalc,
} from './finance/finance_dashboard';
export { exportFinanceSummary, exportFinanceSummaryJson } from './finance/financeExport';
export { generateFinanceCoachAdvice } from './finance/financeCoach';
export { onFinanceSummaryGoalsAlerts, setFinanceGoals } from './finance/finance_goals_alerts';
export { convertCurrency } from './finance/convertCurrency';
export { syncFxRates } from './finance/fxRates';
export { calculateTax } from './finance/taxEngine';
export { seedTaxMatrix } from './finance/syncTaxMatrix';
export { determineTaxAndCurrency } from './finance/determineTaxAndCurrency';
export { processTaxQueue } from './finance/processTaxQueue';
export {
  onInvoiceCreateAutoAssign,
  onExpenseCreateAutoAssign,
  onPurchaseOrderCreateAutoAssign,
} from './finance/onDocumentCreateAutoAssign';
export { processDueReminders } from './tasks/processDueReminders';
export { sendTaskEmail } from './tasks/sendTaskEmail';
export { generateEmail } from './ai/generateEmail';
export { onInvoiceCreated, onInvoicePaid } from './invoice/onInvoiceCreated';
export { generateInvoicePdf } from './invoices/generateInvoicePdf';
export { exportInvoiceFormats } from './invoices/exportInvoiceFormats';
export { generateInvoiceNumber } from './invoices/generateInvoiceNumber';
export { markOverdueInvoices } from './invoice/markOverdueInvoices';
export { visionOcr } from './ocr/ocrProcessor';
export { onExpenseApproved } from './expenses/onExpenseApproved';
export { onExpenseApprovedInventory } from './expenses/onExpenseApprovedInventory';
export { onExpenseCreatedNotify } from './expenses/notifyApproval';
export { createInventoryItem } from './inventory/createInventoryItem';
export { adjustStock } from './inventory/adjustStock';
export { deductStockOnInvoicePaid } from './inventory/deductStockOnInvoicePaid';
export { intakeStockFromOCR } from './inventory/intakeStockFromOCR';
export { createCheckoutSession } from './payments/createCheckoutSession';
export { stripeWebhook } from './payments/stripeWebhook';
export { migrateBusinessProfiles, verifyBusinessProfileMigration, rollbackBusinessProfileMigration } from './migrations/migrate_business_profiles';
export { createCheckoutSession as createCheckoutSessionBilling } from './billing/createCheckoutSession';
export { stripeWebhook as stripeWebhookBilling } from './billing/stripeWebhook';
export { sendReceiptEmail } from './billing/sendReceiptEmail';
export { generateInvoiceReceipt } from './billing/generateInvoiceReceipt';
export { auditPaymentEvent, getPaymentAuditTrail, exportPaymentRecords } from './billing/paymentAudit';
export { sendPaymentConfirmationEmail, paymentReceiptEmail } from './billing/sendPaymentEmail';
export { generateInvoicePreview } from './billing/generateInvoicePreview';
export {
  saveBrandingProfile,
  getBrandingProfile,
  deleteBrandingProfile,
  getDefaultBrandingProfile,
  createBrandingFromTemplate,
  listBrandingTemplates,
} from './billing/brandingProfiles';
export {
  generateNextInvoiceNumber,
  getInvoiceSettings,
  updateInvoiceSettings,
} from './billing/generateNextInvoiceNumber';
export { createPaymentLinkOnInvoiceCreate } from './billing/create_payment_link';
export {
  generateNextInvoiceNumber as generateNextInvoiceNumberv2,
} from './invoice/generateNextInvoiceNumber';
export { sendInvoiceEmail as sendInvoiceEmailSimple } from "./invoices/sendInvoiceEmail";
export {
  sendInvoiceEmail,
  sendPaymentConfirmation,
  sendBulkInvoices,
} from './invoicing/emailService';
export { autoStatusAndReminder } from "./invoices/autoStatusAndReminder";
export { generatePOPDF } from './purchaseOrders/generatePOPDF';
export { emailPurchaseOrder } from './purchaseOrders/emailPurchaseOrder';
export { onInvoiceWriteAudit, onInvoiceStatusChange } from './audit/onInvoiceChange';
export { grantAdminRole, revokeAdminRole, listAdmins, getAdminStatus, getMyAdminStatus, setFirstAdmin } from './admin/manageAdmins';
export { archiveOldAuditEntries, archiveAuditManually } from './audit/archiveAudit';
export { exportAudit } from './audit/exportAudit';
export { detectExpenseAnomalies, detectInvoiceAnomalies, detectAuditAnomalies, resolveAnomaly, queryAnomalies } from './audit/anomalyDetection';
export { anomalyScanner } from './anomaly/anomalyScanner';
export { dailyAnomalyCount, queryAnomaliesDailyCount } from './anomaly/dailyAnomalyCount';
export { generateAnomalyInsights, queryAnomalyInsights } from './anomaly/generateInsights';
export { generateAIInsights, queryAIInsights } from './anomaly/generateAIInsights';
export { dailyAggregateScheduler, aggregateAnomaliesCallable } from './analytics/anomalyAggregator';
export { sendEmailAlertCallable, emailAnomalyAlert, emailInvoiceReminder, emailAlertPubSubHandler } from './notifications/emailAlert';
export { sendPushNotification, sendPushNotificationCallable, pushAnomalyAlert, pushRiskAlert, registerDevice, removeFCMToken } from './notifications/pushNotification';
export { logAuditEvent, getUserAudits, getFailedAudits, updateAuditStatus, getAuditStats, deleteOldAudits } from './notifications/auditLogger';
export { saveUserNotification, auditNotification, getUserDeviceTokens, sendPushToTokens } from './notifications/helpers';
export { shouldSendNotification, buildDedupeDocId, dedupeWindowMs, recordSkippedAudit, recordSentAudit, recordFailedAudit } from './notifications/dedupeThrottle';
export { onAnomalyCreate, onInvoiceWrite } from './notifications/sendPushOnEvent';
export { sendEmailAlert } from './notifications/sendEmailAlert';
export { sendSmsAlert } from './notifications/sendSmsAlert';
export { defaultEmailTemplate, renderTemplate, renderAlertEmail } from './notifications/emailTemplates';
