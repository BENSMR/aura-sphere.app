# STRIPE INTEGRATION - ARCHITECTURE DIAGRAM

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        USER BROWSER (Web App)                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  React Components                                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │   │
│  │  │   Pricing    │  │   Billing    │  │  Payment    │         │   │
│  │  │   Page       │  │  History     │  │  Methods    │         │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘         │   │
│  │         │                 │                    │               │   │
│  │         └─────────────────┼────────────────────┘               │   │
│  │                           ▼                                    │   │
│  │  ┌────────────────────────────────────────┐                   │   │
│  │  │  CardPaymentForm Component             │                   │   │
│  │  │  - Stripe Card Element                 │                   │   │
│  │  │  - Real-time validation                │                   │   │
│  │  │  - Error handling                      │                   │   │
│  │  └────────────────────────────────────────┘                   │   │
│  │                    │                                           │   │
│  │                    ▼                                           │   │
│  │  ┌────────────────────────────────────────┐                   │   │
│  │  │  stripe_service.dart                   │                   │   │
│  │  │  (14 payment functions)                │                   │   │
│  │  │  - createPaymentIntent()               │                   │   │
│  │  │  - confirmPayment()                    │                   │   │
│  │  │  - createSubscription()                │                   │   │
│  │  │  - getPaymentHistory()                 │                   │   │
│  │  └────────────────────────────────────────┘                   │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                           │                                         │
└───────────────────────────┼─────────────────────────────────────────┘
                            │
                ┌───────────┴────────────┐
                │                        │
                ▼                        ▼
        ┌─────────────────┐    ┌──────────────────┐
        │  Stripe.js      │    │  Stripe.com      │
        │  (Client SDK)   │    │  (Payment Network)
        └─────────────────┘    └──────────────────┘
                │                        │
                └───────────┬────────────┘
                            │
        ┌───────────────────┴────────────────────┐
        │                                        │
        ▼                                        ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        FIREBASE BACKEND                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  Cloud Functions (Node.js / TypeScript)                        │   │
│  │                                                                │   │
│  │  ┌──────────────────────┐  ┌─────────────────────────────┐   │   │
│  │  │  Payment Functions   │  │  Webhook Handler           │   │   │
│  │  ├──────────────────────┤  ├─────────────────────────────┤   │   │
│  │  │- createPaymentIntent │  │ stripe_webhook()           │   │   │
│  │  │- confirmPayment      │  │ - Verify signature         │   │   │
│  │  │- createSubscription  │  │ - Route to handlers        │   │   │
│  │  │- updateSubscription  │  │ - Update Firestore         │   │   │
│  │  │- cancelSubscription  │  │ - Send notifications       │   │   │
│  │  │- savePaymentMethod   │  │                            │   │   │
│  │  │- deletePaymentMethod │  └─────────────────────────────┘   │   │
│  │  │- getBillingPortalUrl │                                    │   │
│  │  │- getInvoice          │   ┌─────────────────────────────┐   │   │
│  │  │- refund              │   │  Webhook Event Handlers    │   │   │
│  │  └──────────────────────┘   ├─────────────────────────────┤   │   │
│  │            │                │- handleInvoicePaid         │   │   │
│  │            ▼                │- handleInvoicePaymentFailed│   │   │
│  │   ┌──────────────────┐      │- handleSubscriptionUpdated │   │   │
│  │   │  Stripe SDK      │      │- handleSubscriptionDeleted │   │   │
│  │   │ (Node.js)        │      │- handleChargeRefunded      │   │   │
│  │   │                  │      └─────────────────────────────┘   │   │
│  │   │ - Verify Keys    │                                        │   │
│  │   │ - API Calls      │                                        │   │
│  │   │ - Webhook Verify │                                        │   │
│  │   └──────────────────┘                                        │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                           │                                          │
│                           ▼                                          │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  Firestore Database                                            │   │
│  │  ┌──────────────────────────────────────────────────────────┐ │   │
│  │  │ users/{userId}                                           │ │   │
│  │  │ ├── subscription                                         │ │   │
│  │  │ │   ├── tierId: "team"                                   │ │   │
│  │  │ │   ├── status: "active"                                 │ │   │
│  │  │ │   ├── stripeSubscriptionId: "sub_xxx"                  │ │   │
│  │  │ │   ├── stripeCustomerId: "cus_xxx"                      │ │   │
│  │  │ │   ├── billingCycle: "monthly"                          │ │   │
│  │  │ │   ├── currentPeriodStart: Timestamp                    │ │   │
│  │  │ │   ├── currentPeriodEnd: Timestamp                      │ │   │
│  │  │ │   └── lastPaymentDate: Timestamp                       │ │   │
│  │  │ │                                                         │ │   │
│  │  │ ├── payments (subcollection)                             │ │   │
│  │  │ │   ├── {paymentId}                                      │ │   │
│  │  │ │   │   ├── paymentIntentId: "pi_xxx"                    │ │   │
│  │  │ │   │   ├── amount: 2900                                 │ │   │
│  │  │ │   │   ├── currency: "usd"                              │ │   │
│  │  │ │   │   ├── tierId: "team"                               │ │   │
│  │  │ │   │   ├── status: "succeeded"                          │ │   │
│  │  │ │   │   └── timestamp: Timestamp                         │ │   │
│  │  │ │   └── {paymentId}                                      │ │   │
│  │  │ │                                                         │ │   │
│  │  │ └── paymentMethods (subcollection)                       │ │   │
│  │  │     └── {methodId}                                       │ │   │
│  │  │         ├── stripePaymentMethodId: "pm_xxx"              │ │   │
│  │  │         ├── isDefault: true                              │ │   │
│  │  │         └── createdAt: Timestamp                         │ │   │
│  │  └──────────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                           │                                          │
└───────────────────────────┼──────────────────────────────────────────┘
                            │
                ┌───────────┴────────────┐
                │                        │
                ▼                        ▼
        ┌─────────────────┐    ┌──────────────────┐
        │ Stripe.com      │    │  Email Service   │
        │ (Payments)      │    │  (SendGrid, etc) │
        └─────────────────┘    └──────────────────┘
