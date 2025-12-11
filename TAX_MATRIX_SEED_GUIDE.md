# Tax Matrix Seed Guide

## Overview

The `calculateTax` Cloud Function requires tax rules stored in Firestore at `config/tax_matrix/{countryCode}`. This document explains how to seed the initial data.

## Document Structure

**Path:** `config/tax_matrix/{countryCode}`  
**Example:** `config/tax_matrix/FR`

```json
{
  "country": "FR",
  "region": "EU",
  "vat": {
    "standard": 0.20,
    "reduced": [0.10, 0.055],
    "isEu": true,
    "has_vat": true
  },
  "sales_tax": null,
  "seedAt": "<timestamp>"
}
```

## Field Definitions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `country` | String | ISO country code | `FR`, `DE`, `US` |
| `region` | String | Geographic region | `EU`, `Americas`, `APAC` |
| `vat` | Object | VAT configuration (EU) | See below |
| `vat.standard` | Number | Standard VAT rate | `0.20` (20%) |
| `vat.reduced` | Array | Reduced rates for special items | `[0.10, 0.055]` |
| `vat.isEu` | Boolean | Is country in EU | `true` |
| `vat.has_vat` | Boolean | Does country use VAT | `true` |
| `sales_tax` | Object | Sales tax config (US, etc.) | `null` or config |
| `seedAt` | Timestamp | When record was created | Auto-set |

## Seeding Methods

### Method 1: Firebase Console (Recommended)

