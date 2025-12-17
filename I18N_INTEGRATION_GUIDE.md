# 📚 i18n Integration Guide - Practical Examples

---

## 1️⃣ BASIC HTML INTEGRATION

### Update index.html
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title data-i18n="app_name">AuraSphere</title>
</head>
<body>
    <!-- Header -->
    <header>
        <h1 data-i18n="app_name">AuraSphere</h1>
        <nav>
            <a href="#" data-i18n="dashboard">Dashboard</a>
            <a href="#" data-i18n="clients">Clients</a>
            <a href="#" data-i18n="invoices">Invoices</a>
        </nav>
    </header>

    <!-- Language Selector -->
    <div class="language-selector">
        <button onclick="changeLanguage('en')">🇬🇧 English</button>
        <button onclick="changeLanguage('ar')">🇸🇦 العربية</button>
        <button onclick="changeLanguage('fr')">🇫🇷 Français</button>
        <button onclick="changeLanguage('es')">🇪🇸 Español</button>
        <button onclick="changeLanguage('de')">🇩🇪 Deutsch</button>
    </div>

    <!-- Main Content -->
    <main>
        <h2 data-i18n="aura_crm">Aurasphere CRM</h2>
        <button data-i18n="add_client">Add Client</button>
        <button data-i18n="send_invoice">Send Invoice</button>
    </main>

    <!-- Load Translations -->
    <script src="js/translations.js"></script>
</body>
</html>
```

---

## 2️⃣ DYNAMIC CONTENT TRANSLATION

### JavaScript Translation Function
```javascript
// Translate content created at runtime
function translateString(key, language = null) {
  const lang = language || localStorage.getItem('preferredLanguage') || getUserLanguage();
  
  if (translations[lang] && translations[lang][key]) {
    return translations[lang][key];
  }
  
  // Fallback to English
  return translations.en[key] || key;
}

// Example usage:
const userName = 'John';
const message = `${translateString('welcome')} ${userName}`;
console.log(message); // "Welcome John" or "أهلا وسهلا جون"
```

### Create Dynamic Elements
```javascript
function createInvoiceButton() {
  const button = document.createElement('button');
  button.textContent = translateString('send_invoice');
  button.onclick = () => sendInvoice();
  
  return button;
}

// When language changes, re-create elements
function refreshUI() {
  const container = document.getElementById('actions');
  container.innerHTML = '';
  container.appendChild(createInvoiceButton());
}
```

---

## 3️⃣ LANGUAGE SWITCHER COMPONENT

### Create Language Dropdown
```html
<select id="languageSelect" onchange="handleLanguageChange(this.value)">
  <option value="en">🇬🇧 English</option>
  <option value="ar">🇸🇦 العربية</option>
  <option value="es">🇪🇸 Español</option>
  <option value="fr">🇫🇷 Français</option>
  <option value="de">🇩🇪 Deutsch</option>
  <option value="tr">🇹🇷 Türkçe</option>
  <option value="pt">🇵🇹 Português</option>
  <option value="ru">🇷🇺 Русский</option>
  <option value="id">🇮🇩 Bahasa</option>
  <option value="zh">🇨🇳 中文</option>
</select>

<script>
function handleLanguageChange(lang) {
  changeLanguage(lang);
  
  // Update select value
  document.getElementById('languageSelect').value = lang;
  
  // Optional: Show notification
  console.log(`Language changed to ${lang}`);
}

// Set initial value
document.addEventListener('DOMContentLoaded', () => {
  const currentLang = localStorage.getItem('preferredLanguage') || getUserLanguage();
  document.getElementById('languageSelect').value = currentLang;
});
</script>
```

---

## 4️⃣ FORM LABELS TRANSLATION

### HTML Forms with i18n
```html
<form id="loginForm">
  <div class="form-group">
    <label data-i18n="login" for="email">Login</label>
    <input 
      type="email" 
      id="email" 
      placeholder="" 
      data-i18n-placeholder="your_email"
    />
  </div>
  
  <div class="form-group">
    <label data-i18n="password" for="password">Password</label>
    <input 
      type="password" 
      id="password" 
      data-i18n-placeholder="enter_password"
    />
  </div>
  
  <button type="submit" data-i18n="login">Login</button>
  <a href="#" data-i18n="forgot_password">Forgot Password?</a>
