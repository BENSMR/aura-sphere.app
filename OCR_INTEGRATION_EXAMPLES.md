# OCR Integration Examples for aura-sphere.app

Complete HTML examples showing where to place the receipt scanner UI.

## Example 1: Dedicated Receipt Scanner Page

Create a new file: `scanner.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Receipt Scanner - AuraSphere</title>
    <link rel="stylesheet" href="/css/style.css">
    <style>
        .scanner-container {
            max-width: 600px;
            margin: 2rem auto;
            padding: 2rem;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .ocr-section {
            margin-bottom: 2rem;
        }

        .ocr-section label {
            display: block;
            font-weight: 600;
            margin-bottom: 0.5rem;
            color: #333;
        }

        .ocr-section input[type="file"] {
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 6px;
            cursor: pointer;
            width: 100%;
        }

        .ocr-section input[type="file"]:hover {
            border-color: #667eea;
        }

        #ocr-output {
            margin-top: 8px;
            min-height: 80px;
            background: #f9f9f9;
            padding: 10px;
            border-radius: 4px;
            border: 1px solid #eee;
            font-family: monospace;
            font-size: 13px;
            white-space: pre-wrap;
            word-wrap: break-word;
            color: #333;
        }

        #expense-description {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-family: inherit;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <header>
        <nav>
            <h1>AuraSphere</h1>
            <div id="language-switcher"></div>
        </nav>
    </header>

    <div class="scanner-container">
        <h2 data-i18n="scan_receipt">Scan Receipt</h2>

        <!-- Receipt Scanner UI -->
        <div class="ocr-section">
            <label for="receipt-upload" data-i18n="scan_receipt">Upload Receipt Image</label>
            <input 
                type="file" 
                id="receipt-upload" 
                accept="image/*"
                data-i18n="placeholder"
            />
            <pre id="ocr-output">Upload an image to scan...</pre>
        </div>

        <!-- Expense form (optional auto-fill) -->
        <div>
            <label for="expense-description" data-i18n="description">Description</label>
            <textarea 
                id="expense-description" 
                rows="6"
                placeholder="Extracted receipt text will appear here..."
            ></textarea>
        </div>
    </div>

    <!-- Scripts (at end of body, in correct order) -->
    <script src="/js/translations.js"></script>
    <script src="/js/language-switcher.js"></script>
    <script src="/js/ocr-handler.js"></script>
</body>
</html>
```

## Example 2: Integrated into CRM Page

Add to existing `crm.html` in the expense management section:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CRM - AuraSphere</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <nav>
            <h1>AuraSphere CRM</h1>
            <div id="language-switcher"></div>
        </nav>
    </header>

    <main>
        <!-- ... existing CRM content ... -->

        <!-- Receipt Scanner Section (NEW) -->
        <section class="expenses-section">
            <h2 data-i18n="log_expense">Log Expense</h2>

            <div class="ocr-section">
                <label for="receipt-upload" data-i18n="scan_receipt">Scan Receipt</label>
                <input 
                    type="file" 
                    id="receipt-upload" 
                    accept="image/*"
                />
                <pre id="ocr-output" style="margin-top: 8px; min-height: 60px; background: #f9f9f9; padding: 10px;"></pre>
            </div>

            <!-- Expense form (optional auto-fill) -->
            <form id="expense-form">
                <div class="form-group">
                    <label for="expense-description" data-i18n="description">Description</label>
                    <textarea 
                        id="expense-description" 
                        placeholder="Extracted receipt text will appear here..."
                        rows="4"
                    ></textarea>
                </div>

                <div class="form-group">
                    <label for="expense-amount" data-i18n="amount">Amount</label>
                    <input type="number" id="expense-amount" placeholder="0.00" step="0.01">
                </div>

                <button type="submit" class="btn-primary">Save Expense</button>
            </form>
        </section>

        <!-- ... rest of CRM content ... -->
    </main>

    <!-- Scripts (at end of body, in correct order) -->
    <script src="/js/translations.js"></script>
    <script src="/js/language-switcher.js"></script>
    <script src="/js/ocr-handler.js"></script>
