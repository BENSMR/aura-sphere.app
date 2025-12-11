/**
 * Seed initial FX rates into Firestore
 * 
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json node seed-fx-rates.js
 * 
 * Or if service account is already authenticated:
 *   node seed-fx-rates.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  try {
    admin.initializeApp();
    console.log('✅ Firebase Admin initialized');
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin:', error.message);
    process.exit(1);
  }
}

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
    ZAR: 17.8,
  },
};

async function seedFxRates() {
  try {
    const docRef = admin.firestore().doc('config/fx_rates');
    
    console.log('📝 Seeding FX rates to Firestore...');
    await docRef.set(fxRates, { merge: true });
    
    console.log('✅ FX rates seeded successfully!');
    console.log(`   Base currency: ${fxRates.base}`);
    console.log(`   Currencies: ${Object.keys(fxRates.rates).length}`);
    console.log(`   Provider: ${fxRates.provider}`);
    
    // Verify it was written
    const doc = await docRef.get();
    if (doc.exists) {
      console.log('✔️  Verification: Document exists in Firestore');
      console.log(`   Document size: ${JSON.stringify(doc.data()).length} bytes`);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding FX rates:', error.message);
    process.exit(1);
  }
}

seedFxRates();
