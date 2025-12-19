/**
 * OCR Worker for Receipt Processing
 * 
 * Uses Tesseract.js for client-side receipt image processing
 * Reduces server load and enables offline OCR capability
 * 
 * Features:
 * - Preloads Tesseract worker once for performance
 * - Reuses worker across multiple receipts
 * - Supports multiple languages (eng, spa, fra, deu, etc.)
 * - Graceful error handling with fallback
 */

class OCRWorkerManager {
  constructor() {
    this.worker = null;
    this.isInitialized = false;
    this.isInitializing = false;
    this.initPromise = null;
    this.supportedLanguages = ['eng', 'spa', 'fra', 'deu', 'ita', 'por'];
  }

  /**
   * Initialize Tesseract worker
   * @param {string} language - Language code (default: 'eng')
   * @returns {Promise<void>}
   */
  async initialize(language = 'eng') {
    // Return existing promise if already initializing
    if (this.isInitializing) {
      return this.initPromise;
    }

    // Skip if already initialized
    if (this.isInitialized) {
      return Promise.resolve();
    }

    this.isInitializing = true;

    this.initPromise = (async () => {
      try {
        console.log('🔄 Initializing Tesseract OCR worker...');
        
        // Check if Tesseract is available
        if (typeof Tesseract === 'undefined') {
          throw new Error('Tesseract.js library not loaded. Ensure <script src="...tesseract.min.js"></script> is in index.html');
        }

        // Create worker
        this.worker = await Tesseract.createWorker({
          workerPath: 'https://cdn.jsdelivr.net/npm/tesseract.js@5/dist/worker.min.js',
          langPath: 'https://cdn.jsdelivr.net/npm/tesseract.js-data@v1.0.0/4.0_best/',
          corePath: 'https://cdn.jsdelivr.net/npm/tesseract.js-core@v5/tesseract-core.wasm.js'
        });

        console.log('✅ Worker created');

        // Load language
        if (!this.supportedLanguages.includes(language)) {
          console.warn(`⚠️ Language '${language}' not supported, defaulting to 'eng'`);
          language = 'eng';
        }

        await this.worker.load();
        console.log('✅ Tesseract language data loaded');

        await this.worker.loadLanguage(language);
        console.log(`✅ Language '${language}' loaded`);

        await this.worker.initialize(language);
        console.log(`✅ OCR initialized for language: '${language}'`);

        this.isInitialized = true;
        this.isInitializing = false;

      } catch (error) {
        this.isInitializing = false;
        console.error('❌ Tesseract initialization failed:', error.message);
        throw new Error(`OCR initialization failed: ${error.message}`);
      }
    })();

    return this.initPromise;
  }

  /**
   * Process receipt image with OCR
   * @param {File|Blob|string} input - Image file, blob, or data URL
   * @param {Object} options - Recognition options
   * @returns {Promise<string>} - Extracted text from receipt
   */
  async processReceipt(input, options = {}) {
    try {
      // Initialize if needed
      if (!this.isInitialized) {
        await this.initialize(options.language || 'eng');
      }

      if (!this.worker) {
        throw new Error('OCR worker not initialized');
      }

      console.log('🔄 Processing receipt with OCR...');

      // Recognize text
      const { data: { text, confidence } } = await this.worker.recognize(input, {
        tessedit_ocr_engine_mode: Tesseract.OEM.LSTM_ONLY,
      });

      console.log(`✅ OCR completed (confidence: ${Math.round(confidence)}%)`);

      return {
        success: true,
        text: text.trim(),
        confidence: confidence,
        timestamp: new Date().toISOString()
      };

    } catch (error) {
      console.error('❌ Receipt processing failed:', error.message);
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   * Batch process multiple receipts
   * @param {File[]|Blob[]|string[]} inputs - Array of images
   * @param {Object} options - Processing options
   * @returns {Promise<Object[]>} - Array of OCR results
   */
  async batchProcessReceipts(inputs, options = {}) {
    if (!Array.isArray(inputs) || inputs.length === 0) {
      return { success: false, error: 'No inputs provided' };
    }

    // Initialize if needed
    if (!this.isInitialized) {
      await this.initialize(options.language || 'eng');
    }

    console.log(`🔄 Batch processing ${inputs.length} receipts...`);

    const results = [];
    for (let i = 0; i < inputs.length; i++) {
      try {
        const result = await this.processReceipt(inputs[i], options);
        results.push({ index: i, ...result });
        console.log(`  [${i + 1}/${inputs.length}] ✅ Processed`);
      } catch (error) {
        results.push({
          index: i,
          success: false,
          error: error.message
        });
        console.log(`  [${i + 1}/${inputs.length}] ❌ Failed: ${error.message}`);
      }
    }

    console.log(`📊 Batch processing complete: ${results.filter(r => r.success).length}/${inputs.length} succeeded`);
    return results;
  }

  /**
   * Switch to different language
   * @param {string} language - Language code
   * @returns {Promise<void>}
   */
  async switchLanguage(language) {
    if (!this.worker) {
      throw new Error('OCR worker not initialized');
    }

    if (!this.supportedLanguages.includes(language)) {
      throw new Error(`Language '${language}' not supported. Supported: ${this.supportedLanguages.join(', ')}`);
    }

    try {
      console.log(`🔄 Switching to language: '${language}'`);
      await this.worker.loadLanguage(language);
      await this.worker.initialize(language);
      console.log(`✅ Switched to language: '${language}'`);
    } catch (error) {
      throw new Error(`Failed to switch language: ${error.message}`);
    }
  }

  /**
   * Cleanup OCR worker
   * @returns {Promise<void>}
   */
  async terminate() {
    if (this.worker) {
      try {
        console.log('🔄 Terminating OCR worker...');
        await this.worker.terminate();
        this.worker = null;
        this.isInitialized = false;
        console.log('✅ OCR worker terminated');
      } catch (error) {
        console.error('❌ Worker termination failed:', error.message);
      }
    }
  }

  /**
   * Get worker status
   * @returns {Object}
   */
  getStatus() {
    return {
      initialized: this.isInitialized,
      initializing: this.isInitializing,
      workerActive: this.worker !== null,
      supportedLanguages: this.supportedLanguages
    };
  }
}

// Global OCR manager instance
window.ocrManager = new OCRWorkerManager();

console.log('✅ OCR Worker Manager loaded');

// Expose to Flutter via window object
window.processReceiptOCR = async (fileOrDataUrl, options = {}) => {
  try {
    const result = await window.ocrManager.processReceipt(fileOrDataUrl, options);
    return result;
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  window.ocrManager.terminate();
});
