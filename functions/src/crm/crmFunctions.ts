import { DocumentSnapshot } from 'firebase-functions/v1/firestore';

export const crmFunctions = {
  onCreate: async (snapshot: DocumentSnapshot) => {
    const contact = snapshot.data();
    console.log('New CRM contact created:', contact);

    // TODO: Send welcome email, add to mailing list, etc.
    return null;
  },
};
