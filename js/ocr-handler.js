// ocr-handler.js
// Receipt OCR integration with language-aware processing
// Integrates with language-switcher.js to use user's selected language as OCR hint
//
// Uses Tesseract.js (v5.0.7) for client-side OCR
// - Privacy-first: processes images locally, nothing sent to servers
// - Language-aware: uses user's UI language preference for accurate scanning
// - Fallback: uses multi-language model for mixed-language receipts
//
// Usage:
//   1. Include in HTML: <script src="/js/ocr-handler.js"></script>
//   2. Add file input: <input type="file" id="receipt-upload" accept="image/*">
//   3. Add output element: <div id="ocr-output"></div>
//   4. Optional: add textarea: <textarea id="expense-description"></textarea>

/**
 * Map UI language codes to Tesseract-compatible OCR language codes
 * Based on Tesseract.js tessdata (v4+) available languages
 * Source: https://github.com/tesseract-ocr/tessdata
 */
const uiLangToOcrLang = {
  'en': 'eng',      // English
  'bg': 'bul',      // Bulgarian
  'fr': 'fra',      // French
  'de': 'deu',      // German
  'es': 'spa',      // Spanish
  'it': 'ita',      // Italian
  'pt': 'por',      // Portuguese
  'nl': 'nld',      // Dutch
  'pl': 'pol',      // Polish
  'sv': 'swe',      // Swedish
  'da': 'dan',      // Danish
  'fi': 'fin',      // Finnish
  'el': 'ell',      // Greek
  'cs': 'ces',      // Czech
  'hu': 'hun',      // Hungarian
  'ro': 'ron',      // Romanian
  'ar': 'ara',      // Arabic
  'zh': 'chi_sim',  // Chinese (Simplified)
  'ru': 'rus'       // Russian
};

/**
 * Fallback: multi-language model for unsupported or mixed-language receipts
 * Covers ~95% of global receipts with major business languages
 */
const DEFAULT_OCR_LANG = 'eng+fra+deu+spa+ita+por+rus+ara+chi_sim';

/**
 * Get best OCR language based on user's UI language preference
 * Falls back to multi-language model if language not directly supported
 * @returns {string} Tesseract language code (e.g., 'eng', 'chi_sim', or multi-lang string)
 */
function getOcrLanguage() {
  // Get user's selected language from language-switcher
  const uiLang = localStorage.getItem('aura-sphere-lang') || navigator.language.split('-')[0];
  
  // Return mapped OCR language or fallback to multi-language
  return uiLangToOcrLang[uiLang] || DEFAULT_OCR_LANG;
}

/**
 * Scan receipt image using Tesseract.js OCR
 * Loads language model dynamically based on user preference
 * @param {File} imageFile - Image file from file input
 * @returns {Promise<string>} Extracted text from receipt
 */
async function scanReceipt(imageFile) {
  // Dynamically import Tesseract.js from CDN (v5.0.7)
  const { createWorker } = await import('https://unpkg.com/tesseract.js@5.0.7/dist/tesseract.min.js');
  
  // Create worker with optional progress logging
  const worker = createWorker({
    logger: m => console.log(`OCR Progress: ${Math.round(m.progress * 100)}%`),
    gzip: true // Enable gzip compression for faster downloads
  });

  try {
    // Load Tesseract engine
    console.log('Loading Tesseract.js engine...');
    await worker.load();
    
    // Get language based on user preference
    const ocrLang = getOcrLanguage();
    console.log(`Loading language model: ${ocrLang}`);
    
    // Load and initialize language model
    await worker.loadLanguage(ocrLang);
    await worker.initialize(ocrLang);

    // Recognize text in image
    console.log('Scanning receipt...');
    const { data: { text } } = await worker.recognize(imageFile);
    
    // Clean up worker
    await worker.terminate();
    
    return text.trim();
  } catch (error) {
    console.error('OCR Error:', error);
    await worker.terminate();
    throw new Error('Failed to scan receipt. Please ensure image is clear and try again.');
  }
}

/**
 * Setup receipt scanner with file input event listener
 * Expects HTML elements:
 *   - <input type="file" id="receipt-upload" accept="image/*">
 *   - <div id="ocr-output"></div>
 *   - Optional: <textarea id="expense-description"></textarea>
 */
function setupReceiptScanner() {
  const fileInput = document.getElementById('receipt-upload');
  const output = document.getElementById('ocr-output');

  if (!fileInput) {
    console.warn('receipt-upload element not found');
    return;
  }

  fileInput.addEventListener('change', async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    // Validate file is an image
    if (!file.type.startsWith('image/')) {
      if (output) output.textContent = 'Please select an image file.';
      return;
    }

    try {
      // Show loading state
      if (output) output.textContent = 'Scanning receipt... (this may take a few seconds)';
      
      // Perform OCR
      const text = await scanReceipt(file);
      
      // Display extracted text
      if (output) {
        output.textContent = text || 'No text found in receipt.';
      }
      
      // Auto-fill expense form if available
      const descriptionField = document.getElementById('expense-description');
      if (descriptionField && text) {
        descriptionField.value = text;
      }
    } catch (err) {
      if (output) {
        output.textContent = err.message;
        output.style.color = '#d32f2f'; // Error red
      }
    }
  });
}

/**
 * Initialize OCR handler when page is ready
 * Only sets up if receipt scanner elements exist on page
 */
document.addEventListener('DOMContentLoaded', () => {
  if (document.getElementById('receipt-upload')) {
    console.log('OCR handler initialized');
    setupReceiptScanner();
  }
});

/**
 * API Export: Manual trigger for OCR (if needed)
 * Usage: const text = await scanReceiptManual(imageFile);
 */
window.scanReceiptManual = scanReceipt;
window.getOcrLanguageManual = getOcrLanguage;
