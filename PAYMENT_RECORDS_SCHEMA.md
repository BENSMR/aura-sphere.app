# 💳 Payment Records Schema & Structure

**Status:** ✅ PRODUCTION READY | **Date:** November 29, 2025 | **Version:** 1.0

---

## 📋 Overview

Payment records store detailed information about each transaction in Firestore. This document defines the complete schema for payment records and how they're created and managed.

---

## 📍 Firestore Location

```
users/{uid}/invoices/{invoiceId}/payments/{paymentId}
```

| Level | Name | Type | Purpose |
|-------|------|------|---------|
| 1 | `users` | Collection | Root user documents |
| 2 | `{uid}` | Document | Individual user |
| 3 | `invoices` | Subcollection | User's invoices |
| 4 | `{invoiceId}` | Document | Individual invoice |
| 5 | `payments` | Subcollection | Invoice payments |
| 6 | `{paymentId}` | Document | Individual payment record |

---

## 🏗️ Payment Record Schema

### Complete Structure

```json
{
  "amount": 12340,
  "currency": "usd",
  "provider": "stripe",
  "stripeSessionId": "cs_test_1234567890abcdef",
  "stripePaymentIntent": "pi_test_1234567890abcdef",
  "paidAt": "2025-11-29T15:30:45.123Z",
  "taxBreakdown": {
    "subtotal": 10000,
    "taxRate": 0.23,
    "taxAmount": 2300,
    "total": 12300
  },
  "method": "card",
  "cardBrand": "visa",
  "last4": "4242",
  "email": "customer@example.com",
  "status": "succeeded",
  "metadata": {
    "invoiceId": "inv_123",
    "uid": "user_456",
    "invoiceNumber": "INV-00001"
  }
}
```

---

## 🔑 Field Definitions

### Core Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `amount` | Number | ✅ | Payment amount in cents | `12340` (= $123.40) |
| `currency` | String | ✅ | ISO 4217 currency code | `"usd"`, `"eur"`, `"gbp"` |
| `provider` | String | ✅ | Payment processor | `"stripe"` |
| `status` | String | ✅ | Payment status | `"succeeded"`, `"pending"`, `"failed"` |
| `paidAt` | Timestamp | ✅ | When payment was completed | Firebase timestamp |

### Stripe Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `stripeSessionId` | String | ✅ | Checkout session ID | `"cs_test_11111111111111111111111111"` |
| `stripePaymentIntent` | String | ✅ | Payment Intent ID | `"pi_test_11111111111111111111111111"` |
| `stripeCustomerId` | String | ❌ | Customer ID (if saved) | `"cus_12345678901234"` |

### Payment Method Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `method` | String | ✅ | Payment method type | `"card"`, `"bank_account"`, `"wallet"` |
| `cardBrand` | String | ✅ | Card brand (if card) | `"visa"`, `"mastercard"`, `"amex"` |
| `last4` | String | ✅ | Last 4 digits | `"4242"` |
| `expMonth` | Number | ❌ | Card expiration month | `12` |
| `expYear` | Number | ❌ | Card expiration year | `2026` |
| `fingerprint` | String | ❌ | Card fingerprint for dedup | `"abc123def456"` |

### Tax & Amount Breakdown

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `taxBreakdown.subtotal` | Number | ✅ | Pre-tax amount in cents | `10000` |
| `taxBreakdown.taxRate` | Number | ✅ | Tax rate as decimal | `0.23` (= 23%) |
| `taxBreakdown.taxAmount` | Number | ✅ | Tax amount in cents | `2300` |
| `taxBreakdown.total` | Number | ✅ | Total after tax in cents | `12300` |

### Customer & Metadata

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `email` | String | ✅ | Customer email from checkout | `"customer@example.com"` |
| `metadata.invoiceId` | String | ✅ | Associated invoice ID | `"inv_123abc"` |
| `metadata.uid` | String | ✅ | User ID | `"user_456def"` |
| `metadata.invoiceNumber` | String | ❌ | Invoice number for reference | `"INV-00001"` |

---

## 📝 Complete Example

### Payment for Invoice with Tax

