# Firebase → Supabase Full Migration Specification

**Date**: December 2025  
**Scope**: Complete migration of AuraSphere Pro from Firebase to Supabase  
**Status**: Pre-Migration Planning  

---

## Table of Contents
1. [Overview](#overview)
2. [PostgreSQL Schema Design](#postgresql-schema-design)
3. [Dependency Changes](#dependency-changes)
4. [Service Layer Migration Patterns](#service-layer-migration-patterns)
5. [Model Migration Patterns](#model-migration-patterns)
6. [Authentication Migration](#authentication-migration)
7. [Cloud Functions → Edge Functions](#cloud-functions--edge-functions)
8. [Storage Migration](#storage-migration)
9. [Security & RLS Policies](#security--rls-policies)
10. [Implementation Priority](#implementation-priority)

---

## Overview

### Current Architecture
- **Client**: Flutter (lib/)
- **Database**: Firestore (NoSQL, document-based)
- **Backend**: Firebase Cloud Functions (Node.js 18)
- **Auth**: Firebase Authentication
- **Storage**: Firebase Cloud Storage
- **Config**: firebase.json, .env

### Target Architecture
- **Client**: Flutter (lib/) - minimal changes
- **Database**: PostgreSQL via Supabase
- **Backend**: Supabase Edge Functions (Deno)
- **Auth**: Supabase Authentication (PostgreSQL-backed)
- **Storage**: Supabase Storage (S3-compatible)
- **Config**: supabase.json, .env

### Key Differences
| Aspect | Firebase | Supabase |
|--------|----------|---------|
| Database Model | NoSQL (docs) | SQL (tables) |
| Queries | Limited, client-side | Full SQL, server-side |
| Real-time | Firestore Listeners | PostgreSQL Realtime |
| Auth | Proprietary | Supabase Auth (open-source) |
| Functions | Cloud Functions | Edge Functions (Deno) |
| Scalability | Horizontal | Vertical (but good) |
| Cost | Pay-per-operation | Pay-per-row |

---

## PostgreSQL Schema Design

### Core Tables (Denormalization Strategy)

```sql
-- Users (extends Supabase auth)
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  business_id UUID,
  aura_tokens BIGINT DEFAULT 0,
  timezone TEXT DEFAULT 'UTC',
  locale TEXT DEFAULT 'en',
  role TEXT DEFAULT 'user' CHECK (role IN ('admin', 'manager', 'accountant', 'sales', 'support', 'viewer', 'user')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Clients
CREATE TABLE public.clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  company TEXT,
  address TEXT,
  assigned_to UUID REFERENCES public.users(id),
  ai_score NUMERIC(5,2) DEFAULT 0,
  ai_summary TEXT,
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, name)
);

-- Invoices
CREATE TABLE public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  invoice_number TEXT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'viewed', 'paid', 'overdue', 'cancelled', 'refunded')),
  payment_status TEXT DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid', 'partially_paid')),
  issue_date DATE NOT NULL,
  due_date DATE NOT NULL,
  paid_at TIMESTAMP WITH TIME ZONE,
  paid_amount DECIMAL(12,2),
  paid_currency TEXT,
  payment_verified BOOLEAN DEFAULT FALSE,
  last_payment_intent_id TEXT,
  branding_template TEXT DEFAULT 'classic',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, invoice_number)
);

-- Invoice Items
CREATE TABLE public.invoice_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity NUMERIC(10,2) NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  vat_rate NUMERIC(5,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Expenses
CREATE TABLE public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0 AND amount <= 100000),
  currency TEXT DEFAULT 'USD',
  vendor TEXT NOT NULL,
  category TEXT CHECK (category IN ('travel', 'meals', 'office_supplies', 'equipment', 'software', 'marketing', 'other')),
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'reimbursed', 'archived')),
  receipt_url TEXT,
  items TEXT[] NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Deals (CRM)
CREATE TABLE public.deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  amount DECIMAL(12,2),
  currency TEXT DEFAULT 'USD',
  stage TEXT NOT NULL DEFAULT 'prospect' CHECK (stage IN ('prospect', 'qualified', 'proposal', 'negotiation', 'won', 'lost')),
  probability NUMERIC(5,2) DEFAULT 0,
  description TEXT,
  close_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Leads
CREATE TABLE public.leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  company TEXT,
  status TEXT DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'qualified', 'converted', 'lost')),
  source TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tasks
CREATE TABLE public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed', 'cancelled')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  assigned_to UUID REFERENCES public.users(id),
  related_expense_id UUID REFERENCES public.expenses(id),
  completed_at TIMESTAMP WITH TIME ZONE,
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inventory
CREATE TABLE public.inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  item TEXT NOT NULL,
  quantity NUMERIC(10,2) NOT NULL,
  cost DECIMAL(12,2),
  sku TEXT,
  category TEXT,
  supplier TEXT,
  location TEXT,
  reorder_level NUMERIC(10,2),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Suppliers
CREATE TABLE public.suppliers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  payment_terms TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, name)
);

-- Purchase Orders
CREATE TABLE public.purchase_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  supplier_id UUID REFERENCES public.suppliers(id) ON DELETE SET NULL,
  po_number TEXT NOT NULL,
  amount DECIMAL(12,2),
  currency TEXT DEFAULT 'USD',
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'confirmed', 'received', 'cancelled')),
  items JSONB,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, po_number)
);

-- Finance Summary (Denormalized for performance)
CREATE TABLE public.finance_summary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  total_revenue DECIMAL(12,2) DEFAULT 0,
  total_expenses DECIMAL(12,2) DEFAULT 0,
  net_income DECIMAL(12,2) DEFAULT 0,
  currency TEXT DEFAULT 'USD',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, period_start, period_end)
);

-- Audit Logs
CREATE TABLE public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  changes JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AuraToken Transactions
CREATE TABLE public.aura_token_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount BIGINT NOT NULL,
  reason TEXT NOT NULL,
  balance_after BIGINT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT,
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Indexes
```sql
-- Frequently queried
CREATE INDEX idx_clients_user_id ON public.clients(user_id);
CREATE INDEX idx_invoices_user_id ON public.invoices(user_id);
CREATE INDEX idx_invoices_client_id ON public.invoices(client_id);
CREATE INDEX idx_invoices_status ON public.invoices(status);
CREATE INDEX idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX idx_deals_user_id ON public.deals(user_id);
CREATE INDEX idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX idx_audit_logs_user_id ON public.audit_logs(user_id);
```

---

## Dependency Changes

### Flutter (pubspec.yaml)

#### Remove
```yaml
# Firebase dependencies
firebase_core: ^3.6.0
firebase_auth: ^5.3.0
cloud_firestore: ^5.6.12
firebase_storage: ^12.4.10
cloud_functions: ^5.6.2
firebase_dynamic_links: ^6.1.0
firebase_messaging: ^15.2.10
```

#### Add
```yaml
# Supabase
supabase_flutter: ^2.5.0
supabase: ^2.1.0
postgrest: ^0.8.0

# Real-time and Edge Functions
realtime_client: ^0.2.0

# Push notifications (Firebase is optional now, but Supabase can use it)
firebase_messaging: ^15.2.10  # Optional for push

# Additional utilities
uuid: ^4.0.0
```

### Node.js Functions (package.json)

#### Remove
```json
"firebase-admin": "^12.7.0",
"firebase-functions": "^4.9.0"
```

#### Add
```json
"@supabase/supabase-js": "^2.38.0",
"@supabase/functions-js": "^2.1.0",
"deno": "latest"  // For Edge Functions
```

---

## Service Layer Migration Patterns

### Pattern 1: Service Conversion Template

#### Before (Firebase Service)
```dart
// lib/services/invoice_service.dart
class InvoiceService {
  final firestore = FirebaseFirestore.instance;

  Future<Invoice> getInvoice(String id) async {
    final doc = await firestore
        .collection('invoices')
        .doc(id)
        .get();
    return Invoice.fromJson(doc.data()!);
  }

  Stream<List<Invoice>> watchInvoices(String userId) {
    return firestore
        .collection('invoices')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Invoice.fromJson(doc.data()))
            .toList());
  }

  Future<void> createInvoice(Invoice invoice) async {
    await firestore
        .collection('invoices')
        .doc(invoice.id)
        .set(invoice.toJson());
  }
}
```

#### After (Supabase Service)
```dart
// lib/services/invoice_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoiceService {
  final supabase = Supabase.instance.client;

  Future<Invoice> getInvoice(String id) async {
    final data = await supabase
        .from('invoices')
        .select()
        .eq('id', id)
        .single();
    return Invoice.fromJson(data);
  }

  Stream<List<Invoice>> watchInvoices(String userId) {
    return supabase
        .from('invoices')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((list) => list
            .map((json) => Invoice.fromJson(json))
            .toList());
  }

  Future<void> createInvoice(Invoice invoice) async {
    await supabase
        .from('invoices')
        .insert(invoice.toJson());
  }
}
```

### Pattern 2: Migration Path for All Services

**Priority 1 (Core - Week 1)**
- `user_service.dart` → Auth + users table
- `invoice_service.dart` → Invoices + Items
- `expense_service.dart` → Expenses
- `client_service.dart` → Clients

**Priority 2 (Business Logic - Week 2)**
- `deal_service.dart` → Deals
- `task_service.dart` → Tasks
- `crm_service.dart` → CRM aggregations
- `finance_service.dart` → Finance Summary

**Priority 3 (Supporting - Week 3)**
- `inventory_service.dart` → Inventory
- `supplier_service.dart` → Suppliers
- `purchase_order_service.dart` → Purchase Orders
- `audit_service.dart` → Audit Logs

**Priority 4 (External - Week 4)**
- `payment_service.dart` → No change needed (Stripe integration stays)
- `email_service.dart` → No change needed (SendGrid stays)
- `ai_service.dart` → No change needed (OpenAI stays)
- `ocr_service.dart` → No change needed (Vision API stays)

---

## Model Migration Patterns

### Before (Firestore Model)
```dart
class Invoice {
  final String id;
  final String userId;
  final String invoiceNumber;
  final double amount;
  final DateTime issueDate;
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.userId,
    required this.invoiceNumber,
    required this.amount,
    required this.issueDate,
    required this.items,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      userId: json['userId'],
      invoiceNumber: json['invoiceNumber'],
      amount: json['amount'].toDouble(),
      issueDate: _parseDateTime(json['issueDate']),
      items: (json['items'] as List)
          .map((i) => InvoiceItem.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'invoiceNumber': invoiceNumber,
      'amount': amount,
      'issueDate': issueDate.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
```

### After (PostgreSQL Model)
```dart
class Invoice {
  final String id;
  final String userId;
  final String invoiceNumber;
  final double amount;
  final String currency;
  final String status;
  final DateTime issueDate;
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.userId,
    required this.invoiceNumber,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.issueDate,
    required this.items,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      userId: json['user_id'],  // ← SQL uses snake_case
      invoiceNumber: json['invoice_number'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'draft',
      issueDate: DateTime.parse(json['issue_date']),  // ← PostgreSQL returns ISO strings
      items: [],  // Load separately via jointure if needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,  // Match DB column names
      'invoice_number': invoiceNumber,
      'amount': amount,
      'currency': currency,
      'status': status,
      'issue_date': issueDate.toIso8601String(),
      // Don't include items in top-level JSON
    };
  }
}
```

### Key Model Changes
- **Naming**: `userId` → `user_id` (match SQL column names)
- **Types**: TIMESTAMP is String in JSON, parse with `DateTime.parse()`
- **Nested Objects**: Load separately (items via junction table, not embedded)
- **Enum Strings**: Status fields are CHECK constraints

---

## Authentication Migration

### Firebase Auth → Supabase Auth

#### Before
```dart
// lib/services/auth_service.dart
class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
```

#### After
```dart
// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signUp(String email, String password) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    // Also create user profile in public.users table
    await _supabase.from('users').insert({
      'id': _supabase.auth.currentUser!.id,
      'email': email,
    });
  }

  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // New: Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final userId = _supabase.auth.currentUser!.id;
    return await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();
  }
}
```

---

## Cloud Functions → Edge Functions

### Function Structure Conversion

#### Before (Firebase Function)
```typescript
// functions/src/invoices/generateInvoicePdf.ts
import * as functions from 'firebase-functions';
import { CallableContext } from 'firebase-functions/v1/https';

export const generateInvoicePdf = functions.https.onCall(
  async (data: any, context: CallableContext) => {
    if (!context.auth) throw new Error('Unauthorized');

    const { invoiceId } = data;
    // ... PDF generation logic
    return { pdfUrl: '...' };
  }
);
```

#### After (Supabase Edge Function)
```typescript
// supabase/functions/generate-invoice-pdf/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

serve(async (req: Request) => {
  // Auth check
  const authHeader = req.headers.get('Authorization')?.split(' ')[1];
  if (!authHeader) {
    return new Response('Unauthorized', { status: 401 });
  }

  const { data: user } = await supabase.auth.getUser(authHeader);
  if (!user) {
    return new Response('Unauthorized', { status: 401 });
  }

  const { invoiceId } = await req.json();
  // ... PDF generation logic
  
  return new Response(JSON.stringify({ pdfUrl: '...' }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

### Calling Edge Functions from Flutter
```dart
// Before (Firebase)
final result = await FirebaseFunctions.instance
    .httpsCallable('generateInvoicePdf')
    .call({'invoiceId': id});

// After (Supabase)
final result = await supabase.functions.invoke(
  'generate-invoice-pdf',
  body: {'invoiceId': id},
);
```

---

## Storage Migration

### Supabase Storage Buckets

```sql
-- Create buckets (via Supabase dashboard or SQL)
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('receipts', 'receipts', false),
  ('invoice_pdfs', 'invoice_pdfs', false),
  ('profile_images', 'profile_images', false),
  ('documents', 'documents', false);
```

### Service Migration
```dart
// Before (Firebase)
final storageRef = FirebaseStorage.instance.ref();
await storageRef.child('receipts/$userId/$fileId').putFile(file);

// After (Supabase)
final fileName = '$userId/$fileId';
await supabase.storage
    .from('receipts')
    .upload(fileName, file);

// Get public URL
final publicUrl = supabase.storage
    .from('receipts')
    .getPublicUrl(fileName);
```

---

## Security & RLS Policies

### Row Level Security (RLS) Policies

```sql
-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
-- ... etc

-- Users can only see their own data
CREATE POLICY "Users can only access own data"
  ON public.users
  FOR ALL
  USING (auth.uid() = id);

-- Invoices: users see only their own
CREATE POLICY "Users can only see own invoices"
  ON public.invoices
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can only insert own invoices"
  ON public.invoices
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can only update own invoices"
  ON public.invoices
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can only delete own invoices"
  ON public.invoices
  FOR DELETE
  USING (auth.uid() = user_id);

-- Apply same pattern to all user-owned tables
```

---

## Implementation Priority

### Phase 1: Foundation (Days 1-3)
1. ✅ Create PostgreSQL schema
2. ✅ Set up Supabase project
3. ✅ Configure RLS policies
4. ✅ Migrate Auth service
5. ✅ Update pubspec.yaml & package.json

### Phase 2: Core Services (Days 4-7)
1. ✅ Migrate User Service
2. ✅ Migrate Invoice Service
3. ✅ Migrate Expense Service
4. ✅ Migrate Client Service
5. ✅ Update Models (4 core models)

### Phase 3: Business Logic (Days 8-12)
1. ✅ Migrate CRM Services (Deals, Leads)
2. ✅ Migrate Task Service
3. ✅ Migrate Finance Services
4. ✅ Migrate remaining models

### Phase 4: Supporting Services (Days 13-16)
1. ✅ Migrate Inventory, Supplier, PO services
2. ✅ Migrate Audit/Notification services
3. ✅ Migrate Storage integration
4. ✅ Update all providers

### Phase 5: Edge Functions (Days 17-21)
1. ✅ Convert 179 Cloud Functions to Edge Functions
2. ✅ Update function calls in client
3. ✅ Test all integrations

### Phase 6: Testing & Cleanup (Days 22-25)
1. ✅ Integration testing
2. ✅ Remove Firebase dependencies
3. ✅ Update documentation
4. ✅ Performance tuning

---

## Files to Delete/Create/Modify

### Delete (Firebase-specific)
- `lib/services/firebase/firestore_service.dart`
- `firebase.json`
- `firestore.rules`
- `firestore.indexes.json`
- `storage.rules`
- `functions/` (entire Cloud Functions)

### Create (Supabase-specific)
- `supabase/` (Edge Functions)
- `supabase.json`
- `lib/core/supabase_client.dart` (singleton)
- `lib/services/supabase/` (base Supabase service)

### Modify (All services/models/providers)
- `lib/services/` (50+ files)
- `lib/models/` (35+ files)
- `lib/providers/` (30+ files)
- `pubspec.yaml`
- `functions/package.json`

---

## Testing Strategy

### Unit Tests
- Test each service's SQL queries
- Mock Supabase responses

### Integration Tests
- Test full user workflows (Auth → Create Invoice → Export)
- RLS policy validation
- Edge Function invocation

### Performance Tests
- Query performance vs Firestore
- Realtime subscription overhead
- Storage access patterns

---

## Rollback Plan

If issues arise:
1. Keep Firebase project running in parallel (read-only mode)
2. Test Supabase thoroughly in staging
3. Implement feature flags to switch backends
4. Gradual rollout: test users → beta users → all users

---

## Estimated Effort
- **Scope**: 35 tables, 50+ services, 30+ models, 179 functions
- **Team**: 2-3 developers
- **Timeline**: 4-6 weeks
- **Cost**: Supabase: ~$25-100/month (vs Firebase: $0-500/month depending on scale)

---

## Next Steps

1. **Review this spec** with the team
2. **Set up Supabase project** (create account, configure)
3. **Hand off to coding agent** with this document
4. **Track progress** via GitHub issues/PRs
5. **Test thoroughly** before launch

