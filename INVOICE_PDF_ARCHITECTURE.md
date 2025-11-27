# Invoice PDF & Expense System - Visual Architecture

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP (Client)                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │  Invoice UI      │  │  Expense UI      │  │  PDF Preview     │  │
│  │  Screens         │  │  Screens         │  │  Screens         │  │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘  │
│           │                     │                      │             │
│           └─────────────────────┼──────────────────────┘             │
│                                 ▼                                     │
│              ┌──────────────────────────────────┐                    │
│              │     InvoiceService (Enhanced)    │                    │
│              │  ┌────────────────────────────┐  │                    │
│              │  │ PDF Generation:             │  │                    │
│              │  │ • generateLocalPdf()       │  │                    │
│              │  │ • generateLocalPdfWith...()│  │                    │
│              │  │                            │  │                    │
│              │  │ Expense Linking:           │  │                    │
│              │  │ • linkExpenseToInvoice()   │  │                    │
│              │  │ • unlinkExpenseFromInvoice │  │                    │
│              │  │ • getLinkedExpenses()      │  │                    │
│              │  │ • watchLinkedExpenses()    │  │                    │
│              │  │ • calculateTotal...()      │  │                    │
│              │  │ • syncInvoiceTotal...()    │  │                    │
│              │  └────────────────────────────┘  │                    │
│              └──────────┬───────────────────────┘                    │
│                         │                                             │
│        ┌────────────────┼────────────────┐                           │
│        ▼                ▼                ▼                           │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐               │
│  │LocalPdf      │ │Firestore     │ │Firebase      │               │
│  │Generator     │ │Real-time     │ │Storage       │               │
│  │              │ │Streams       │ │              │               │
│  │• generate    │ │              │ │• Save PDF    │               │
│  │  InvoicePdf()│ │• watch       │ │• Get Signed  │               │
│  │• generate    │ │  Linked      │ │  URL         │               │
│  │  Invoice...()│ │  Expenses    │ │              │               │
│  └──────────────┘ └──────────────┘ └──────────────┘               │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
                    ▼            ▼            ▼
         ┌──────────────────┐ ┌──────────────────┐
         │  Cloud Function  │ │  Firestore       │
         │  generateInvoice │ │  Database        │
         │  Pdf             │ │                  │
         │  (Puppeteer)     │ │ • invoices       │
         │                  │ │ • expenses       │
         │  • Auth check    │ │ • audit_logs     │
         │  • Validate      │ │                  │
         │  • Render HTML   │ │ Security Rules:  │
         │  • Puppeteer PDF │ │ • User ownership │
         │  • Upload Storage│ │ • Read/Write     │
         │  • Update Doc    │ │ • Audit trail    │
         │  • Return URL    │ │                  │
         └──────────────────┘ └──────────────────┘
                    │                  ▲
                    └──────────────────┘
```

## Data Flow Diagrams

### 1. PDF Generation Flow (Local)

```
User clicks "Generate PDF"
        ▼
InvoiceService.generateLocalPdf()
        ▼
LocalPdfGenerator.generateInvoicePdf()
        ▼
    ┌───┴────────────────────────┐
    ▼                            ▼
Build PDF Structure         Fetch Invoice Data
• Header                    • Client details
• Items table               • Business info
• Totals                    • Items array
• Notes                     • Amounts
• Linked exp count
        │                        │
        └────────────┬───────────┘
                     ▼
            Render PDF (pw.Document)
                     ▼
            Convert to Uint8List
                     ▼
            Return to Service
                     ▼
        Save to Firebase Storage
                     ▼
        Show success notification
```

### 2. PDF Generation Flow (Cloud)

```
User clicks "Generate PDF (Cloud)"
        ▼
Call FirebaseFunctions.httpsCallable('generateInvoicePdf')
        ▼
        ┌─────────────────────────────────┐
        │  Cloud Function                 │
        │  (generateInvoicePdf.ts)        │
        └─────────────────────────────────┘
        ▼
    Check Auth (context.auth)
        ▼
    Validate Parameters
        ▼
    Render HTML Template
        ├── Invoice header
        ├── Client details
        ├── Items table
        ├── Totals section
        └── Linked expenses info
        ▼
    Launch Puppeteer Browser
        ▼
    Set HTML Content
        ▼
    Generate PDF (Puppeteer)
        ▼
    Upload to Firebase Storage
        (path: invoices/{userId}/{invoiceNumber}.pdf)
        ▼
    Generate Signed URL (30 days)
        ▼
    Update Invoice Document
        (set: pdfUrl, pdfGeneratedAt)
        ▼
    Return { success, url, filePath, size }
        ▼
    Show download link to user
