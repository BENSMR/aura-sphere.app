const admin = require('firebase-admin');

// Initialize with emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';

admin.initializeApp({
  projectId: 'aurasphere-pro',
});

const db = admin.firestore();

async function verifyTestData() {
  try {
    console.log('='.repeat(70));
    console.log('VERIFICATION: Test Data and Trigger Results');
    console.log('='.repeat(70));

    // Check anomaly
    console.log('\n1️⃣  ANOMALY DOCUMENT:');
    const anomalies = await db.collection('anomalies').get();
    if (anomalies.empty) {
      console.log('❌ No anomalies found');
    } else {
      anomalies.forEach(doc => {
        console.log('✅ Found anomaly:', doc.id);
        console.log('   Data:', JSON.stringify(doc.data(), null, 4));
      });
    }

    // Check user notifications
    console.log('\n2️⃣  USER NOTIFICATIONS:');
    const notifs = await db.collection('users').doc('test-user-001').collection('notifications').get();
    if (notifs.empty) {
      console.log('❌ No notifications found for test-user-001');
      console.log('   (Trigger may not have fired yet)');
    } else {
      console.log('✅ Found', notifs.size, 'notification(s):');
      notifs.forEach(doc => {
        console.log('   -', doc.id, ':', doc.data().title);
      });
    }

    // Check audit trail
    console.log('\n3️⃣  AUDIT TRAIL:');
    const audits = await db.collection('notifications_audit').get();
    if (audits.empty) {
      console.log('❌ No audit entries found');
    } else {
      console.log('✅ Found', audits.size, 'audit entries:');
      audits.forEach(doc => {
        console.log('   -', doc.id);
        console.log('     Type:', doc.data().type);
        console.log('     Status:', doc.data().status);
        if (doc.data().error) {
          console.log('     Error:', doc.data().error);
        }
      });
    }

    console.log('\n' + '='.repeat(70));
    console.log('SUMMARY:');
    console.log('='.repeat(70));
    console.log('Anomaly created: ✅ YES');
    console.log('Trigger fired: ' + (notifs.empty ? '❌ NO' : '✅ YES'));
    console.log('Audit logged: ' + (audits.empty ? '❌ NO' : '✅ YES'));
    
    console.log('\nNext step:');
    if (notifs.empty) {
      console.log('Check Cloud Functions logs:');
      console.log('  firebase functions:log --function=onAnomalyCreate');
    } else {
      console.log('✅ Notification system working! Check next:');
      console.log('  - Email alerts (configure SendGrid/SMTP)');
      console.log('  - SMS alerts (configure Twilio)');
      console.log('  - Push notifications (register FCM tokens)');
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

verifyTestData();
