# OCR Handler Documentation

Complete guide to integrating Tesseract.js OCR with the language switcher system.

## Overview

The `ocr-handler.js` component provides **client-side, privacy-first receipt scanning** that automatically adapts to the user's selected language from the language switcher.

### Three-Part Language System

```
Part 1: translations.js
  ├─ Provides: UI translations (19 languages)
  └─ Functions: getUserLanguage(), translateUI()

Part 2: language-switcher.js
  ├─ Provides: Language selection dropdown UI
  ├─ Persists: localStorage['aura-sphere-lang']
  └─ Features: Auto-detection, real-time updates, RTL support

Part 3: ocr-handler.js (NEW)
  ├─ Reads: User's language preference from localStorage
  ├─ Maps: UI language → OCR language (Tesseract)
  ├─ Scans: Receipts in user's preferred language
  └─ Fallback: Multi-language model for mixed documents
```

## Installation

### 1. Copy ocr-handler.js

```bash
# Copy to /js/ directory in your project
cp ocr-handler.js /path/to/project/js/ocr-handler.js
```

### 2. Add HTML Elements

```html
<!-- File input for receipt upload -->
<input 
  type="file" 
  id="receipt-upload" 
  accept="image/*"
  placeholder="Select receipt image"
>

<!-- Output area for extracted text -->
<div id="ocr-output" style="margin-top: 1rem; padding: 1rem; background: #f5f5f5; border-radius: 6px;"></div>

<!-- Optional: Auto-fill form field -->
<textarea 
  id="expense-description" 
  placeholder="Receipt text will appear here..."
  rows="6"
></textarea>
```

### 3. Include Scripts in HTML

```html
<!-- Load in correct order -->
<script src="/js/translations.js"></script>
<script src="/js/language-switcher.js"></script>
<script src="/js/ocr-handler.js"></script>
```

**Important:** Scripts must load in this order:
1. translations.js (provides translations object)
2. language-switcher.js (reads localStorage, provides language functions)
3. ocr-handler.js (uses language selection)

## How It Works

### Execution Flow

```
User loads page
  ↓
language-switcher.js runs
  ├─ Reads localStorage['aura-sphere-lang'] OR browser language
  ├─ Saves user's language choice
  └─ Makes it available for other components
  ↓
ocr-handler.js initializes
  ├─ Detects receipt upload element
  ├─ Attaches file input listener
  └─ Ready for receipt scanning
  ↓
User selects receipt image
  ↓
File change event fires
  ├─ getOcrLanguage() called
  ├─ Reads localStorage['aura-sphere-lang']
  ├─ Maps UI language → OCR language
  ├─ Tesseract.js loads language model
  ├─ scanReceipt() runs OCR
  └─ Text displayed in output element
  ↓
User sees extracted receipt text
```

### Language Mapping

The component automatically maps your UI language to the appropriate OCR language:

| UI Language | OCR Language | Support |
|---|---|---|
| English (en) | eng | ✅ Full |
| Bulgarian (bg) | bul | ✅ Full |
| French (fr) | fra | ✅ Full |
| German (de) | deu | ✅ Full |
| Spanish (es) | spa | ✅ Full |
| Italian (it) | ita | ✅ Full |
| Portuguese (pt) | por | ✅ Full |
| Dutch (nl) | nld | ✅ Full |
| Polish (pl) | pol | ✅ Full |
| Swedish (sv) | swe | ✅ Full |
| Danish (da) | dan | ✅ Full |
| Finnish (fi) | fin | ✅ Full |
| Greek (el) | ell | ✅ Full |
| Czech (cs) | ces | ✅ Full |
| Hungarian (hu) | hun | ✅ Full |
| Romanian (ro) | ron | ✅ Full |
| Arabic (ar) | ara | ✅ Full |
| Chinese (zh) | chi_sim | ✅ Full |
| Russian (ru) | rus | ✅ Full |

### Fallback Strategy

