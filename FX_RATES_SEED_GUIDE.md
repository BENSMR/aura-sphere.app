# FX Rates Initial Seed Guide

## Overview

The `convertCurrency` and `syncFxRates` Cloud Functions require initial exchange rates stored in Firestore at `config/fx_rates`. This document explains how to seed the initial data.

## Document Structure

**Path:** `config/fx_rates`

```json
{
  "base": "USD",
  "provider": "exchangerate.host",
  "updatedAt": "<timestamp>",
  "fetchedAt": "<ISO8601 string>",
  "rates": {
    "EUR": 0.92,
    "GBP": 0.79,
    "JPY": 149.5,
    ...
  }
}
```

## Seeding Methods

### Method 1: Firebase Console (Easiest - Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/project/aurasphere-pro)
2. Navigate to **Firestore Database**
3. Click **+ Start Collection**
4. Collection name: `config`
5. Document name: `fx_rates`
6. Add the following fields:

| Field | Type | Value |
|-------|------|-------|
| `base` | String | `USD` |
| `provider` | String | `exchangerate.host` |
| `updatedAt` | Timestamp | (current time) |
| `fetchedAt` | String | (current ISO 8601 time) |
| `rates` | Map | (see rates below) |

For the `rates` Map, add these currency pairs:

| Currency | Rate | Currency | Rate |
|----------|------|----------|------|
| AED | 3.6725 | EUR | 0.92 |
| ARS | 1050.0 | GBP | 0.79 |
| AUD | 1.53 | HKD | 7.78 |
| BGN | 1.82 | HRK | 6.9 |
| BRL | 5.12 | HUF | 380.0 |
| CAD | 1.38 | IDR | 16500.0 |
| CHF | 0.88 | ILS | 3.5 |
| CNY | 7.25 | INR | 83.5 |
| CZK | 23.5 | ISK | 137.0 |
| DKK | 6.85 | JPY | 149.5 |

(See [firestore-seed-fx-rates.json](../firestore-seed-fx-rates.json) for complete list)

### Method 2: Node.js Script (If You Have Service Account)

If you have Firebase Admin SDK credentials:

```bash
cd /workspaces/aura-sphere-pro
GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account-key.json node scripts/seed-fx-rates.js
```

Expected output:
```
✅ Firebase Admin initialized
📝 Seeding FX rates to Firestore...
✅ FX rates seeded successfully!
   Base currency: USD
   Currencies: 34
   Provider: exchangerate.host
✔️  Verification: Document exists in Firestore
   Document size: 1847 bytes
```

### Method 3: Firebase Emulator (Local Testing)

```bash
cd /workspaces/aura-sphere-pro
firebase emulators:start

# In another terminal:
GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json node scripts/seed-fx-rates.js
```

## Automatic Updates

After the initial seed, exchange rates are automatically updated every 24 hours via the `syncFxRates` scheduled Cloud Function.

**Schedule:** `every 24 hours`  
**Provider:** `exchangerate.host` (free, no API key required)  
**Data:** Fetches latest rates and merges into existing document

## Verifying the Seed

### In Firebase Console
1. Go to Firestore Database
2. Navigate to `config` collection
3. Open `fx_rates` document
4. Verify `rates` map contains 34+ currency pairs
5. Check `updatedAt` timestamp is recent

### Via Cloud Functions

Test the `convertCurrency` function:

```bash
curl -X POST https://us-central1-aurasphere-pro.cloudfunctions.net/convertCurrency \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "amount": 100,
      "from": "USD",
      "to": "EUR"
    }
  }'
```

Expected response:
```json
{
  "result": {
    "success": true,
    "converted": 92.0,
    "rate": 0.92
  }
}
```

## Currency Pairs Included

**34 Major Currencies:**
- **Europe:** EUR, GBP, CHF, SEK, NOK, DKK, PLN, CZK, HUF, RON, BGN, HRK
- **Asia-Pacific:** JPY, CNY, INR, IDR, PHP, SGD, MYR, THB, KRW, AUD, NZD
- **Americas:** CAD, MXN, BRL, ARS
- **Middle East & Africa:** AED, ILS, TRY, RUB, ZAR, UAH, VND, ISK

## Troubleshooting

### "No rates found" error

**Problem:** `convertCurrency` returns `"No rates found"`  
**Solution:** Ensure `config/fx_rates` document exists and has `rates` map with at least 2 currencies

### Exchange rates are stale

**Problem:** Rates are older than 24 hours  
**Solution:** Either:
1. Wait for automatic `syncFxRates` (runs every 24 hours)
2. Manually trigger from Firebase Console → Cloud Functions → `syncFxRates` → Execute

### Missing currencies

**Problem:** Your currency pair isn't in the rates map  
**Solution:** 
1. Add it manually via Firebase Console
2. Contact exchangerate.host for coverage

## Next Steps

1. ✅ Seed initial FX rates using one of the methods above
2. Test `convertCurrency` function in your Flutter app
3. Verify `syncFxRates` runs on schedule

Your currency conversion is now ready! 🚀

---

**Files:**
- JSON seed data: [firestore-seed-fx-rates.json](../firestore-seed-fx-rates.json)
- Node.js script: [scripts/seed-fx-rates.js](./seed-fx-rates.js)
- Tax matrix seeds: See FIRESTORE_SECURITY_RULES_OCR.md for tax rules structure