</form>

<script>
// Enhanced translation to handle attributes
function translateUI(lang = getUserLanguage()) {
  // Translate text content
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    el.textContent = translations[lang]?.[key] || translations.en[key] || key;
  });
  
  // Translate placeholders
  document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
    const key = el.getAttribute('data-i18n-placeholder');
    el.placeholder = translations[lang]?.[key] || translations.en[key] || key;
  });
  
  // Handle RTL
  document.body.dir = (lang === 'ar') ? 'rtl' : 'ltr';
  document.documentElement.lang = lang;
}
</script>
```

---

## 5️⃣ MODAL/DIALOG TRANSLATIONS

### Confirmation Dialog
```javascript
function showConfirmDialog(titleKey, messageKey, onConfirm) {
  const lang = localStorage.getItem('preferredLanguage') || getUserLanguage();
  
  const dialog = document.createElement('div');
  dialog.className = 'modal';
  dialog.innerHTML = `
    <div class="modal-content">
      <h2>${translateString(titleKey, lang)}</h2>
      <p>${translateString(messageKey, lang)}</p>
      <button onclick="closeModal()" data-i18n="cancel">Cancel</button>
      <button onclick="confirmAction()" data-i18n="save">Confirm</button>
    </div>
  `;
  
  document.body.appendChild(dialog);
  
  window.confirmAction = () => {
    onConfirm();
    dialog.remove();
  };
}

// Usage:
showConfirmDialog(
  'delete_invoice',
  'are_you_sure',
  () => deleteInvoice(invoiceId)
);
```

---

## 6️⃣ DATE & NUMBER FORMATTING (LOCALE-AWARE)

### Locale-Aware Formatting
```javascript
function formatCurrencyByLanguage(amount, language = null) {
  const lang = language || localStorage.getItem('preferredLanguage') || getUserLanguage();
  
  const localeMap = {
    en: 'en-US',
    ar: 'ar-SA',
    fr: 'fr-FR',
    de: 'de-DE',
    es: 'es-ES',
    pt: 'pt-PT',
    tr: 'tr-TR',
    ru: 'ru-RU',
    id: 'id-ID',
    zh: 'zh-CN'
  };
  
  const locale = localeMap[lang] || 'en-US';
  
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: 'USD'
  }).format(amount);
}

// Usage:
console.log(formatCurrencyByLanguage(1234.56, 'en')); // "$1,234.56"
console.log(formatCurrencyByLanguage(1234.56, 'fr')); // "1 234,56 $US"
console.log(formatCurrencyByLanguage(1234.56, 'ar')); // "١٬٢٣٤٫٥٦ $"
```

### Date Formatting
```javascript
function formatDateByLanguage(date, language = null) {
  const lang = language || localStorage.getItem('preferredLanguage') || getUserLanguage();
  
  const localeMap = {
    en: 'en-US',
    ar: 'ar-SA',
    fr: 'fr-FR',
    de: 'de-DE',
    // ... etc
  };
  
  const locale = localeMap[lang] || 'en-US';
  
  return new Intl.DateTimeFormat(locale, {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  }).format(date);
}

// Usage:
const today = new Date();
console.log(formatDateByLanguage(today, 'en'));  // "December 17, 2025"
console.log(formatDateByLanguage(today, 'ar'));  // "17 ديسمبر 2025"
console.log(formatDateByLanguage(today, 'fr'));  // "17 décembre 2025"
```

---

## 7️⃣ NOTIFICATIONS & ALERTS

### Translated Alerts
```javascript
function showNotification(messageKey, type = 'info') {
  const lang = localStorage.getItem('preferredLanguage') || getUserLanguage();
  const message = translateString(messageKey, lang);
  
  const notification = document.createElement('div');
  notification.className = `notification notification-${type}`;
  notification.textContent = message;
  
  document.body.appendChild(notification);
  
  // Auto-remove after 3 seconds
  setTimeout(() => notification.remove(), 3000);
}

