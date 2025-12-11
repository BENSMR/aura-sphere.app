/**
 * Seed tax matrix into Firestore
 * 
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json node scripts/seed-tax-matrix.js
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

const taxMatrix = {
  FR: {
    country: 'FR',
    region: 'EU',
    vat: {
      standard: 0.20,
      reduced: [0.10, 0.055],
      isEu: true,
      has_vat: true,
    },
    sales_tax: null,
  },
  DE: {
    country: 'DE',
    region: 'EU',
    vat: {
      standard: 0.19,
      reduced: [0.07],
      isEu: true,
      has_vat: true,
    },
    sales_tax: null,
  },
  GB: {
    country: 'GB',
    region: 'EU',
    vat: {
      standard: 0.20,
      reduced: [0.05],
      isEu: true,
      has_vat: true,
    },
    sales_tax: null,
  },
  ES: {
    country: 'ES',
    region: 'EU',
    vat: {
      standard: 0.21,
      reduced: [0.10],
      isEu: true,
      has_vat: true,
    },
    sales_tax: null,
  },
  IT: {
    country: 'IT',
    region: 'EU',
    vat: {
      standard: 0.22,
      reduced: [0.10, 0.05],
      isEu: true,
      has_vat: true,
    },
    sales_tax: null,
  },
  NL: {
    country: 'NL',
    region: 'EU',
    vat: {
      standard: 0.21,
      reduced: [0.09],
      isEu: true,
      has_vat: true,
    },
    sales_tax: null,
  },
  BE: {
    country: 'BE',
    region: 'EU',
    vat: {
      standard: 0.21,
      reduced: [0.12, 0.06],
      isEu: true,
      has_vat: true,
    },
    sales_tax: null,
  },
  AT: {
    country: 'AT',
    region: 'EU',
    vat: {
      standard: 0.20,
      reduced: [0.10],
      isEu: true,
      has_vat: true,
    },
    sales_tax: null,
  },
  PL: {
    country: 'PL',
    region: 'EU',
    vat: {
      standard: 0.23,
      reduced: [0.08, 0.05],
      isEu: true,
      has_vat: true,
    },
    sales_tax: null,
  },
  SE: {
    country: 'SE',
    region: 'EU',
    vat: {
      standard: 0.25,
      reduced: [0.12, 0.06],
      isEu: true,
      has_vat: true,
    },
    sales_tax: null,
  },
  US: {
    country: 'US',
    region: 'Americas',
    vat: null,
    sales_tax: {
      states: true,
      note: 'Varies by state (5%-10%)',
    },
  },
  CA: {
    country: 'CA',
    region: 'Americas',
    vat: {
      standard: 0.05,
      reduced: [0],
      isEu: false,
      has_vat: true,
    },
    sales_tax: null,
  },
  AU: {
    country: 'AU',
    region: 'APAC',
    vat: {
      standard: 0.10,
      reduced: [0],
      isEu: false,
      has_vat: true,
    },
    sales_tax: null,
  },
  JP: {
    country: 'JP',
    region: 'APAC',
    vat: {
      standard: 0.10,
      reduced: [0.08],
      isEu: false,
      has_vat: true,
    },
    sales_tax: null,
  },
  SG: {
    country: 'SG',
    region: 'APAC',
    vat: {
      standard: 0.08,
      reduced: [0],
      isEu: false,
      has_vat: true,
    },
    sales_tax: null,
  },
  IN: {
    country: 'IN',
    region: 'APAC',
    vat: {
      standard: 0.18,
      reduced: [0.12, 0.05],
      isEu: false,
      has_vat: true,
    },
    sales_tax: null,
  },
};

async function seedTaxMatrix() {
  try {
    const batch = admin.firestore().batch();
    let count = 0;

    console.log('📝 Seeding tax matrix to Firestore...');

    // Write each country's tax rules
    for (const [key, data] of Object.entries(taxMatrix)) {
      const docRef = admin.firestore().doc(`config/tax_matrix/${key}`);
      batch.set(
        docRef,
        {
          ...data,
          seedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      count++;
    }

    await batch.commit();

    console.log('✅ Tax matrix seeded successfully!');
    console.log(`   Countries: ${count}`);
    console.log(`   EU countries: 10`);
    console.log(`   Americas: 2`);
    console.log(`   APAC: 4`);

    // Verify a sample
    const sampleDoc = await admin
      .firestore()
      .doc('config/tax_matrix/FR')
      .get();
    if (sampleDoc.exists) {
      const data = sampleDoc.data();
      console.log(
        `\n✔️  Verification: FR VAT standard rate = ${data.vat.standard * 100}%`
      );
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding tax matrix:', error.message);
    process.exit(1);
  }
}

seedTaxMatrix();
