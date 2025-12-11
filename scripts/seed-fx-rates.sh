#!/bin/bash
# Seed initial FX rates into Firestore using curl to trigger a callable function
# This requires the seedTaxMatrix function to be running

PROJECT_ID="aurasphere-pro"
REGION="us-central1"

# First, let's use Firebase CLI to set the FX rates document directly
# by creating a temporary Cloud Function to seed it

cat > /tmp/seed_fx.js << 'EOF'
const admin = require('firebase-admin');
admin.initializeApp();

async function seed() {
  const fxRates = {
    base: 'USD',
    provider: 'exchangerate.host',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    fetchedAt: new Date().toISOString(),
    rates: {
      AED: 3.6725,
      ARS: 1050.0,
      AUD: 1.53,
      BGN: 1.82,
      BRL: 5.12,
      CAD: 1.38,
      CHF: 0.88,
      CNY: 7.25,
      CZK: 23.5,
      DKK: 6.85,
      EUR: 0.92,
      GBP: 0.79,
      HKD: 7.78,
      HRK: 6.9,
      HUF: 380.0,
      IDR: 16500.0,
      ILS: 3.5,
      INR: 83.5,
      ISK: 137.0,
      JPY: 149.5,
      KRW: 1285.0,
      MXN: 20.35,
      MYR: 4.45,
      NOK: 10.65,
      NZD: 1.68,
      PHP: 57.0,
      PLN: 4.0,
      RON: 4.58,
      RUB: 105.0,
      SEK: 10.8,
      SGD: 1.35,
      THB: 35.5,
      TRY: 33.5,
      UAH: 41.5,
      VND: 25500.0,
      ZAR: 17.8
    }
  };

  try {
    await admin.firestore().doc('config/fx_rates').set(fxRates, { merge: true });
    console.log('✅ FX rates seeded successfully');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding FX rates:', error);
    process.exit(1);
  }
}

seed();
EOF

# Note: To run this, you would need to:
# 1. Be authenticated with Firebase
# 2. Have service account key available
# 3. Run: node /tmp/seed_fx.js

echo "Seed script created at /tmp/seed_fx.js"
echo ""
echo "To seed FX rates, run one of:"
echo "1. Via Firebase Console: https://console.firebase.google.com/project/aurasphere-pro"
echo "2. Via Node.js script: node /tmp/seed_fx.js (requires service account)"
echo "3. Via manual document creation in Console"
echo ""
echo "Document path: config/fx_rates"
echo "See firestore-seed-fx-rates.json for structure"
