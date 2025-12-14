# Google Vision API Setup Guide

## Overview
The AuraSphere Pro expense scanner uses Google Cloud Vision API for advanced OCR on receipts. This guide walks you through enabling and configuring it.

## Step 1: Enable Google Vision API

### 1a. Go to Google Cloud Console
1. Open [Google Cloud Console](https://console.cloud.google.com)
2. Make sure you're in the correct GCP project (same one linked to your Firebase project)
3. Check the project name in the top-left dropdown

### 1b. Enable the Vision API
1. Go to **APIs & Services** > **Library**
2. Search for "Cloud Vision API"
3. Click on it and press **Enable**
4. Wait for it to finish enabling (1-2 minutes)

## Step 2: Create a Service Account Key

### 2a. Create Service Account
1. Go to **APIs & Services** > **Credentials**
2. Click **+ Create Credentials** > **Service Account**
3. Fill in:
   - **Service account name**: `aurasphere-vision-ocr`
   - **Service account ID**: Auto-filled
   - **Description**: "Vision API for expense OCR"
4. Click **Create and Continue**

### 2b. Grant Permissions
1. On the "Grant this service account access to project" step:
   - Select role: **Editor** (or more restrictive: **Cloud Vision API User**)
   - Click **Continue**
2. Click **Done**

### 2c. Create API Key
1. Go back to **APIs & Services** > **Credentials**
2. Find the service account you just created
3. Click on it to open the details
4. Go to **Keys** tab
5. Click **Add Key** > **Create new key**
6. Choose **JSON** format
7. Click **Create**
   - A JSON file will download automatically
   - **Keep this file safe** - it contains your credentials

## Step 3: Configure Firebase Functions

### 3a. Extract API Key from JSON
1. Open the downloaded JSON file
2. Find the field `"private_key_id"` 
3. You have two options:

**Option A: Use the entire service account JSON (Recommended for production)**
```bash
# Set the entire JSON as a config variable
firebase functions:config:set vision.credentials='{"type":"service_account","project_id":"...","...":"..."}'
```

**Option B: Use just the API key (Simpler for development)**
This requires creating a separate API key:

### 3b. Create an API Key (for Option B)
1. Go to **APIs & Services** > **Credentials**
2. Click **+ Create Credentials** > **API Key**
3. Copy the generated API key
4. Click **Restrict Key** and set:
   - **API restrictions**: Cloud Vision API
   - **Application restrictions**: HTTP referrers (add your domain)

### 3c. Set the API Key in Firebase Functions

```bash
# For development - using simple API key
firebase functions:config:set vision.key="YOUR_API_KEY_HERE"

# Example:
firebase functions:config:set vision.key="YOUR_GOOGLE_API_KEY"
```

**Or for production - using service account:**
```bash
firebase functions:config:set vision.credentials="$(cat path/to/service-account-key.json)"
```

## Step 4: Verify Configuration

### 4a. Check Functions Config
```bash
firebase functions:config:get
```

You should see:
```json
{
  "vision": {
    "key": "YOUR_GOOGLE_API_KEY"
  }
}
```

### 4b. Deploy Functions
```bash
cd functions
npm run build
firebase deploy --only functions
```

## Step 5: Test the Vision API

### 5a. Test from Flutter
1. Upload a receipt image to Firebase Storage
2. Call the `visionOcr` function:

```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<void> testVisionOcr(String imageUrl) async {
  try {
    final result = await FirebaseFunctions.instance
      .httpsCallable('visionOcr')
      .call({'imageUrl': imageUrl});
    
    print('OCR Result: ${result.data}');
    // Expected response:
    // {
    //   'rawText': '...',
    //   'parsed': {
    //     'merchant': 'Store Name',
    //     'amount': 42.50,
    //     'currency': 'EUR',
    //     'date': '2024-11-27T...'
    //   }
    // }
  } catch (e) {
    print('Error: $e');
  }
}
```

### 5b. Test from Cloud Functions Logs
1. Go to Firebase Console > Functions
2. Click on the `visionOcr` function
3. Go to **Logs** tab
4. Trigger a test from the Flutter app
5. Check the output for any errors

## Pricing

**Free tier (per month):**
- 1,000 requests for `DOCUMENT_TEXT_DETECTION`

**Paid tier:**
- $1.50 per 1,000 requests (after free quota)

For expense receipts (typically 100-500/month), you'll likely stay within free tier.

## Troubleshooting

### "Vision API not configured" Error
```
HttpsError(failed-precondition, 'Vision API not configured')
```
**Solution:** 
- Verify API key is set: `firebase functions:config:get`
- Verify Vision API is enabled in GCP Console
- Redeploy functions after setting config

### "Invalid API Key" Error
```
HttpsError(internal, 'Vision API failed')
```
**Solution:**
- Check API key is correct (no extra spaces)
- Verify API key has Vision API enabled (in GCP Console > Credentials)
- Check API key restrictions match your domain

### "Request had invalid image data" Error
```
Vision API error: {..., "Invalid image data"}
```
**Solution:**
- Image URL must be publicly accessible or in Cloud Storage
- Image must be a valid format (JPEG, PNG, GIF, WebP)
- Image size should be < 20MB

### "Unauthenticated" Error
**Solution:**
- User must be logged in
- Firebase Auth must be properly initialized
- Check Firebase config in `web/index.html`

## Advanced: Using Service Account Credentials

For production with higher security:

```typescript
// In functions/src/ocr/ocrProcessor.ts
import { ImageAnnotatorClient } from '@google-cloud/vision';

const vision = new ImageAnnotatorClient({
  credentials: JSON.parse(process.env.GOOGLE_VISION_CREDENTIALS || '{}'),
});

export const visionOcr = functions.https.onCall(async (data, context) => {
  // Use vision client directly
  const [result] = await vision.textDetection(data.imageUrl);
  // ...
});
```

Then set credentials:
```bash
firebase functions:config:set vision.credentials="$(cat ./service-account-key.json)"
```

## Next Steps

1. ✅ Enable Vision API in GCP
2. ✅ Create and configure API key
3. ✅ Deploy functions
4. ✅ Test with a receipt image
5. ✅ Monitor usage in GCP Console

## References

- [Google Vision API Documentation](https://cloud.google.com/vision/docs)
- [Firebase Functions Config](https://firebase.google.com/docs/functions/config-env)
- [Cloud Vision Pricing](https://cloud.google.com/vision/pricing)
