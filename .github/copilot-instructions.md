# AuraSphere Pro — AI Agent Guide

## Big Picture
**Multi-layer SaaS business OS**: Flutter client → Provider state mgmt → Service layer (Firebase + external APIs) → Cloud Functions (Node.js, domain-organized) → Firestore (per-user docs enforce auth via rules).

**Key modules** (each has service + provider pattern):
- **Invoicing**: invoice creation, PDF generation, email delivery, payment tracking → `functions/src/invoices/`, `functions/src/invoice/`, stripe integration
- **CRM**: leads, deals, clients, AI scoring + timeline generation → `functions/src/crm/`
- **Finance**: dashboard, forecasts, tax calculation, multi-currency → `functions/src/finance/`
- **Expenses**: OCR receipt scanning, approval workflows → `functions/src/expenses/`, `functions/src/ocr/`
- **AI & Chat**: finance coach, email generation, insights → `functions/src/ai/`, OpenAI integration
- **AuraToken Economy**: rewards, balances, transactions → `functions/src/auraToken/`

## Daily Workflows

### Setup & Running
```bash
# Full stack
flutter pub get && cd functions && npm install && cd ..
firebase emulators:start  # Runs Auth, Firestore, Functions, Storage locally on ports 9099, 8080, 5001, 9199
flutter run  # Emulator will auto-connect if Firebase config exists in platform folders

# Functions only during development
cd functions && npm run build && npm run serve
```

### Deployment
```bash
# Rules first (no function code needed)
firebase deploy --only firestore:rules,storage:rules
# Then functions
firebase deploy --only functions
# Full deploy (rarely needed)
firebase deploy
```

## Code Conventions

### Flutter (Client-Side)
- **Files**: snake_case (e.g., `invoice_service.dart`, `user_provider.dart`)
- **Types & Classes**: PascalCase (`InvoiceService`, `UserModel`)
- **Members**: private with `_` prefix (`_cache`, `_isLoading`)
- **Models**: always implement `fromJson(Map)` and `toJson()→ Map` (used everywhere in Firestore sync)
  - Constructor must accept `required` fields for all document properties
  - Example pattern in `lib/models/invoice_model.dart`: parse Timestamps via `_parseDateTime()` helper
- **Providers** (state mgmt in `lib/providers/`):
  - Extend `ChangeNotifier` 
  - Wrap async calls: toggle `_isLoading = true` → `await task` → set result → `notifyListeners()` → `_isLoading = false`
  - Example: `InvoiceProvider` watches `InvoiceService.watchInvoices()` stream and notifies on change
  - **Cleanup**: cancel subscriptions in `dispose()`
- **Services** (`lib/services/`) are **repositories**, NOT business logic:
  - Pure Firebase/HTTP wrappers (e.g., `firestore.collection().docs()`, `http.post()`)
  - Return typed models or Streams (e.g., `Future<Invoice>`, `Stream<List<Invoice>>`)
  - No UI side effects; let providers handle loading/error states

### TypeScript (Cloud Functions)
- **File organization**: By domain under `functions/src/{ai,crm,finance,invoice,ocr,...}`
- **Auth check**: Every callable must start with `if (!context.auth) throw Error('Unauthorized')`
- **Error handling**: Always wrap external calls (OpenAI, Vision API, Stripe):
  ```typescript
  try { /* external call */ } catch (error) {
    console.error('Detailed error:', error);
    throw new Error('User-friendly message');
  }
  ```
- **Logging**: Use `functions/src/utils/logger.ts` (structured, queryable in Cloud Logging)
- **Export pattern**: Define function, then export in `functions/src/index.ts` (all callables exposed there)

## Key Integration Points & Data Flows

### OpenAI Chat & Email Generation
- **Callable**: `functions/src/ai/aiAssistant.ts` (or specific domain, e.g., `financeCoach`)
- **Rate limit**: 60 req/min (enforce with Redis if scaling beyond POC)
- **Prompt guidelines**: Keep business-focused; include user context (currency, locale, business type)
- **Cost tracking**: `functions/src/ai/getFinanceCoachCost.ts` logs OpenAI usage

### Receipt OCR → Invoice Workflow
1. Upload receipt → `Storage: receipts/{userId}/{receiptId}` (max 5MB in rules)
2. Trigger `functions/src/ocr/ocrProcessor.ts` (Google Vision API)
3. Vision returns raw text → function calls OpenAI to parse into structured fields
4. Save as `Expense` doc, notify user for approval

