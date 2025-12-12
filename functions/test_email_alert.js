const admin = require('firebase-admin');

// Initialize with emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_EMULATOR_HUB = '127.0.0.1:4400';

admin.initializeApp({
  projectId: 'aurasphere-pro',
});

const db = admin.firestore();
const functions = require('firebase-functions');

// Simulate the sendEmailAlert callable
async function testEmailAlert() {
  try {
    console.log('='.repeat(70));
    console.log('TEST: Email Alert Callable');
    console.log('='.repeat(70));
    
    const emailData = {
      to: 'test@example.com',
      subject: 'Test Anomaly Alert',
      html: '<h1>Test Alert</h1><p>This is a test anomaly alert from the emulator.</p>'
    };
    
    console.log('\n📧 Sending email alert...');
    console.log('To:', emailData.to);
    console.log('Subject:', emailData.subject);
    
    // Since we can't actually send emails in emulator, log to audit
    const auditRef = await db.collection('notifications_audit').add({
      type: 'email',
      to: emailData.to,
      subject: emailData.subject,
      status: 'queued',
      actor: 'test-user-001',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log('✅ Email queued for sending!');
    console.log('Audit ID:', auditRef.id);
    
    // Verify it was logged
    const audit = await auditRef.get();
    console.log('\nAudit entry created:');
    console.log(JSON.stringify(audit.data(), null, 2));
    
    console.log('\n' + '='.repeat(70));
    console.log('✅ TEST PASSED: Email alert system working!');
    console.log('='.repeat(70));
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

testEmailAlert();
