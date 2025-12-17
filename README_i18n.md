# 🌍 AuraSphere Multi-Language (i18n) System

**Status:** ✅ Complete - 10 Languages Supported  
**Auto-Detection:** ✅ Yes (navigator.language)  
**RTL Support:** ✅ Yes (Arabic)  
**Persistence:** ✅ Yes (localStorage)

---

## 📊 Supported Languages

| Language | Code | Flag | Features |
|----------|------|------|----------|
| English | `en` | 🇬🇧 | Default fallback |
| Arabic | `ar` | 🇸🇦 | RTL layout + Modern Standard Arabic |
| Spanish | `es` | 🇪🇸 | Latin Spanish |
| French | `fr` | 🇫🇷 | European French |
| German | `de` | 🇩🇪 | Standard German |
| Turkish | `tr` | 🇹🇷 | Turkish |
| Portuguese | `pt` | 🇵🇹 | European/Brazilian Portuguese |
| Russian | `ru` | 🇷🇺 | Russian (Cyrillic) |
| Indonesian | `id` | 🇮🇩 | Indonesian |
| Chinese | `zh` | 🇨🇳 | Simplified Chinese |

---

## 🚀 Quick Start

### 1. Include the Script
```html
<!-- In your index.html -->
<script src="js/translations.js"></script>
```

### 2. Mark Elements for Translation
```html
<!-- Use data-i18n attribute -->
<h1 data-i18n="app_name">AuraSphere</h1>
<button data-i18n="login">Login</button>
<p data-i18n="privacy_first">Privacy-first AI...</p>
```

### 3. Translations Auto-Apply on Load
The script automatically:
- Detects user's browser language (e.g., `ar-SA` → `ar`)
- Loads localStorage preference if exists
- Applies translations to all `[data-i18n]` elements
- Handles RTL for Arabic

---

## 💻 Usage Examples

### Auto-Detect (Default)
```javascript
// Automatically uses navigator.language
// User with ar-SA browser language → Arabic UI
// User with en-US browser language → English UI
```

### Change Language Programmatically
```javascript
// Switch to French
changeLanguage('fr');

// Switch to Arabic
changeLanguage('ar');

// Switch to Chinese
changeLanguage('zh');
```

### Get Current Language
```javascript
const currentLang = localStorage.getItem('preferredLanguage') || getUserLanguage();
console.log(currentLang); // e.g., "ar", "en", "fr"
```

### Translate Dynamic Content
```javascript
// For content created at runtime
const greeting = translations[currentLang]['app_name'];
console.log(greeting); // "AuraSphere" or "أوراسفير"

// Update element
document.getElementById('header').textContent = 
  translations[currentLang]['dashboard'];
```

---

## 🎨 RTL Support (Arabic)

When Arabic is selected:
```javascript
// Automatic RTL handling
document.body.dir = 'rtl';      // Right-to-left layout
document.body.textAlign = 'right';
```

**CSS for RTL:**
```css
body.rtl {
    direction: rtl;
    text-align: right;
}

/* Margins flip automatically in flexbox */
.flex-container {
    display: flex;
    gap: 10px; /* Works in both LTR and RTL */
}
```

---

## 📁 File Structure

```
aura-sphere.app/
├── js/
│   └── translations.js          ← Main i18n file (10 languages)
├── i18n-example.html            ← Demo page
└── README_i18n.md               ← This file
```

---

## 🔧 Adding New Languages

### Step 1: Add Translation Object
```javascript
// In translations.js, add new language block:
zh_traditional: {
  app_name: "靈光球",
  aura_post: "靈光貼文",
  // ... add all other keys
}
```

### Step 2: Update Language Selector (HTML)
```html
<button class="lang-btn" onclick="changeLanguage('zh_traditional')">
  🇹🇼 繁體中文
</button>
```

### Step 3: Test RTL (if needed)
```javascript
// For right-to-left languages, update translateUI():
if (lang === 'ar' || lang === 'ur' || lang === 'he') {
  document.body.dir = 'rtl';
}
```

---

## 💾 Translation Keys

### Global
```javascript
'app_name'      // "AuraSphere"
'dashboard'     // "Dashboard"
'settings'      // "Settings"
'language'      // "Language"
'save'          // "Save"
'cancel'        // "Cancel"
'close'         // "Close"
```

### CRM Features
```javascript
'clients'       // "Clients"
'invoices'      // "Invoices"
'tasks'         // "Tasks"
'wallet'        // "Wallet"
'expenses'      // "Expenses"
'add_client'    // "Add Client"
'send_invoice'  // "Send Invoice"
```

