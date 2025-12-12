import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

const db = admin.firestore();
const logger = functions.logger;

export interface DigestSummary {
  invoices?: any[];
  expenses?: any[];
  tasks?: any[];
  stock?: any[];
  crm?: any[];
}

/**
 * Build a comprehensive digest summary for a user based on their preferences
 */
export async function buildDigestForUser(
  uid: string,
  settings: any
): Promise<DigestSummary> {
  try {
    const summary: DigestSummary = {};

    if (settings.includeInvoices !== false) {
      summary.invoices = await getPendingInvoices(uid);
    }

    if (settings.includeExpenses !== false) {
      summary.expenses = await getPendingExpenses(uid);
    }

    if (settings.includeTasks !== false) {
      summary.tasks = await getPendingTasks(uid);
    }

    if (settings.includeStock !== false) {
      summary.stock = await getLowStockItems(uid);
    }

    if (settings.includeCRM !== false) {
      summary.crm = await getCRMFollowups(uid);
    }

    logger.info(`[buildDigestForUser] Built digest for ${uid}:`, {
      invoices: summary.invoices?.length ?? 0,
      expenses: summary.expenses?.length ?? 0,
      tasks: summary.tasks?.length ?? 0,
      stock: summary.stock?.length ?? 0,
      crm: summary.crm?.length ?? 0,
    });

    return summary;
  } catch (error) {
    logger.error(`[buildDigestForUser] Error building digest for ${uid}:`, error);
    return {};
  }
}

/**
 * Get pending/unpaid invoices for user
 */
async function getPendingInvoices(uid: string): Promise<any[]> {
  try {
    const snap = await db
      .collection('users')
      .doc(uid)
      .collection('invoices')
      .where('status', '==', 'pending')
      .orderBy('dueDate', 'desc')
      .limit(10)
      .get();

    return snap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
  } catch (error) {
    logger.warn(`[getPendingInvoices] Error for user ${uid}:`, error);
    return [];
  }
}

/**
 * Get pending/unreviewed expenses for user
 */
async function getPendingExpenses(uid: string): Promise<any[]> {
  try {
    const snap = await db
      .collection('users')
      .doc(uid)
      .collection('expenses')
      .where('status', '==', 'pending_review')
      .orderBy('createdAt', 'desc')
      .limit(10)
      .get();

    return snap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
  } catch (error) {
    logger.warn(`[getPendingExpenses] Error for user ${uid}:`, error);
    return [];
  }
}

/**
 * Get incomplete tasks for user
 */
async function getPendingTasks(uid: string): Promise<any[]> {
  try {
    const snap = await db
      .collection('users')
      .doc(uid)
      .collection('tasks')
      .where('status', '!=', 'done')
      .orderBy('status')
      .orderBy('dueDate', 'asc')
      .limit(15)
      .get();

    return snap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
  } catch (error) {
    logger.warn(`[getPendingTasks] Error for user ${uid}:`, error);
    return [];
  }
}

/**
 * Get low stock inventory items (quantity <= threshold)
 */
async function getLowStockItems(uid: string, threshold: number = 5): Promise<any[]> {
  try {
    const snap = await db
      .collection('users')
      .doc(uid)
      .collection('inventory')
      .where('quantity', '<=', threshold)
      .orderBy('quantity', 'asc')
      .limit(10)
      .get();

    return snap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
  } catch (error) {
    logger.warn(`[getLowStockItems] Error for user ${uid}:`, error);
    return [];
  }
}

/**
 * Get CRM clients/deals needing followup
 */
async function getCRMFollowups(uid: string): Promise<any[]> {
  try {
    // Get clients needing followup
    const clientsSnap = await db
      .collection('users')
      .doc(uid)
      .collection('crm')
      .where('needsFollowup', '==', true)
      .orderBy('lastActivityAt', 'asc')
      .limit(10)
      .get();

    const clients = clientsSnap.docs.map((doc) => ({
      id: doc.id,
      type: 'client',
      ...doc.data(),
    }));

    // Get deals that are close to closing (optional)
    const dealsSnap = await db
      .collection('users')
      .doc(uid)
      .collection('deals')
      .where('status', '==', 'qualified')
      .orderBy('expectedCloseDate', 'asc')
      .limit(5)
      .get();

    const deals = dealsSnap.docs.map((doc) => ({
      id: doc.id,
      type: 'deal',
      ...doc.data(),
    }));

    return [...clients, ...deals];
  } catch (error) {
    logger.warn(`[getCRMFollowups] Error for user ${uid}:`, error);
    return [];
  }
}