If a language isn't directly supported, OCR uses this multi-language model:

```
'eng+fra+deu+spa+ita+por+rus+ara+chi_sim'
```

This covers ~95% of global business receipts across these language families:
- Romance: French, Spanish, Italian, Portuguese
- Germanic: English, German
- Slavic: Russian
- Semitic: Arabic
- Sino-Tibetan: Chinese

## Complete Example

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Receipt Scanner</title>
    <style>
        body {
            font-family: sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 2rem;
        }
        
        .scanner-container {
            background: white;
            padding: 2rem;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        input[type="file"] {
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 6px;
            cursor: pointer;
        }
        
        #ocr-output {
            margin-top: 1rem;
            padding: 1rem;
            background: #f5f5f5;
            border-radius: 6px;
            min-height: 50px;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        
        textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-family: monospace;
        }
        
        .language-selector {
            margin-bottom: 1rem;
        }
        
        #language-switcher {
            padding: 8px 12px;
            border: 2px solid #667eea;
            border-radius: 6px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <h1>Receipt Scanner</h1>
    
    <div class="scanner-container">
        <div class="language-selector">
            <label for="language-switcher">Language:</label>
            <div id="language-switcher"></div>
        </div>
        
        <h2>Upload Receipt</h2>
        <input 
            type="file" 
            id="receipt-upload" 
            accept="image/*"
            placeholder="Select receipt image"
        >
        
        <h2>Extracted Text</h2>
        <div id="ocr-output">Upload a receipt to scan...</div>
        
        <h2>Expense Description</h2>
        <textarea 
            id="expense-description" 
            placeholder="Extracted text will auto-fill here..."
            rows="8"
        ></textarea>
    </div>

    <!-- Load scripts in correct order -->
    <script src="/js/translations.js"></script>
    <script src="/js/language-switcher.js"></script>
    <script src="/js/ocr-handler.js"></script>
</body>
</html>
```

## API Reference

### Functions

#### `getOcrLanguage()`

Returns the OCR language code based on user's UI language preference.

```javascript
// Returns 'eng', 'bul', 'fra', etc., or fallback multi-language string
const lang = getOcrLanguage();
console.log(lang); // 'eng' if English selected, 'bul' if Bulgarian, etc.
```

#### `scanReceipt(imageFile)`

Performs OCR on an image file using Tesseract.js.

```javascript
// Input: File object (from file input)
// Output: Promise<string> containing extracted text

const text = await scanReceipt(imageFile);
console.log(text); // "Store: Walmart\nDate: 12/17/2025\nTotal: $42.50"
```

#### `setupReceiptScanner()`

Initializes the receipt scanner by attaching file input listeners.

```javascript
// Called automatically on DOMContentLoaded
// Manual call:
setupReceiptScanner();
```

### Window API (For Manual Calls)

```javascript
// Manually trigger OCR from console or other scripts
const text = await window.scanReceiptManual(imageFile);

// Get current OCR language
const lang = window.getOcrLanguageManual();
```

## Configuration

### Change Default Fallback Language

Edit ocr-handler.js and modify:

```javascript
// Instead of multi-language, use single language fallback
const DEFAULT_OCR_LANG = 'eng'; // Always use English

// Or customize multi-language selection
const DEFAULT_OCR_LANG = 'fra+deu+spa'; // European languages only
```

### Change Output Element ID

If you use a different ID for the output element:

```html
<!-- Instead of id="ocr-output" -->
<div id="my-custom-output"></div>