```

---

## Data Flow Sequences

### 1️⃣ CREATE SUBSCRIPTION FLOW

```
User clicks "Upgrade"
    ↓
SubscriptionUpgrade Component appears
    ↓
User selects tier (e.g., "Team")
    ↓
User enters payment details in CardPaymentForm
    ↓
CardPaymentForm calls: stripeService.createPaymentIntent(userId, amount, tierId)
    ↓
Frontend calls: stripe_createPaymentIntent Cloud Function
    ↓
Function authenticates user (context.auth.uid)
    ↓
Function gets/creates Stripe Customer
    ↓
stripe.paymentIntents.create() → returns clientSecret
    ↓
Frontend receives clientSecret
    ↓
stripe.confirmCardPayment(clientSecret, { card })
    ↓
Stripe processes card → returns paymentIntent
    ↓
Frontend calls: stripeService.confirmPayment(clientSecret, tierId)
    ↓
Frontend calls: stripe_confirmPayment Cloud Function
    ↓
Function verifies payment succeeded
    ↓
Function updates Firestore:
    - users/{userId}/subscription/tierId = "team"
    - users/{userId}/subscription/status = "active"
    ↓
Function records payment:
    - users/{userId}/payments/{id}/ document created
    ↓
Frontend shows success message
    ↓
App redirects to team dashboard
    ↓
Role-based permissions automatically grant team features
```

### 2️⃣ WEBHOOK FLOW

```
Stripe generates event (e.g., payment succeeded)
    ↓
Stripe sends POST to: /api/stripe/webhook
    ↓
stripe_webhook Cloud Function receives request
    ↓
Function verifies webhook signature with STRIPE_WEBHOOK_SECRET
    ↓
Signature valid ✓
    ↓
Function routes event to handler:
    - event.type = "invoice.paid"
    ↓
handleInvoicePaid(invoice)
    ↓
Function extracts userId from invoice.metadata.userId
    ↓
Function updates Firestore:
    - users/{userId}/subscription/status = "active"
    - users/{userId}/subscription/lastPaymentDate = now()
    ↓
Function sends confirmation email (optional)
    ↓
Function returns 200 OK to Stripe
    ↓
Stripe marks webhook as delivered
```

### 3️⃣ UPGRADE SUBSCRIPTION FLOW

```
User clicks "Upgrade" from Team to Business
    ↓
SubscriptionUpgrade Component shows tier options
    ↓
User selects "Business" tier
    ↓
Component calls: stripeService.updateSubscription("business")
    ↓
Frontend calls: stripe_updateSubscription Cloud Function
    ↓
Function gets current subscription from Firestore
    ↓
Function calls: stripe.subscriptions.update()
    ↓
Stripe updates subscription with new price
    ↓
Stripe calculates proration (partial refund/charge)
    ↓
Function updates Firestore:
    - users/{userId}/subscription/tierId = "business"
    ↓
Stripe webhook fires: customer.subscription.updated
    ↓
Webhook handler syncs Firestore
    ↓
Frontend refreshes and shows new tier
```

### 4️⃣ PAYMENT HISTORY FETCH FLOW

```
User navigates to Billing → History
    ↓
BillingHistory Component mounts
    ↓
Component calls: stripeService.getPaymentHistory(userId, 10)
    ↓
Service queries Firestore:
    - Collection: users/{userId}/payments
    - Where: status == "succeeded"
    ↓
Firestore returns array of payment docs
    ↓
Component renders table with:
    - Date (from timestamp)
    - Amount (formatted with formatPrice())
    - Plan (tierId)
    - Status (succeeded badge)
    - Download link
    ↓
User clicks "Download Invoice"
    ↓
Component calls: stripeService.downloadInvoice(paymentId)
    ↓
Frontend calls: stripe_getInvoice Cloud Function
    ↓
