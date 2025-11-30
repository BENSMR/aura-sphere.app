# 🎯 Stripe Integration Reference Card

**Print this or bookmark it!**

---

## ⚡ QUICK LINKS

### Documentation Files (In Order of Reading)
1. 📌 **QUICK:** [`STRIPE_WEBHOOK_QUICK_SETUP.md`](STRIPE_WEBHOOK_QUICK_SETUP.md) (5 min)
2. 📖 **SETUP:** [`STRIPE_WEBHOOK_SETUP_GUIDE.md`](STRIPE_WEBHOOK_SETUP_GUIDE.md) (20 min)
3. 💻 **CODE:** [`STRIPE_CLIENT_INTEGRATION_GUIDE.md`](STRIPE_CLIENT_INTEGRATION_GUIDE.md) (30 min)
4. 🏗️ **EXPERT:** [`STRIPE_ARCHITECTURE_AND_BEST_PRACTICES.md`](STRIPE_ARCHITECTURE_AND_BEST_PRACTICES.md) (ref)
5. 📊 **SUMMARY:** [`STRIPE_IMPLEMENTATION_SUMMARY.md`](STRIPE_IMPLEMENTATION_SUMMARY.md) (overview)

---

## 🔗 YOUR WEBHOOK URL

```
https://us-central1-aurasphere-pro.cloudfunctions.net/stripeWebhook
```

⚠️ **Replace `aurasphere-pro` with your actual Firebase project ID**

---

## 🚀 DEPLOYMENT COMMANDS

### Deploy Functions
```bash
cd /workspaces/aura-sphere-pro/functions
npm run build
firebase deploy --only functions:createCheckoutSession,functions:stripeWebhook
```

### Verify Configuration
```bash
firebase functions:config:get
```

Expected output:
```json
{
  "stripe": {
    "publishable": "pk_live_...",
    "secret": "sk_live_...",
    "webhook_secret": "whsec_..."
  }
}
```

---

## 🧪 TEST CARDS

| Use Case | Card Number | Expiry | CVC |
|----------|-------------|--------|-----|
| ✅ Success | 4242 4242 4242 4242 | 12/26 | 123 |
| ⚠️ Auth Required | 4000 0025 0000 3155 | 12/26 | 123 |
| ❌ Declined | 4000 0000 0000 0002 | 12/26 | 123 |

**Note:** Use any future expiry and 3-digit CVC

---

## 💻 CLIENT CODE SNIPPET

```dart
import 'package:aura_sphere_pro/services/payments/stripe_service.dart';

// Start payment
Future<void> _pay() async {
  try {
    final result = await StripeService.createCheckoutSession(
      invoiceId: invoice.id,
      successUrl: 'https://yourapp.com/success',
      cancelUrl: 'https://yourapp.com/cancel',
    );

    if (result['success'] == true) {
      await StripeService.openCheckoutUrl(result['url']);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment error: $e')),
    );
  }
}
```

---

## 📋 3-STEP SETUP

### Step 1: Deploy (2 minutes)
```bash
firebase deploy --only functions:createCheckoutSession,functions:stripeWebhook
```

### Step 2: Configure Stripe (3 minutes)
1. Go: https://dashboard.stripe.com/developers/webhooks
2. **Add endpoint**
3. **URL:** Paste your webhook URL above
4. **Events:** Check `checkout.session.completed`
5. **Copy** signing secret

### Step 3: Update Firebase (1 minute)
```bash
firebase functions:config:set stripe.webhook_secret="whsec_..."
```

---

## ✅ VERIFICATION

After payment, check:

**Firestore:**
```
invoices/{id}
├─ paymentStatus: "paid" ✅
├─ paidAt: [timestamp] ✅
└─ payments/{id}
   ├─ type: "stripe_checkout" ✅
   ├─ amount_total: 12340 ✅
   └─ status: "paid" ✅
```

**Firebase Console:**
```
Cloud Functions → stripeWebhook → Logs
├─ Event received ✅
├─ Signature verified ✅
└─ Invoice updated ✅
```

**Stripe Dashboard:**
```
Payments (tab) → Shows your transaction ✅
Webhooks → Recent events show 200 ✅
```

---

## 🆘 QUICK TROUBLESHOOTING

| Issue | Solution |
|-------|----------|
| **Webhook shows 500** | Check functions logs: `firebase functions:describe stripeWebhook --region us-central1` |
| **Signature verification failed** | Verify webhook secret: `firebase functions:config:get` |
| **Invoice not marked paid** | Check Firestore rules allow writes to invoices collection |
| **Payment button not working** | Verify user is authenticated: `FirebaseAuth.instance.currentUser` |
| **Can't open checkout URL** | Add to pubspec.yaml: `url_launcher: ^6.0.0` |

**Detailed troubleshooting:** See `STRIPE_WEBHOOK_SETUP_GUIDE.md`

---

## 📊 FIRESTORE STRUCTURE

```
invoices/
├── {invoiceId}
│   ├── invoiceNumber: "INV-001"
│   ├── items: [...]
│   ├── total: 123.40
│   ├── paymentStatus: "paid"          ← NEW
│   ├── paidAt: Timestamp              ← NEW
│   ├── paymentMethod: "stripe"        ← NEW
│   ├── lastPaymentIntentId: "pi_..." ← NEW
│   ├── lastCheckoutSessionId: "cs_..."← NEW
│   └── payments/                      ← NEW
│       └── {paymentId}
│           ├── type: "stripe_checkout"
│           ├── sessionId: "cs_..."
│           ├── paymentIntentId: "pi_..."
│           ├── amount_total: 12340
│           ├── currency: "eur"
│           ├── status: "paid"
│           ├── metadata: {invoiceId, userId}
│           └── createdAt: Timestamp
```

