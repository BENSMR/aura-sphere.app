# Stripe Integration Deployment Checklist

**Phase:** 13 - Stripe Payment Integration  
**Status:** ✅ Ready for Deployment  
**Last Updated:** 2024  
**Document Version:** 1.0

---

## Pre-Deployment Verification

### Backend Setup

- [ ] **Cloud Functions Deployed**
  ```bash
  firebase deploy --only functions
  ```
  - [ ] stripeWebhook function active
  - [ ] createPaymentIntent function active
  - [ ] confirmPayment function active
  - [ ] createCheckoutSession function active
  - [ ] updateSubscription function active
  - [ ] cancelSubscription function active
  - [ ] downloadInvoice function active
  - [ ] getPaymentHistory function active

- [ ] **Firebase Configuration Set**
  ```bash
  firebase functions:config:get
  ```
  - [ ] `stripe.secret` configured
  - [ ] `stripe.webhook_secret` configured
  - [ ] `sendgrid.key` configured
  - [ ] `sendgrid.sender` configured

- [ ] **Firestore Rules Deployed**
  ```bash
  firebase deploy --only firestore:rules
  ```
  - [ ] Payment collection security rules in place
  - [ ] Invoice payment access restricted to owner
  - [ ] Subscription data protected

- [ ] **Firestore Indexes Created**
  - [ ] Composite index on `invoices(status, createdAt)`
  - [ ] Composite index on `payments(status, paidAt)`

### Frontend Setup

- [ ] **Environment Variables Configured** (`.env.local`)
  - [ ] `REACT_APP_STRIPE_PUBLISHABLE_KEY` set
  - [ ] `REACT_APP_SUCCESS_URL` set
  - [ ] `REACT_APP_CANCEL_URL` set

- [ ] **Stripe SDK Initialized**
  - [ ] `@stripe/js` package installed
  - [ ] `@stripe/react-stripe-js` package installed
  - [ ] `stripeConfig.js` loaded before app initialization

- [ ] **Payment Components Integrated**
  - [ ] `PaymentComponents.jsx` imported in billing screens
  - [ ] `stripe_service.js` available in all payment paths
  - [ ] Error handling configured

- [ ] **Flutter Web Payment Integration** (Optional)
  - [ ] `stripe_service.dart` imported in payment screens
  - [ ] Checkout flow implemented
  - [ ] Error messages displayed properly

---

## Stripe Dashboard Configuration

### API Keys

- [ ] **Test Mode Keys Obtained**
  - [ ] Publishable key copied: `pk_test_...`
  - [ ] Secret key copied: `sk_test_...`

- [ ] **Live Mode Keys Obtained** (Production only)
  - [ ] Publishable key copied: `pk_live_...`
  - [ ] Secret key copied: `sk_live_...`
  - [ ] Keys rotated (old keys deleted)

### Webhook Configuration

- [ ] **Webhook Endpoint Created**
  - [ ] URL: `https://us-central1-<project>.cloudfunctions.net/stripeWebhookBilling`
  - [ ] Signing secret obtained: `whsec_...`
  - [ ] Added to Firebase config: `stripe.webhook_secret`

- [ ] **Event Subscriptions Configured**
  - [ ] `checkout.session.completed` ✓
  - [ ] `payment_intent.succeeded` ✓
  - [ ] `customer.subscription.created` ✓
  - [ ] `customer.subscription.updated` ✓
  - [ ] `customer.subscription.deleted` ✓
  - [ ] `invoice.payment_failed` ✓

- [ ] **Webhook Test Completed**
  ```bash
  stripe trigger checkout.session.completed --stripe-account <account-id>
  ```
  - [ ] Webhook delivered successfully
  - [ ] Event processed without errors
  - [ ] Firestore updated correctly

### Payment Settings

- [ ] **Product Created in Stripe**
  - [ ] Name: "AuraSphere Pro Subscription"
  - [ ] Type: Service
  - [ ] Metadata includes tier information

- [ ] **Pricing Tiers Configured**
  - [ ] Solo: $9/month ($99/year)
  - [ ] Team: $29/month ($299/year)
  - [ ] Business: $79/month ($799/year)
  - [ ] Each tier has both monthly and yearly prices

- [ ] **Customer Email Settings**
  - [ ] Automatic receipts enabled
  - [ ] Receipt template customized
  - [ ] Invoice preview verified

### Security Settings

- [ ] **Dashboard Restrictions Enabled**
  - [ ] 2FA enabled on Stripe account
  - [ ] API key permissions restricted
  - [ ] IP whitelist configured (if available)

- [ ] **Fraud Protection Enabled**
  - [ ] Radar enabled (if on higher tier)
  - [ ] 3D Secure enabled for high-risk regions
  - [ ] Manual review threshold set

---

## Testing Phase

### Unit Tests

