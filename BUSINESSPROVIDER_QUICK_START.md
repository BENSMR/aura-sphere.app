# 🚀 Quick Reference: Using BusinessProvider

## Essential Usage Patterns

### 1. Initialize Business Profile (On User Login)
```dart
// In UserProvider or auth listener
final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
await businessProvider.start(userId);  // Auto-loads profile with defaults
```

### 2. Access Business Data in UI
```dart
// Option A: Consumer pattern (recommended)
Consumer<BusinessProvider>(
  builder: (context, provider, _) {
    return Text(
      'Business: ${provider.businessName}',
      style: TextStyle(color: Color(int.parse(provider.brandColor.replaceFirst('#', '0xFF')))),
    );
  },
)

// Option B: Provider.of pattern
final business = Provider.of<BusinessProvider>(context);
print('Currency: ${business.defaultCurrency}');  // EUR
print('Template: ${business.invoiceTemplate}');  // minimal
```

### 3. Update Business Profile
```dart
// Save multiple fields at once (merge-safe)
await Provider.of<BusinessProvider>(context, listen: false).saveProfile({
  'businessName': 'New Company',
  'defaultCurrency': 'USD',
  'brandColor': '#FF6B35',
});
```

### 4. Upload Logo
```dart
final File file = /* selected from image picker */;
final logoUrl = await Provider.of<BusinessProvider>(context, listen: false)
    .uploadLogo(file);
// Profile automatically updates with new logo
```

### 5. Reload Profile
```dart
// Refresh from Firestore (e.g., after sync)
await businessProvider.reload();
```

### 6. Clean Up (e.g., On Logout)
```dart
businessProvider.stop();  // Resets provider state
```

---

## Available Properties & Methods

### State Properties
```dart
BusinessProfile? profile           // Full typed profile object
bool isLoading                      // Loading state
bool isSaving                       // Saving state
bool hasError                       // Has error occurred
String? error                       // Error message
```

### Convenience Getters
```dart
String businessName                 // Company name
String legalName                    // Legal entity name
String taxId                        // Tax ID
String logoUrl                      // Logo image URL
String brandColor                   // Hex color (e.g., '#0A84FF')
String defaultCurrency              // Currency code (e.g., 'EUR')
String defaultLanguage              // Language code (e.g., 'en')
String invoiceTemplate              // Template name (e.g., 'minimal')
```

### Methods
```dart
Future<void> start(String userId)                    // Initialize
void stop()                                          // Reset
Future<void> saveProfile(Map<String, dynamic> data) // Update
Future<String?> uploadLogo(File file)               // Upload logo
Future<void> reload()                               // Refresh
```

---

## Complete Example Screen

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BusinessProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Business Profile')),
      body: Consumer<BusinessProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (provider.hasError) {
            return Center(
              child: Text('Error: ${provider.error}'),
            );
          }
          
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Logo
              if (provider.logoUrl.isNotEmpty)
                Center(
                  child: Image.network(
                    provider.logoUrl,
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              
              SizedBox(height: 20),
              
              // Business Name
              ListTile(
                title: Text('Business Name'),
                subtitle: Text(provider.businessName),
              ),
              
              // Currency
              ListTile(
                title: Text('Currency'),
                subtitle: Text(provider.defaultCurrency),
              ),
              
              // Language
              ListTile(
                title: Text('Language'),
                subtitle: Text(provider.defaultLanguage),
              ),
              
              // Template
              ListTile(
                title: Text('Invoice Template'),
                subtitle: Text(provider.invoiceTemplate),
              ),
              
              SizedBox(height: 20),
              
              // Edit Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to edit screen
                },
                child: Text('Edit Profile'),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

---

## Error Handling

```dart
// Check for errors
if (provider.hasError) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(provider.error ?? 'Unknown error')),
  );
}

// Handle async errors
try {
  await provider.saveProfile({'businessName': 'New Name'});
} catch (e) {
  print('Failed: $e');
  // Show error to user
}
```

---

## Firestore Structure

```
users/{userId}/meta/business {
  businessName: "My Business",
  legalName: "My Business Inc",
  taxId: "12-3456789",
  vatNumber: "DE123456789",
  address: "123 Main St",
  city: "New York",
  postalCode: "10001",
  logoUrl: "https://...",
  invoicePrefix: "AS-",
  documentFooter: "Thank you for your business",
  brandColor: "#0A84FF",
  watermarkText: "DRAFT",
  invoiceTemplate: "minimal",      // 'minimal', 'classic', 'modern'
  defaultCurrency: "EUR",
  defaultLanguage: "en",
  taxSettings: { /* VAT config */ },
  updatedAt: <timestamp>
}
```

---

## Default Values

If fields are missing or not provided, these defaults apply:

```dart
businessName → 'My Business'
legalName → ''
logoUrl → ''
brandColor → '#0A84FF'
defaultCurrency → 'EUR'
defaultLanguage → 'en'
invoiceTemplate → 'minimal'
// ... other fields → empty strings
```

---

## Tips & Best Practices

✅ **Do:**
- Call `start(userId)` once on app startup after user auth
- Use `Consumer<BusinessProvider>` for reactive UI updates
- Use `saveProfile()` for all updates (it's merge-safe)
- Reload profile after major changes or sync operations
- Handle `isLoading` and `isSaving` states in UI

❌ **Don't:**
- Modify `profile` directly (use `saveProfile()` instead)
- Forget to initialize with `start(userId)` before using
- Create multiple BusinessProvider instances
- Update business data from multiple places simultaneously

---

## Testing

```dart
// Mock for testing
class MockBusinessProvider extends ChangeNotifier implements BusinessProvider {
  @override
  BusinessProfile? get profile => BusinessProfile(
    businessName: 'Test Business',
    // ... other fields
  );
  
  @override
  String get businessName => 'Test Business';
  
  // ... implement other getters/methods
}
```

---

*For more details, see POST_PATCH_ACTIONS_COMPLETE.md*