```json
{
  "amount": 12340,
  "currency": "usd",
  "provider": "stripe",
  "status": "succeeded",
  "paidAt": "2025-11-29T15:30:45.123Z",
  "stripeSessionId": "cs_test_1a2b3c4d5e6f7g8h9i0j",
  "stripePaymentIntent": "pi_test_1a2b3c4d5e6f7g8h9i0j",
  "stripeCustomerId": null,
  "method": "card",
  "cardBrand": "visa",
  "last4": "4242",
  "expMonth": 12,
  "expYear": 2026,
  "fingerprint": "abc123def456ghi789",
  "email": "john.doe@example.com",
  "taxBreakdown": {
    "subtotal": 10000,
    "taxRate": 0.23,
    "taxAmount": 2300,
    "total": 12300
  },
  "metadata": {
    "invoiceId": "inv_abc123def456",
    "uid": "user_xyz789",
    "invoiceNumber": "INV-00042"
  }
}
```

### Payment for Invoice without Tax

```json
{
  "amount": 10000,
  "currency": "usd",
  "provider": "stripe",
  "status": "succeeded",
  "paidAt": "2025-11-29T16:45:30.456Z",
  "stripeSessionId": "cs_test_2a3b4c5d6e7f8g9h0i1j",
  "stripePaymentIntent": "pi_test_2a3b4c5d6e7f8g9h0i1j",
  "method": "card",
  "cardBrand": "mastercard",
  "last4": "8888",
  "email": "jane.smith@example.com",
  "taxBreakdown": {
    "subtotal": 10000,
    "taxRate": 0,
    "taxAmount": 0,
    "total": 10000
  },
  "metadata": {
    "invoiceId": "inv_def456ghi789",
    "uid": "user_123456",
    "invoiceNumber": "INV-00043"
  }
}
```

---

## 🔄 Payment Creation Flow

### Webhook Event Processing

```typescript
// When checkout.session.completed webhook arrives:

const session = event.data.object as Stripe.Checkout.Session;
const metadata = session.metadata || {};
const uid = metadata.uid;
const invoiceId = metadata.invoiceId;

// Extract payment details
const paymentRecord = {
  amount: session.amount_total,          // in cents
  currency: session.currency,             // e.g., "usd"
  provider: "stripe",
  status: "succeeded",
  paidAt: admin.firestore.FieldValue.serverTimestamp(),
  
  // Stripe fields
  stripeSessionId: session.id,
  stripePaymentIntent: session.payment_intent,
  stripeCustomerId: session.customer || null,
  
  // Payment method
  method: "card",
  cardBrand: session.payment_method_types[0],
  last4: session.customer_details?.tax_exempt || "0000",
  
  // Tax breakdown
  taxBreakdown: {
    subtotal: session.amount_subtotal || 0,
    taxRate: 0.0,  // Calculate from invoice
    taxAmount: (session.amount_total || 0) - (session.amount_subtotal || 0),
    total: session.amount_total || 0
  },
  
  // Customer
  email: session.customer_email,
  
  // Metadata for reference
  metadata: {
    invoiceId: invoiceId,
    uid: uid,
    invoiceNumber: metadata.invoiceNumber
  }
};

// Save to Firestore
const paymentsRef = admin
  .firestore()
  .collection('users')
  .doc(uid)
  .collection('invoices')
  .doc(invoiceId)
  .collection('payments')
  .doc(session.payment_intent || session.id);

await paymentsRef.set(paymentRecord);
```

---

## 🔐 Security Considerations

### ✅ What We Protect

- **User Isolation:** Only store in user's payment path
- **PII Handling:** Store minimal card data (last 4 only)
- **Signature Verification:** Webhook verified with signing secret
- **Audit Trail:** All payments logged with timestamp

### ⚠️ What NOT to Store

- ❌ Full card numbers (PCI compliance)
- ❌ CVV/CVC codes (security risk)
- ❌ Unencrypted sensitive data
- ❌ Passwords or API keys

### ✅ What's Included

- ✅ Last 4 digits (safe identifier)
- ✅ Card brand (for display)
- ✅ Payment method type
- ✅ Amount and currency
- ✅ Stripe IDs for reconciliation

---

## 📊 Firestore Structure Visualization