### Invoice Lifecycle & Payments
- **Create**: Model built in UI, saved to Firestore → triggers `functions/src/invoice/onInvoiceCreated.ts`
  - Auto-generates PDF via `functions/src/invoices/generateInvoicePdf.ts` (puppeteer + pdf-lib)
  - Auto-assigns to appropriate user role (Finance, Admin) via `functions/src/finance/onDocumentCreateAutoAssign.ts`
- **Payment**: Stripe webhook → `functions/src/payments/` → updates invoice `paymentStatus`, triggers email
- **Overdue**: Scheduled function `markOverdueInvoices` runs daily

### AuraToken Rewards Engine
- **Balance field**: `users.{userId}.auraTokens` (Firestore doc field)
- **Transactions ledger**: `auraTokenTransactions/{userId}/{txnId}` (audit trail)
- **Reward triggers**: `functions/src/auraToken/rewards.ts` (on invoice paid, expense approved, etc.)
- **Shop**: `lib/screens/billing/token_shop_screen.dart` allows purchase of premium features

### Multi-Tenancy & Security
- Every Firestore write enforces `request.auth.uid == document.userId` (or team ownership check)
- All Storage paths nested under `{userId}/` (Storage rules validate path)
- Feature flags in `lib/config/constants.dart > FeatureFlags`: respect before exposing UI (e.g., `cryptoEnabled = false`)

## Patterns to Follow

### Adding a New Feature
1. **Model** → `lib/models/{feature}_model.dart` (with fromJson/toJson)
2. **Service** → `lib/services/{feature}_service.dart` (Firebase reads/writes + business queries)
3. **Provider** → `lib/providers/{feature}_provider.dart` (state, watches service streams)
4. **Screens** → `lib/screens/{feature}/` (consume provider, build UI)
5. **Routes** → Register in `lib/config/app_routes.dart` → add to `AppRoutes` class const, add to `generateRoute()` switch
6. **i18n** → Add strings to `lib/l10n/en.json` (and other locales)

### Adding New Firestore Collection
1. Declare in `lib/config/constants.dart` > `FirestoreCollections`
2. Update `firestore.rules` (add read/write/delete rules enforcing auth ownership)
3. Update `firestore.indexes.json` if complex queries (multi-field composite indexes)
4. Create model + service before touching UI
5. Mirror security rules in backend (callable functions also check `context.auth.uid`)

### Adding Cloud Function
1. Create file in matching domain: `functions/src/{domain}/{functionName}.ts`
2. Implement function signature: `export const functionName = async (data: any, context: CallableContext) => { ... }`
3. Start with auth check: `if (!context.auth) throw Error('Unauthorized')`
4. Export in `functions/src/index.ts` (required to be callable)
5. Call from client via `FunctionsService().callFunction('functionName', params)` or `FirebaseFunctions.instance.httpsCallable('functionName')`

### Testing Locally
- Emulators auto-reload code on save (no manual rebuild needed for functions)
- Test callable via Emulator UI at `http://127.0.0.1:4000` or directly in code using `functions.httpsCallable()`
- Firestore emulator stores data in memory (cleared on restart) — use `firestore-seed-*.json` files to pre-populate if needed

## Security & Secrets

- **Never commit**: `.env`, `google-services.json`, `GoogleService-Info.plist`, API keys
- **Storage**: Use GitHub Secrets for CI/CD; Firebase console for function env vars (`.runtimeconfig.json`)
- **File limits**: 5MB receipts, 10MB general, 2MB images (enforced in Storage rules)
- **Document structure**: Always persist `userId` field on every Firestore doc before write; security rules validate
- **Callable auth**: Every `context.auth` check is mandatory; no bypass for "internal" calls (functions run under service account in prod, not user context)

## Reference Docs
- [docs/setup.md](../docs/setup.md) — Firebase config, emulator setup, env vars
- [docs/architecture.md](../docs/architecture.md) — System design, layer breakdown, Firestore schema
- [lib/config/constants.dart](../lib/config/constants.dart) — All collection names, feature flags, endpoints
- [functions/src/index.ts](../functions/src/index.ts) — All exported callable functions (start here when unsure what exists)
- [firestore.rules](../firestore.rules) — Security & data access rules
- [firebase.json](../firebase.json) — Firebase config, emulator ports, deploy targets

**When stuck**: Search the domain folder in `functions/src/` first, then check existing service/provider pairs.