- [ ] **Payment Intent Tests**
  - [ ] `createPaymentIntent` with valid data succeeds
  - [ ] Missing `amount` parameter fails appropriately
  - [ ] Invalid `tierId` returns error
  - [ ] Amount conversion to cents is correct

- [ ] **Webhook Handler Tests**
  - [ ] Valid signature accepted
  - [ ] Invalid signature rejected
  - [ ] Duplicate events handled idempotently
  - [ ] Missing metadata handled gracefully
  - [ ] Payment record created with full schema
  - [ ] Invoice marked as paid
  - [ ] Firestore updated atomically

- [ ] **Error Handling Tests**
  - [ ] Network errors handled gracefully
  - [ ] Stripe API errors formatted correctly
  - [ ] Invalid card data caught early
  - [ ] Rate limiting respected

### Integration Tests

- [ ] **End-to-End Payment Flow (Test Mode)**
  1. [ ] Create payment intent successfully
  2. [ ] Load Stripe card form without errors
  3. [ ] Submit card `4242 4242 4242 4242`
  4. [ ] Payment succeeds (status = succeeded)
  5. [ ] Confirm payment on backend
  6. [ ] User subscription updated
  7. [ ] Access to new tier granted
  8. [ ] Receipt email sent

- [ ] **Card Decline Test**
  1. [ ] Submit card `4000 0000 0000 0002`
  2. [ ] Decline error shown to user
  3. [ ] No payment record created
  4. [ ] Subscription unchanged
  5. [ ] User can retry

- [ ] **Webhook Delivery Test**
  1. [ ] Trigger test event from Stripe
  2. [ ] Webhook received within 30 seconds
  3. [ ] Firestore updated correctly
  4. [ ] Email sent (if configured)
  5. [ ] Logs show successful processing

- [ ] **Checkout Session Test**
  1. [ ] Create checkout session for invoice
  2. [ ] Redirect to Stripe Checkout succeeds
  3. [ ] Complete payment flow
  4. [ ] Webhook triggers on success
  5. [ ] Invoice marked as paid
  6. [ ] Return URL functions correctly

- [ ] **Subscription Management**
  1. [ ] Upgrade from Solo to Team succeeds
  2. [ ] Prorated amount calculated correctly
  3. [ ] New tier access granted immediately
  4. [ ] Downgrade processes correctly
  5. [ ] Cancellation confirms properly
  6. [ ] Access revoked at period end

### User Acceptance Testing

- [ ] **Customer Experience**
  - [ ] Payment form loads without lag
  - [ ] Error messages are clear and helpful
  - [ ] Success confirmation is obvious
  - [ ] Can view payment history
  - [ ] Can download invoices
  - [ ] Can manage payment methods
  - [ ] Can cancel/modify subscription

- [ ] **Mobile Responsiveness**
  - [ ] Card form responsive on mobile
  - [ ] Checkout flow works on small screens
  - [ ] Success page readable on all devices
  - [ ] Payment history table scrolls properly

- [ ] **Accessibility**
  - [ ] Form labels associated with inputs
  - [ ] Error messages announced to screen readers
  - [ ] Tab navigation works correctly
  - [ ] Color contrast meets WCAG AA

---

## Database Verification

### Firestore Structure

- [ ] **User Subscription Records Created**
  ```
  users/{uid}/subscription
  ├── status: string
  ├── plan: string
  ├── currentPeriodStart: timestamp
  ├── currentPeriodEnd: timestamp
  ├── stripeCustomerId: string
  ├── stripeSubscriptionId: string
  └── stripePriceId: string
  ```

- [ ] **Payment Records Created**
  ```
  users/{uid}/invoices/{invoiceId}/payments/{paymentId}
  ├── amount: number
  ├── currency: string
  ├── status: string
  ├── paidAt: timestamp
  ├── stripeSessionId: string
  ├── stripePaymentIntent: string
  ├── method: string
  ├── cardBrand: string
  ├── last4: string
  └── metadata: object
  ```

- [ ] **Invoice Payment Status Updated**
  ```
  users/{uid}/invoices/{invoiceId}
  ├── paymentStatus: string ('paid' vs 'unpaid')
  ├── paymentVerified: boolean
  ├── lastPaymentProvider: string ('stripe')
  ├── paidAt: timestamp
  └── paymentMetadata: object
  ```

### Security Rules

- [ ] **Payment Records Protected**
  - [ ] Only invoice owner can read own payments
  - [ ] Only Cloud Functions can write payments
  - [ ] Timestamp enforced on creation

- [ ] **Subscription Records Protected**
  - [ ] Only user can read own subscription
  - [ ] Only Cloud Functions can write subscription
  - [ ] Stripe IDs stored securely

---

## Monitoring Setup

### Logging

