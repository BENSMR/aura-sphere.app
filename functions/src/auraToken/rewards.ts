import { CallableContext } from 'firebase-functions/v1/https';

export const rewards = {
  // Reward users for various actions
  onExpenseAdded: 10,
  onInvoiceCreated: 20,
  onProjectCompleted: 50,
  onReferral: 100,
};
