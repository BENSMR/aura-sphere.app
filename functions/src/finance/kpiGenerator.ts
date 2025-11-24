import { CallableContext } from 'firebase-functions/v1/https';

export const kpiGenerator = async (data: any, context: CallableContext) => {
  if (!context.auth) {
    throw new Error('Unauthorized');
  }

  const { userId } = data;

  // TODO: Aggregate data from Firestore
  return {
    revenue: 0,
    expenses: 0,
    profit: 0,
  };
};