- [ ] **Cloud Function Logs Configured**
  ```bash
  firebase functions:log
  ```
  - [ ] All payment events logged
  - [ ] Errors logged with full context
  - [ ] PII not logged (no card details)

- [ ] **Stripe Activity Monitoring**
  - [ ] Dashboard → API → Recent requests checked
  - [ ] Webhook delivery status monitored
  - [ ] Error rates reviewed

### Alerts

- [ ] **Alerting Rules Configured**
  - [ ] High payment failure rate alert
  - [ ] Webhook delivery failure alert
  - [ ] Function error rate alert
  - [ ] Email receipts sent for each payment

---

## Transition to Production

### Pre-Production

1. [ ] All tests passing
2. [ ] Security review completed
3. [ ] Performance testing done
4. [ ] Scalability verified
5. [ ] Disaster recovery plan documented
6. [ ] Support team trained

### Switch to Live Keys

- [ ] **Credentials Updated**
  ```bash
  firebase functions:config:set stripe.secret="sk_live_..."
  firebase functions:config:set stripe.webhook_secret="whsec_..."
  ```

- [ ] **Environment Variables Updated**
  - [ ] Production `.env` file updated
  - [ ] Stripe publishable key changed to live
  - [ ] Success/cancel URLs point to production domain

- [ ] **Webhook Reconfigured**
  - [ ] New live mode webhook endpoint created
  - [ ] New signing secret configured
  - [ ] Test webhook verified

### Deployment

```bash
# 1. Update configuration
firebase functions:config:set stripe.secret="sk_live_..."

# 2. Deploy functions with live keys
firebase deploy --only functions

# 3. Verify deployment
firebase functions:log

# 4. Test with live Stripe account
# Use real (declined) test card: 4000 0000 0000 0002
```

- [ ] Functions deployed successfully
- [ ] No errors in logs
- [ ] Webhook endpoint responding
- [ ] Database connections working

### Go-Live Monitoring

- [ ] **First 24 Hours**
  - [ ] Monitor error logs hourly
  - [ ] Check payment success rate (target: >95%)
  - [ ] Verify webhook delivery (target: 100%)
  - [ ] Monitor function latency
  - [ ] Check email delivery

- [ ] **First Week**
  - [ ] Process multiple payment cycles
  - [ ] Verify subscription renewals work
  - [ ] Test customer refund flows
  - [ ] Monitor fraud patterns

---

## Rollback Plan

If critical issues occur:

```bash
# 1. Switch back to test keys temporarily
firebase functions:config:set stripe.secret="sk_test_..."

# 2. Deploy
firebase deploy --only functions

# 3. Notify customers of temporary maintenance
# Message: "We're performing maintenance on payments. 
#           Please try again in 15 minutes."

# 4. Investigate and fix
# 5. Redeploy with corrections
# 6. Monitor carefully
```

**Keep backup of working version:**
```bash
git tag stripe-v1-live
git push origin stripe-v1-live
```

---

## Post-Launch Maintenance

### Weekly

- [ ] Review failed payment attempts
- [ ] Check webhook delivery rates
- [ ] Monitor function performance
- [ ] Verify email delivery

### Monthly

- [ ] Review payment metrics
- [ ] Analyze payment patterns
- [ ] Check fraud indicators
- [ ] Verify customer refunds processed

### Quarterly

- [ ] Security audit of payment system
- [ ] Review Stripe API updates
- [ ] Update dependent packages
- [ ] Test disaster recovery procedures

---

## Handoff Checklist

Transfer to operations team:

- [ ] **Documentation**
  - [ ] All integration guides provided
  - [ ] API reference available
  - [ ] Troubleshooting guide reviewed
  - [ ] Runbooks for common issues created

- [ ] **Access & Credentials**
  - [ ] Stripe dashboard access granted
  - [ ] Firebase console access granted
  - [ ] SendGrid account access granted
  - [ ] Production environment keys secured

- [ ] **Training**
  - [ ] Support team trained on payment refunds
  - [ ] Operations team trained on monitoring
  - [ ] Finance team trained on revenue reports
  - [ ] Developers trained on troubleshooting

- [ ] **Contacts**
  - [ ] Stripe support contact documented
  - [ ] Firebase support contact documented
  - [ ] On-call rotation established
  - [ ] Escalation procedures documented

---

## Success Criteria

✅ **All items checked = Ready for Production**

- Production deployment successful
- Payment success rate > 95%
- Webhook delivery rate = 100%
- Customer satisfaction with payment flow = high
- Zero critical security issues
- Support team independent of development
- Monitoring and alerts functional
- Runbooks tested and documented

---

**Deployment Date:** _______________

**Deployed By:** _______________

**Verified By:** _______________

**Approved By:** _______________

---

*Document Version: 1.0*  
*Last Updated: Phase 13*  
*Status: Ready for Deployment ✅*
