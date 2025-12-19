# Firebase → Supabase Migration - Coding Agent Brief

**Target**: Migrate entire AuraSphere Pro from Firebase to Supabase  
**Status**: Ready for agent execution  
**Deliverable**: Full PR with all changes  

---

## What You're Building

Complete replacement of Firebase with Supabase across:
- **Flutter client** (50+ service files, 35+ models, 30+ providers)
- **Cloud Functions** (179 functions → Edge Functions in TypeScript/Deno)
- **Database** (Firestore → PostgreSQL)
- **Auth** (Firebase Auth → Supabase Auth)

---

## Pre-Migration Setup (Human Does This)

Before you start, ensure:

```bash
# 1. Create Supabase project
# Go to https://supabase.com and create new project
# Get SUPABASE_URL and SUPABASE_ANON_KEY from project settings

# 2. Initialize Supabase in repo
cd /workspaces/aura-sphere-pro
supabase init

# 3. Create database schema (run SQL in Supabase dashboard)
# Execute all SQL from MIGRATION_FIREBASE_TO_SUPABASE.md section "PostgreSQL Schema Design"

# 4. Set environment variables
cat > .env.local << EOF
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
EOF
```

---

## Agent Tasks (Phase-by-Phase)

### Phase 1: Foundation & Core Services

#### Task 1.1: Update Dependencies
**Files**: `pubspec.yaml`, `functions/package.json`

```yaml
# pubspec.yaml - REMOVE these:
- firebase_core: ^3.6.0
- firebase_auth: ^5.3.0
- cloud_firestore: ^5.6.12
- firebase_storage: ^12.4.10
- cloud_functions: ^5.6.2
- firebase_dynamic_links: ^6.1.0
- firebase_messaging: ^15.2.10

# ADD these:
- supabase_flutter: ^2.5.0
- supabase: ^2.1.0
- postgrest: ^0.8.0
- realtime_client: ^0.2.0
```

#### Task 1.2: Create Supabase Client Singleton
**File**: `lib/core/supabase_client.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global Supabase client singleton
final supabaseClient = Supabase.instance.client;

/// Initialize Supabase on app startup
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your_anon_key',
    authFlowType: AuthFlowType.implicit,
  );
}
```

#### Task 1.3: Migrate Auth Service
**File**: `lib/services/auth_service.dart`

**Replace entire file with Firebase auth logic converted to Supabase:**
- `signUp()` → create auth user + insert into public.users
- `signIn()` → use Supabase auth
- `signOut()` → use Supabase auth
- `getCurrentUser()` → `_supabase.auth.currentUser`

**Refer to example**: `lib/services/user_service_supabase.dart`

#### Task 1.4: Migrate User Service
**File**: `lib/services/user_service.dart`

**Replace with Supabase version**:
- Get/update user profiles from public.users table
- Watch user changes via stream()
- Manage AuraToken balance
- Refer to: `lib/services/user_service_supabase.dart` (template)

#### Task 1.5: Migrate Invoice Service
**File**: `lib/services/invoice/invoice_service.dart`

**Replace with Supabase version**:
- CRUD operations on invoices + invoice_items tables
- Real-time watching via stream(primaryKey: ['id'])
- Query helpers: getByStatus, getOverdue, etc.
- Refer to: `lib/services/invoice_service_supabase.dart` (template)

#### Task 1.6: Migrate Expense Service
**File**: `lib/services/expense_service.dart`

**Replace with Supabase version**:
- CRUD on expenses table
- Status transitions: pending → approved → reimbursed
- Category grouping
- Refer to: `lib/services/expense_service_supabase.dart` (template)

#### Task 1.7: Migrate Client Service
**File**: `lib/services/client_service.dart`

**Replace with Supabase version**:
- CRUD on clients table
- Fetch by user_id
- Real-time updates via stream()
- Refer to pattern from invoice service

---

### Phase 2: Update Models (Naming Convention)

**Rule**: Change Firestore field names to PostgreSQL snake_case

#### Models to Update (35 files)

For each model in `lib/models/`:

```dart
// BEFORE (Firestore)
class Invoice {
  final String userId;
  final String invoiceNumber;
  
  factory Invoice.fromJson(Map json) {
    return Invoice(
      userId: json['userId'],
      invoiceNumber: json['invoiceNumber'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'invoiceNumber': invoiceNumber,
    };
  }
}

// AFTER (PostgreSQL)
class Invoice {
  final String userId;
  final String invoiceNumber;
  
  factory Invoice.fromJson(Map json) {
    return Invoice(
      userId: json['user_id'],           // ← snake_case
      invoiceNumber: json['invoice_number'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,                 // ← match DB columns
      'invoice_number': invoiceNumber,
    };
  }
}
```

