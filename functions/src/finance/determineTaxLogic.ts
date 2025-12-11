import * as admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();

interface TaxRule {
  vat?: {
    standard: number;
    reduced?: number[];
    isEu?: boolean;
  };
  sales_tax?: {
    average?: number;
    [key: string]: any;
  };
  region?: string;
  [key: string]: any;
}

interface TaxBreakdown {
  type: 'vat' | 'sales_tax' | 'none';
  rate: number;
  standard?: number;
  reduced?: number[];
  note?: string;
}

/**
 * Shared tax determination logic (extracted for reuse)
 * This is called by both determineTaxAndCurrency (callable) and processTaxQueue (scheduled)
 */
async function getTaxRule(countryCode: string | null): Promise<TaxRule | null> {
  if (!countryCode) return null;
  const doc = await admin
    .firestore()
    .doc(`config/tax_matrix/${countryCode.toUpperCase()}`)
    .get();
  return doc.exists ? (doc.data() as TaxRule) : null;
}

async function getCompanySettings(
  uid: string,
  companyId?: string | null,
): Promise<Record<string, any> | null> {
  if (!companyId) {
    const snap = await admin
      .firestore()
      .collection('users')
      .doc(uid)
      .collection('companies')
      .limit(1)
      .get();
    if (!snap.empty) return (snap.docs[0].data() as Record<string, any>) || null;
    return null;
  }
  const doc = await admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('companies')
    .doc(companyId)
    .get();
  return doc.exists ? (doc.data() as Record<string, any>) : null;
}

async function getContact(
  uid: string,
  contactId?: string | null,
): Promise<Record<string, any> | null> {
  if (!contactId) return null;
  const doc = await admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('contacts')
    .doc(contactId)
    .get();
  return doc.exists ? (doc.data() as Record<string, any>) : null;
}

async function getFxRates(): Promise<Record<string, any> | null> {
  try {
    const doc = await admin.firestore().doc('config/fx_rates').get();
    return doc.exists ? (doc.data() as Record<string, any>) : null;
  } catch (err) {
    console.warn('FX rates fetch error (ignored):', err);
    return null;
  }
}

/**
 * Core tax determination logic (reusable)
 * Called from determineTaxAndCurrency callable and processTaxQueue scheduled function
 */
