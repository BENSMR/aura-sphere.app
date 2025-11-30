# 🔗 Business Profile & Invoice Export Integration - Practical Guide

**Status:** ✅ **IMPLEMENTATION READY**  
**Date:** November 28, 2025  
**Purpose:** Wire business profile screens into invoice workflow  
**Effort:** 30-45 minutes

---

## 🎯 Integration Overview

Connect these components into a complete workflow:

```
App Navigation
  ↓
Settings/Menu
  ├─ Business Profile Screen ← User configures branding
  │   ├─ Upload logo
  │   ├─ Set company details
  │   └─ Save profile
  │
Invoice List Screen
  ├─ Invoice Branding Preview (optional)
  │   └─ See live preview of branding
  │
  └─ Invoice Details Screen
      └─ Export Button
          └─ Invoice Export Screen
              ├─ Load business profile
              ├─ Merge with invoice
              ├─ Call Cloud Function
              └─ Display signed URLs
```

---

## 📱 Part 1: Navigate to Business Profile

### Option A: From Settings Menu

Add to your app's settings/menu screen:

```dart
// In your settings_screen.dart or menu_screen.dart

class SettingsScreen extends StatelessWidget {
  final String userId;
  const SettingsScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          // ... other settings ...
          
          ListTile(
            leading: Icon(Icons.business),
            title: Text('Business Profile'),
            subtitle: Text('Company details, logo, branding'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BusinessProfileScreen(userId: userId),
              ),
            ),
          ),
          
          ListTile(
            leading: Icon(Icons.preview),
            title: Text('Invoice Branding Preview'),
            subtitle: Text('See how invoices will look'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoiceBrandingScreen(userId: userId),
              ),
            ),
          ),
          
          // ... other settings ...
        ],
      ),
    );
  }
}
```

### Option B: From Bottom Navigation

```dart
// In your main app widget or navigation controller

bottomNavigationBar: BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Invoices'),
    BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Profile'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ],
  onTap: (index) {
    if (index == 2) {
      // Business Profile
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessProfileScreen(userId: userId),
        ),
      );
    }
  },
),
```

### Option C: FloatingActionButton

```dart
// In your invoice list screen

FloatingActionButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BusinessProfileScreen(
        userId: FirebaseAuth.instance.currentUser!.uid,
      ),
    ),
  ),
  tooltip: 'Business Profile',
  child: Icon(Icons.business),
)
```

---

## 🧾 Part 2: Invoice Export Integration

### Step 2.1: Add Export Button to Invoice Details

```dart
// In your invoice_details_screen.dart

class InvoiceDetailsScreen extends StatefulWidget {
  final String invoiceId;
  final String userId;
  
  const InvoiceDetailsScreen({
    required this.invoiceId,
    required this.userId,
  });

  @override
  _InvoiceDetailsScreenState createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  InvoiceModel? _invoice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('invoices')
          .doc(widget.invoiceId)
          .get();
      
      if (doc.exists) {
        setState(() {
          _invoice = InvoiceModel.fromMap(doc.data() as Map<String, dynamic>);
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading invoice: $e');
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_invoice == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Invoice Not Found')),
        body: Center(child: Text('Could not load invoice')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${_invoice!.invoiceNumber}'),
        actions: [
          // Export button
          IconButton(
            icon: Icon(Icons.download),
            tooltip: 'Export Invoice',
            onPressed: () => _showExportOptions(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice details
              _buildInvoiceHeader(),
              SizedBox(height: 16),
              _buildLineItems(),
              SizedBox(height: 16),
              _buildTotals(),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => InvoiceExportSheet(
        invoice: _invoice!,
        userId: widget.userId,
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice #${_invoice!.invoiceNumber}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text('Client: ${_invoice!.clientName}'),
            Text('Email: ${_invoice!.clientEmail}'),
            SizedBox(height: 8),
            Text(
              'Created: ${DateFormat('MMM dd, yyyy').format(_invoice!.createdAt)}',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItems() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Line Items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12),
            ..._invoice!.items.map((item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.description),
                        Text(
                          'Qty: ${item.quantity} @ \$${item.unitPrice}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTotals() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal'),
                Text('\$${_invoice!.subtotal.toStringAsFixed(2)}'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('VAT (10%)'),
                Text('\$${_invoice!.totalVat.toStringAsFixed(2)}'),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  '\$${_invoice!.total.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 2.2: Create Export Bottom Sheet

```dart
// In invoice_export_sheet.dart

