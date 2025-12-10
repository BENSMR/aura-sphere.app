#!/usr/bin/env node

/**
 * Set admin custom claim on a user
 * Usage: node scripts/set-admin.js <uid> [--revoke]
 * 
 * Examples:
 *   node scripts/set-admin.js user123
 *   node scripts/set-admin.js user123 --revoke
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
  path.join(__dirname, '../serviceAccountKey.json');

if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(require(serviceAccountPath)),
    });
  } catch (err) {
    console.error('❌ Failed to initialize Firebase Admin SDK');
    console.error(`   Make sure GOOGLE_APPLICATION_CREDENTIALS is set or serviceAccountKey.json exists`);
    process.exit(1);
  }
}

const args = process.argv.slice(2);
const uid = args[0];
const revoke = args.includes('--revoke');

if (!uid) {
  console.error('Usage: node scripts/set-admin.js <uid> [--revoke]');
  process.exit(1);
}

async function main() {
  try {
    const auth = admin.auth();
    
    if (revoke) {
      // Revoke admin claim
      await auth.setCustomUserClaims(uid, { admin: false });
      console.log(`✅ Revoked admin claim from user ${uid}`);
    } else {
      // Grant admin claim
      await auth.setCustomUserClaims(uid, { admin: true });
      console.log(`✅ Granted admin claim to user ${uid}`);
    }

    // Verify
    const user = await auth.getUser(uid);
    const isAdmin = user.customClaims?.admin === true;
    console.log(`   Current admin status: ${isAdmin ? '✓ Admin' : '✗ Not admin'}`);
  } catch (err) {
    console.error(`❌ Error: ${err.message}`);
    process.exit(1);
  }
}

main();
