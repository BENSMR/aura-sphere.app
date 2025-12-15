# Mobile Layout Implementation Guide

## Overview
This implementation enables your Flutter mobile app to read user-customized feature preferences and render only the enabled features (max 8) on the mobile dashboard.

## Architecture

```
User customizes layout at /customize (web)
        ↓
Firestore: users/{uid}/settings/dashboard_layout
        ↓
Mobile app reads mobileModules field
        ↓
MobileLayoutService fetches preferences
        ↓
MobileLayoutProvider manages state
        ↓
MobileDashboardScreen renders only enabled features
```

## Components

### 1. MobileLayoutService (`lib/services/mobile_layout_service.dart`)
**Responsibility:** Direct Firestore communication

**Key Methods:**
```dart
// Fetch user's mobile modules from Firestore
Future<Map<String, bool>> getMobileModules()

// Get default layout (first 8 features)
Map<String, bool> _getDefaultMobileModules()

// Enforce max 8 features limit
Map<String, bool> _enforceMobileLimit(Map<String, bool> modules)

// Get only enabled feature names
Future<List<String>> getEnabledMobileFeatures()

// Save preferences back to Firestore
Future<void> saveMobileModules(Map<String, bool> modules)

// Check if single feature is enabled
Future<bool> isFeatureEnabled(String featureName)

// Get count of enabled features
Future<int> getEnabledFeatureCount()
```

**Data Structure in Firestore:**
```json
{
  "users": {
    "{userId}": {
      "settings": {
        "dashboard_layout": {
          "mobileModules": {
            "scanReceipts": true,
            "quickContacts": true,
            "sendInvoices": true,
            "inventoryStock": true,
            "taskBoard": true,
            "loyaltyPoints": true,
            "walletBalance": true,
            "aiAlerts": true,
            "fullReports": false,
            "teamManagement": false,
            "advancedSettings": false,
            "dashboard": false
          },
          "updatedAt": "2025-12-15T10:00:00Z"
        }
      }
    }
  }
}
```

### 2. MobileLayoutProvider (`lib/providers/mobile_layout_provider.dart`)
**Responsibility:** State management with ChangeNotifier pattern

**Properties:**
```dart
Map<String, bool> mobileModules         // Full module map
List<String> enabledFeatures             // Only enabled features (max 8)
bool isLoading                           // Loading state
String? error                            // Error messages
int enabledFeatureCount                  // Count of enabled
int maxFeatures = 8                      // Hard limit
```

**Key Methods:**
```dart
// Load preferences on app startup or refresh
Future<void> loadMobileLayout()

// Toggle single feature on/off
Future<void> toggleFeature(String featureName)

// Reset to default 8 features
Future<void> resetToDefault()

// Check if feature is enabled
bool isFeatureEnabled(String featureName)

// Get enabled count
int getEnabledCount()
```

### 3. MobileDashboardScreen (`lib/screens/mobile/mobile_dashboard_screen.dart`)
**Responsibility:** UI rendering with user preferences

**Features:**
- Loads layout on `initState()`
- Shows loading spinner while fetching
- Displays error state with retry button
- Shows empty state if no features enabled (with link to customize)
- Renders up to 8 feature cards in ListView
- Pull-to-refresh to reload preferences
- Settings button to navigate to customization

**Feature Card Includes:**
- Icon emoji (📸, 👥, 📧, etc.)
- Feature title & description
- Tap handler to navigate to feature
- Consistent styling with gold/cyan branding

## Integration Steps

### Step 1: Register Provider in Main App
```dart
// In main.dart or your app widget
ChangeNotifierProvider(
  create: (_) => MobileLayoutProvider(),
  child: MyApp(),
)
```

### Step 2: Update Route Navigation
```dart
// In lib/config/app_routes.dart
import 'package:aura_sphere_pro/screens/mobile/mobile_dashboard_screen.dart';

final routes = {
  '/home': (context) => const MobileDashboardScreen(),
  // ... other routes
};
```

