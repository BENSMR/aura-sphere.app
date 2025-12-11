import * as admin from 'firebase-admin';

/**
 * Tax Queue Request Type Definition
 *
 * Firestore Path: internal/tax_queue/requests/{requestId}
 *
 * Purpose:
 * - Decouples real-time entity creation from async tax calculation
 * - Enables batch processing of tax calculations (processTaxQueue)
 * - Provides audit trail and retry logic
 *
 * Lifecycle:
 * 1. Entity created (invoice, expense, PO) → onXxxCreateAutoAssign trigger fires
 * 2. Queue request created with processed=false, attempts=0
 * 3. processTaxQueue (scheduled 1m) picks up unprocessed requests
 * 4. determineTaxLogic called for each request
 * 5. Entity updated with tax fields (taxRate, taxAmount, total, taxBreakdown, etc.)
 * 6. Queue request marked as processed=true, processedAt set
 * 7. UI detects taxStatus change: 'queued' → 'calculated', refreshes display
 */
export interface TaxQueueRequest {
  /**
   * User ID (from parent invoice/expense)
   * Used to load correct entity from users/{uid}/invoices/... path
   */
  uid: string;

  /**
   * Full Firestore path to entity being taxed
   * Examples:
   *   - "users/{uid}/invoices/{invoiceId}"
   *   - "users/{uid}/expenses/{expenseId}"
   *   - "users/{uid}/purchaseOrders/{poId}"
   *
   * Path is used to load and update the entity
   */
  entityPath: string;

  /**
   * Entity type for processing logic
   * Values: 'invoice' | 'expense' | 'purchaseOrder' | ...
   *
   * Used to:
   * - Determine tax direction (sale vs purchase)
   * - Apply type-specific field names
   * - Route to appropriate update logic
   */
  entityType: 'invoice' | 'expense' | 'purchaseOrder';

  /**
   * Whether this queue request has been processed
   * Default: false
   * Set to true when tax calculation completes (successfully or with error)
   */
  processed: boolean;

  /**
   * Number of processing attempts
   * Incremented each time processTaxQueue tries to process this request
   * Used to implement exponential backoff or max retry limit
   * Max attempts typically: 3
   */
  attempts: number;

  /**
   * Timestamp when queue request was created
   * Set by onXxxCreateAutoAssign trigger
   * Helpful for monitoring queue age
   */
  createdAt?: admin.firestore.Timestamp;

  /**
   * Timestamp when queue request was processed
   * Set by processTaxQueue after successful or final failed attempt
   * Null until processing completes
   */
  processedAt?: admin.firestore.Timestamp;

  /**
   * Last error message if processing failed
   * Set by processTaxQueue if tax calculation threw
   * Useful for debugging and monitoring
   */
  lastError?: string;

  /**
   * Optional notes for special handling
   * Examples:
   *   - "Manual override: tax calculated offline"
   *   - "Requires manager approval due to VAT mismatch"
   */
  note?: string;

  /**
   * Optional related queue request ID
   * Used if this request triggers another tax calculation
   * Example: expense marked as reimbursable → creates invoice queue request
   */
  relatedRequestId?: string;

  /**
   * Optional taxQueueRequestId from entity
   * Back-reference from invoice/expense to this queue request
   * Allows entity to know which queue item calculated its taxes
   */
  entityQueueRequestId?: string;
}

/**
 * Data structure stored in entity (invoice/expense/PO)
 * Fields added by processTaxQueue after tax calculation
 */
export interface EntityTaxFields {
  /**
   * Tax status indicates calculation state
   * 'queued' → Waiting in tax queue for calculation
   * 'calculated' → Successfully calculated by server
   * 'manual' → Manually entered by user
   * 'error' → Tax calculation failed
   */
  taxStatus: 'queued' | 'calculated' | 'manual' | 'error';

  /**
   * Indicator that server:determineTaxLogic calculated this
   * Value: "server:determineTaxLogic"
   * Used to distinguish server-calculated vs manually entered
   */
  taxCalculatedBy?: string;

  /**
   * Tax rate applied (0.20 = 20%)
   * Loaded from config/tax_matrix/{country}
   */
  taxRate?: number;

  /**
   * Tax amount in base currency
   * Calculated as: (amount || totalAmount) * taxRate
   */
  taxAmount?: number;

  /**
   * Final total including tax
   * Calculated as: amount + taxAmount
   */
  total?: number;