// Usage:
showNotification('invoice_sent', 'success');     // ✅
showNotification('error_occurred', 'error');     // ❌
showNotification('loading_data', 'info');        // ℹ️
```

### Toast Messages
```javascript
function toast(key, duration = 3000) {
  const message = translateString(key);
  
  const el = document.createElement('div');
  el.style.cssText = `
    position: fixed;
    bottom: 20px;
    right: 20px;
    background: #333;
    color: white;
    padding: 15px 20px;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    z-index: 9999;
    animation: slideIn 0.3s ease;
  `;
  el.textContent = message;
  
  document.body.appendChild(el);
  
  setTimeout(() => el.remove(), duration);
}

// Usage:
toast('copied'); // Copied!
```

---

## 8️⃣ EMAIL TEMPLATES TRANSLATION

### Generate Translated Email
```javascript
function generateEmailTemplate(lang, data) {
  const t = translations[lang];
  
  return `
    <h1>${t.app_name}</h1>
    <h2>${t.send_invoice}</h2>
    <p>${t.hello} ${data.clientName},</p>
    
    <p>${t.invoice_amount}: ${data.amount}</p>
    <p>${t.due_date}: ${formatDateByLanguage(data.dueDate, lang)}</p>
    
    <button>${t.pay_now}</button>
  `;
}

// Usage:
const emailBody = generateEmailTemplate('ar', {
  clientName: 'أحمد',
  amount: '1000 ر.س',
  dueDate: new Date('2025-12-31')
});
```

---

## 9️⃣ API RESPONSE TRANSLATION

### Translate API Errors
```javascript
async function fetchData(url) {
  try {
    const response = await fetch(url);
    
    if (!response.ok) {
      const lang = localStorage.getItem('preferredLanguage') || getUserLanguage();
      
      // Map error codes to translation keys
      const errorMap = {
        404: 'error_not_found',
        401: 'error_unauthorized',
        500: 'error_server_error',
        503: 'error_service_unavailable'
      };
      
      const errorKey = errorMap[response.status] || 'error_occurred';
      const message = translateString(errorKey, lang);
      
      throw new Error(message);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Translated Error:', error.message);
    showNotification(error.message, 'error');
  }
}
```

---

## 🔟 FLUTTER INTEGRATION

### Call JavaScript from Flutter
```dart
// lib/services/translation_service.dart
import 'package:webview_flutter/webview_flutter.dart';

class TranslationService {
  final WebViewController _controller;
  
  TranslationService(this._controller);
  
  // Switch language
  Future<void> changeLanguage(String langCode) async {
    await _controller.runJavaScript(
      'changeLanguage("$langCode")'
    );
  }
  
  // Get translated string
  Future<String> translate(String key) async {
    final result = await _controller.runJavaScript(
      'translateString("$key")'
    );
    return result ?? key;
  }
  
  // Update from business profile
  Future<void> applyBusinessLanguage(String defaultLanguage) async {
    await changeLanguage(defaultLanguage);
  }
}

// Usage:
final translation = TranslationService(controller);
await translation.changeLanguage('ar');
final greeting = await translation.translate('welcome');
```

---

## 📋 CHECKLIST FOR IMPLEMENTATION

- [ ] Copy `js/translations.js` to your project
- [ ] Add `<script src="js/translations.js"></script>` to HTML
- [ ] Add `data-i18n` attributes to all text elements
- [ ] Test auto-detection with different browser languages
- [ ] Test RTL for Arabic
- [ ] Add language selector button/dropdown
- [ ] Test localStorage persistence
- [ ] Add locale-aware date/currency formatting
- [ ] Translate email templates
- [ ] Test on mobile (responsive)
- [ ] Document custom translation keys for team

---

## 🎯 BEST PRACTICES

1. **Use Keys for All UI Text**
   ```html
   ❌ <button>Click me</button>
   ✅ <button data-i18n="click_me">Click me</button>
   ```

2. **Fallback to English**
   ```javascript
   // Automatic fallback if translation missing
   el.textContent = translations[lang][key] || translations.en[key];
   ```

3. **RTL-Safe CSS**
   ```css
   /* Use flex for direction-agnostic layouts */
   .container {
     display: flex;
     gap: 10px;  /* Works in RTL */
   }
   
   /* Avoid hardcoded left/right */
   ❌ padding-left: 20px;
   ✅ padding-inline-start: 20px;
   ```

4. **Save User Preference**
   ```javascript
   localStorage.setItem('preferredLanguage', lang);
   ```

5. **Document Translation Keys**
   Keep a master list of all translation keys for team members.

---

**Ready to Deploy!** 🚀