/**
 * Get total counts for digest summary (for email subject/preview)
 */
export function getDigestCounts(summary: DigestSummary): {
  total: number;
  breakdown: Record<string, number>;
} {
  const breakdown = {
    invoices: summary.invoices?.length ?? 0,
    expenses: summary.expenses?.length ?? 0,
    tasks: summary.tasks?.length ?? 0,
    stock: summary.stock?.length ?? 0,
    crm: summary.crm?.length ?? 0,
  };

  const total = Object.values(breakdown).reduce((a, b) => a + b, 0);

  return { total, breakdown };
}

/**
 * Format digest summary for email template
 */
export function formatDigestForEmail(
  summary: DigestSummary,
  frequency: 'daily' | 'weekly'
): string {
  const counts = getDigestCounts(summary);
  
  let html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <h2>Your ${frequency === 'daily' ? 'Daily' : 'Weekly'} Business Digest</h2>
      <p>You have <strong>${counts.total}</strong> items to review:</p>
      
      <div style="background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 20px 0;">
  `;

  if (summary.invoices && summary.invoices.length > 0) {
    html += `<p><strong>📄 Invoices (${summary.invoices.length})</strong><br/>`;
    html += summary.invoices.slice(0, 5).map((inv) => 
      `- ${inv.invoiceNumber}: $${inv.amount} (due ${inv.dueDate || 'TBD'})`
    ).join('<br/>');
    if (summary.invoices.length > 5) html += `<br/>+${summary.invoices.length - 5} more`;
    html += `</p>`;
  }

  if (summary.expenses && summary.expenses.length > 0) {
    html += `<p><strong>💰 Expenses (${summary.expenses.length})</strong><br/>`;
    html += summary.expenses.slice(0, 5).map((exp) => 
      `- ${exp.category}: $${exp.amount}`
    ).join('<br/>');
    if (summary.expenses.length > 5) html += `<br/>+${summary.expenses.length - 5} more`;
    html += `</p>`;
  }

  if (summary.tasks && summary.tasks.length > 0) {
    html += `<p><strong>✓ Tasks (${summary.tasks.length})</strong><br/>`;
    html += summary.tasks.slice(0, 5).map((task) => 
      `- ${task.title} (${task.status})`
    ).join('<br/>');
    if (summary.tasks.length > 5) html += `<br/>+${summary.tasks.length - 5} more`;
    html += `</p>`;
  }

  if (summary.stock && summary.stock.length > 0) {
    html += `<p><strong>📦 Low Stock (${summary.stock.length})</strong><br/>`;
    html += summary.stock.slice(0, 5).map((item) => 
      `- ${item.name}: ${item.quantity} units`
    ).join('<br/>');
    if (summary.stock.length > 5) html += `<br/>+${summary.stock.length - 5} more`;
    html += `</p>`;
  }

  if (summary.crm && summary.crm.length > 0) {
    html += `<p><strong>👥 CRM Followups (${summary.crm.length})</strong><br/>`;
    html += summary.crm.slice(0, 5).map((item) => 
      `- ${item.name || item.dealName} (${item.type})`
    ).join('<br/>');
    if (summary.crm.length > 5) html += `<br/>+${summary.crm.length - 5} more`;
    html += `</p>`;
  }

  html += `
      </div>
      
      <p style="text-align: center; margin-top: 30px;">
        <a href="https://aurasphere.app/dashboard" 
           style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px;">
          View Full Dashboard
        </a>
      </p>
      
      <p style="font-size: 12px; color: #999; text-align: center; margin-top: 30px;">
        You're receiving this because you have email digests enabled. 
        <a href="https://aurasphere.app/settings/digest" style="color: #007bff;">Manage preferences</a>
      </p>
    </div>
  `;

  return html;
}
