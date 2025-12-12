# AuraSphere Pro

<div align="center">

![AuraSphere Pro](https://img.shields.io/badge/AuraSphere-Pro-6C63FF?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**Enterprise-grade business management platform with AI-powered automation**

[Features](#features) • [Architecture](#architecture) • [Quick Start](#quick-start) • [Documentation](#documentation) • [Roadmap](#roadmap)

</div>

---

## 🌟 Overview

AuraSphere Pro is a comprehensive, AI-powered business management platform built with Flutter and Firebase. It combines expense tracking, CRM, project management, invoicing, and AI assistance into a single, elegant application for Android, iOS, and Web.

## ✨ Features

### Core Capabilities
- 🔐 **Secure Authentication** - Firebase Auth with email/password
- 💰 **Smart Expense Tracking** - OCR receipt scanning with Google Vision AI
- 🤖 **AI Assistant** - OpenAI-powered business intelligence
- 👥 **CRM** - Contact and client relationship management
- 📊 **Project Management** - Track projects, budgets, and timelines
- 📄 **Invoice Generation** - Automated invoicing with PDF export
- 💳 **Subscription Billing** - Stripe integration for payments
- 🎁 **AuraToken Rewards** - Gamification and loyalty system

### Technical Highlights
- 📱 **Cross-platform** - Android, iOS, Web, PWA support
- 🎨 **Glassmorphic Design** - Modern, beautiful UI with animations
- 🌍 **Internationalization** - Support for 4+ languages (EN, FR, ES, AR)
- 🔒 **Enterprise Security** - GDPR compliant, encrypted data
- ⚡ **Serverless Backend** - Scalable Firebase Cloud Functions
- 🎯 **Modular Architecture** - Clean separation of concerns

## 🏗️ Architecture

```
┌─────────────────────┐
│   Flutter Client    │  ← Presentation Layer
│  (Android/iOS/Web)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│     Providers       │  ← State Management
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│     Services        │  ← Business Logic
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Firebase Backend   │  ← Data & Functions
│  • Auth             │
│  • Firestore        │
│  • Functions        │
│  • Storage          │
└─────────────────────┘
```

**Key Patterns:**
- **State Management**: Provider pattern with ChangeNotifier
- **Architecture**: Layered (Presentation → State → Service → Data)
- **Backend**: Domain-driven Cloud Functions organization
- **Security**: User-scoped data isolation with Firestore rules

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Node.js 18+
- Firebase CLI
- Android Studio / Xcode

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/aura-sphere-pro.git
cd aura-sphere-pro
```

2. **Install Flutter dependencies**
```bash
flutter pub get
```

3. **Setup Firebase**
```bash
# Login to Firebase
firebase login

# Initialize project
firebase init

# Deploy rules and functions
firebase deploy --only firestore:rules,storage:rules,functions
```

4. **Configure environment**
Create `.env` file:
```env
OPENAI_API_KEY=your_key
STRIPE_PUBLISHABLE_KEY=your_key
STRIPE_SECRET_KEY=your_key
ENV=development
```

5. **Run the app**
```bash
flutter run
```

## 📚 Documentation

- **[Setup Guide](docs/setup.md)** - Detailed installation instructions
- **[Architecture](docs/architecture.md)** - System design and patterns
- **[API Reference](docs/api_reference.md)** - Cloud Functions documentation
- **[Roadmap](docs/roadmap.md)** - Feature roadmap and versions
- **[Security](docs/security_standards.md)** - Security policies and compliance
- **[AI Instructions](.github/copilot-instructions.md)** - Guide for AI coding agents

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **UI Libraries**: Material Design 3, Shimmer
- **Networking**: http, connectivity_plus
- **Localization**: intl

### Backend
- **Platform**: Firebase
- **Runtime**: Node.js 18 (Cloud Functions)
- **Database**: Firestore (NoSQL)
- **Storage**: Cloud Storage
- **Authentication**: Firebase Auth

### Integrations
- **AI**: OpenAI GPT-4
- **OCR**: Google Vision API
- **Payments**: Stripe
- **Monitoring**: Firebase Analytics

## 💳 Payment Setup (Stripe)

### Token Checkout Configuration

1. **Set Stripe API keys**
```bash
firebase functions:config:set \
  stripe.secret="sk_test_..." \
  stripe.publishable="pk_test_..." \
  stripe.webhook_secret="whsec_..."
```

2. **Deploy token payment functions**
```bash
firebase deploy --only \
  functions:createTokenCheckoutSession,\
  functions:stripeTokenWebhook
```

3. **Configure Stripe webhook**
   - Go to Stripe Dashboard → Webhooks
   - Add endpoint: `https://us-central1-YOUR_PROJECT.cloudfunctions.net/stripeTokenWebhook`
   - Select event: `checkout.session.completed`
   - Copy signing secret and set in config above

4. **Verify deployment**
   - Check Firebase Console → Functions for both functions deployed
   - Test in Flutter via `PaymentService.createTokenCheckoutSession()`

### Post-Checkout Deep Link Setup

After user completes payment, they're redirected back to your app:

1. **Host payment pages**
   ```bash
   # These are auto-deployed via Firebase Hosting
   web/public/payment-success.html
   web/public/payment-cancel.html
   ```

2. **Stripe appends session ID**
   ```
   https://aurasphere-pro.web.app/billing/success?session_id=cs_test_123...
   ```

3. **HTML page opens app with deep link**
   ```
   aura://payment-success?session_id=cs_test_123...
   ```

4. **Initialize deep link service in Flutter**
   ```dart
   // In main.dart
   final deepLinkService = DeepLinkService();
   deepLinkService.init();
   
   // Wrap app with payment handler
   PaymentResultHandler(
     deepLinkService: deepLinkService,
     walletService: WalletService(),
     child: const MyApp(),
   )
   ```

5. **App receives session ID and polls webhook**
   - `DeepLinkService` captures `session_id` from deep link
   - Polls `payments_processed/{sessionId}` for up to 25 seconds
   - On webhook confirmation, wallet balance updates automatically

### Custom Scheme Configuration

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<activity android:name=".MainActivity">
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="aura" android:host="payment-success" />
  </intent-filter>
</activity>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>aura</string>
    </array>
  </dict>
</array>
```

### Token Economy

- **Starter Pack**: 200 tokens for $5 (40 AI calls)
- **Growth Pack**: 600 tokens for $12 (best value)
- **Pro Pack**: 1600 tokens for $25 (heavy users)

**Usage:**
- Free users: 5 tokens per AI Finance Coach call
- Pro+ subscribers: Unlimited AI (no tokens)
- Tokens never expire
- All transactions logged in `users/{uid}/token_audit`

## 📁 Project Structure

```
aurasphere_pro/
├── lib/
│   ├── config/          # App configuration
│   ├── core/            # Core utilities
│   ├── services/        # API services
│   ├── providers/       # State management
│   ├── screens/         # UI screens
│   ├── components/      # Reusable widgets
│   ├── models/          # Data models
│   └── utils/           # Helper functions
├── functions/
│   └── src/
│       ├── ai/          # AI functions
│       ├── ocr/         # Receipt scanning
│       ├── billing/     # Subscriptions
│       ├── finance/     # Tax, invoices, KPIs
│       └── auraToken/   # Token economy
├── docs/                # Documentation
├── assets/              # Images, fonts, icons
└── test/                # Unit & integration tests
```

## 🔧 Development

### Commands
```bash
# Run app
flutter run

# Run tests
flutter test

# Build for production
flutter build apk --release      # Android
flutter build ios --release      # iOS
flutter build web --release      # Web

# Deploy functions
cd functions && npm run deploy

# Run Firebase emulators
firebase emulators:start
```

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` for linting
- Format code with `flutter format .`
- Run tests before committing

## 🗺️ Roadmap

### v1.0 (Current) - MVP
- ✅ Core features: Auth, Expenses, AI, CRM, Projects, Invoices
- ✅ Firebase backend with Cloud Functions
- ✅ OCR receipt scanning
- ✅ Multi-platform support

### v1.1 (Q2 2026)
- [ ] Multi-currency support
- [ ] Advanced analytics
- [ ] Dark mode
- [ ] PWA optimization

### v2.0 (Q4 2026)
- [ ] AuraToken implementation
- [ ] Crypto wallet
- [ ] Enterprise features (RBAC, SSO)

See [full roadmap](docs/roadmap.md) for details.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) first.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure
- OpenAI for AI capabilities
- Google Cloud for Vision API
- Stripe for payment processing

## 📞 Contact

- **Website**: https://aurasphere.app
- **Email**: support@aurasphere.app
- **Twitter**: [@AuraSphere](https://twitter.com/aurasphere)
- **Discord**: [Join our community](https://discord.gg/aurasphere)

---

<div align="center">

**Built with ❤️ using Flutter and Firebase**

[![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Powered%20by-Firebase-FFCA28?logo=firebase)](https://firebase.google.com)

</div>
AURA-SPEHERE PRO ISD A REVOLUTIONARY CRM WITH MULTY FEATURES LINKED TO THE MANDEMENT OF THE MAJORS NEEDS IN BUSSINESS PAWERED BY AI
