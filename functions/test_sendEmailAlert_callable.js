/**
 * Test the sendEmailAlert Cloud Function
 * 
 * Usage:
 *   - With emulator: FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node test_sendEmailAlert_callable.js
 *   - Production: node test_sendEmailAlert_callable.js (with valid credentials)
 */

const admin = require('firebase-admin');
const fetch = require('node-fetch');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * METHOD 1: Direct HTTP POST to Cloud Function (LOCAL EMULATOR)
 * Best for testing locally with emulator running
 */
async function testViaHTTP_Emulator() {
  console.log('\n📧 METHOD 1: Testing via HTTP POST (Emulator)');
  console.log('═══════════════════════════════════════════════════\n');

  const functionUrl = 'http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert';
  
  const payload = {
    data: {
      to: 'test@example.com',
      subject: 'Test Email Alert',
      html: '<h1>Test Email</h1><p>This is a <b>test email</b> from AuraSphere Pro.</p>',
      userId: 'test-user-123',
      type: 'anomaly',
      severity: 'high'
    }
  };

  try {
    console.log('Sending request to:', functionUrl);
    console.log('Payload:', JSON.stringify(payload, null, 2));

    const response = await fetch(functionUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload)
    });

    const result = await response.json();
    console.log('\n✅ Response Status:', response.status);
    console.log('✅ Response Body:', JSON.stringify(result, null, 2));

    if (response.ok) {
      console.log('\n✅ EMAIL CALLABLE TEST PASSED');
    } else {
      console.log('\n❌ EMAIL CALLABLE TEST FAILED');
    }
  } catch (error) {
    console.error('\n❌ Error testing email callable:', error.message);
  }
}

/**
 * METHOD 2: Direct HTTP POST to Cloud Function (PRODUCTION)
 * For testing against live Firebase project
 */
async function testViaHTTP_Production() {
  console.log('\n📧 METHOD 2: Testing via HTTP POST (Production)');
  console.log('═══════════════════════════════════════════════════\n');

  const functionUrl = 'https://us-central1-aurasphere-pro.cloudfunctions.net/sendEmailAlert';
  
  const payload = {
    data: {
      to: 'your-email@domain.com',
      subject: 'Test Email Alert from Prod',
      html: '<h1>Production Test</h1><p>This email was sent from production Firebase.</p>',
      userId: 'test-user-456',
      type: 'invoice',
      severity: 'medium'
    }
  };

  try {
    console.log('Sending request to production function...');
    console.log('URL:', functionUrl);

    const response = await fetch(functionUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload)
    });

    const result = await response.json();
    console.log('\n✅ Response Status:', response.status);
    console.log('✅ Response Body:', JSON.stringify(result, null, 2));

    if (response.ok) {
      console.log('\n✅ PRODUCTION EMAIL TEST PASSED');
    }
  } catch (error) {
    console.error('\n❌ Error testing production:', error.message);
  }
}

/**
 * METHOD 3: Firebase Admin SDK (Server-side)
 * For testing from another Cloud Function or backend service
 */
async function testViaAdminSDK() {
  console.log('\n📧 METHOD 3: Testing via Firebase Admin SDK');
  console.log('═══════════════════════════════════════════════════\n');

  try {
    const functions = admin.functions('us-central1');
    const sendEmailAlert = functions.httpsCallable('sendEmailAlert');

    const payload = {
      to: 'admin@example.com',
      subject: 'Test via Admin SDK',
      html: '<h1>Admin SDK Test</h1><p>Testing email via Firebase Admin SDK.</p>',
      userId: 'test-user-789',
      type: 'system',
      severity: 'low'
    };

    console.log('Calling sendEmailAlert via Admin SDK...');
    console.log('Payload:', JSON.stringify(payload, null, 2));

    const result = await sendEmailAlert(payload);
    
    console.log('\n✅ Response:', JSON.stringify(result.data, null, 2));
    console.log('\n✅ ADMIN SDK EMAIL TEST PASSED');
  } catch (error) {
    console.error('\n❌ Error via Admin SDK:', error.message);
    console.error('Details:', error);
  }
}

/**
 * METHOD 4: Test with different email configurations
 * Tests SendGrid, SMTP, and fallback scenarios
 */
async function testDifferentConfigs() {
  console.log('\n📧 METHOD 4: Testing Different Email Configurations');
  console.log('═══════════════════════════════════════════════════\n');

  const configs = [
    {
      name: 'SendGrid Configuration',
      payload: {
        data: {
          to: 'sendgrid-test@example.com',
          subject: 'SendGrid Test Email',
          html: '<h1>SendGrid Test</h1><p>Sent via SendGrid.</p>',
          provider: 'sendgrid'
        }
      }
    },
    {
      name: 'SMTP Configuration',
      payload: {
        data: {
          to: 'smtp-test@example.com',
          subject: 'SMTP Test Email',
          html: '<h1>SMTP Test</h1><p>Sent via generic SMTP.</p>',
          provider: 'smtp'
        }
      }
    },
    {
      name: 'Multiple Recipients',
      payload: {
        data: {
          to: ['user1@example.com', 'user2@example.com'],
          subject: 'Multi-recipient Test',
          html: '<h1>Multiple Recipients</h1><p>Sent to multiple users.</p>'
        }
      }
    },
    {
      name: 'With CC and BCC',
      payload: {
        data: {
          to: 'primary@example.com',
          cc: 'cc@example.com',
          bcc: 'bcc@example.com',
          subject: 'CC and BCC Test',
          html: '<h1>CC and BCC Test</h1>'
        }
      }
    }
  ];

  const functionUrl = 'http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert';

  for (const config of configs) {
    console.log(`\nTesting: ${config.name}`);
    console.log('─────────────────────────────────────────');

    try {
      const response = await fetch(functionUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(config.payload)
      });

      const result = await response.json();
      
      if (response.ok) {
        console.log(`✅ ${config.name} - SUCCESS`);
        console.log(`   Message ID: ${result.data?.messageId || 'N/A'}`);
      } else {
        console.log(`❌ ${config.name} - FAILED`);
        console.log(`   Error: ${result.error || 'Unknown error'}`);
      }
    } catch (error) {
      console.error(`❌ ${config.name} - ERROR: ${error.message}`);
    }
  }
}

/**
 * MAIN: Run all tests
 */
async function runAllTests() {
  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║     sendEmailAlert Cloud Function - Comprehensive Tests     ║');
  console.log('╚════════════════════════════════════════════════════════════╝');

  // Check if emulator is running
  const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
  
  if (emulatorHost) {
    console.log(`\n🔥 Emulator Mode: Using ${emulatorHost}`);
    await testViaHTTP_Emulator();
  } else {
    console.log('\n☁️ Production Mode: Testing against Firebase');
    await testViaHTTP_Production();
  }

  // Uncomment to test other methods:
  // await testViaAdminSDK();
  // await testDifferentConfigs();

  console.log('\n✅ Test suite completed!\n');
}

// Run tests
runAllTests().catch(console.error);
