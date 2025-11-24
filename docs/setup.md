# AuraSphere Pro Setup Guide

## Prerequisites

- Flutter SDK 3.0+
- Node.js 18+
- Firebase CLI
- Android Studio / Xcode (for mobile development)

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/aurasphere-pro.git
cd aurasphere-pro
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Firebase Authentication (Email/Password)
3. Create Firestore database
4. Enable Storage
5. Download configuration files:
   - For Android: `google-services.json` → `android/app/`
   - For iOS: `GoogleService-Info.plist` → `ios/Runner/`
   - For Web: Add Firebase config to `web/index.html`

### 4. Environment Variables

Create a `.env` file in the root directory:

```
OPENAI_API_KEY=your_openai_key
STRIPE_PUBLISHABLE_KEY=your_stripe_key
STRIPE_SECRET_KEY=your_stripe_secret
SENTRY_DSN=your_sentry_dsn
ENV=development
```

### 5. Firebase Functions Setup

```bash
cd functions
npm install
cd ..
```

### 6. Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

### 7. Deploy Functions

```bash
firebase deploy --only functions
```

## Running the App

### Development Mode

```bash
flutter run
```

### Build for Production

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
firebase deploy --only hosting
```

## Firebase Emulator (Local Development)

```bash
firebase emulators:start
```

This will start local emulators for:
- Firestore
- Functions
- Authentication
- Storage

## Troubleshooting

### Flutter Issues
- Run `flutter clean && flutter pub get`
- Check Flutter doctor: `flutter doctor`

### Firebase Issues
- Ensure you're logged in: `firebase login`
- Check project: `firebase projects:list`

### Functions Issues
- Check logs: `firebase functions:log`
- Test locally with emulators

## Next Steps

1. Review the [Architecture Documentation](architecture.md)
2. Check [API Reference](api_reference.md)
3. Read [Roadmap](roadmap.md)