**Models to Update**:
- `invoice_model.dart` ✓ (template ready)
- `expense_model.dart` ✓ (template ready)
- `user_model.dart` ✓ (template ready)
- `client_model.dart` - apply same pattern
- `deal_model.dart` - apply same pattern
- `lead_model.dart` - apply same pattern
- `task_model.dart` - apply same pattern
- `supplier_model.dart` - apply same pattern
- `purchase_order.dart` - apply same pattern
- `inventory_item_model.dart` - apply same pattern
- `audit_entry.dart` - apply same pattern
- All others... (systematically update each)

**Key Changes for All Models**:
- Firestore: `userId` → PostgreSQL: `user_id`
- Firestore: `createdAt` → PostgreSQL: `created_at` (parse as DateTime)
- Firestore: `status` → PostgreSQL: `status` (stay as string, not enum)
- Nested objects: Don't embed in toJson; load separately via jointure

---

### Phase 3: Update Providers (State Management)

**Pattern**: Replace Firestore `.snapshots()` with Supabase `.stream()`

#### For Each Provider File

```dart
// BEFORE
class InvoiceProvider extends ChangeNotifier {
  final _svc = InvoiceService();
  List<Invoice> invoices = [];

  void startWatching(String userId) {
    _watchSub = _svc.watchInvoices(userId).listen((list) {
      invoices = list;
      notifyListeners();
    });
  }
}

// AFTER (same code, but service returns Supabase stream)
class InvoiceProvider extends ChangeNotifier {
  final _svc = InvoiceService();
  List<Invoice> invoices = [];

  void startWatching(String userId) {
    // Service now returns Supabase stream instead of Firestore
    _watchSub = _svc.watchInvoices(userId).listen((list) {
      invoices = list;
      notifyListeners();
    });
  }
}
```

**Providers to Update** (~30 files):
- All in `lib/providers/` directory
- Logic stays mostly the same; just service calls change

---

### Phase 4: Remaining Service Files

**Priority Order** (follow this sequence):

**Priority 1 (Week 2)**:
- `deal_service.dart` → deals table
- `lead_service.dart` → leads table
- `task_service.dart` → tasks table
- `crm_service.dart` → aggregations from deals/leads/tasks

**Priority 2 (Week 2-3)**:
- `finance_dashboard_service.dart` → query finance_summary table
- `finance_goals_service.dart` → no database change (reference only)
- `contact_service.dart` → contacts table (if exists)

**Priority 3 (Week 3)**:
- `inventory_service.dart` → inventory table
- `supplier_service.dart` → suppliers table
- `purchase_order_service.dart` → purchase_orders table

**Priority 4 (Week 3)**:
- `audit_service.dart` → audit_logs table
- `notification_service.dart` → notifications table
- `notification_audit_service.dart` → notification tracking

**Don't Change** (External APIs stay the same):
- `stripe_service.dart` - Stripe integration unchanged
- `email_service.dart` - SendGrid unchanged
- `payment_service.dart` - Payment logic unchanged
- `ocr_service.dart` - Vision API unchanged
- `ai_service.dart` / `finance_coach_service.dart` - OpenAI unchanged

---

### Phase 5: Cloud Functions → Edge Functions

**This is a separate codebase rewrite**:

```bash
# Create Edge Functions directory
mkdir -p supabase/functions

# Each function goes into: supabase/functions/{function-name}/index.ts
```

**Example Pattern** (for each of 179 functions):

```typescript
// BEFORE: functions/src/invoices/generateInvoicePdf.ts (Firebase)
import * as functions from 'firebase-functions';

export const generateInvoicePdf = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) throw new Error('Unauthorized');
    const { invoiceId } = data;
    // ... logic
  }
);

// AFTER: supabase/functions/generate-invoice-pdf/index.ts (Supabase Edge)
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

serve(async (req: Request) => {
  const authHeader = req.headers.get('Authorization')?.split(' ')[1];
  if (!authHeader) return new Response('Unauthorized', { status: 401 });

  const { data: user } = await supabase.auth.getUser(authHeader);
  if (!user) return new Response('Unauthorized', { status: 401 });

  const { invoiceId } = await req.json();
  // ... logic

  return new Response(JSON.stringify({ pdfUrl: '...' }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

**Function Categories** (from `functions/src/index.ts`):
- `ai/` → Generate AI responses (OpenAI wrapper)
- `invoices/` → PDF generation, email
- `expenses/` → Approval workflows
- `crm/` → Lead scoring, insights
- `finance/` → Dashboard calculations
- `payments/` → Stripe webhooks
- `ocr/` → Receipt scanning
- `notifications/` → Email/SMS/push
- `auth/` → User creation hooks
- Others... (179 total)

**Strategy**: 
1. Migrate highest-impact functions first (payment, invoice generation)
2. Group by domain and migrate in parallel
3. Keep external API calls (OpenAI, Stripe, Vision) exactly the same

---

### Phase 6: Calling Edge Functions from Flutter

**Update all function invocations**:

```dart
// BEFORE (Firebase)
final result = await FirebaseFunctions.instance
    .httpsCallable('generateInvoicePdf')
    .call({'invoiceId': id});

