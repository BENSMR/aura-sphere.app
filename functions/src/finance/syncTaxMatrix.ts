import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

interface TaxMatrixEntry {
  country: string;
  region?: string;
  vat?: {
    standard: number;
    reduced?: number[];
    isEu?: boolean;
  } | null;
  sales_tax?: {
    states?: boolean;
  } | null;
}

/**
 * Seeds the tax matrix collection with common VAT/sales tax rules
 * Creates documents in config/tax_matrix/{countryCode}
 *
 * HTTP callable endpoint - can be triggered once or periodically
 * Returns: Success message with number of countries seeded
 */
export const seedTaxMatrix = functions.https.onRequest(
  async (req: functions.https.Request, res: functions.Response): Promise<void> => {
    try {
      // Verify authorization (optional: restrict to admin)
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).send('Unauthorized: Bearer token required');
        return;
      }

      // Common VAT matrix for major markets
      const taxMatrix: Record<string, TaxMatrixEntry> = {
        FR: {
          country: 'FR',
          region: 'EU',
          vat: {
            standard: 0.20,
            reduced: [0.1, 0.055],
            isEu: true,
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
          },
          sales_tax: null,
        },
        GB: {
          country: 'GB',
          region: 'EU',
          vat: {
            standard: 0.2,
            reduced: [0.05],
            isEu: true,
          },
          sales_tax: null,
        },
        ES: {
          country: 'ES',
          region: 'EU',
          vat: {
            standard: 0.21,
            reduced: [0.1],
            isEu: true,
          },
          sales_tax: null,
        },
        IT: {
          country: 'IT',
          region: 'EU',
          vat: {
            standard: 0.22,
            reduced: [0.1, 0.05],
            isEu: true,
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
          },
          sales_tax: null,
        },
        AT: {
          country: 'AT',
          region: 'EU',
          vat: {
            standard: 0.2,
            reduced: [0.1],
            isEu: true,
          },
          sales_tax: null,
        },
        PL: {
          country: 'PL',
          region: 'EU',
          vat: {
            standard: 0.23,
            reduced: [0.8, 0.5],
            isEu: true,
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
          },
          sales_tax: null,
        },
        US: {
          country: 'US',
          region: 'Americas',
          vat: null,
          sales_tax: {
            states: true,
          },
        },
        CA: {
          country: 'CA',
          region: 'Americas',
          vat: {
            standard: 0.05,
            reduced: [0],
            isEu: false,
          },
          sales_tax: null,
        },
        AU: {
          country: 'AU',
          region: 'APAC',
          vat: {
            standard: 0.1,
            reduced: [0],
            isEu: false,
          },
          sales_tax: null,
        },
        JP: {
          country: 'JP',
          region: 'APAC',
          vat: {
            standard: 0.1,
            reduced: [0.08],
            isEu: false,
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
          },
          sales_tax: null,
        },
      };

      const batch = admin.firestore().batch();
      let count = 0;

      // Write each country's tax rules to its own document
      for (const [key, data] of Object.entries(taxMatrix)) {
        const docRef = admin
          .firestore()
          .doc(`config/tax_matrix/${key}`);
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

      console.log(`✅ Tax matrix seeded with ${count} countries`);
      res.status(200).json({
        success: true,
        message: `Tax matrix seeded with ${count} countries`,
        countries: Object.keys(taxMatrix),
      });
    } catch (error) {
      console.error('❌ seedTaxMatrix error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to seed tax matrix',
        details: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }
);
