/**
 * Expense receipt parsing helpers for OCR text extraction
 */

/**
 * Extract all currency amounts from text
 * Returns sorted by value descending (largest first, typically the total)
 */
export function findAmounts(text: string): { raw: string; value: number }[] {
  const amounts: { raw: string; value: number }[] = [];
  
  // Match currency patterns: 1,234.56 or 1.234,56 or 1234.56 etc
  const amountRegex = /([-+]?\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)/g;
  const matches = text.match(amountRegex);

  if (!matches) return amounts;

  const seen = new Set<number>();
  for (const raw of matches) {
    // Normalize: replace . with empty (thousand sep) or , with . (decimal sep)
    const normalized = raw.replace(/\./g, '').replace(/,/, '.');
    const value = parseFloat(normalized);

    // Skip if NaN, zero, or already seen (deduplicate)
    if (isNaN(value) || value === 0 || seen.has(value)) continue;

    seen.add(value);
    amounts.push({ raw, value });
  }

  // Sort descending (largest/most likely total first)
  return amounts.sort((a, b) => b.value - a.value);
}

/**
 * Extract all date strings from text
 * Supports: yyyy-mm-dd, dd/mm/yyyy, mm/dd/yyyy, dd-mm-yy, etc.
 * Returns ISO format strings (YYYY-MM-DD)
 */
export function findDates(text: string): string[] {
  const dates: string[] = [];
  const seen = new Set<string>();

  // Multiple date patterns
  const patterns = [
    // yyyy-mm-dd or yyyy/mm/dd
    /(\d{4}[-/]\d{1,2}[-/]\d{1,2})/g,
    // dd-mm-yyyy or dd/mm/yyyy
    /(\d{1,2}[-/]\d{1,2}[-/]\d{4})/g,
    // dd-mm-yy or dd/mm/yy
    /(\d{1,2}[-/]\d{1,2}[-/]\d{2})/g,
    // Month names: 1 Jan 2024, January 1, 2024, etc.
    /(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4})/gi,
  ];

  for (const pattern of patterns) {
    let match;
    while ((match = pattern.exec(text)) !== null) {
      const raw = match[0];
      let isoDate: string | null = null;

      // Try to parse each format
      if (/\d{4}[-/]\d{1,2}[-/]\d{1,2}/.test(raw)) {
        // yyyy-mm-dd or yyyy/mm/dd
        const parts = raw.replace(/\//g, '-').split('-').map(p => parseInt(p));
        isoDate = `${parts[0]}-${String(parts[1]).padStart(2, '0')}-${String(parts[2]).padStart(2, '0')}`;
      } else if (/\d{1,2}[-/]\d{1,2}[-/]\d{4}/.test(raw)) {
        // dd-mm-yyyy or dd/mm/yyyy
        const parts = raw.replace(/\//g, '-').split('-').map(p => parseInt(p));
        isoDate = `${parts[2]}-${String(parts[1]).padStart(2, '0')}-${String(parts[0]).padStart(2, '0')}`;
      } else if (/\d{1,2}[-/]\d{1,2}[-/]\d{2}/.test(raw)) {
        // dd-mm-yy or dd/mm/yy
        const parts = raw.replace(/\//g, '-').split('-').map(p => parseInt(p));
        const year = parts[2] < 30 ? 2000 + parts[2] : 1900 + parts[2];
        isoDate = `${year}-${String(parts[1]).padStart(2, '0')}-${String(parts[0]).padStart(2, '0')}`;
      } else if (/\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/i.test(raw)) {
        // Parse "1 Jan 2024" format
        const monthMap: { [key: string]: number } = {
          jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6,
          jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12,
        };
        const monthMatch = raw.match(/(\d{1,2})\s+([A-Z][a-z]{2})[a-z]*\s+(\d{4})/i);
        if (monthMatch) {
          const day = parseInt(monthMatch[1]);
          const month = monthMap[monthMatch[2].toLowerCase()];
          const year = parseInt(monthMatch[3]);
          isoDate = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        }
      }

      // Validate date is reasonable (not in far future, not before 1970)
      if (isoDate && !seen.has(isoDate)) {
        try {
          const d = new Date(isoDate);
          const now = new Date();
          if (d.getFullYear() >= 1970 && d <= now) {
            seen.add(isoDate);
            dates.push(isoDate);
          }
        } catch (e) {
          // Skip invalid dates
        }
      }
    }
  }

  return dates;
}

/**
 * Guess merchant name from receipt text
 * Looks for: first substantial text line, invoice/po numbers, business names
 */
export function guessMerchant(text: string): string {
  const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 0);

  if (lines.length === 0) return 'Unknown';

  // Remove common header/footer clutter
  const stopWords = /^(Page|printed|date|time|total|subtotal|tax|vat|invoice|receipt|#|no\.|ref\.?|bill|amount|quantity|price|item|description|phone|fax|email|www|http|address|street|city|postal|zip|country|thank|welcome|signature|authorized)/i;

  for (const line of lines) {
    // Skip lines that are just numbers, dates, or obviously not names
    if (stopWords.test(line) || /^\d+$/.test(line) || /^\d{1,2}[-/]\d{1,2}/.test(line)) {
      continue;
    }

    // Look for lines with at least 3 alphabetic characters and not too long (probably a name)
    if (/[A-Za-z]{3,}/.test(line) && line.length < 100) {
      // Clean up common noise
      let cleaned = line
        .replace(/\*+/g, '')     // Remove asterisks
        .replace(/\|+/g, '')     // Remove pipes
        .replace(/#+/g, '')      // Remove hashes
        .replace(/\s{2,}/g, ' ') // Collapse whitespace
        .trim();

      // Prefer lines with word-like structure (spaces between words)
      if (cleaned.length > 2 && /\w/.test(cleaned)) {
        return cleaned;
      }
    }
  }

  // Fallback: return first non-empty line
  return lines[0] || 'Unknown';
}

/**
 * Guess currency from receipt text
 */
export function guessCurrency(text: string): string | null {
  const upperText = text.toUpperCase();

  // Check for currency symbols and codes
  if (text.includes('€') || upperText.includes('EUR') || upperText.includes('EURO')) return 'EUR';
  if (text.includes('$') || upperText.includes('USD') || upperText.includes('DOLLAR')) return 'USD';
  if (text.includes('£') || upperText.includes('GBP') || upperText.includes('POUND')) return 'GBP';
  if (upperText.includes('CHF') || upperText.includes('SWISS')) return 'CHF';
  if (text.includes('¥') || upperText.includes('JPY') || upperText.includes('YEN')) return 'JPY';
  if (upperText.includes('CAD') || upperText.includes('CANADIAN')) return 'CAD';
  if (upperText.includes('AUD') || upperText.includes('AUSTRALIAN')) return 'AUD';
  if (upperText.includes('SGD') || upperText.includes('SINGAPORE')) return 'SGD';
  if (upperText.includes('HKD') || upperText.includes('HONG KONG')) return 'HKD';
  if (upperText.includes('INR') || upperText.includes('RUPEE')) return 'INR';
  if (upperText.includes('CNY') || upperText.includes('YUAN')) return 'CNY';

  return null;
}
