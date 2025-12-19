// Firestore Collections
class FirestoreCollections {
  static const String users = 'users';
  static const String invoices = 'invoices';
  static const String expenses = 'expenses';
  static const String clients = 'clients';
  static const String products = 'products';
  static const String payments = 'payments';
  static const String deals = 'deals';
  static const String leads = 'leads';
  static const String projects = 'projects';
  static const String tasks = 'tasks';
  static const String estimates = 'estimates';
  static const String purchaseOrders = 'purchaseOrders';
  static const String suppliers = 'suppliers';
  static const String inventory = 'inventory';
  static const String subscriptions = 'subscriptions';
  static const String loyaltyPrograms = 'loyaltyPrograms';
  static const String loyaltyTransactions = 'loyaltyTransactions';
  static const String notifications = 'notifications';
  static const String auditLogs = 'auditLogs';
  static const String auraTokens = 'auraTokens';
  static const String auraTokenTransactions = 'auraTokenTransactions';
  static const String invoiceTemplates = 'invoiceTemplates';
  static const String emailTemplates = 'emailTemplates';
  static const String taxRates = 'taxRates';
  static const String fxRates = 'fxRates';
  static const String proactiveInsights = 'proactiveInsights';
  static const String aiRules = 'aiRules';
  static const String businessProfiles = 'businessProfiles';
  static const String teams = 'teams';
  static const String webhooks = 'webhooks';
}

// Storage Buckets
class StoragePaths {
  static const String receipts = 'receipts';
  static const String invoicePdfs = 'invoice_pdfs';
  static const String profileImages = 'profile_images';
  static const String documentUploads = 'documents';
  static const String attachments = 'attachments';
  static const String exports = 'exports';
}

// Feature Flags
class FeatureFlags {
  static const bool aiEnabled = true;
  static const bool ocrEnabled = true;
  static const bool cryptoEnabled = false;
  static const bool advancedAnalyticsEnabled = true;
  static const bool loyaltyEnabled = true;
  static const bool proactiveAgentsEnabled = true;
  static const bool invoiceAutomationEnabled = true;
  static const bool paymentProcessingEnabled = true;
  static const bool emailIntegrationEnabled = true;
  static const bool mobileAppEnabled = true;
}

// API Endpoints
class ApiEndpoints {
  static const String openaiApi = 'https://api.openai.com/v1';
  static const String stripeApi = 'https://api.stripe.com/v1';
  static const String sendgridApi = 'https://api.sendgrid.com/v3';
}

// Pagination
class PaginationConfig {
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

// File Size Limits
class FileLimits {
  static const int maxReceiptSize = 5 * 1024 * 1024; // 5MB
  static const int maxGeneralUploadSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageSize = 2 * 1024 * 1024; // 2MB
}

// Time Constants
class TimeConstants {
  static const Duration cacheExpiry = Duration(hours: 1);
  static const Duration tokenRefreshInterval = Duration(minutes: 55);
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration debounceDelay = Duration(milliseconds: 500);
}

// Default Values
class DefaultValues {
  static const String defaultCurrency = 'USD';
  static const String defaultLanguage = 'en';
  static const int invoiceOverdueThreshold = 30; // days
  static const double defaultTaxRate = 0.0;
}

// Role-Based Access Control
class RbacRoles {
  static const String admin = 'admin';
  static const String manager = 'manager';
  static const String accountant = 'accountant';
  static const String sales = 'sales';
  static const String support = 'support';
  static const String viewer = 'viewer';
  static const String user = 'user';
}

// Invoice Status
class InvoiceStatus {
  static const String draft = 'draft';
  static const String sent = 'sent';
  static const String viewed = 'viewed';
  static const String paid = 'paid';
  static const String overdue = 'overdue';
  static const String cancelled = 'cancelled';
  static const String refunded = 'refunded';
}

// Expense Status
class ExpenseStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String reimbursed = 'reimbursed';
  static const String archived = 'archived';
}

// Deal Stages
class DealStages {
  static const String prospect = 'prospect';
  static const String qualified = 'qualified';
  static const String proposal = 'proposal';
  static const String negotiation = 'negotiation';
  static const String won = 'won';
  static const String lost = 'lost';
}

// Payment Methods
class PaymentMethods {
  static const String stripe = 'stripe';
  static const String bankTransfer = 'bank_transfer';
  static const String cash = 'cash';
  static const String check = 'check';
  static const String crypto = 'crypto';
}

// Project Status
class ProjectStatus {
  static const String planning = 'planning';
  static const String inProgress = 'in_progress';
  static const String onHold = 'on_hold';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}
