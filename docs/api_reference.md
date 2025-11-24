# API Reference

## Firebase Cloud Functions

All functions are callable HTTPS functions accessible via `FunctionsService`.

### Authentication

All functions require authentication. Pass the Firebase ID token in the request.

### AI Functions

#### `chatCompletion`
AI-powered chat assistant for business queries.

**Parameters:**
```typescript
{
  prompt: string  // User's question or prompt
}
```

**Returns:**
```typescript
{
  response: string  // AI-generated response
}
```

**Example:**
```dart
final response = await FunctionsService().callFunction('chatCompletion', {
  'prompt': 'Help me categorize this expense',
});
```

---

### OCR Functions

#### `processReceipt`
Extract expense data from receipt images using Google Vision AI.

**Parameters:**
```typescript
{
  imageUrl: string  // Firebase Storage URL of receipt image
}
```

**Returns:**
```typescript
{
  amount: number,
  date: string,
  merchant: string,
  category: string,
  description: string
}
```

---

### Billing Functions

#### `createSubscription`
Create a new Stripe subscription for a user.

**Parameters:**
```typescript
{
  userId: string,
  plan: 'free' | 'pro' | 'enterprise'
}
```

**Returns:**
```typescript
{
  subscriptionId: string,
  status: string,
  plan: string
}
```

#### `getSubscriptionStatus`
Retrieve current subscription status.

**Parameters:**
```typescript
{
  userId: string
}
```

**Returns:**
```typescript
{
  status: 'active' | 'canceled' | 'past_due',
  plan: string,
  expiresAt: string
}
```

---

### AuraToken Functions

#### `getAuraTokenBalance`
Get user's AuraToken balance.

**Parameters:**
```typescript
{
  userId: string
}
```

**Returns:**
```typescript
{
  balance: number
}
```

#### `rewardAuraTokens`
Award tokens to a user for completing actions.

**Parameters:**
```typescript
{
  userId: string,
  amount: number,
  reason: string
}
```

**Returns:**
```typescript
{
  success: boolean
}
```

---

### Finance Functions

#### `calculateTax`
Calculate tax for a given amount.

**Parameters:**
```typescript
{
  amount: number,
  country: string,
  state?: string
}
```

**Returns:**
```typescript
{
  amount: number,
  tax: number,
  total: number,
  taxRate: number
}
```

#### `generateInvoice`
Create and send a PDF invoice.

**Parameters:**
```typescript
{
  clientId: string,
  items: Array<{
    description: string,
    quantity: number,
    unitPrice: number
  }>,
  dueDate: string
}
```

**Returns:**
```typescript
{
  invoiceNumber: string,
  status: string,
  pdfUrl: string
}
```

#### `generateKPIs`
Generate key performance indicators for a period.

**Parameters:**
```typescript
{
  userId: string,
  period: 'week' | 'month' | 'quarter' | 'year'
}
```

**Returns:**
```typescript
{
  totalRevenue: number,
  totalExpenses: number,
  profit: number,
  profitMargin: number,
  activeProjects: number,
  completedProjects: number,
  outstandingInvoices: number
}
```

---

## Firestore API

### Collections

- `users` - User profiles
- `expenses` - Expense records
- `invoices` - Invoice documents
- `projects` - Project management
- `crm` - Customer contacts
- `auraTokenTransactions` - Token transaction history

### Security Rules

All collections enforce:
- Authentication required
- User can only access their own data (`userId` field)
- Create operations must set `userId` to authenticated user
- File uploads limited to 5-10MB

---

## Rate Limits

- **OpenAI API**: 60 requests/minute per user
- **Vision API**: 1800 requests/minute
- **Firestore**: 10,000 reads/writes per day (free tier)
- **Functions**: 2,000,000 invocations/month (free tier)

---

## Error Codes

| Code | Description |
|------|-------------|
| `unauthenticated` | User not authenticated |
| `permission-denied` | Insufficient permissions |
| `not-found` | Resource not found |
| `already-exists` | Resource already exists |
| `resource-exhausted` | Quota exceeded |
| `invalid-argument` | Invalid parameters |
| `internal` | Internal server error |