### AuraPost
```javascript
'generate_post' // "Generate Social Post"
'saved_posts'   // "Saved Posts"
'dialect'       // "Dialect"
'egyptian'      // "Egyptian"
'gulf'          // "Gulf"
'levantine'     // "Levantine"
'maghrebi'      // "Maghrebi"
```

### Authentication
```javascript
'login'         // "Login"
'signup'        // "Sign Up"
'subscribe'     // "Subscribe"
'free_trial'    // "3-Day Free Trial"
```

---

## 🌐 Browser Language Detection

The system auto-detects:
```
User Browser Language     →    Detected Code    →    Translation
ar-SA (Arabic - Saudi)   →    'ar'             →    Arabic UI
en-US (English - US)     →    'en'             →    English UI
fr-FR (French - France)  →    'fr'             →    French UI
de-DE (German - Germany) →    'de'             →    German UI
zh-CN (Chinese)          →    'zh'             →    Chinese UI
```

If language not supported, falls back to English.

---

## 💾 LocalStorage

Translations preference is saved:
```javascript
localStorage.setItem('preferredLanguage', 'ar');
localStorage.getItem('preferredLanguage'); // Returns 'ar'
```

Users can:
- Switch languages and preference persists across sessions
- Clear cache to reset to auto-detected language

---

## 🔌 Integration with CRM App

### In Flutter App
```dart
// Use business profile default language
final userLang = businessProfile.defaultLanguage; // 'ar', 'fr', 'en'

// Call JavaScript to switch
_webViewController.runJavaScript('changeLanguage("$userLang")');
```

### In Cloud Functions
```typescript
// Get user's preferred language from Firestore
const userLang = userDoc.data()?.defaultLanguage || 'en';

// Return translated content
const translation = translations[userLang];
return {
  title: translation['invoices'],
  message: translation['send_invoice']
};
```

---

## 📱 Mobile App Integration (Flutter)

**Translation files location:**
```
lib/localization/
├── en.json          # English strings
├── ar.json          # Arabic strings
├── fr.json          # French strings
├── es.json          # Spanish strings
└── ... (other languages)
```

**Usage in Dart:**
```dart
// Get translated string
Text(AppLocalizations.of(context)!.appName)

// Switch language
Locale newLocale = Locale('ar');  // Arabic
// App rebuilds with new locale
```

---

## 🎯 OCR Language Support

Tesseract.js (already integrated) supports 100+ languages:

```javascript
// Initialize OCR with specific language
await ocrWorker.initialize('ara');  // Arabic
await ocrWorker.initialize('fra');  // French
await ocrWorker.initialize('deu');  // German
await ocrWorker.initialize('zho');  // Chinese
```

---

## 🧪 Testing

### Manual Testing
1. Open `i18n-example.html` in browser
2. Click different language buttons
3. Verify:
   - Text translates correctly
   - Arabic shows RTL layout
   - Language preference persists on refresh

### Auto-Detection Testing
```javascript
// Test in browser console
navigator.language  // Shows your browser language
getUserLanguage()   // Shows detected AuraSphere language
```

---

## 🔍 Troubleshooting

### Text Not Translating?
```javascript
// Check if element has data-i18n attribute
document.querySelectorAll('[data-i18n]').length  // Should be > 0

// Check if key exists in language
console.log(translations['ar']['app_name']); // Should not be undefined
```

### RTL Not Working?
```javascript
// Verify body direction
document.body.dir;  // Should be 'rtl' for Arabic

// Check CSS
body {
    direction: rtl;
    text-align: right;
}
```

### Language Not Persisting?
```javascript
// Check localStorage
localStorage.getItem('preferredLanguage');  // Should return language code

// Manually set
localStorage.setItem('preferredLanguage', 'ar');
```

---

## 📊 Translation Statistics

- **Total Keys:** 40+
- **Languages:** 10
- **Total Strings:** 400+
- **Auto-Detection:** ✅ Yes
- **RTL Support:** ✅ Yes (Arabic)
- **LocalStorage:** ✅ Yes
- **Module Export:** ✅ Yes (for Node.js)

---

## 🚀 Future Enhancements

- [ ] Add 5+ more languages (Italian, Greek, Polish, etc.)
- [ ] Automated translation via Google Translate API
- [ ] Translation completeness checker
- [ ] Language-specific number/date formatting
- [ ] Pluralization support
- [ ] Context-aware translations
- [ ] Translation contribution system

---

## 📄 License

AuraSphere i18n System - Open Source  
Used in AuraSphere CRM, AuraPost, AuraLink, AuraShield

---

## 💬 Support

For translation corrections or new languages:
- Email: `hello@aura-sphere.app`
- Create issue: GitHub Issues
- Contribute: Submit PR with translations

---

**Status:** 🟢 Production Ready  
**Last Updated:** December 17, 2025  
**Version:** 1.0
