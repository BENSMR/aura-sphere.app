import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

interface VatConfig {
  standard?: number;
  reduced?: number[];
  threshold?: number | null;
  has_vat?: boolean;
  isEu?: boolean;
}

interface TaxRule {
  country: string;
  region?: string;
  vat?: VatConfig;
  sales_tax?: number | null;
}

interface TaxCalculationRequest {
  country: string;
  amount: number;
  taxType?: 'vat' | 'sales';
  vatRate?: number;
  direction?: 'sale' | 'purchase';
  customerIsBusiness?: boolean;
  itemCategory?: string;
}

interface TaxCalculationResponse {
  success: boolean;
  tax: number;
  total: number;
  rate: number;
  note?: string;
}

/**
 * Tax matrix design:
 * Firestore: collection 'config/tax_matrix' -> doc per country code (ISO2/ISO3)
 * Example doc:
 * {
 *   country: "FR",
 *   region: "EU",
 *   vat: {
 *     standard: 0.20,
 *     reduced: [0.10, 0.055],
 *     threshold: null,
 *     has_vat: true,
 *     isEu: true
 *   },
 *   sales_tax: null
 * }
 */

/**
 * Utility: fetch tax rule for country from Firestore
 */
async function getTaxRule(countryCode: string): Promise<TaxRule | null> {
  try {
    const doc = await admin
      .firestore()
      .doc(`config/tax_matrix/${countryCode}`)
      .get();

    if (!doc.exists) {
      console.warn(`No tax rule found for country: ${countryCode}`);
      return null;
    }

    return doc.data() as TaxRule;
  } catch (error) {
    console.error(`Error fetching tax rule for ${countryCode}:`, error);
    return null;
  }
}

/**
 * Calculates tax (VAT or sales tax) based on country rules
 *
 * Request data:
 * {
 *   country: 'FR',                    // ISO country code
 *   amount: 100.0,                    // Base amount (before tax)
 *   taxType?: 'vat'|'sales',          // Preference (default: 'vat')
 *   vatRate?: 0.20,                   // Optional manual override
 *   direction?: 'sale'|'purchase',    // Context (default: 'sale')
 *   customerIsBusiness?: boolean,     // For reverse charge rules
 *   itemCategory?: string             // For reduced rates (optional)
 * }
 *
 * Response:
 * {
 *   success: true,
 *   tax: 20.00,          // Calculated tax amount
 *   total: 120.00,       // Amount + tax
 *   rate: 0.20,          // Applied rate
 *   note?: 'string'      // Optional explanation
 * }
 */
export const calculateTax = functions.https.onCall(
  async (data: TaxCalculationRequest, context): Promise<TaxCalculationResponse> => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required'
      );
    }

    const {
      country,
      amount,
      taxType = 'vat',
      vatRate,
      direction = 'sale',
      customerIsBusiness = false,
      itemCategory,
    } = data;

    // Validate required parameters
    if (!country || typeof amount !== 'number' || amount < 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Required: country (string), amount (positive number)'
      );
    }

    // If manual VAT rate provided, use it directly
    if (vatRate != null && typeof vatRate === 'number') {
      const tax = Number((amount * vatRate).toFixed(2));
      return {
        success: true,
        tax,
        total: Number((amount + tax).toFixed(2)),
        rate: vatRate,
        note: 'Manual rate override',
      };
    }

    // Fetch tax rule for country
    const rule = await getTaxRule(country.toUpperCase());

    // No rule found: zero tax
    if (!rule) {
      return {
        success: true,
        tax: 0,
        total: Number(amount.toFixed(2)),
        rate: 0,
        note: `No tax rule available for country: ${country}`,
      };
    }

    // Handle VAT
    if (rule.vat && rule.vat.has_vat && taxType === 'vat') {
      let rate = rule.vat.standard ?? 0;

      // EU B2B reverse charge: zero-rate invoice to business customer within EU
      const isEuRule = rule.region === 'EU' || rule.vat.isEu;
      if (customerIsBusiness && isEuRule && direction === 'sale') {
        return {
          success: true,
          tax: 0,
          total: Number(amount.toFixed(2)),
          rate: 0,
          note: 'Reverse charge applied (EU B2B)',
        };
      }

      // Reduced rate handling (simplified: use standard for now)
      // In production, match itemCategory to reduced rates
      if (
        itemCategory &&
        rule.vat.reduced &&
        rule.vat.reduced.length > 0
      ) {
        // Example: use first reduced rate (real impl would match category)
        rate = rule.vat.reduced[0];
      }

      const tax = Number((amount * rate).toFixed(2));
      return {
        success: true,
        tax,
        total: Number((amount + tax).toFixed(2)),
        rate,
      };
    }

    // Handle sales tax (US, etc.)
    if (rule.sales_tax && taxType === 'sales') {
      const rate = rule.sales_tax;
      const tax = Number((amount * rate).toFixed(2));
      return {
        success: true,
        tax,
        total: Number((amount + tax).toFixed(2)),
        rate,
      };
    }

    // Fallback: no applicable tax
    return {
      success: true,
      tax: 0,
      total: Number(amount.toFixed(2)),
      rate: 0,
      note: 'No applicable tax rule',
    };
  }
);