```

### 3. Expense Linking Flow

```
User selects "Link to Invoice"
        ▼
Show Invoice Picker Dialog
        ▼
User selects invoice
        ▼
InvoiceService.linkExpenseToInvoice()
        ▼
        ┌─────────────────────────────────────┐
        │ Firestore Transactions              │
        └─────────────────────────────────────┘
        ▼
Update Invoice Document:
  • linkedExpenseIds += [expenseId]
  • updatedAt = NOW
        ▼
Update Expense Document:
  • invoiceId = invoiceId
  • updatedAt = NOW
        ▼
Log Audit Entry:
  • action: "expense_linked"
  • timestamp: NOW
        ▼
watchLinkedExpenses() Stream triggers
        ▼
UI Updates in Real-time
        ▼
Show success notification
```

### 4. Expense Unlinking Flow

```
User clicks "Unlink" on expense
        ▼
Show Confirmation Dialog
        ▼
InvoiceService.unlinkExpenseFromInvoice()
        ▼
        ┌─────────────────────────────────────┐
        │ Firestore Transactions              │
        └─────────────────────────────────────┘
        ▼
Update Invoice Document:
  • linkedExpenseIds -= [expenseId]
  • updatedAt = NOW
        ▼
Update Expense Document:
  • invoiceId = null
  • updatedAt = NOW
        ▼
Log Audit Entry:
  • action: "expense_unlinked"
  • timestamp: NOW
        ▼
watchLinkedExpenses() Stream triggers
        ▼
UI Updates in Real-time
        ▼
Show success notification
```

### 5. Real-time Expense Synchronization

```
watchLinkedExpenses(invoiceId)
        ▼
    ┌─────────────────────────────────┐
    │ Firestore Listener              │
    │ Watches: invoices/{invoiceId}   │
    └─────────────────────────────────┘
        ▼
Document changes → Extract linkedExpenseIds
        ▼
    ┌─────────────────────────────────┐
    │ Query Expense Documents         │
    │ WHERE id IN linkedExpenseIds    │
    └─────────────────────────────────┘
        ▼
Listen to Expense Collection Snapshot
        ▼
    On Any Linked Expense Change:
    ├── Amount changed → total updates
    ├── Status changed → display updates
    ├── Details changed → list updates
    └── Document deleted → removed from list
        ▼
Stream.emit(List<Expense>)
        ▼
StreamBuilder rebuilds UI
        ▼
User sees updated data in real-time
```

## Database Schema

### Collections Structure

```
Firestore Database
│
├── invoices/
│   ├── {invoiceId}
│   │   ├── id: string
│   │   ├── userId: string
│   │   ├── invoiceNumber: string
│   │   ├── clientName: string
│   │   ├── items: Array<InvoiceItem>
│   │   ├── linkedExpenseIds: Array<string>
│   │   ├── status: enum
│   │   ├── pdfUrl: string
│   │   ├── pdfGeneratedAt: timestamp
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│   │
│   └── {invoiceId2}
│
├── expenses/
│   ├── {expenseId}
│   │   ├── id: string
│   │   ├── userId: string
│   │   ├── merchant: string
│   │   ├── amount: number
│   │   ├── invoiceId: string (reference)
│   │   ├── status: enum
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│   │
│   └── {expenseId2}
│
├── users/
│   ├── {userId}
│   │   ├── invoice_audit_log/ (subcollection)
│   │   │   ├── {auditId}
│   │   │   │   ├── invoiceId: string
│   │   │   │   ├── action: string
│   │   │   │   ├── details: object
│   │   │   │   └── timestamp: timestamp
│   │   │
│   │   └── expense_audit_log/ (subcollection)
│   │
│   └── {userId2}
│
└── projects/
    └── {projectId}
```

## Component Interaction Matrix

```
                │ Invoice │ Expense │ FireAuth │ Storage │ Firestore
