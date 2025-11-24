import { CallableContext } from 'firebase-functions/v1/https';

export const taxCalculator = async (data: any, context: CallableContext) => {
  if (!context.auth) {
    throw new Error('Unauthorized');
  }

  const { amount, taxRate } = data;

  return {
    tax: amount * taxRate,
    total: amount * (1 + taxRate),
  };
};