1. Open [Firebase Console](https://console.firebase.google.com/project/aurasphere-pro)
2. Go to **Firestore Database**
3. Create collection: `config/tax_matrix`
4. For each country, create a document with the country code as ID

**Example: Creating FR (France) document**

1. Click **Add document**
2. Document ID: `FR`
3. Add fields:

| Field | Type | Value |
|-------|------|-------|
| `country` | String | `FR` |
| `region` | String | `EU` |
| `vat` | Map | (see below) |
| `sales_tax` | Null | null |

4. Inside `vat` Map, add:

| Field | Type | Value |
|-------|------|-------|
| `standard` | Number | `0.20` |
| `reduced` | Array | `[0.10, 0.055]` |
| `isEu` | Boolean | `true` |
| `has_vat` | Boolean | `true` |

5. Repeat for all countries in the seed file

### Method 2: Node.js Script (Automated)

If you have Firebase Admin SDK credentials:

```bash
cd /workspaces/aura-sphere-pro
GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account-key.json node scripts/seed-tax-matrix.js
```

Expected output:
```
✅ Firebase Admin initialized
📝 Seeding tax matrix to Firestore...
✅ Tax matrix seeded successfully!
   Countries: 16
   EU countries: 10
   Americas: 2
   APAC: 4

✔️  Verification: FR VAT standard rate = 20%
```

### Method 3: Firebase Emulator (Local Testing)

```bash
cd /workspaces/aura-sphere-pro
firebase emulators:start

# In another terminal:
GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json node scripts/seed-tax-matrix.js
```

## Countries Included (16 Total)

### 🇪🇺 European Union (10 countries)

| Country | Code | Standard VAT | Reduced | EU Reverse Charge |
|---------|------|---------------|---------|--------------------|
| France | FR | 20% | 10%, 5.5% | ✅ Yes |
| Germany | DE | 19% | 7% | ✅ Yes |
| United Kingdom | GB | 20% | 5% | ✅ Yes |
| Spain | ES | 21% | 10% | ✅ Yes |
| Italy | IT | 22% | 10%, 5% | ✅ Yes |
| Netherlands | NL | 21% | 9% | ✅ Yes |
| Belgium | BE | 21% | 12%, 6% | ✅ Yes |
| Austria | AT | 20% | 10% | ✅ Yes |
| Poland | PL | 23% | 8%, 5% | ✅ Yes |
| Sweden | SE | 25% | 12%, 6% | ✅ Yes |

### 🌎 Americas (2 countries)

| Country | Code | Tax Type | Standard | Notes |
|---------|------|----------|----------|-------|
| United States | US | Sales Tax | Varies | 5-10% by state |
| Canada | CA | GST | 5% | Federal only |

### 🌏 Asia-Pacific (4 countries)

| Country | Code | Tax Type | Standard | Reduced |
|---------|------|----------|----------|---------|
| Australia | AU | GST | 10% | — |
| Japan | JP | Consumption Tax | 10% | 8% |
| Singapore | SG | GST | 8% | — |
| India | IN | GST | 18% | 12%, 5% |

## Key Features

✅ **EU B2B Reverse Charge**
- Automatically applied for business-to-business invoices within EU
- Tax rate becomes 0% (buyer pays VAT in their country)

✅ **Reduced Rates**
- Multiple reduced rates per country supported
- Special handling for specific item categories

✅ **Multiple Tax Systems**
- VAT (Europe, Asia-Pacific)
- Sales Tax (Americas)
- GST (Canada, Australia)

✅ **Extensible**
- Add more countries easily
- Update rates as regulations change

## Verifying the Seed

### In Firebase Console

1. Navigate to `config/tax_matrix` collection
2. Verify 16 documents exist (one per country)
3. Open `FR` document and verify:
   - `vat.standard` = 0.20
   - `vat.reduced` = [0.10, 0.055]
   - `region` = "EU"

### Via Cloud Functions

Test the `calculateTax` function:

```bash
curl -X POST https://us-central1-aurasphere-pro.cloudfunctions.net/calculateTax \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "data": {
      "country": "FR",
      "amount": 100.0,
      "taxType": "vat"
    }
  }'
```

Expected response:
```json
{
  "result": {
    "success": true,
    "tax": 20.0,
    "total": 120.0,
    "rate": 0.20
  }
}
```

### Test EU Reverse Charge

```bash
curl -X POST https://us-central1-aurasphere-pro.cloudfunctions.net/calculateTax \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "data": {
      "country": "DE",
      "amount": 100.0,
      "taxType": "vat",
      "direction": "sale",
      "customerIsBusiness": true
    }
  }'
```

Expected response (reverse charge applied):
```json
{
  "result": {
    "success": true,
    "tax": 0.0,
    "total": 100.0,
    "rate": 0.0,
    "note": "Reverse charge applied (EU B2B)"
  }
}
```

## Adding New Countries

To add a new country:

1. **Get tax rates** from official sources:
   - EU: https://ec.europa.eu/taxation_customs/
   - US/CA: State tax websites
   - Other: https://taxfoundation.org/

2. **Add document to Firestore:**
   ```json
   {
     "country": "XX",
     "region": "REGION",
     "vat": {
       "standard": 0.XX,
       "reduced": [0.XX],
       "isEu": false,
       "has_vat": true
     },
     "sales_tax": null
   }
   ```

3. **Update** `scripts/seed-tax-matrix.js` and `firestore-seed-tax-matrix.json`

## Troubleshooting

### "No tax rule for country" error

**Problem:** `calculateTax` returns empty response  
**Solution:** Ensure document exists at `config/tax_matrix/{countryCode}`

### Incorrect tax rate

**Problem:** Function returns wrong rate  
**Solutions:**
1. Verify rate in Firebase Console
2. Check VAT regulations for country
3. Update document if rates changed

### Reverse charge not working

**Problem:** B2B EU invoice still shows tax  
**Solution:** Ensure:
- `customerIsBusiness`: true
- `direction`: "sale"
- `vat.isEu`: true in tax rule
- Both countries in EU

## Maintenance

- **Review annually** for rate changes
- **Subscribe** to EU VAT rate updates
- **Test** `calculateTax` quarterly
- **Document** any custom rates

## Next Steps

1. ✅ Seed tax matrix using Method 1 or 2 above
2. Test `calculateTax` function with various countries
3. Verify reverse charge rules work correctly
4. Add additional countries as needed

Your multi-country tax system is ready! 🌍

---

**Files:**
- JSON seed data: [firestore-seed-tax-matrix.json](../firestore-seed-tax-matrix.json)
- Node.js script: [scripts/seed-tax-matrix.js](./seed-tax-matrix.js)
- Cloud Function: See [taxEngine.ts](../functions/src/finance/taxEngine.ts)