// AFTER (Supabase)
final result = await supabase.functions.invoke(
  'generate-invoice-pdf',
  body: {'invoiceId': id},
);
```

**Files to Update**:
- All files that call `FirebaseFunctions.instance.httpsCallable()`
- Search codebase for `httpsCallable` and replace all

---

### Phase 7: Storage Migration

```dart
// BEFORE (Firebase)
final storageRef = FirebaseStorage.instance.ref();
await storageRef
    .child('receipts/$userId/$fileId')
    .putFile(file);
final url = await storageRef
    .child('receipts/$userId/$fileId')
    .getDownloadURL();

// AFTER (Supabase)
await supabase.storage
    .from('receipts')
    .upload('$userId/$fileId', file);
final url = supabase.storage
    .from('receipts')
    .getPublicUrl('$userId/$fileId');
```

**Buckets** (created in Phase 1):
- `receipts/` - Receipt images
- `invoice_pdfs/` - Generated PDFs
- `profile_images/` - User avatars
- `documents/` - Document uploads

---

### Phase 8: Remove Firebase Code

**Delete**:
- `functions/` (entire directory - replaced by supabase/functions/)
- `lib/services/firebase/firestore_service.dart`
- `firebase.json`
- `firestore.rules`
- `firestore.indexes.json`
- `storage.rules`

**Update**:
- `.gitignore` - keep Firebase config files out
- Remove Firebase imports from all files

---

## Testing Strategy

### Unit Tests
```dart
// Mock Supabase responses
test('createInvoice returns correct Invoice', () async {
  // Mock: supabase.from('invoices').insert()
  // Verify: correct data structure returned
});
```

### Integration Tests
```dart
// Test full workflows
test('User can create and pay invoice', () async {
  // 1. Sign up
  // 2. Create invoice
  // 3. Mark as paid
  // 4. Verify in list
});
```

### RLS Policy Testing
```sql
-- Verify users can only access their own data
SELECT * FROM invoices WHERE user_id != auth.uid(); -- Should return 0 rows
```

---

## Success Criteria

- [x] All Firebase dependencies removed
- [x] All services use Supabase
- [x] All models use PostgreSQL field names
- [x] All providers work with Supabase streams
- [x] All Edge Functions deployed
- [x] Auth flows work
- [x] Real-time updates work
- [x] Storage uploads work
- [x] All 35 tables populated
- [x] RLS policies enforced
- [x] Integration tests pass
- [x] No Firebase code in codebase

---

## Execution Order

1. **Day 1-2**: Dependencies + Supabase client + Auth
2. **Day 3-4**: Core services (User, Invoice, Expense, Client)
3. **Day 5-7**: All other services
4. **Day 8-10**: Update all models
5. **Day 11-12**: Update all providers
6. **Day 13-18**: Edge Functions (parallel by domain)
7. **Day 19-20**: Function invocation updates
8. **Day 21-22**: Storage migration
9. **Day 23-24**: Testing & cleanup
10. **Day 25**: Final deployment

---

## File Manifest

### Created (Templates Provided)
- ✅ `lib/services/user_service_supabase.dart`
- ✅ `lib/services/invoice_service_supabase.dart`
- ✅ `lib/services/expense_service_supabase.dart`
- ✅ `lib/core/supabase_client.dart` (create)

### To Create
- `supabase/` directory structure
- 179 Edge Functions
- Updated auth service

### To Modify
- 50+ service files (replace Firebase with Supabase)
- 35+ model files (snake_case naming)
- 30+ provider files (use new services)
- `pubspec.yaml` (dependencies)
- `functions/package.json` (for any shared utilities)

### To Delete
- `functions/` directory
- `firebase.json`
- `firestore.rules`
- All Firebase-specific configs

---

## References

- **Full Schema**: `MIGRATION_FIREBASE_TO_SUPABASE.md`
- **Setup Guide**: `docs/setup.md` (update for Supabase)
- **Supabase Docs**: https://supabase.com/docs
- **Supabase Flutter**: https://supabase.com/docs/reference/flutter

---

## Approval Checklist

Before marking complete, verify:

- [ ] All tests pass
- [ ] No Firebase imports remain
- [ ] All services migrated
- [ ] All models use PostgreSQL naming
- [ ] All providers updated
- [ ] All functions as Edge Functions
- [ ] Storage working
- [ ] Auth flows working
- [ ] Real-time subscriptions working
- [ ] Documentation updated
- [ ] `.env` configured
- [ ] Supabase project deployed

---

**Ready to Execute**: Once human confirms Supabase project created, you can begin.