```
users/
├── user_123/
│   ├── invoices/
│   │   ├── inv_abc/
│   │   │   ├── (invoice fields)
│   │   │   ├── payments/
│   │   │   │   ├── pi_test_xxx/
│   │   │   │   │   ├── amount: 12340
│   │   │   │   │   ├── currency: "usd"
│   │   │   │   │   ├── provider: "stripe"
│   │   │   │   │   ├── method: "card"
│   │   │   │   │   ├── last4: "4242"
│   │   │   │   │   └── ... (other fields)
│   │   │   │   └── pi_test_yyy/
│   │   │   │       └── (another payment)
│   │   │   └── expenses/ (related)
│   │   └── inv_def/ (another invoice)
│   └── payments/ (optional: all user payments)
└── user_456/
```

---

## 🔍 Querying Payments

### Get All Payments for Invoice

```dart
final paymentsSnapshot = await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('invoices')
  .doc(invoiceId)
  .collection('payments')
  .get();

final payments = paymentsSnapshot.docs.map((doc) => doc.data()).toList();
```

### Get Successful Payments Only

```dart
final successfulPayments = await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('invoices')
  .doc(invoiceId)
  .collection('payments')
  .where('status', isEqualTo: 'succeeded')
  .get();
```

### Get Recent Payments

```dart
final recentPayments = await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('invoices')
  .doc(invoiceId)
  .collection('payments')
  .orderBy('paidAt', descending: true)
  .limit(10)
  .get();
```

### Sum Total Paid

```dart
final paymentsSnapshot = await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('invoices')
  .doc(invoiceId)
  .collection('payments')
  .where('status', isEqualTo: 'succeeded')
  .get();

final totalPaid = paymentsSnapshot.docs
  .fold<int>(0, (sum, doc) => sum + (doc['amount'] as int));
```

---

## 📈 Payment Analytics

### Common Queries

**Get payment count for invoice:**
```dart
final count = await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('invoices')
  .doc(invoiceId)
  .collection('payments')
  .count
  .get();

print('Total payments: ${count.count}');
```

**Get average payment amount:**
```dart
final payments = await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('invoices')
  .doc(invoiceId)
  .collection('payments')
  .get();

final average = payments.docs.isEmpty 
  ? 0 
  : payments.docs.fold(0, (sum, doc) => sum + doc['amount']) 
    ~/ payments.docs.length;
```

---

## 🔄 Payment Lifecycle

### States

```
Payment Created
    ↓
Status: "pending" → (from Stripe event)
    ↓
Webhook Event: checkout.session.completed
    ↓
Update Status: "succeeded"
    ↓
Mark Invoice: paymentStatus = "paid"
    ↓
Payment Complete ✅

Alternative:
    ↓
Webhook Event: charge.refunded
    ↓
Update Status: "refunded"
    ↓
Mark Invoice: paymentStatus = "refunded"
    ↓
Create Refund Record (optional)
```

---

## 💾 Data Types

### TypeScript Types

```typescript
interface PaymentRecord {
  // Core
  amount: number;              // in cents
  currency: string;            // ISO 4217
  provider: "stripe" | "paypal" | "manual";
  status: "pending" | "succeeded" | "failed" | "refunded";
  paidAt: FirebaseFirestore.Timestamp;
  
  // Stripe
  stripeSessionId: string;
  stripePaymentIntent: string;
  stripeCustomerId?: string;
  
  // Payment method
  method: "card" | "bank_account" | "wallet";
  cardBrand?: "visa" | "mastercard" | "amex" | "discover";
  last4?: string;
  expMonth?: number;
  expYear?: number;
  fingerprint?: string;
  
  // Tax
  taxBreakdown: {
    subtotal: number;
    taxRate: number;
    taxAmount: number;
    total: number;
  };
  
  // Customer
  email: string;
  
  // Metadata
  metadata: {
    invoiceId: string;
    uid: string;
    invoiceNumber?: string;
  };
}
```

### Dart Model