export async function determineTaxLogic(
  payload: {
    amount?: number;
    fromCurrency?: string | null;
    companyId?: string | null;
    contactId?: string | null;
    country?: string | null;
    direction?: 'sale' | 'purchase';
    customerIsBusiness?: boolean;
  },
  uid: string,
): Promise<{
  success: boolean;
  country: string | null;
  currency: string | null;
  taxRate: number;
  taxBreakdown: TaxBreakdown | null;
  taxAmount: number;
  total: number;
  sellerCountry: string | null;
  buyerCountry: string | null;
  conversionHint?: {
    toCurrency: string;
    converted: number;
    rate: number;
  };
  note: string | null;
}> {
  const {
    amount = 0,
    fromCurrency = null,
    companyId = null,
    contactId = null,
    country: countryOverride = null,
    direction = 'sale',
    customerIsBusiness = false,
  } = payload;

  try {
    // 1) Fetch company settings (seller)
    const company = await getCompanySettings(uid, companyId);
    const sellerCountry = company?.country ? company.country.toUpperCase() : null;
    const sellerDefaultCurrency = company?.defaultCurrency
      ? company.defaultCurrency.toUpperCase()
      : company?.currency
        ? company.currency.toUpperCase()
        : 'USD';

    // 2) Fetch contact (buyer)
    const contact = await getContact(uid, contactId);
    const buyerCountry = contact?.country ? contact.country.toUpperCase() : null;
    const buyerCurrency = contact?.currency ? contact.currency.toUpperCase() : null;
    const buyerIsBusiness = contact?.isBusiness ?? customerIsBusiness;

    // 3) Determine which country's tax rules to apply
    let country: string | null = countryOverride ? countryOverride.toUpperCase() : null;
    if (!country) {
      if (direction === 'sale') {
        country = buyerCountry || sellerCountry;
      } else {
        country = sellerCountry || buyerCountry;
      }
    }

    // 4) Select currency
    let currency: string | null = fromCurrency
      ? fromCurrency.toUpperCase()
      : buyerCurrency ?? sellerDefaultCurrency;

    // 5) Fetch tax rule
    const taxRule = await getTaxRule(country);

    // 6) Determine tax rate and breakdown
    let taxRate = 0;
    let taxBreakdown: TaxBreakdown | null = null;
    let note: string | null = null;

    if (!taxRule) {
      taxRate = 0;
      note = 'No tax rule found for country; defaulting to 0%';
      taxBreakdown = { type: 'none', rate: 0 };
    } else if (taxRule.vat && taxRule.vat.standard != null) {
      const isEU = taxRule.vat.isEu ?? taxRule.region === 'EU';

      // EU B2B reverse charge
      if (
        isEU &&
        buyerIsBusiness &&
        direction === 'sale' &&
        sellerCountry &&
        buyerCountry &&
        sellerCountry !== '' &&
        buyerCountry !== ''
      ) {
        const buyerRule = await getTaxRule(buyerCountry);
        if (buyerRule && (buyerRule.vat?.isEu ?? false)) {
          taxRate = 0;
          note = 'EU B2B reverse charge applied';
          taxBreakdown = {
            type: 'vat',
            rate: 0,
            standard: taxRule.vat.standard,
            reduced: taxRule.vat.reduced ?? [],
          };
        } else {
          taxRate = taxRule.vat.standard;
          taxBreakdown = {
            type: 'vat',
            rate: taxRate,
            standard: taxRule.vat.standard,
            reduced: taxRule.vat.reduced ?? [],
          };
        }
      } else {
        taxRate = taxRule.vat.standard;
        taxBreakdown = {
          type: 'vat',
          rate: taxRate,
          standard: taxRule.vat.standard,
          reduced: taxRule.vat.reduced ?? [],
        };
      }
    } else if (taxRule.sales_tax) {
      taxRate = taxRule.sales_tax.average ?? 0;
      taxBreakdown = {
        type: 'sales_tax',
        rate: taxRate,
        note: 'Sales tax may vary by region/state; use manual override for accuracy.',
      };
    } else {
      taxRate = 0;
      taxBreakdown = { type: 'none', rate: 0 };
    }

    // 7) Calculate amounts
    const numericAmount = typeof amount === 'number' ? amount : Number(amount || 0);
    const taxAmount = Number((numericAmount * taxRate).toFixed(2));
    const total = Number((numericAmount + taxAmount).toFixed(2));

    // 8) Optional FX conversion to seller's base currency
    let conversionHint:
      | {
          toCurrency: string;
          converted: number;
          rate: number;
        }
      | undefined = undefined;

    try {
      const fxData = await getFxRates();
      if (
        fxData &&
        currency &&
        fxData.base &&
        fxData.rates &&
        currency !== sellerDefaultCurrency
      ) {
        const baseFx = fxData.base;
        const rates = fxData.rates as Record<string, number>;

        const rateFrom = currency === baseFx ? 1 : rates[currency];
        const rateTo = sellerDefaultCurrency === baseFx ? 1 : rates[sellerDefaultCurrency];

        if (rateFrom && rateTo) {
          const baseMid = currency === baseFx ? numericAmount : numericAmount / rateFrom;
          const converted = baseMid * rateTo;

          conversionHint = {
            toCurrency: sellerDefaultCurrency,
            converted: Number(converted.toFixed(2)),
            rate: Number((rateTo / rateFrom).toFixed(6)),
          };
        }
      }
    } catch (err) {
      console.warn('FX conversion warning (ignored):', err);
    }

    return {
      success: true,
      country,
      currency,
      taxRate,
      taxBreakdown,
      taxAmount,
      total,
      sellerCountry,
      buyerCountry,
      ...(conversionHint && { conversionHint }),
      note,
    };
  } catch (err) {
    console.error('❌ determineTaxLogic error:', err);
    throw err;
  }
}
