# 🌍 Multi-Language Quick Reference Card

## 📋 USAGE CHEAT SHEET

### Add to HTML
```html
<script src="js/translations.js"></script>
```

### Mark Elements
```html
<h1 data-i18n="app_name">AuraSphere</h1>
```

### Change Language
```javascript
changeLanguage('ar');  // Arabic
changeLanguage('en');  // English
changeLanguage('fr');  // French
```

### Translate String
```javascript
const text = translateString('welcome');
```

### Get User Language
```javascript
const lang = getUserLanguage();
```

---

## 🌐 LANGUAGE CODES

| Language | Code | Emoji |
|----------|------|-------|
| English | `en` | 🇬🇧 |
| Arabic | `ar` | 🇸🇦 |
| Spanish | `es` | 🇪🇸 |
| French | `fr` | 🇫🇷 |
| German | `de` | 🇩🇪 |
| Turkish | `tr` | 🇹🇷 |
| Portuguese | `pt` | 🇵🇹 |
| Russian | `ru` | 🇷🇺 |
| Indonesian | `id` | 🇮🇩 |
| Chinese | `zh` | 🇨🇳 |

---

## 🎯 COMMON KEYS

```
app_name, dashboard, settings, language, save, cancel, close
clients, invoices, tasks, wallet, expenses
login, signup, subscribe, monthly, yearly, free_trial
generate_post, saved_posts, copy, copied
```

---

## 💾 PERSISTENCE

```javascript
// Auto-saved to localStorage
localStorage.getItem('preferredLanguage');

// Persists across sessions
// User's language preference never lost
```

---

## 🇸🇦 RTL (Arabic)

Automatic! No code needed.
```
document.body.dir = 'rtl'  ← Applied automatically
```

---

## 📱 Flutter Integration

```dart
await controller.runJavaScript('changeLanguage("ar")');
```

---

**All 10 languages ready to use!** ✅