Function calls: stripe.invoices.retrieve(invoiceId)
    ↓
Function returns invoice PDF URL
    ↓
window.open(pdfUrl) opens in new tab
    ↓
User downloads PDF invoice
```

---

## Component Relationships

```
┌─────────────────────────────────────────────────────┐
│            Main App Component                       │
└──────────────┬──────────────────────────────────────┘
               │
       ┌───────┴────────┬─────────────────┐
       │                │                 │
       ▼                ▼                 ▼
┌─────────────┐  ┌──────────────┐  ┌──────────────┐
│   Pricing   │  │  Settings    │  │   Account    │
│   Page      │  │  Page        │  │   Page       │
└──────┬──────┘  └──────┬───────┘  └──────┬───────┘
       │                │                 │
       ▼                ▼                 ▼
┌──────────────────────────────────────────────────┐
│      StripePaymentContainer                      │
│      (Wraps with Stripe Provider)                │
└──────┬───────────────────────────┬───────────────┘
       │                           │
       ▼                           ▼
┌─────────────────────┐   ┌────────────────────────┐
│ SubscriptionUpgrade │   │ CardPaymentForm        │
│ Component           │   │ (with Stripe element)  │
├─────────────────────┤   ├────────────────────────┤
│ - Tier selector     │   │ - Input fields         │
│ - Upgrade button    │   │ - Card element         │
│ - Price comparison  │   │ - Error messages       │
└──────┬──────────────┘   └──────┬─────────────────┘
       │                         │
       ▼                         ▼
   updateSubscription()    confirmPayment()
       │                         │
       └──────────┬──────────────┘
                  │
                  ▼
        ┌──────────────────────┐
        │  stripeService.dart  │
        └──────┬───────────────┘
               │
               ▼
    ┌──────────────────────────────┐
    │  Firebase Cloud Functions    │
    │  stripe_createPaymentIntent  │
    │  stripe_confirmPayment       │
    │  stripe_updateSubscription   │
    └──────────┬───────────────────┘
               │
               ▼
        ┌──────────────────────┐
        │   Stripe API         │
        │   stripe.com         │
        └──────────┬───────────┘
               │
               ▼
        ┌──────────────────────┐
        │  Firestore           │
        │  (Payment records)    │
        └──────────────────────┘
```

---

## Security Flow

```
┌─────────────────────────────────────────────────┐
│  User's Browser (Public)                        │
│  - Contains: Public Key (pk_test_...)           │
│  - Cannot contain: Secret Key (sk_)             │
└────────────────┬────────────────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
    ▼                         ▼
┌──────────────┐    ┌───────────────────┐
│ Stripe.js    │    │ Stripe Servers    │
│              │    │ (Encrypted HTTPS) │
└──────────────┘    └───────────────────┘
    ▲                        │
    │                        │
    └────────────┬───────────┘
                 │ (Encrypted)
    ┌────────────┴────────────┐
    │                         │
    ▼                         ▼
┌──────────────┐    ┌───────────────────┐
│ Firebase     │    │ Firebase Cloud    │
│ Frontend App │    │ Functions         │
└──────────────┘    │ (Secret Key)      │
                    │ (Webhook Secret)  │
                    └───────┬───────────┘
                            │
                ┌───────────┴────────────┐
                │                        │
                ▼                        ▼
        ┌────────────────┐    ┌──────────────────┐
        │  Stripe API    │    │  Firestore       │
        │  (Encrypted)   │    │  (Rules enforce  │
        │                │    │   user ownership)│
        └────────────────┘    └──────────────────┘

Security Principles:
✓ Public key only in frontend
✓ Secret key only in backend
✓ Webhook signature verified
✓ User authentication required
✓ Authorization checks on all data
✓ HTTPS everywhere
✓ Sensitive errors not exposed
```

---

## Deployment Architecture

```
Development:
  ├── Test Stripe Keys (pk_test_, sk_test_)
  ├── Local Firebase Emulator
  ├── Localhost:3000
  └── Test cards (4242 4242...)

Staging:
  ├── Test Stripe Keys
  ├── Firebase Staging Project
  ├── staging.aurasphere.pro
  └── Test webhook secret

Production:
  ├── Live Stripe Keys (pk_live_, sk_live_)
  ├── Firebase Production Project
  ├── aurasphere.pro
  ├── Live webhook secret
  ├── Real credit cards
  ├── Stripe monitoring
  └── Email notifications
```

---

## Summary

The Stripe integration is a **multi-layer system** that:

1. **Frontend Layer**: Secure Stripe Card Element + React components
2. **Service Layer**: 14 functions for all payment operations
3. **Backend Layer**: 11 Cloud Functions + webhook handler
4. **Database Layer**: Firestore stores payments with security rules
5. **External Layer**: Stripe API for payments + webhooks for events

All layers communicate via **secure, authenticated, encrypted channels** with proper error handling and logging.

**Status**: 🟢 Complete and ready for deployment
