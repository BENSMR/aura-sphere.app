# AuraSphere Pro — AI Agent Guide

## Big Picture
- Flutter multi-layer app (screens → providers → services → Firebase) with feature folders for Expenses, CRM, Projects, Invoices, AI chat.
- Firebase backend handled via TypeScript Cloud Functions split by domain under `functions/src/{ai,ocr,billing,finance,crm,projects,auraToken}`.
- Firestore stores per-user data (collections declared in `lib/config/constants.dart`); security rules enforce `request.auth.uid` ownership and Storage limits.

## Daily Workflows
- Install deps: `flutter pub get && (cd functions && npm install)`.
- Run app: `flutter run` (emulators need Firebase config files in platform folders).
- Local backend: `firebase emulators:start` (functions build via `npm run build`).
- Deploy bits: `firebase deploy --only firestore:rules,storage:rules,functions` once tested.
- Tests: `flutter test` and `flutter test integration_test/` once integrations exist.

## Code Conventions
- Flutter: snake_case files, `PascalCase` types, private members `_foo`, models always expose `fromJson/toJson`, providers extend `ChangeNotifier` and toggle `_isLoading`/`notifyListeners()` around async calls.
- Services wrap Firebase/HTTP APIs (see `lib/services/*_service.dart`) and should remain side-effect free beyond data access.
- Functions: always check `context.auth`, guard required params, wrap external calls (OpenAI, Vision, Stripe) in try/catch, log via `functions/src/utils/logger.ts`.

## Key Integration Points
- OpenAI chat: `lib/services/openai_service.dart` → `functions/src/ai/aiAssistant.ts` (rate limit 60/min; keep prompts business-focused).
- Receipt OCR: upload to Storage (`receipts/{userId}/{receiptId}`) then call `ocrProcessor`; parsing helpers live inside that function and still need AI refinement.
- AuraToken: balance on `users.{auraTokens}`, rewards logic in `functions/src/auraToken/rewards.ts`, transactions recorded in `auraTokenTransactions`.
- Feature flags toggled in `lib/utils/feature_constants.dart` (AI on, crypto/token off by default)—check before exposing UI/actions.

## Patterns to Follow
- Adding feature: model → service → provider → screens, then register route in `lib/config/app_routes.dart` and wire localization strings.
- New Firestore data: update `constants.dart`, mirror security rules + optional indexes, and expose typed model/service before touching UI.
- New Cloud Function: create file under matching domain, export via `functions/src/index.ts`, write minimal unit logic, then call through `FunctionsService().callFunction(name, params)`.

## Security + Secrets
- Never commit `.env` or platform config files; rely on Firebase config + GitHub secrets as noted in `docs/setup.md`.
- Respect file-size limits in rules (5MB receipts, 10MB general uploads) and always persist `userId` on docs before writes.

## Reference Material
- `docs/setup.md` (env + Firebase bootstrap) • `docs/architecture.md` (layered design) • `docs/api_reference.md` (callable functions) • `docs/roadmap.md` (feature targets) • `docs/security_standards.md` (compliance expectations).

Questions? Open the matching doc above before guessing.
