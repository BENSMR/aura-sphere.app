# AuraSphere Pro Architecture

## Overview

AuraSphere Pro is a multi-platform enterprise business management application built with Flutter (client) and Firebase (backend).

## System Architecture

```
┌─────────────────────────────────────────┐
│         Client Applications              │
│  (Flutter - Android/iOS/Web/PWA)        │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│         Firebase Services                │
│  • Authentication                        │
│  • Firestore (Database)                  │
│  • Cloud Functions (Backend Logic)       │
│  • Storage (File Storage)                │
│  • Messaging (Push Notifications)        │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│      External Services                   │
│  • OpenAI (AI Assistant)                 │
│  • Google Vision (OCR)                   │
│  • Stripe (Payments)                     │
└─────────────────────────────────────────┘
```

## Flutter App Architecture

### Layer Structure

1. **Presentation Layer** (`lib/screens/`, `lib/components/`)
   - UI components and screens
   - Stateful and stateless widgets
   - Route management

2. **Business Logic Layer** (`lib/providers/`)
   - State management using Provider
   - Business logic and data transformation
   - Communication between services and UI

3. **Service Layer** (`lib/services/`)
   - Firebase service wrappers
   - External API integrations
   - Business-specific services (CRM, Projects, etc.)

4. **Data Layer** (`lib/models/`)
   - Data models and entities
   - JSON serialization/deserialization
   - Type-safe data structures

5. **Core Layer** (`lib/core/`)
   - Error handling
   - Logging
   - Network checking
   - Permissions

6. **Configuration** (`lib/config/`)
   - App theme and colors
   - Routes
   - Constants
   - Environment configuration

### State Management

- **Provider Pattern**: Used for dependency injection and state management
- Each major feature has its own provider (ExpenseProvider, CRMProvider, etc.)
- Global app state managed by AppProvider

### Navigation

- Declarative routing with named routes
- Centralized route management in `app_routes.dart`
- Support for deep linking (planned)

## Firebase Backend Architecture

### Cloud Functions

Organized by feature domain:

- **AI Functions** (`functions/src/ai/`): OpenAI integration
- **OCR Functions** (`functions/src/ocr/`): Receipt scanning
- **Billing Functions** (`functions/src/billing/`): Stripe subscriptions
- **Finance Functions** (`functions/src/finance/`): Tax, invoices, KPIs
- **CRM Functions** (`functions/src/crm/`): Contact management triggers
- **Project Functions** (`functions/src/projects/`): Project lifecycle
- **AuraToken Functions** (`functions/src/auraToken/`): Token economy

### Firestore Collections

```
users/
  {userId}/
    - email
    - displayName
    - businessId
    - auraTokens
    - createdAt

expenses/
  {expenseId}/
    - userId
    - amount
    - currency
    - category
    - description
    - date
    - receiptUrl

invoices/
  {invoiceId}/
    - userId
    - clientId
    - invoiceNumber
    - amount
    - status
    - items[]

projects/
  {projectId}/
    - userId
    - name
    - description
    - status
    - startDate
    - budget

crm/
  {contactId}/
    - userId
    - name
    - email
    - company
    - tags[]
```

### Security Rules

- User data isolated by `userId`
- Read/write operations require authentication
- Field-level validation in Firestore rules
- File size limits in Storage rules

## Data Flow

1. **User Action** → UI Component
2. **Event** → Provider (State Management)
3. **Provider** → Service Layer
4. **Service** → Firebase (Auth, Firestore, Functions, Storage)
5. **Firebase** → External APIs (OpenAI, Vision, Stripe)
6. **Response** ← External APIs
7. **Response** ← Firebase
8. **Response** ← Service
9. **State Update** ← Provider
10. **UI Update** ← Component Re-render

## Key Design Patterns

- **Repository Pattern**: Service layer abstracts data sources
- **Provider Pattern**: State management and dependency injection
- **Factory Pattern**: Model construction from JSON
- **Singleton Pattern**: Service instances (auth, firestore, etc.)

## Scalability Considerations

- **Client-side**: Stateless widgets, lazy loading, pagination
- **Backend**: Serverless functions scale automatically
- **Database**: Firestore scales horizontally
- **Storage**: Cloud Storage for file uploads

## Future Enhancements

- GraphQL API layer
- WebSocket for real-time updates
- Microservices architecture for complex operations
- Redis caching layer
- CDN for static assets
