# 🚀 Business Profile Module - Quick Setup (5 minutes)

**Ready to integrate the Business Profile module? Follow these 5 steps.**

---

## Step 1: Import Provider (1 minute)

**File:** `lib/app/app.dart`

Add import at top:
```dart
import 'package:aura_sphere_pro/providers/business_provider.dart';
import 'package:aura_sphere_pro/services/firebase/business_service.dart';
```

Find `MultiProvider` and add:
```dart
ChangeNotifierProvider(
  create: (_) => BusinessProvider(BusinessService()),
),
```

**Complete example:**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => UserProvider(...)),
    ChangeNotifierProvider(create: (_) => ExpenseProvider(...)),
    // Add this:
    ChangeNotifierProvider(
      create: (_) => BusinessProvider(BusinessService()),
    ),
  ],
  child: MaterialApp(
    // ...
  ),
)
```

---

## Step 2: Add Route (1 minute)

**File:** `lib/config/app_routes.dart`

Add import:
```dart
import '../screens/business/business_profile_screen.dart';
```

Add constant:
```dart
static const String businessProfile = '/business-profile';
```

Add route handler:
```dart
case businessProfile:
  return MaterialPageRoute(
    builder: (_) => const BusinessProfileScreen(),
  );
```

---

## Step 3: Add Navigation (1 minute)

**File:** Your main navigation/drawer (e.g., `lib/screens/home/home_screen.dart`)

```dart
ListTile(
  title: const Text('Business Profile'),
  leading: const Icon(Icons.business),
  onTap: () => Navigator.pushNamed(context, AppRoutes.businessProfile),
),
```

Or as a button:
```dart
ElevatedButton.icon(
  onPressed: () => Navigator.pushNamed(context, AppRoutes.businessProfile),
  icon: const Icon(Icons.business),
  label: const Text('Business Profile'),
)
```

---

## Step 4: Add Firestore Security Rules (1 minute)

**File:** `firestore.rules`

Add this collection rule:
```javascript
match /users/{userId}/business/{document=**} {
  // Only the user can read/write their business profile
  allow read: if request.auth.uid == userId;
  allow write: if request.auth.uid == userId && 
                  request.resource.data.userId == userId;
  allow delete: if request.auth.uid == userId;
}
```

---

## Step 5: Test (1 minute)

1. Run app: `flutter run`
2. Navigate to Business Profile
3. Click "Create Profile" button
4. Fill in a few fields (Business Name, Email, Phone at minimum)
5. Click "Create Profile"
6. Verify saved in Firebase Console:
   - Go to Firestore → users → {your-user-id} → business → profile
   - See your business data saved there

✅ Done! You're ready to use the Business Profile module.

---

## 📚 Next Steps

### Want to use business data in other screens?
```dart
// In any screen, access business info:
final businessProvider = context.read<BusinessProvider>();

String businessName = businessProvider.businessName;
String currency = businessProvider.currency;
String email = businessProvider.businessEmail;
```

### Want to customize the form?
Edit `lib/screens/business/business_profile_form_screen.dart` to add/remove fields.

### Want to add more fields?
1. Add to `BusinessProfile` model in `business_model.dart`
2. Add to form in `business_profile_form_screen.dart`
3. Add to view in `business_profile_screen.dart`

---

## 🎯 Files to Copy

Copy these 5 files to your project:

```
lib/data/models/business_model.dart
lib/services/firebase/business_service.dart
lib/providers/business_provider.dart
lib/screens/business/business_profile_screen.dart
lib/screens/business/business_profile_form_screen.dart
```

---

## ⚡ That's It!

You now have a complete Business Profile module. Users can:
- ✅ Create their business profile
- ✅ View all information organized by sections
- ✅ Edit any field
- ✅ Delete their profile
- ✅ Data is stored securely in Firestore

For detailed documentation, see: `BUSINESS_PROFILE_MODULE.md`

---

*Setup time: 5 minutes*
*Integration time: 10 minutes*
*Production ready: Yes ✅*
