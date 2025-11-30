# ⚡ Stripe Webhook Quick Setup (5 minutes)

## TL;DR - Webhook Configuration Checklist

### Step 1: Deploy Functions (if not done)
```bash
cd /workspaces/aura-sphere-pro/functions
npm run build
firebase deploy --only functions:createCheckoutSession,functions:stripeWebhook
```

✅ Note the webhook function URL:
```
https://us-central1-aurasphere-pro.cloudfunctions.net/stripeWebhook
```

---

### Step 2: Configure Stripe Dashboard

Go to: **https://dashboard.stripe.com/developers/webhooks**

**Add Endpoint:**
1. Click **Add endpoint**
2. **URL:** Paste function URL above (replace project ID if different)
3. **Events:** Check `checkout.session.completed`
4. Click **Add endpoint**

**Copy Signing Secret:**
1. Click your new endpoint
2. Copy the **Signing secret** (whsec_...)

---

### Step 3: Update Firebase Config

```bash
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_SECRET_HERE"
```

**Verify:**
```bash
firebase functions:config:get
```

Should show:
```json
{
  "stripe": {
    "secret": "sk_live_...",
    "webhook_secret": "whsec_...",
    "publishable": "pk_live_..."
  }
}
```

---

### Step 4: Test Payment Flow

**Create Invoice:**
1. Open Flutter app
2. Create invoice with items totaling $1+

**Pay:**
1. Click "Create Payment Link"
2. Use test card: `4242 4242 4242 4242`
3. Complete payment

**Verify:**
1. Stripe Dashboard → Payments (shows transaction)
2. Firebase Console → Cloud Functions logs (webhook received)
3. Firestore → invoices/{id} shows `paymentStatus: "paid"`
4. Firestore → invoices/{id}/payments has payment record

---

## Test Cards

| Scenario | Card | Expiry | CVC |
|----------|------|--------|-----|
| Success | 4242 4242 4242 4242 | 12/26 | 123 |
| Requires Auth | 4000 0025 0000 3155 | 12/26 | 123 |
| Declined | 4000 0000 0000 0002 | 12/26 | 123 |

---

## Verify Everything Works

### In Stripe Dashboard:
- [ ] Endpoint created and enabled (green checkmark)
- [ ] Recent events show `checkout.session.completed` with 200 status
- [ ] Payments tab shows your test transaction

### In Firebase Console:
- [ ] Cloud Functions → Execution logs show `stripeWebhook` invocations
- [ ] Logs show "Webhook received" for your test payment
- [ ] No signature verification errors

### In Firestore:
- [ ] invoices/{id} has:
  - `paymentStatus: "paid"`
  - `paidAt: [timestamp]`
  - `paymentMethod: "stripe"`
  - `lastPaymentIntentId: "pi_..."`
  
- [ ] invoices/{id}/payments/{paymentId} has:
  - `type: "stripe_checkout"`
  - `sessionId: "cs_..."`
  - `amount_total: 100` (in cents, so $1.00)
  - `status: "paid"`
  - `metadata: {invoiceId: "...", userId: "..."}`

---

## Troubleshooting

### Webhook not triggering?
- Verify endpoint URL in Stripe Dashboard is correct
- Check endpoint status is "Enabled" (green)
- Try "Send test event" in Stripe Dashboard

### Signature verification failed?
- Double-check webhook secret copied correctly
- Run: `firebase functions:config:set stripe.webhook_secret="whsec_NEW"`
- Check logs for exact error message

### Invoice not marked as paid?
- Check Cloud Functions logs for errors
- Verify invoiceId is in session metadata
- Check Firestore security rules allow writes

---

## Your Webhook URL

Replace `aurasphere-pro` if your project ID is different:

```
https://us-central1-aurasphere-pro.cloudfunctions.net/stripeWebhook
```

---

For detailed guide, see: `STRIPE_WEBHOOK_SETUP_GUIDE.md`
