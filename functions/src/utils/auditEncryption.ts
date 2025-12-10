/**
 * auditEncryption.ts
 *
 * Encryption utilities for sensitive audit data
 *
 * Uses AES-256-GCM (Galois/Counter Mode) for authenticated encryption
 * Requires ENCRYPTION_KEY_BASE64 environment variable (32-byte base64-encoded key)
 *
 * Usage:
 * ```typescript
 * const encrypted = encryptField('sensitive data');
 * // Store: { ciphertext, iv, tag }
 *
 * const decrypted = decryptField(encrypted.ciphertext, encrypted.iv, encrypted.tag);
 * ```
 *
 * For production, use Google Cloud KMS instead of storing keys in environment variables.
 */

import * as crypto from 'crypto';

/**
 * Load encryption key from environment
 * Must be 32 bytes when base64-decoded (for AES-256)
 */
const ENCRYPTION_KEY_B64 = process.env.ENCRYPTION_KEY_BASE64 || '';

/**
 * Validate key on module load
 */
function validateKey(): void {
  if (!ENCRYPTION_KEY_B64) {
    console.warn('[encryption] ENCRYPTION_KEY_BASE64 not set. Encryption disabled.');
    return;
  }

  try {
    const key = Buffer.from(ENCRYPTION_KEY_B64, 'base64');
    if (key.length !== 32) {
      console.warn(
        `[encryption] ENCRYPTION_KEY_BASE64 invalid length: ${key.length} bytes (expected 32). Use: openssl rand -base64 32`,
      );
    }
  } catch (e) {
    console.warn('[encryption] ENCRYPTION_KEY_BASE64 is not valid base64:', e);
  }
}

validateKey();

/**
 * Encrypt a string using AES-256-GCM
 *
 * Returns object with:
 * - ciphertext: base64-encoded encrypted data
 * - iv: base64-encoded initialization vector (96-bit for GCM)
 * - tag: base64-encoded authentication tag
 *
 * Throws if key is missing or invalid
 *
 * @param plaintext Plain text to encrypt
 * @returns Encrypted data with iv and auth tag
 */
export function encryptField(plaintext: string): {
  ciphertext: string;
  iv: string;
  tag: string;
} {
  if (!ENCRYPTION_KEY_B64) {
    throw new Error(
      'Encryption not configured. Set ENCRYPTION_KEY_BASE64 environment variable. For production, use Google Cloud KMS.',
    );
  }

  try {
    const key = Buffer.from(ENCRYPTION_KEY_B64, 'base64');

    if (key.length !== 32) {
      throw new Error(`Invalid key length: ${key.length} bytes (expected 32)`);
    }

    // Generate random 96-bit IV (recommended for GCM)
    const iv = crypto.randomBytes(12);

    // Create cipher
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);

    // Encrypt
    const encrypted = Buffer.concat([
      cipher.update(plaintext, 'utf8'),
      cipher.final(),
    ]);

    // Get authentication tag (16 bytes)
    const tag = cipher.getAuthTag();

    return {
      ciphertext: encrypted.toString('base64'),
      iv: iv.toString('base64'),
      tag: tag.toString('base64'),
    };
  } catch (err) {
    console.error('[encryption-error] encryptField:', err);
    throw err;
  }
}

/**
 * Decrypt a string encrypted with encryptField()
 *
 * @param ciphertextB64 Base64-encoded ciphertext
 * @param ivB64 Base64-encoded initialization vector
 * @param tagB64 Base64-encoded authentication tag
 * @returns Decrypted plaintext
 * @throws If decryption fails or authentication tag is invalid
 */
export function decryptField(
  ciphertextB64: string,
  ivB64: string,
  tagB64: string,
): string {
  if (!ENCRYPTION_KEY_B64) {
    throw new Error(
      'Encryption not configured. Set ENCRYPTION_KEY_BASE64 environment variable. For production, use Google Cloud KMS.',
    );
  }

  try {
    const key = Buffer.from(ENCRYPTION_KEY_B64, 'base64');

    if (key.length !== 32) {
      throw new Error(`Invalid key length: ${key.length} bytes (expected 32)`);
    }

    const iv = Buffer.from(ivB64, 'base64');
    const tag = Buffer.from(tagB64, 'base64');
    const ciphertext = Buffer.from(ciphertextB64, 'base64');

    // Create decipher
    const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);

    // Set authentication tag (must match for integrity)
    decipher.setAuthTag(tag);

    // Decrypt
    const decrypted = Buffer.concat([
      decipher.update(ciphertext),
      decipher.final(),
    ]);

    return decrypted.toString('utf8');
  } catch (err) {
    console.error('[encryption-error] decryptField:', err);
    throw err;
  }
}

