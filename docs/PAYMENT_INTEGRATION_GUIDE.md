# Finance Coach & Token System Integration Guide

## Overview

This document covers integrating the Finance Coach feature with the AuraToken payment system into your app's root widget and navigation.

## Components

### 1. Deep Link Service
**File:** `lib/services/deep_link_service.dart`

Handles:
- Firebase Dynamic Links initialization
- Session ID extraction from deep links
- Payment processing polling (waits for webhook)

### 2. Payment Result Handler
**File:** `lib/screens/wallet/payment_result_handler.dart`

- Listens to payment session callbacks
- Shows snackbar on success/failure
- Runs silently without blocking navigation

### 3. Payment Success Page
**File:** `lib/screens/billing/payment_success_page.dart`

- Full-screen loading during payment processing
- Prevents back navigation
- Auto-navigates when complete

## Integration Steps

### Step 1: Wrap App Root with Payment Handler

In your main app widget (e.g., `MaterialApp` in `main.dart`):

```dart
import 'lib/services/deep_link_service.dart';
import 'lib/services/wallet_service.dart';
import 'lib/screens/wallet/payment_result_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final DeepLinkService _deepLinkService;
  late final WalletService _walletService;

  @override
  void initState() {
    super.initState();
    _deepLinkService = DeepLinkService();
    _walletService = WalletService();
    
    // Initialize deep link listening
    _deepLinkService.init();
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PaymentResultHandler(
        deepLinkService: _deepLinkService,
        walletService: _walletService,
        child: const MyHomePage(),
      ),
      // ... rest of MaterialApp config
    );
  }
}
```

### Step 2: Add Payment Routes

In `lib/config/app_routes.dart`, the `paymentSuccess` route is already defined:

```dart
case paymentSuccess:
  final sessionId = settings.arguments as String?;
  if (sessionId == null || sessionId.isEmpty) {
    return MaterialPageRoute(builder: (_) => const TokenShopScreen());
  }
  return MaterialPageRoute(
    builder: (_) => PaymentSuccessPage(
      sessionId: sessionId,
      deepLinkService: _deepLinkService,
    ),
  );
```

### Step 3: Update Stripe Webhook URL

In Stripe Dashboard:

1. Go to **Developers** → **Webhooks**
2. Add endpoint pointing to your webhook function:
   ```
   https://us-central1-YOUR_PROJECT.cloudfunctions.net/stripeTokenWebhook
   ```
3. Select event: **checkout.session.completed**
4. Copy the signing secret
5. Set in Firebase config:
   ```bash
   firebase functions:config:set stripe.webhook_secret="whsec_..."
   ```

### Step 4: Set Firebase Config

```bash
firebase functions:config:set \
  stripe.secret="sk_test_..." \
  stripe.publishable="pk_test_..." \
  stripe.webhook_secret="whsec_..." \
  openai.key="sk-..." \
  auracoach.cost="5"
```

### Step 5: Deploy Everything

```bash
# Deploy functions
firebase deploy --only functions

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy storage rules
firebase deploy --only storage:rules

# Deploy static pages
firebase deploy --only hosting:default
```

## User Flow Diagram

```
User opens Token Shop
         ↓
Clicks "Buy Tokens"
         ↓
createTokenCheckoutSession() → Stripe
         ↓
User completes payment in Stripe
         ↓
Stripe redirects to payment-success.html
         ↓
HTML page attempts deep link: aura://payment-success?session_id=...
         ↓
App receives session ID via DeepLinkService
         ↓
PaymentResultHandler polls for webhook
         ↓
stripeTokenWebhook processes payment
         ↓
tokens credited to users/{uid}/wallet/aura
         ↓
payment marked in payments_processed/{sessionId}
         ↓
DeepLinkService detects completion
         ↓
Shows success snackbar
         ↓
WalletService stream refreshes balance
         ↓
User sees updated token count
```

## Testing

### Local Testing

1. **Run Firebase emulator:**
   ```bash
   firebase emulators:start
   ```

2. **Use Stripe test keys:**
   - Publishable: `pk_test_...`
   - Secret: `sk_test_...`

3. **Test card number:** `4242 4242 4242 4242` (any future expiry)

### Redirect URL Testing

For local testing, update redirect URLs to:
```dart
const successUrl = 'http://localhost:3000/payment-success.html';
const cancelUrl = 'http://localhost:3000/payment-cancel.html';
```

## Monitoring & Debugging

### Firebase Console

- **Cloud Functions** → Check logs for webhook processing
- **Firestore** → Monitor `payments_processed` collection
- **Firestore** → Check `users/{uid}/wallet/aura` for balance updates

### Logs

```bash
# View function logs
firebase functions:log

# Follow stripeTokenWebhook specifically
firebase functions:log | grep stripeTokenWebhook
```

## Troubleshooting

### Payment processes but tokens don't appear

1. Check webhook signature in Firebase config
2. Verify Stripe webhook is registered and active
3. Check `payments_processed` collection for session record
4. Review function logs for errors

### Deep link not opening app

1. Ensure Firebase Dynamic Links configured in app
2. Verify custom scheme registered in `AndroidManifest.xml` and `Info.plist`
3. Test with Firebase test URLs first

### Balance not updating in real-time

1. Ensure `WalletService.streamBalance()` is subscribed
2. Check Firestore security rules allow reads
3. Verify wallet document at `users/{uid}/wallet/aura` exists

## Files Modified

- `lib/services/deep_link_service.dart` (NEW)
- `lib/services/wallet_service.dart` (UPDATED)
- `lib/services/payment_service.dart` (UPDATED)
- `lib/screens/billing/token_shop_screen.dart` (NEW)
- `lib/screens/billing/payment_success_page.dart` (NEW)
- `lib/screens/wallet/token_store_screen.dart` (NEW)
- `lib/screens/wallet/payment_result_handler.dart` (NEW)
- `lib/config/app_routes.dart` (UPDATED)
- `functions/src/payments/tokenPacks.ts` (NEW)
- `functions/src/payments/createTokenCheckoutSession.ts` (NEW)
- `functions/src/payments/stripeTokenWebhook.ts` (NEW)
- `firestore.rules` (UPDATED)
- `web/public/payment-success.html` (NEW)
- `web/public/payment-cancel.html` (NEW)
- `README.md` (UPDATED)

## Next Steps

1. ✅ Initialize `DeepLinkService` in app root
2. ✅ Wrap app with `PaymentResultHandler`
3. ✅ Set Firebase config with Stripe keys
4. ✅ Deploy functions and rules
5. ✅ Test end-to-end with Stripe test cards
6. ✅ Monitor logs and user feedback
7. ✅ Switch to production keys when ready
