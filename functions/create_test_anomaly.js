const admin = require('firebase-admin');

// Initialize with emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';

admin.initializeApp({
  projectId: 'aurasphere-pro',
});

const db = admin.firestore();

async function createTestAnomaly() {
  try {
    const docRef = await db.collection('anomalies').add({
      ownerUid: 'test-user-001',
      entityType: 'invoice',
      entityId: 'INV-TEST-1',
      severity: 'high',
      detectedAt: admin.firestore.Timestamp.now(),
    });

    console.log('✅ Test anomaly created successfully!');
    console.log('Document ID:', docRef.id);
    console.log('Path: anomalies/' + docRef.id);
    
    // Verify it was created
    const doc = await docRef.get();
    console.log('\nDocument data:');
    console.log(JSON.stringify(doc.data(), null, 2));
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating anomaly:', error.message);
    process.exit(1);
  }
}

createTestAnomaly();