---

## 🔐 SECURITY CHECKLIST

- [ ] ✅ Webhook URL in Stripe Dashboard
- [ ] ✅ Webhook signing secret in Firebase config
- [ ] ✅ Stripe secret key NOT in source code
- [ ] ✅ User auth required in `createCheckoutSession`
- [ ] ✅ Webhook signature verified before processing
- [ ] ✅ Firestore rules enforce user ownership
- [ ] ✅ Amount validation in webhook (recommended)
- [ ] ✅ HTTPS enforced (automatic with Cloud Functions)

---

## 🎯 API REFERENCE

### StripeService Methods

**createCheckoutSession()**
```dart
Future<Map<String, dynamic>> createCheckoutSession({
  required String invoiceId,           // Firestore doc ID
  required String successUrl,          // Redirect on success
  required String cancelUrl,           // Redirect on cancel
})
// Returns: {success: bool, url: String, sessionId: String}
```

**openCheckoutUrl()**
```dart
Future<void> openCheckoutUrl(String url)
// Launches Stripe Checkout in browser
```

---

## 📈 MONITORING

Monitor these in Firebase Console:

1. **Cloud Functions**
   - `createCheckoutSession` invocations
   - `stripeWebhook` invocations
   - Error rate (should be <1%)

2. **Firestore**
   - Reads to invoices collection
   - Writes to payments subcollection
   - Query latency (<100ms expected)

3. **Stripe Dashboard**
   - Webhook delivery status (100% success expected)
   - Payment volume
   - Error rates

---

## 🚀 NEXT STEPS

**Week 1: Deploy**
- Deploy functions
- Configure webhook
- Test with test cards

**Week 2: Integrate**
- Add payment button to invoice screens
- Integrate StripeService
- Test full flow

**Week 3: Monitor**
- Watch webhook events
- Monitor payment volume
- Gather user feedback

**Week 4: Optimize**
- Add email receipts
- Implement refund handling
- Optimize checkout experience

---

## 📞 CONTACTS & RESOURCES

### Documentation
- Quick Setup: 5 minutes
- Complete Setup: 20 minutes
- Client Integration: 30 minutes
- Advanced Topics: Reference as needed

### Stripe Resources
- Test Mode: https://stripe.com/docs/testing
- API Docs: https://stripe.com/docs/api
- Webhooks: https://stripe.com/docs/webhooks
- Dashboard: https://dashboard.stripe.com

### Firebase
- Functions: https://firebase.google.com/docs/functions
- Firestore: https://firebase.google.com/docs/firestore
- Console: https://console.firebase.google.com

---

## 🔄 PAYMENT FLOW SEQUENCE

```
1. User taps "Pay" button
   ↓
2. StripeService.createCheckoutSession() called
   ↓
3. Cloud Function validates & creates Stripe session
   ↓
4. Returns checkout URL to client
   ↓
5. Client opens URL in browser
   ↓
6. User enters card on Stripe Checkout
   ↓
7. Stripe processes payment
   ↓
8. Stripe sends webhook to stripeWebhook endpoint
   ↓
9. Webhook verifies signature & updates Firestore
   ↓
10. Invoice marked as "Paid"
   ↓
11. App notified (Stream, polling, or redirect)
```

---

## 💾 CONFIGURATION REFERENCE

### Environment Variables (Stored in Firebase)

```bash
# Set in Firebase Functions config
stripe.secret = "sk_live_..."
stripe.webhook_secret = "whsec_..."
stripe.publishable = "pk_live_..."

# Verify with
firebase functions:config:get
```

### Never Store in Code

```
❌ DO NOT commit these to GitHub
- sk_live_... (Secret key)
- whsec_... (Webhook secret)
- API keys of any kind

✅ DO use Firebase config or environment variables
- firebase functions:config:set
- functions.config().stripe.secret
```

---

## 🎓 LEARNING PATH

### Beginner (Just want it to work)
1. Read: Quick Setup (5 min)
2. Follow: Deploy steps
3. Test: Payment flow
✅ Done

### Intermediate (Want to understand)
1. Read: Webhook Setup Guide (20 min)
2. Read: Client Integration (30 min)
3. Integrate: Into your app
4. Test: All scenarios
✅ Production ready

### Advanced (Want to master)
1. Read: All documentation
2. Study: Source code
3. Implement: Advanced features
4. Deploy: Custom enhancements
5. Monitor: Production metrics
✅ Expert level

---

## 📝 NOTES & CHECKLISTS

### Pre-Deployment
- [ ] Cloud Functions built successfully (npm run build)
- [ ] No TypeScript errors
- [ ] Stripe API keys configured in Firebase
- [ ] Webhook endpoint URL determined

### Post-Deployment
- [ ] Functions visible in Firebase Console
- [ ] Webhook configured in Stripe Dashboard
- [ ] Test payment completed
- [ ] Firestore shows payment record
- [ ] No errors in Cloud Functions logs

### Production Handoff
- [ ] All tests passing
- [ ] Documentation reviewed
- [ ] Team trained on system
- [ ] Monitoring configured
- [ ] Backup/disaster recovery plan

---

## 🎉 SUCCESS INDICATORS

You'll know it's working when:

✅ Test payment shows in Stripe Dashboard → Payments tab  
✅ Firestore invoice has `paymentStatus: "paid"`  
✅ Cloud Functions logs show "Webhook received"  
✅ No signature verification errors  
✅ Payment record appears in payments subcollection  

---

**Bookmark this page!**

Last Updated: November 28, 2025  
Status: ✅ Ready to Use

**👉 Start with:** [`STRIPE_WEBHOOK_QUICK_SETUP.md`](STRIPE_WEBHOOK_QUICK_SETUP.md)
