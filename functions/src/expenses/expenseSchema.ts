/**
 * Expense OCR Workflow - Firestore Schema Definitions
 * 
 * This file documents the Firestore schema for expenses created via the OCR workflow.
 * Path: /users/{uid}/expenses/{expenseId}
 */

/**
 * Expense document structure
 */
export interface ExpenseDocument {
  // Core identity
  expenseId: string;
  
  // User-provided/edited data
  merchant: string;
  totalAmount: number;
  currency: string; // ISO 4217 (EUR, USD, GBP, etc)
  date: string; // YYYY-MM-DD format
  status: ExpenseStatus;
  notes?: string;
  
  // OCR extracted data
  rawOcr: string; // Full Vision API text output
  parsed: ParsedOCRData;
  amounts: ParsedAmount[];
  dates: string[]; // ISO format dates extracted
  
  // File references
  attachments: Attachment[]; // List of receipt images/documents
  
  // Audit trail
  audit: AuditEntry[];
  
  // Timestamps
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt?: FirebaseFirestore.Timestamp;
  
  // Metadata
  editedBy?: string; // User ID of last editor
}

/**
 * Expense status enum
 */
export type ExpenseStatus = 
  | 'draft'           // User is editing
  | 'pending'         // Waiting for approval
  | 'approved'        // Approved by manager
  | 'rejected'        // Rejected by manager
  | 'paid';           // Reimbursed to user

/**
 * OCR-parsed data from Vision API
 */
export interface ParsedOCRData {
  rawText?: string;
  merchant?: string;
  total?: number;
  currency?: string;
  date?: string;
  amounts: ParsedAmount[];
  dates: string[];
}

/**
 * Parsed amount from OCR text
 */
export interface ParsedAmount {
  raw: string;  // Original text "23.50 EUR"
  value: number; // Numeric value 23.50
}

/**
 * File attachment (receipt image)
 */
export interface Attachment {
  path: string;      // Cloud Storage path: users/{uid}/expenses/{id}/receipt.jpg
  uploadedAt: FirebaseFirestore.Timestamp;
  name?: string;     // Original file name
}

/**
 * Audit trail entry
 */
export interface AuditEntry {
  action: AuditAction;
  at: FirebaseFirestore.Timestamp;
  by?: string; // User ID
}

/**
 * Audit action types
 */
export type AuditAction =
  | 'ocr_created'     // OCR extraction completed
  | 'created'         // Document created
  | 'edited'          // User edited fields
  | 'submitted'       // Submitted for approval
  | 'approved'        // Approved by manager
  | 'rejected'        // Rejected by manager
  | 'paid'           // Marked as paid
  | 'deleted';       // Document deleted

/**
 * Approval task subcollection
 * Path: /users/{uid}/expenses/{expenseId}/approvals/{approvalId}
 */
export interface ApprovalTask {
  status: ApprovalStatus;
  expenseAmount: number;
  merchant: string;
  expenseDate: string;
  
  // Timestamps
  createdAt: FirebaseFirestore.Timestamp;
  notified: boolean;
  notifiedAt?: FirebaseFirestore.Timestamp;
  
  // Resolution
  approvedBy?: string; // User ID of approver
  approvedAt?: FirebaseFirestore.Timestamp;
}

/**
 * Approval status
 */
export type ApprovalStatus = 'pending' | 'approved' | 'rejected';

/**
 * OCR Processing Result (from Cloud Function)
 */
export interface OCRProcessingResult {
  success: boolean;
  rawText: string;
  parsed: ParsedOCRData;
  amounts: ParsedAmount[];
  dates: string[];
  merchant: string;
  currency: string;
  timestamp: string;
}

/**
 * Example Firestore document:
 * 
 * {
 *   expenseId: "exp_abc123",
 *   merchant: "Coffee Shop",
 *   totalAmount: 23.5,
 *   currency: "EUR",
 *   date: "2025-12-01",
 *   status: "pending",
 *   notes: "Weekly meeting",
 *   
 *   rawOcr: "...",
 *   parsed: {
 *     merchant: "Coffee Shop",
 *     total: 23.5,
 *     currency: "EUR",
 *     date: "2025-12-01",
 *     amounts: [
 *       { raw: "23.50", value: 23.50 },
 *       { raw: "23,50 EUR", value: 23.50 }
 *     ],
 *     dates: ["2025-12-01"]
 *   },
 *   amounts: [{ raw: "23.50", value: 23.50 }],
 *   dates: ["2025-12-01"],
 *   
 *   attachments: [
 *     {
 *       path: "users/user123/expenses/exp_abc123/receipt-1733040000.jpg",
 *       uploadedAt: Timestamp(2025-12-01),
 *       name: "receipt.jpg"
 *     }
 *   ],
 *   
 *   audit: [
 *     { action: "ocr_created", at: Timestamp(...), by: "user123" },
 *     { action: "submitted", at: Timestamp(...), by: "user123" }
 *   ],
 *   
 *   createdAt: Timestamp(2025-12-01),
 *   updatedAt: Timestamp(2025-12-01),
 *   editedBy: "user123"
 * }
 */