class InvoiceExportSheet extends StatefulWidget {
  final InvoiceModel invoice;
  final String userId;
  
  const InvoiceExportSheet({
    required this.invoice,
    required this.userId,
  });

  @override
  _InvoiceExportSheetState createState() => _InvoiceExportSheetState();
}

class _InvoiceExportSheetState extends State<InvoiceExportSheet> {
  final _exportService = PdfExportService();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _export() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      // Build payload (merges invoice + business profile)
      final payload = await _exportService.buildExportPayload(
        widget.userId,
        widget.invoice.toMapForExport(),
      );

      print('📤 Exporting invoice with payload: ${payload.keys}');

      // Call Cloud Function
      final res = await _exportService.exportInvoice(
        widget.userId,
        widget.invoice.toMapForExport(),
      );

      print('✅ Export response: $res');

      setState(() {
        _loading = false;
        _result = res;
      });
    } catch (e) {
      print('❌ Export error: $e');
      setState(() {
        _loading = false;
        _error = 'Export failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Export Invoice',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 12),
          Text(
            'Export invoice ${widget.invoice.invoiceNumber}',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 20),
          
          if (_loading)
            Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Generating exports...'),
              ],
            )
          else if (_error != null)
            Column(
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Colors.red)),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _export,
                  child: Text('Retry'),
                ),
              ],
            )
          else if (_result != null && _result!['success'] == true)
            Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 12),
                Text('Export Complete!'),
                SizedBox(height: 16),
                Text(
                  'Available formats:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                ..._buildDownloadLinks(),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Done'),
                ),
              ],
            )
          else
            Column(
              children: [
                Text('Click to generate PDF, DOCX, and CSV exports'),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _export,
                  icon: Icon(Icons.download),
                  label: Text('Generate Exports'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDownloadLinks() {
    final urls = _result?['urls'] as Map<String, dynamic>?;
    if (urls == null) return [];

    return [
      _buildDownloadLink('PDF', urls['pdf']),
      SizedBox(height: 8),
      _buildDownloadLink('DOCX', urls['docx']),
      SizedBox(height: 8),
      _buildDownloadLink('CSV', urls['csv']),
    ];
  }

  Widget _buildDownloadLink(String format, String? url) {
    if (url == null) return SizedBox.shrink();

    return Material(
      child: InkWell(
        onTap: () async {
          // Open URL in browser or download
          if (await canLaunch(url)) {
            await launch(url);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open link')),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                format == 'PDF' ? Icons.picture_as_pdf :
                format == 'DOCX' ? Icons.description :
                Icons.table_chart,
                color: Colors.blue,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$format Export',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Click to download',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 📋 Part 3: Wire into App Routes

### Update Your App Routes

```dart
// In lib/config/app_routes.dart

class AppRoutes {
  static const String home = '/';
  static const String businessProfile = '/business-profile';
  static const String invoiceBrandingPreview = '/invoice-branding';
  static const String invoiceDetails = '/invoice-details';
  static const String invoiceExport = '/invoice-export';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case businessProfile:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => BusinessProfileScreen(
            userId: args['userId'] as String,
          ),
        );

      case invoiceBrandingPreview:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => InvoiceBrandingScreen(
            userId: args['userId'] as String,
          ),
        );

      case invoiceDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => InvoiceDetailsScreen(
            invoiceId: args['invoiceId'] as String,
            userId: args['userId'] as String,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
```

### Update MaterialApp

```dart
// In main.dart or your app widget

MaterialApp(
  title: 'AuraSphere Pro',
  theme: ThemeData(primarySwatch: Colors.blue),
  home: HomePage(),
  onGenerateRoute: AppRoutes.generateRoute,
  navigatorObservers: [FirebaseAnalyticsObserver(...)],
)
```

---

## 🧪 Part 4: Test Integration

### Test Scenario

```dart
// In your test code or manual testing

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

// Manual Test Flow:
// 1. Login as testuser@example.com
// 2. Navigate to Settings → Business Profile
// 3. Fill in company details:
//    - Name: "Acme Corp"
//    - Logo: Select image from gallery
//    - Color: Blue
//    - Watermark: "CONFIDENTIAL"
// 4. Click Save
// 5. Verify SnackBar: "Business profile saved"
// 6. Navigate to Invoices
// 7. Create new invoice or select existing
// 8. Click Download button
// 9. Click "Generate Exports"
// 10. Wait for Cloud Function (5-10 seconds)
// 11. See 3 signed URLs (PDF, DOCX, CSV)
// 12. Click each URL to verify downloads
```

---

## 🔍 Verification Checklist

### UI Integration
- [ ] Business Profile screen accessible from settings
- [ ] Invoice Branding Preview screen accessible
- [ ] Export button visible on invoice details
- [ ] Export bottom sheet opens when clicked
- [ ] Loading indicator shows during export
- [ ] Download links appear after success
- [ ] Error message shows if export fails

### Data Flow
- [ ] Business profile data loaded correctly
- [ ] Invoice data loaded correctly
- [ ] Payload merging works (business + invoice)
- [ ] Cloud Function receives merged payload
- [ ] Cloud Function generates all 3 formats
- [ ] Files stored in correct Storage path
- [ ] Signed URLs generated (30-day expiry)

### File Content
- [ ] PDF includes logo
- [ ] PDF includes watermark
- [ ] PDF includes company name
- [ ] DOCX has same branding
- [ ] CSV has correct data
- [ ] All calculations correct

### Links & Downloads
- [ ] Signed URLs are clickable
- [ ] Downloads work from browser
- [ ] Files download completely
- [ ] Files are readable/valid
- [ ] No 404 errors

---

## 🚀 Deployment Checklist

- [ ] All services created (2 files)
- [ ] Firestore rules deployed
- [ ] Cloud Function deployed
- [ ] Screens integrated into app
- [ ] Navigation routes configured
- [ ] Local testing complete
- [ ] No console errors
- [ ] Performance acceptable
- [ ] Documentation updated

---

## 📊 Expected Results

After integration, your app will have:

✅ **Settings → Business Profile**
- Company details form
- Logo upload with preview
- Brand color picker
- Professional form validation

✅ **Invoice Details → Export**
- Beautiful export modal
- 3 export format options
- Real-time progress indicator
- Success/error messaging

✅ **Download Integration**
- 3 signed URLs for each export
- Links clickable and valid
- Files downloadable
- Professional document quality

✅ **Data Integration**
- Automatic business profile enrichment
- Company logo in all exports
- Brand colors applied
- Watermarks visible
- Professional formatting

---

## 💡 Tips & Best Practices

1. **Error Handling:** Show user-friendly errors
2. **Loading States:** Disable buttons during export
3. **Timeouts:** Cloud Function can take 5-10 seconds
4. **Network:** Handle offline scenarios gracefully
5. **Permissions:** Ensure Firestore/Storage rules are correct
6. **Testing:** Test with various business profile combinations
7. **Analytics:** Track export format popularity
8. **Feedback:** Notify user of success with SnackBar

---

## 🎉 Success!

Once integrated, users can:

1. ✅ Create business profile with custom branding
2. ✅ Upload company logo
3. ✅ See live preview of branding
4. ✅ Export invoices with professional branding
5. ✅ Download in multiple formats
6. ✅ Share with clients confidently

---

*Integration Guide Created: November 28, 2025*  
*Difficulty Level: Intermediate*  
*Estimated Time: 30-45 minutes*