</body>
</html>
```

## Example 3: Minimal Integration (Single Component)

Add to any existing page that needs receipt scanning:

```html
<!-- Paste this in your HTML body where you want the scanner -->
<div class="ocr-section">
    <label for="receipt-upload" data-i18n="scan_receipt">Scan Receipt</label>
    <input type="file" id="receipt-upload" accept="image/*" />
    <pre id="ocr-output" style="margin-top: 8px; min-height: 60px; background: #f9f9f9; padding: 10px;"></pre>
</div>

<!-- Expense description (optional) -->
<input type="text" id="expense-description" placeholder="Description" />

<!-- Make sure these scripts are at the end of your </body> tag -->
<script src="/js/translations.js"></script>
<script src="/js/language-switcher.js"></script>
<script src="/js/ocr-handler.js"></script>
```

## Key Points

### HTML Structure
- **File Input**: `id="receipt-upload"` (required for file selection)
- **Output Area**: `id="ocr-output"` (required for displaying extracted text)
- **Description Field**: `id="expense-description"` (optional, for auto-fill)

### Styling
```css
/* Optional: Enhance the UI */
#ocr-output {
    margin-top: 8px;
    min-height: 60px;
    background: #f9f9f9;
    padding: 10px;
    border-radius: 4px;
    font-family: monospace;
    white-space: pre-wrap;
    word-wrap: break-word;
}

#receipt-upload {
    padding: 10px;
    border: 2px solid #ddd;
    border-radius: 6px;
    cursor: pointer;
}

#receipt-upload:hover {
    border-color: #667eea;
}
```

### i18n Attributes
Add translation keys to your `translations.js`:
```javascript
{
  "scan_receipt": "Scan Receipt",
  "description": "Description",
  "log_expense": "Log Expense",
  "amount": "Amount"
}
```

### Script Loading Order (CRITICAL)
1. `translations.js` - Must load first (provides global `translations` object)
2. `language-switcher.js` - Depends on `translations.js` and `getUserLanguage()`, `translateUI()`
3. `ocr-handler.js` - Depends on `language-switcher.js` and localStorage

```html
<!-- ✅ CORRECT -->
<script src="/js/translations.js"></script>
<script src="/js/language-switcher.js"></script>
<script src="/js/ocr-handler.js"></script>

<!-- ❌ WRONG - will cause errors -->
<script src="/js/ocr-handler.js"></script>
<script src="/js/language-switcher.js"></script>
<script src="/js/translations.js"></script>
```

## Integration Checklist

For each page where you add the OCR section:

- [ ] Copy HTML markup for receipt scanner
- [ ] Ensure `id="receipt-upload"` exists
- [ ] Ensure `id="ocr-output"` exists
- [ ] Optional: Add `id="expense-description"` for auto-fill
- [ ] Add scripts in correct order at end of `</body>`
- [ ] Test file upload works
- [ ] Test language switching affects OCR
- [ ] Verify extracted text appears in output

## Testing

1. **Open page** in browser
2. **Select language** from dropdown
3. **Upload receipt image** (JPG, PNG, etc.)
4. **Wait** for "Scanning receipt..." message
5. **See** extracted text in output area
6. **Reload page** - language preference persists
7. **Upload different image** - should use same language

## Files Needed

These files must already exist in aura-sphere.app:

- `/js/translations.js` - Provided by language system (19 languages)
- `/js/language-switcher.js` - Provided by language system
- `/js/ocr-handler.js` - Ready to copy (from aura-sphere-pro)

## Troubleshooting

**"Receipt upload element not found"** in console
→ Check `id="receipt-upload"` exists in HTML

**"No text found in receipt"**
→ Try higher quality image, ensure good lighting

**Language not changing OCR**
→ Verify language-switcher.js loaded before ocr-handler.js
→ Check localStorage shows correct language: `localStorage.getItem('aura-sphere-lang')`

**Scripts not loading**
→ Verify file paths are correct (`/js/` not `js/` without leading slash)
→ Check browser console for 404 errors
