import { DocumentSnapshot } from 'firebase-functions/v1/firestore';

export const projectsFunctions = {
  onCreate: async (snapshot: DocumentSnapshot) => {
    const project = snapshot.data();
    console.log('New project created:', project);

    // TODO: Notify team members, create tasks, etc.
    return null;
  },
};