  /**
   * ISO 3166-1 alpha-2 country code where tax applies
   * Determined by Company.country (seller location)
   * Used in audit trail
   */
  taxCountry?: string;

  /**
   * Detailed tax breakdown including:
   * {
   *   type: 'vat' | 'sales_tax' | 'none',
   *   rate: 0.20,
   *   standard: true,  // vs reduced rate
   *   country: 'FR',
   *   reverseCharge?: true,  // if EU B2B
   *   conversionRate?: 1.08,  // if FX conversion applied
   *   appliedLogic: "EU B2B reverse charge (buyer in different EU member)"
   * }
   */
  taxBreakdown?: {
    type: 'vat' | 'sales_tax' | 'none';
    rate: number;
    standard?: boolean;
    country?: string;
    reverseCharge?: boolean;
    conversionRate?: number;
    appliedLogic?: string;
    [key: string]: any;
  };

  /**
   * Optional notes about tax calculation
   * Examples:
   *   - "EU B2B reverse charge applied"
   *   - "Reduced VAT rate for services"
   *   - "Cross-border sale to non-EU country"
   */
  taxNote?: string;

  /**
   * Queue request ID that calculated this tax
   * Back-reference to internal/tax_queue/requests/{requestId}
   */
  taxQueueRequestId?: string;

  /**
   * Currency in which tax was calculated
   * Synced from Contact.currency or Company.defaultCurrency
   */
  currency?: string;

  /**
   * Timestamp when tax was last calculated
   */
  taxCalculatedAt?: admin.firestore.Timestamp;

  /**
   * Audit trail of all tax changes
   * Array of:
   * {
   *   action: 'tax_calculation_queued' | 'tax_calculation_completed' | 'tax_manual_override' | ...,
   *   queueRequestId?: string,
   *   oldRate?: number,
   *   newRate?: number,
   *   reason?: string,
   *   at: Timestamp
   * }
   */
  audit?: Array<{
    action: string;
    queueRequestId?: string;
    oldRate?: number;
    newRate?: number;
    reason?: string;
    at: admin.firestore.Timestamp;
    [key: string]: any;
  }>;
}

/**
 * Queue Processing Configuration
 *
 * Used by processTaxQueue to manage batch processing
 */
export interface QueueProcessingConfig {
  /** Batch size: how many queue requests to process per 1-minute run */
  batchSize: number;

  /** Max retry attempts before marking as error */
  maxAttempts: number;

  /** Whether to skip silently if entity not found */
  skipMissingEntities: boolean;

  /** Timeout in ms for each tax calculation */
  calculationTimeout: number;
}

/**
 * Default Processing Configuration
 */
export const DEFAULT_QUEUE_CONFIG: QueueProcessingConfig = {
  batchSize: 10,
  maxAttempts: 3,
  skipMissingEntities: true,
  calculationTimeout: 5000, // 5 seconds
};

/**
 * Helper to create a new tax queue request
 *
 * Usage:
 *   const request = createTaxQueueRequest({
 *     uid: 'user-123',
 *     entityPath: 'users/user-123/invoices/inv-456',
 *     entityType: 'invoice'
 *   });
 *   await firestore.collection('internal/tax_queue/requests').add(request);
 */
export function createTaxQueueRequest(
  uid: string,
  entityPath: string,
  entityType: 'invoice' | 'expense' | 'purchaseOrder',
  overrides?: Partial<TaxQueueRequest>,
): TaxQueueRequest {
  return {
    uid,
    entityPath,
    entityType,
    processed: false,
    attempts: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp() as any,
    ...overrides,
  };
}

/**
 * Helper to mark queue request as processed
 *
 * Usage:
 *   const update = markQueueRequestAsProcessed();
 *   await queueRef.update(update);
 */
export function markQueueRequestAsProcessed(
  lastError?: string,
  note?: string,
): Partial<TaxQueueRequest> {
  return {
    processed: true,
    processedAt: admin.firestore.FieldValue.serverTimestamp() as any,
    ...(lastError && { lastError }),
    ...(note && { note }),
  };
}

/**
 * Helper to increment queue request attempts
 *
 * Usage:
 *   const update = incrementQueueAttempts('Error message');
 *   await queueRef.update(update);
 */
export function incrementQueueAttempts(
  error?: string,
): Partial<TaxQueueRequest> {
  return {
    attempts: admin.firestore.FieldValue.increment(1) as any,
    ...(error && { lastError: error }),
  };
}