### Step 3: Load Layout on App Startup
```dart
// In your app's init logic or home screen
void initState() {
  super.initState();
  Future.microtask(() {
    context.read<MobileLayoutProvider>().loadMobileLayout();
  });
}
```

### Step 4: Connect Customize Navigation
In `mobile_dashboard_screen.dart`, uncomment and complete the navigation:
```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.of(context).pushNamed('/customize');
  },
  icon: const Icon(Icons.settings),
  label: const Text('Customize'),
)
```

## Usage Examples

### Example 1: Render Feature Only if Enabled
```dart
Consumer<MobileLayoutProvider>(
  builder: (context, provider, child) {
    if (provider.isFeatureEnabled('scanReceipts')) {
      return ScanReceiptsWidget();
    }
    return SizedBox.shrink();
  },
)
```

### Example 2: Show Feature Count
```dart
Text('${provider.enabledFeatureCount} / ${provider.maxFeatures} features enabled')
```

### Example 3: Toggle Feature from Settings
```dart
ListTile(
  title: Text('Scan Receipts'),
  trailing: Switch(
    value: provider.isFeatureEnabled('scanReceipts'),
    onChanged: (enabled) {
      provider.toggleFeature('scanReceipts');
    },
  ),
)
```

## Flow Diagram: Feature Rendering

```
App Launch
    ↓
MobileDashboardScreen.initState()
    ↓
loadMobileLayout()
    ↓
MobileLayoutService.getMobileModules()
    ↓
Fetch from Firestore: users/{uid}/settings/dashboard_layout
    ↓
Parse mobileModules object
    ↓
Enforce max 8 limit (filter enabled = true)
    ↓
Return List<String> of feature names
    ↓
Provider notifies listeners
    ↓
ListView builds 0-8 feature cards
    ↓
Display feature cards with icons & descriptions
```

## Feature List (Max 8 Mobile)

**Essential (6):**
1. ✅ **scanReceipts** - 📸 Scan Receipts
2. ✅ **quickContacts** - 👥 Quick Contacts
3. ✅ **sendInvoices** - 📧 Send Invoices
4. ✅ **inventoryStock** - 📦 Inventory Stock
5. ✅ **taskBoard** - ✅ Task Board
6. ✅ **loyaltyPoints** - ⭐ Loyalty Points

**Optional (Max +2):**
7. ✅ **walletBalance** - 💰 Wallet Balance
8. ✅ **aiAlerts** - 🤖 AI Alerts

**Desktop Only (Disabled on Mobile):**
- ❌ fullReports
- ❌ teamManagement
- ❌ advancedSettings
- ❌ dashboard

## Security Considerations

✅ **User Authentication Check:** Service validates `FirebaseAuth.currentUser` before accessing Firestore  
✅ **Ownership Validation:** Firestore rules ensure users can only read/write their own documents  
✅ **Limit Enforcement:** App enforces max 8 features before saving (server does too)  
✅ **Error Handling:** Graceful fallback to defaults if Firestore fetch fails  

## Testing Checklist

- [ ] Load mobile layout on app startup
- [ ] Display 0-8 feature cards based on user preferences
- [ ] Pull-to-refresh reloads layout
- [ ] Clicking feature card navigates to feature
- [ ] Settings button opens customization page
- [ ] Toggle feature updates Firestore and refreshes UI
- [ ] Reset to default returns to 8 core features
- [ ] Error state shows with retry button
- [ ] Loading spinner displays while fetching
- [ ] Empty state shows if no features enabled
- [ ] Feature limit enforced (can't enable >8)

## Next Steps

1. **Register MobileLayoutProvider** in app initialization
2. **Connect feature navigation** in tapped feature handlers
3. **Link customize button** to your web customization page
4. **Test with Firebase Emulator** or live Firestore
5. **Add analytics tracking** for feature usage
6. **Implement cloud sync** for real-time updates