────────────────┼─────────┼─────────┼──────────┼─────────┼──────────
LocalPdfGen     │  Read   │    -    │    -     │    -    │    -
CloudFunc       │  Read   │    -    │  Check   │  Write  │  Update
InvoiceService  │ CRUD    │   Read  │    -     │    -    │  Query
ExpenseService  │    -    │  CRUD   │    -     │    -    │  Query
UI (Invoice)    │  Read   │    -    │    -     │    -    │  Stream
UI (Expense)    │  Write  │  Read   │    -     │    -    │  Stream
────────────────┴─────────┴─────────┴──────────┴─────────┴──────────
```

## Security & Authorization Flow

```
User Action (Link Expense)
        ▼
    Check FirebaseAuth.currentUser
        ▼
    Is user authenticated?
    ├─ No  → Throw "User not authenticated"
    └─ Yes → Continue
        ▼
    InvoiceService.linkExpenseToInvoice()
        ▼
    Firestore Read Invoice Document
        ▼
    Firestore Rule Check:
    ├─ userId == request.auth.uid?
    ├─ Correct collection?
    └─ Valid document?
        ▼
    Update Operations with Server Timestamp
        ▼
    Firestore Rule Check on Update:
    ├─ Same userId maintained?
    ├─ No malicious fields?
    └─ Valid array operation?
        ▼
    Log Audit Entry (subcollection)
        ▼
    Return Success/Error to User
```

## Performance Optimization

```
PDF Generation Decision Tree:

User wants PDF
        ▼
    Is PDF large/complex?
    ├─ No  → Use LocalPdfGenerator (instant, client-side)
    │       ✓ Faster (~300-500ms)
    │       ✓ No server cost
    │       ✓ Works offline
    │
    └─ Yes → Use Cloud Function (professional, server-side)
            ✓ Better rendering (~3-5s)
            ✓ Handles complex layouts
            ✓ Stores on cloud
            ✓ Generates signed URL
```

## Real-time Update Chain

```
Expense Amount Changes
        ▼
FirebaseFirestore updates document
        ▼
watchLinkedExpenses(invoiceId) Stream listener triggers
        ▼
Read updated linkedExpenseIds array
        ▼
Query updated Expense documents
        ▼
Stream.emit(updatedList)
        ▼
StreamBuilder.builder() executes
        ▼
UI Rebuilds with new data
        ▼
User sees changes in <100ms
```

## Error Handling Flow

```
Operation (e.g., linkExpenseToInvoice)
        ▼
    Try Block:
    ├─ Validate inputs
    ├─ Check auth
    ├─ Perform Firestore operations
    └─ Log success
        ▼
    Catch Block:
    ├─ Log error with context
    ├─ Return user-friendly message
    ├─ Show error notification
    └─ Rollback if needed
        ▼
    Finally Block:
    └─ Clean up resources
```

## Deployment Architecture

```
Local Development
├── Flutter App (debug)
├── Firebase Emulator Suite
│   ├── Firestore Emulator
│   ├── Storage Emulator
│   └── Functions Emulator
└── LocalPdfGenerator (client-side)

Production Deployment
├── Flutter App (release)
├── Firebase Backend (cloud)
│   ├── Firestore (real database)
│   ├── Storage (real files)
│   ├── Auth (real authentication)
│   └── Cloud Functions (deployed)
│       └── generateInvoicePdf
└── Browser/Client
    └── LocalPdfGenerator
```

## Integration Points Summary

```
Expense System  ←──→  Invoice System  ←──→  PDF System
├── Link        │     ├── Store       │     ├── Render
├── Unlink      │     ├── Update      │     ├── Generate
├── Track       │     ├── Track       │     ├── Upload
└── Sync        │     └── Sync        │     └── Share
        │              │                    │
        └──────────────┼────────────────────┘
                       ▼
                Firestore Database
                (Central Source of Truth)
```

---

**Key Architectural Decisions:**

1. **Two PDF Methods:** Local (fast) + Cloud (professional)
2. **Real-time Streams:** No polling, instant updates
3. **Firestore as SSOT:** Single source of truth for all data
4. **Audit Trail:** All mutations tracked for accountability
5. **Security-First:** Auth checks at every layer
6. **Scalable Design:** Works for 1 invoice or 1M invoices