/**
 * Check if encryption is enabled
 *
 * Returns true if ENCRYPTION_KEY_BASE64 is set and valid
 */
export function isEncryptionEnabled(): boolean {
  if (!ENCRYPTION_KEY_B64) return false;

  try {
    const key = Buffer.from(ENCRYPTION_KEY_B64, 'base64');
    return key.length === 32;
  } catch {
    return false;
  }
}

/**
 * Encrypt an entire audit entry (selective fields)
 *
 * Encrypts sensitive fields: before, after, meta
 * Leaves audit trail fields unencrypted for searchability
 *
 * @param entry Audit entry with potentially sensitive data
 * @returns Entry with encrypted sensitive fields
 */
export interface EncryptedAuditEntry {
  [key: string]: any;
  before_encrypted?: {
    ciphertext: string;
    iv: string;
    tag: string;
  };
  after_encrypted?: {
    ciphertext: string;
    iv: string;
    tag: string;
  };
  meta_encrypted?: {
    ciphertext: string;
    iv: string;
    tag: string;
  };
}

export function encryptAuditEntry(entry: Record<string, any>): EncryptedAuditEntry {
  if (!isEncryptionEnabled()) {
    return entry; // Return unencrypted if not configured
  }

  const encrypted: EncryptedAuditEntry = { ...entry };

  // Encrypt sensitive fields
  if (entry.before) {
    encrypted.before_encrypted = encryptField(JSON.stringify(entry.before));
    delete encrypted.before; // Remove plaintext
  }

  if (entry.after) {
    encrypted.after_encrypted = encryptField(JSON.stringify(entry.after));
    delete encrypted.after; // Remove plaintext
  }

  if (entry.meta) {
    encrypted.meta_encrypted = encryptField(JSON.stringify(entry.meta));
    delete encrypted.meta; // Remove plaintext
  }

  return encrypted;
}

/**
 * Decrypt an encrypted audit entry
 *
 * @param entry Encrypted audit entry
 * @returns Entry with decrypted sensitive fields
 */
export function decryptAuditEntry(
  entry: EncryptedAuditEntry,
): Record<string, any> {
  if (!isEncryptionEnabled()) {
    return entry; // Return as-is if not configured
  }

  const decrypted: Record<string, any> = { ...entry };

  // Decrypt sensitive fields
  if (entry.before_encrypted) {
    const plaintext = decryptField(
      entry.before_encrypted.ciphertext,
      entry.before_encrypted.iv,
      entry.before_encrypted.tag,
    );
    decrypted.before = JSON.parse(plaintext);
    delete decrypted.before_encrypted; // Remove encrypted
  }

  if (entry.after_encrypted) {
    const plaintext = decryptField(
      entry.after_encrypted.ciphertext,
      entry.after_encrypted.iv,
      entry.after_encrypted.tag,
    );
    decrypted.after = JSON.parse(plaintext);
    delete decrypted.after_encrypted; // Remove encrypted
  }

  if (entry.meta_encrypted) {
    const plaintext = decryptField(
      entry.meta_encrypted.ciphertext,
      entry.meta_encrypted.iv,
      entry.meta_encrypted.tag,
    );
    decrypted.meta = JSON.parse(plaintext);
    delete decrypted.meta_encrypted; // Remove encrypted
  }

  return decrypted;
}

/**
 * Example usage documentation
 *
 * For sensitive PII or payment data:
 *
 * ```typescript
 * // Encrypt on write
 * const encrypted = encryptAuditEntry({
 *   action: 'invoice.paid',
 *   before: { amount: 1000, currency: 'USD' },
 *   after: { amount: 1000, currency: 'USD' },
 *   meta: { paymentMethodLast4: '4242' },
 *   tags: ['payment']
 * });
 *
 * // Stored in Firestore:
 * // {
 * //   action: 'invoice.paid',
 * //   before_encrypted: { ciphertext: '...', iv: '...', tag: '...' },
 * //   after_encrypted: { ciphertext: '...', iv: '...', tag: '...' },
 * //   meta_encrypted: { ciphertext: '...', iv: '...', tag: '...' },
 * //   tags: ['payment']
 * // }
 *
 * // Decrypt on read (in Cloud Functions or admin console)
 * const decrypted = decryptAuditEntry(storedEntry);
 * // Returns original data structure with decrypted fields
 * ```
 *
 * For production, consider:
 * 1. Use Google Cloud KMS for key management
 * 2. Implement key rotation strategy
 * 3. Log decryption access for audit purposes
 * 4. Restrict decryption to authorized users only
 */