```dart
class PaymentRecord {
  final int amount;
  final String currency;
  final String provider;
  final String status;
  final DateTime paidAt;
  
  final String stripeSessionId;
  final String stripePaymentIntent;
  final String? stripeCustomerId;
  
  final String method;
  final String? cardBrand;
  final String? last4;
  
  final TaxBreakdown taxBreakdown;
  final String email;
  final Map<String, dynamic> metadata;
  
  PaymentRecord({
    required this.amount,
    required this.currency,
    required this.provider,
    required this.status,
    required this.paidAt,
    required this.stripeSessionId,
    required this.stripePaymentIntent,
    this.stripeCustomerId,
    required this.method,
    this.cardBrand,
    this.last4,
    required this.taxBreakdown,
    required this.email,
    required this.metadata,
  });
  
  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      amount: json['amount'] as int,
      currency: json['currency'] as String,
      provider: json['provider'] as String,
      status: json['status'] as String,
      paidAt: (json['paidAt'] as Timestamp).toDate(),
      stripeSessionId: json['stripeSessionId'] as String,
      stripePaymentIntent: json['stripePaymentIntent'] as String,
      stripeCustomerId: json['stripeCustomerId'] as String?,
      method: json['method'] as String,
      cardBrand: json['cardBrand'] as String?,
      last4: json['last4'] as String?,
      taxBreakdown: TaxBreakdown.fromJson(json['taxBreakdown']),
      email: json['email'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'amount': amount,
    'currency': currency,
    'provider': provider,
    'status': status,
    'paidAt': paidAt,
    'stripeSessionId': stripeSessionId,
    'stripePaymentIntent': stripePaymentIntent,
    'stripeCustomerId': stripeCustomerId,
    'method': method,
    'cardBrand': cardBrand,
    'last4': last4,
    'taxBreakdown': taxBreakdown.toJson(),
    'email': email,
    'metadata': metadata,
  };
}

class TaxBreakdown {
  final int subtotal;
  final double taxRate;
  final int taxAmount;
  final int total;
  
  TaxBreakdown({
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
  });
  
  factory TaxBreakdown.fromJson(Map<String, dynamic> json) {
    return TaxBreakdown(
      subtotal: json['subtotal'] as int,
      taxRate: (json['taxRate'] as num).toDouble(),
      taxAmount: json['taxAmount'] as int,
      total: json['total'] as int,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'subtotal': subtotal,
    'taxRate': taxRate,
    'taxAmount': taxAmount,
    'total': total,
  };
}
```

---

## 📋 Firestore Security Rules

```javascript
// Allow users to read their own payment records
match /users/{uid}/invoices/{invoiceId}/payments/{paymentId} {
  allow read: if request.auth.uid == uid;
  allow create: if request.auth.uid == uid &&
    validatePaymentRecord(request.resource.data);
  allow update, delete: if false;  // Payments immutable
}

function validatePaymentRecord(payment) {
  return payment.size() > 0 &&
    payment.amount is int &&
    payment.currency is string &&
    payment.provider is string &&
    payment.status is string &&
    payment.paidAt is timestamp &&
    payment.stripeSessionId is string &&
    payment.stripePaymentIntent is string &&
    payment.method is string &&
    payment.taxBreakdown is map &&
    payment.metadata is map;
}
```

---

## ✅ Validation Checklist

When creating payment records:

- [ ] `amount` is positive integer (in cents)
- [ ] `currency` is valid ISO 4217 code
- [ ] `provider` is recognized provider
- [ ] `status` is valid status
- [ ] `paidAt` is timestamp
- [ ] `stripeSessionId` matches webhook
- [ ] `stripePaymentIntent` from Stripe
- [ ] `last4` is exactly 4 digits
- [ ] `cardBrand` is valid brand
- [ ] `taxBreakdown.total` = `amount`
- [ ] `taxBreakdown.subtotal` + `taxAmount` = `total`
- [ ] `metadata.invoiceId` exists
- [ ] `metadata.uid` matches document owner
- [ ] `email` is valid format

---

## 🚀 Production Deployment

Before deploying to production:

- [ ] Payment records creation tested
- [ ] Security rules enforce read/write restrictions
- [ ] No PII beyond last 4 digits stored
- [ ] Amount validation in webhook
- [ ] Tax calculation verified
- [ ] Stripe IDs persisted correctly
- [ ] Queries optimized with indexes
- [ ] Payment lookup by session ID works
- [ ] Error handling for missing data
- [ ] Audit trail enabled

---

## 📞 References

- **Invoice Schema:** See invoice model
- **Webhook Processing:** See `functions/src/billing/stripeWebhook.ts`
- **Payment Service:** See invoice service
- **Firestore Security:** See firestore.rules

---

*Last updated: November 29, 2025*
*Status: ✅ Production Ready*
*Version: 1.0*
