# InvoiceProvider Advanced Features Guide

This document provides a comprehensive reference for all advanced features added to the `InvoiceProvider` class.

## Table of Contents

1. [Bulk Operations](#bulk-operations)
2. [Filtering & Search](#filtering--search)
3. [Statistics & Analytics](#statistics--analytics)
4. [Export & Sharing](#export--sharing)
5. [Templates](#templates)
6. [Reminders](#reminders)
7. [Usage Examples](#usage-examples)

---

## Bulk Operations

Perform actions on multiple invoices simultaneously.

### `markMultipleAsPaid(List<String> invoiceIds)`

Mark multiple invoices as paid in one operation.

```dart
// Mark 3 invoices as paid
final success = await provider.markMultipleAsPaid(['inv1', 'inv2', 'inv3']);
if (success) {
  print('All invoices marked as paid');
}
```

**Parameters:**
- `invoiceIds`: List of invoice IDs to mark as paid

**Returns:** `Future<bool>` - True if successful, false otherwise

**Side Effects:**
- Updates invoice status to 'paid'
- Triggers appropriate Cloud Functions
- Awards AuraTokens if configured

---

### `deleteMultiple(List<String> invoiceIds)`

Delete multiple invoices in one operation.

```dart
// Delete selected invoices
final success = await provider.deleteMultiple(selectedInvoiceIds);
if (success) {
  print('${selectedInvoiceIds.length} invoices deleted');
}
```

**Parameters:**
- `invoiceIds`: List of invoice IDs to delete

**Returns:** `Future<bool>` - True if successful, false otherwise

**Side Effects:**
- Removes invoices from Firestore
- Updates provider state
- Removes from Firebase Storage if PDFs exist

---

### `duplicateInvoice(String invoiceId)`

Create a copy of an invoice with status set to 'draft'.

```dart
// Duplicate an invoice for a recurring client
final success = await provider.duplicateInvoice(originalInvoiceId);
if (success) {
  print('Invoice duplicated successfully');
  // Navigate to edit the new draft
}
```

**Parameters:**
- `invoiceId`: ID of invoice to duplicate

**Returns:** `Future<bool>` - True if successful, false otherwise

**New Invoice Includes:**
- All items and amounts from original
- Same tax rate and currency
- Status set to 'draft'
- New timestamp
- New invoice number with '-COPY' suffix
- New Firestore document ID

---

## Filtering & Search

Find invoices based on various criteria.

### `searchInvoices(String query)`

Search invoices by client name or invoice number (case-insensitive).

```dart
// Search for invoices
final results = provider.searchInvoices('Acme Corp');
final results2 = provider.searchInvoices('INV-2024');

// Can be used with Consumer to update UI
Consumer<InvoiceProvider>(
  builder: (context, provider, _) {
    final results = provider.searchInvoices(searchQuery);
    return ListView(
      children: results
          .map((inv) => InvoiceCard(invoice: inv))
          .toList(),
    );
  },
)
```

**Parameters:**
- `query`: Search string (searches client name and invoice number)

**Returns:** `List<InvoiceModel>` - Matching invoices

**Notes:**
- Operates on already-loaded invoices
- No network request
- Case-insensitive matching

---

### `getInvoicesByDateRange(DateTime startDate, DateTime endDate)`

Get invoices created within a date range.

```dart
// Get invoices from January 2024
final january = await provider.getInvoicesByDateRange(
  DateTime(2024, 1, 1),
  DateTime(2024, 1, 31),
);

// Get invoices from last 30 days
final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
final recent = await provider.getInvoicesByDateRange(
  thirtyDaysAgo,
  DateTime.now(),
);
```

**Parameters:**
- `startDate`: Inclusive start date
- `endDate`: Exclusive end date

**Returns:** `Future<List<InvoiceModel>>` - Invoices in date range

**Notes:**
- Operates on already-loaded invoices
- No network request
- Useful for reporting and analysis

---

### `getOverdueInvoices()`

Get unpaid invoices past their due date.

```dart
// Get all overdue invoices
final overdue = await provider.getOverdueInvoices();

// Display overdue count
print('${overdue.length} invoices are overdue');

// Total overdue amount
final total = overdue.fold<double>(
  0,
  (sum, inv) => sum + inv.total,
);
```

**Returns:** `Future<List<InvoiceModel>>` - Invoices that are overdue

**Criteria:**
- `status != 'paid'` (unpaid)
- `dueDate != null` (has a due date)
- `dueDate.isBefore(now)` (past due date)

---

### `loadOverdueInvoices()`

Load overdue invoices into provider state with loading indicator.

```dart
// Load and display overdue invoices
await provider.loadOverdueInvoices();
// provider.isLoading will be true during fetch
// provider.invoices will contain only overdue invoices
```

**Side Effects:**
- Sets `isLoading = true` during fetch
- Replaces `invoices` list with overdue invoices only
- Can be used with `Consumer` widget for reactive UI updates

---

## Statistics & Analytics

Analyze invoice data and generate metrics.

### `getPaidRevenue()`

Calculate total revenue from paid invoices.

```dart
final paidRevenue = await provider.getPaidRevenue();
print('Paid Revenue: \$${paidRevenue.toStringAsFixed(2)}');
```

**Returns:** `Future<double>` - Total amount from paid invoices

---

### `getPendingRevenue()`

Calculate total revenue from unpaid invoices.

```dart
final pending = await provider.getPendingRevenue();
print('Pending Payment: \$${pending.toStringAsFixed(2)}');
```

**Returns:** `Future<double>` - Total amount from unpaid invoices

**Criteria:**
- `status != 'paid'` (not paid)
- `status != 'draft'` (has been sent)

---

### `getAverageInvoiceAmount()`

Calculate average invoice total.

```dart
final average = await provider.getAverageInvoiceAmount();
print('Average Invoice: \$${average.toStringAsFixed(2)}');

// Can be used to set pricing expectations
if (average < 500) {
  print('Consider raising prices or target larger clients');
}
```

**Returns:** `Future<double>` - Average invoice total

**Returns 0.0 if:**
- No invoices exist
- Any error occurs

---

### `getMonthlyRevenue()`

Get revenue breakdown by month.

```dart
final monthly = await provider.getMonthlyRevenue();

// Results: {'2024-01': 5000.0, '2024-02': 7500.0, ...}
monthly.forEach((month, revenue) {
  print('$month: \$${revenue.toStringAsFixed(2)}');
});

// Chart data for business intelligence
final chartData = monthly.entries
    .map((e) => {'month': e.key, 'revenue': e.value})
    .toList();
```

**Returns:** `Future<Map<String, double>>` - Monthly revenue breakdown

**Keys Format:** `'YYYY-MM'` (e.g., '2024-01', '2024-12')

**Includes Only:** Paid invoices

---

### `getInvoiceStats()`

Get comprehensive invoice statistics in one call.

```dart
final stats = await provider.getInvoiceStats();

// Returns:
// {
//   'totalRevenue': 50000.0,
//   'paidRevenue': 45000.0,
//   'pendingRevenue': 5000.0,
//   'averageAmount': 1250.0,
//   'totalInvoices': 40,
//   'paidInvoices': 36,
//   'draftInvoices': 2,
//   'sentInvoices': 2,
//   'overdueInvoices': 1,
// }

print('Total Revenue: \$${stats['totalRevenue']}');
print('Overdue: ${stats['overdueInvoices']} invoices');
```

**Returns:** `Future<Map<String, dynamic>>` - Complete statistics object

**Included Metrics:**
- `totalRevenue`: Sum of all invoices
- `paidRevenue`: Sum of paid invoices only
- `pendingRevenue`: Sum of sent but unpaid invoices
- `averageAmount`: Average invoice amount
- `totalInvoices`: Count of all invoices
- `paidInvoices`: Count of paid invoices
- `draftInvoices`: Count of draft invoices
- `sentInvoices`: Count of sent invoices
- `overdueInvoices`: Count of overdue invoices

**Use Cases:**
- Dashboard widgets
- Business reporting
- Performance analysis

---

## Export & Sharing

Export invoice data in standard formats.

### `exportToCSV()`

Export all invoices to CSV format.

```dart
final csvData = await provider.exportToCSV();

if (csvData != null) {
  // Save to file or share
  await File('invoices.csv').writeAsString(csvData);
  
  // Or share via email
  await Share.share(csvData, subject: 'Invoices Export');
}
```

**Returns:** `Future<String?>` - CSV string, or null on error

**CSV Format:**
```
Invoice Number,Client Name,Amount,Tax,Total,Currency,Status,Created Date,Due Date
INV-2024-001,Acme Corp,5000.00,500.00,5500.00,USD,paid,2024-01-15,2024-02-15
```

**Columns:**
1. Invoice Number
2. Client Name
3. Subtotal Amount
4. Tax Amount
5. Total Amount
6. Currency Code
7. Status (draft, sent, paid)
8. Created Date (YYYY-MM-DD)
9. Due Date (YYYY-MM-DD or N/A)

---

### `exportFilteredToCSV(String status)`

Export invoices of specific status to CSV.

```dart
// Export only paid invoices
final paidCSV = await provider.exportFilteredToCSV('paid');

// Export only drafts
final draftCSV = await provider.exportFilteredToCSV('draft');

// Export only pending
final sentCSV = await provider.exportFilteredToCSV('sent');
```

**Parameters:**
- `status`: Invoice status to filter ('draft', 'sent', 'paid')

**Returns:** `Future<String?>` - Filtered CSV string

**Use Cases:**
- Tax reporting
- Accounting exports
- Client communications

---

### `getInvoiceShareData(String invoiceId)`

Get shareable invoice data in JSON format.

```dart
final shareData = provider.getInvoiceShareData(invoiceId);

if (shareData != null) {
  // Share JSON string
  await Share.share(
    shareData,
    subject: 'Invoice Details',
  );
}
```

**Returns:** `String?` - JSON representation of invoice

**Includes:**
- All invoice fields
- All line items
- Client information
- Dates and amounts

---

## Templates

Save and reuse invoice templates.

### `saveAsTemplate(String invoiceId, String templateName)`

Save an invoice as a reusable template.

```dart
// Save current invoice as template for this client
provider.saveAsTemplate(
  invoiceId,
  'Monthly Retainer - Acme Corp',
);

// Template is now available for reuse
```

**Parameters:**
- `invoiceId`: ID of invoice to save as template
- `templateName`: Name for the template (informational)

**Side Effects:**
- Creates template with status = 'template'
- Assigned new unique template ID
- Available via `getTemplates()`

---

### `getTemplates()`

Retrieve all saved templates.

```dart
final allTemplates = provider.getTemplates();

// Display templates in dropdown
DropdownButton(
  items: allTemplates
      .map((t) => DropdownMenuItem(
            value: t.id,
            child: Text(t.clientName),
          ))
      .toList(),
  onChanged: (templateId) {
    // Create invoice from template
  },
)
```

**Returns:** `List<InvoiceModel>` - All saved templates

**Usage:**
- Select template from UI
- Pass to `createFromTemplate()`

---

### `createFromTemplate(String templateId, String clientId, String clientName, String clientEmail)`

Create a new invoice from a template.

```dart
// Create invoice from template for new client
final success = await provider.createFromTemplate(
  templateId: 'template_123',
  clientId: 'new_client_456',
  clientName: 'New Client Inc',
  clientEmail: 'invoice@newclient.com',
);

if (success) {
  // Navigate to edit new invoice
  context.push('/invoice/create?id=${provider.invoices.first.id}');
}
```

**Parameters:**
- `templateId`: ID of template to use
- `clientId`: New client ID
- `clientName`: New client name
- `clientEmail`: New client email

**Returns:** `Future<bool>` - Success status

**New Invoice:**
- Copies all items and amounts from template
- Uses new client information
- Status set to 'draft'
- Due date = today + 30 days
- New timestamp and ID

---

### `deleteTemplate(String templateId)`

Delete a saved template.

```dart
// Remove template
provider.deleteTemplate(templateId);

// Update UI
setState(() {});
```

**Parameters:**
- `templateId`: ID of template to delete

**Side Effects:**
- Removes from `templates` list
- Triggers notifyListeners()

---

## Reminders

Set and manage payment reminders.

### `setReminderDate(String invoiceId, DateTime reminderDate)`

Set a reminder date for an invoice.

```dart
// Set reminder for 2 days before due date
final dueDate = invoice.dueDate!;
final reminderDate = dueDate.subtract(Duration(days: 2));

provider.setReminderDate(invoiceId, reminderDate);

// Now shows in getUpcomingReminders()
```

**Parameters:**
- `invoiceId`: Invoice ID
- `reminderDate`: When to send reminder

**Side Effects:**
- Stores in `reminderDates` map
- Triggers notifyListeners()

---

### `getUpcomingReminders()`

Get reminders due in the next 7 days.

```dart
final upcomingReminders = await provider.getUpcomingReminders();

// Returns list of reminders
// [{
//   'invoiceId': 'inv123',
//   'invoiceNumber': 'INV-2024-001',
//   'clientName': 'Acme Corp',
//   'amount': 5500.0,
//   'dueDate': DateTime(...),
//   'daysUntilDue': 2,
// }, ...]

for (final reminder in upcomingReminders) {
  print('Reminder: ${reminder['clientName']} - '
        '${reminder['daysUntilDue']} days until due');
}
```

**Returns:** `Future<List<Map<String, dynamic>>>` - Upcoming reminders

**Reminder Criteria:**
- Has a reminder date set
- Reminder date is within next 7 days
- Invoice status != 'paid'

**Fields in Each Reminder:**
- `invoiceId`: Invoice ID
- `invoiceNumber`: Invoice number
- `clientName`: Client name
- `amount`: Invoice total
- `dueDate`: Due date
- `daysUntilDue`: Days until reminder

---

### `sendPaymentReminder(String invoiceId)`

Send a payment reminder email to the client.

```dart
// Send reminder email
final success = await provider.sendPaymentReminder(invoiceId);

if (success) {
  print('Reminder sent to ${invoice.clientEmail}');
}
```

**Parameters:**
- `invoiceId`: Invoice ID to remind about

**Returns:** `Future<bool>` - Success status

**Side Effects:**
- Sends email to invoice client
- Uses InvoiceService email method
- Can trigger Cloud Function for logging

---

### `hasReminder(String invoiceId)`

Check if invoice has a reminder set.

```dart
if (provider.hasReminder(invoiceId)) {
  print('Reminder is set for this invoice');
  // Show reminder icon in UI
}
```

**Parameters:**
- `invoiceId`: Invoice ID to check

**Returns:** `bool` - True if reminder exists

---

### `removeReminder(String invoiceId)`

Remove a reminder for an invoice.

```dart
// Cancel reminder
provider.removeReminder(invoiceId);

// Removed from upcoming reminders
```

**Parameters:**
- `invoiceId`: Invoice ID

**Side Effects:**
- Removes from `reminderDates` map
- Triggers notifyListeners()

---

## Usage Examples

### Complete Invoice Dashboard

```dart
class InvoiceDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(invoiceProvider);
    
    return FutureBuilder(
      future: Future.wait([
        provider.getTotalRevenue(),
        provider.getPaidRevenue(),
        provider.getPendingRevenue(),
        provider.getAverageInvoiceAmount(),
        provider.getMonthlyRevenue(),
        provider.getUpcomingReminders(),
        provider.getInvoiceStats(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingWidget();
        }
        
        final totalRevenue = snapshot.data![0] as double;
        final paidRevenue = snapshot.data![1] as double;
        final pendingRevenue = snapshot.data![2] as double;
        final averageAmount = snapshot.data![3] as double;
        final monthly = snapshot.data![4] as Map<String, double>;
        final reminders = snapshot.data![5] as List<Map<String, dynamic>>;
        final stats = snapshot.data![6] as Map<String, dynamic>;
        
        return Column(
          children: [
            // Stats cards
            Row(
              children: [
                StatCard('Total Revenue', '\$${totalRevenue.toStringAsFixed(2)}'),
                StatCard('Paid', '\$${paidRevenue.toStringAsFixed(2)}'),
                StatCard('Pending', '\$${pendingRevenue.toStringAsFixed(2)}'),
                StatCard('Average', '\$${averageAmount.toStringAsFixed(2)}'),
              ],
            ),
            
            // Monthly revenue chart
            MonthlyRevenueChart(data: monthly),
            
            // Upcoming reminders
            RemindersSection(reminders: reminders),
            
            // Invoice statistics
            InvoiceStatsCard(stats: stats),
          ],
        );
      },
    );
  }
}
```

### Bulk Invoice Management

```dart
class BulkInvoiceManager extends ConsumerWidget {
  final List<String> selectedIds = [];
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(invoiceProvider);
    
    return Column(
      children: [
        Text('${selectedIds.length} invoices selected'),
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                final success = await provider.markMultipleAsPaid(selectedIds);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(
                    success ? 'Invoices marked as paid' : 'Error'
                  )),
                );
              },
              child: Text('Mark as Paid'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await provider.deleteMultiple(selectedIds);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(
                    success ? 'Invoices deleted' : 'Error'
                  )),
                );
              },
              child: Text('Delete'),
            ),
          ],
        ),
      ],
    );
  }
}
```

### Search and Filter

```dart
class InvoiceSearchScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(invoiceProvider);
    final searchQuery = useState('');
    
    return Column(
      children: [
        // Search input
        TextField(
          onChanged: (value) => searchQuery.value = value,
          decoration: InputDecoration(
            labelText: 'Search invoices',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        
        // Search results
        Expanded(
          child: ListView(
            children: provider.searchInvoices(searchQuery.value)
                .map((invoice) => InvoiceCard(invoice: invoice))
                .toList(),
          ),
        ),
        
        // Filter buttons
        Row(
          children: [
            FilterChip(
              label: Text('Overdue'),
              onSelected: (_) => provider.loadOverdueInvoices(),
            ),
            FilterChip(
              label: Text('Paid'),
              onSelected: (_) => provider.loadInvoicesByStatus('paid'),
            ),
            FilterChip(
              label: Text('Draft'),
              onSelected: (_) => provider.loadInvoicesByStatus('draft'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## Best Practices

1. **Batch Operations**: Use bulk methods for better performance
2. **Caching**: Load invoices once, use local methods for filtering
3. **Error Handling**: Always check return values and `provider.error`
4. **Real-time Updates**: Use `watchInvoices()` for live data
5. **Templates**: Save recurring invoice types for faster creation
6. **Reminders**: Set reminders for all invoices with due dates
7. **Analytics**: Generate monthly reports for business insights
8. **Export**: Regular exports for backup and accounting

---

## Summary

The enhanced InvoiceProvider provides enterprise-grade functionality:

- **Bulk Operations**: Manage multiple invoices efficiently
- **Smart Search**: Find invoices quickly by name or number
- **Advanced Analytics**: Comprehensive business metrics
- **Export Capabilities**: Standard CSV and JSON formats
- **Template System**: Reuse invoice structures
- **Reminder Management**: Never miss payment deadlines

All features are production-ready with proper error handling and state management.
