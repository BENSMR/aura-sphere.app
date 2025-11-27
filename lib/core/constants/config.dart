class Config {
  static const String appName = 'AuraSphere Pro';
  static const int initialAuraTokens = 200;
  static const double defaultInvoiceTax = 0.20; // 20% example
  
  // Firestore Collections
  static const String firestoreUsersCollection = 'users';
  static const String firestoreExpensesCollection = 'expenses';
  static const String firestoreCRMCollection = 'crm';
  static const String firestoreProjectsCollection = 'projects';
  static const String firestoreInvoicesCollection = 'invoices';
  static const String firestoreReceiptsCollection = 'receipts';
  static const String firestoreAuraTokenTransactionsCollection = 'auraTokenTransactions';
}