<!-- Update ocr-handler.js line: -->
<!-- Change: const output = document.getElementById('ocr-output'); -->
<!-- To:     const output = document.getElementById('my-custom-output'); -->
```

## Performance Considerations

### First Load
- **Language Model Download**: ~40-80MB (first time only, cached by browser)
- **Processing Time**: 5-15 seconds depending on image quality
- **Progress**: Shows "Scanning receipt..." message

### Subsequent Loads
- **Much Faster**: Language model cached by browser
- **Processing Time**: 2-5 seconds
- **Zero Network**: All processing happens locally

### Optimization Tips

1. **Compress images before upload**: Reduces processing time
2. **High quality receipt photos**: Improves OCR accuracy
3. **Good lighting**: Well-lit receipts scan better
4. **Portrait orientation**: Vertical layout works best

## Browser Compatibility

| Browser | Desktop | Mobile |
|---|---|---|
| Chrome/Edge | ✅ Yes | ✅ Yes |
| Firefox | ✅ Yes | ✅ Yes |
| Safari | ✅ Yes | ✅ Yes |
| Mobile Safari (iOS) | - | ✅ Yes |
| Chrome Mobile (Android) | - | ✅ Yes |

**Requirements:**
- Modern browser with WebAssembly support
- 500MB+ free disk space (for language model cache)
- Decent CPU/RAM (processing intensive)

## Troubleshooting

### OCR doesn't start

**Problem:** "Scanning receipt..." appears but doesn't complete

**Solutions:**
1. Check browser console for errors
2. Ensure image file is valid (JPG, PNG, etc.)
3. Try smaller image (< 10MB)
4. Clear browser cache and retry
5. Check internet connection (first load needs download)

```javascript
// Debug in console
console.log(localStorage.getItem('aura-sphere-lang')); // Check language
console.log(getOcrLanguage()); // Check OCR language
```

### Text output is garbled

**Problem:** Extracted text has strange characters

**Solutions:**
1. Try higher quality image
2. Ensure receipt is well-lit
3. Try different language setting
4. Check if receipt has special formatting

### Dropdown not appearing

**Problem:** No language switcher visible

**Solutions:**
1. Check HTML has `<div id="language-switcher"></div>`
2. Verify language-switcher.js loaded
3. Check browser console for errors

```javascript
// Debug in console
document.getElementById('language-switcher'); // Should exist
typeof renderLanguageSwitcher; // Should be 'function'
```

### Memory issues on mobile

**Problem:** App crashes during OCR on mobile

**Solutions:**
1. Close other apps to free memory
2. Use smaller receipt images
3. Try different browser
4. Wait a few seconds between scans

## Security & Privacy

✅ **Client-Side Only**: All processing happens in user's browser
✅ **No Server Upload**: Images never sent to servers
✅ **No Tracking**: No cookies or analytics
✅ **Open Source**: Tesseract.js is fully open-source
✅ **Cache Local**: Language models cached locally after first download

## Advanced Usage

### Auto-Format Extracted Text

```javascript
// Add this to ocr-handler.js to format extracted text

function formatReceiptText(text) {
  // Remove extra whitespace
  text = text.replace(/\s+/g, ' ').trim();
  
  // Try to extract key info
  const lines = text.split('\n').map(l => l.trim()).filter(l => l);
  
  return lines.join('\n');
}

// Then in setupReceiptScanner():
// Replace: output.textContent = text || 'No text found.';
// With:    output.textContent = formatReceiptText(text) || 'No text found.';
```

### Parse Receipt into Structured Data

```javascript
// Extract amounts, dates, store names, etc.

function parseReceipt(text) {
  return {
    store: extractStore(text),
    date: extractDate(text),
    amount: extractAmount(text),
    items: extractItems(text),
    raw: text
  };
}

function extractAmount(text) {
  const match = text.match(/total[:\s]+\$?([\d.,]+)/i);
  return match ? parseFloat(match[1]) : null;
}

// Use in setupReceiptScanner():
// const parsed = parseReceipt(text);
// console.log(parsed); // { store, date, amount, items, raw }
```

## License

Tesseract.js is Apache 2.0 licensed
This wrapper is free to use and modify

## References

- [Tesseract.js Documentation](https://tesseract.projectnaptha.com/)
- [Available Languages](https://github.com/tesseract-ocr/tessdata)
- [GitHub Repository](https://github.com/naptha/tesseract.js)
