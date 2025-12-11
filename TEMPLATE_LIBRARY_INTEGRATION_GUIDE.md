# Template Library Integration Guide

## Quick Start

The template library system is fully integrated and ready to use. Here's what users can do:

### For End Users

1. **Access Invoice Branding Settings**
   - Navigate to Settings → Invoice Branding
   - Upload company logo
   - Upload signature (optional)
   - Customize primary, accent, and text colors
   - Add footer note and watermark text
   - Click "Choose Template"

2. **Select a Template**
   - From the template gallery, tap any of the 5 templates:
     - **Classic**: Professional and traditional (default)
     - **Modern**: Contemporary with bold typography
     - **Minimal**: Clean and minimal aesthetic
     - **Elegant**: Sophisticated business appearance
     - **Business**: Corporate standard design
   - The selected template is immediately saved and applied to future invoices

3. **Generate Invoices with Branding**
   - Create or view an invoice
   - Download the PDF - it automatically applies:
     - Your selected template styling (fonts, sizes)
     - Your branding colors
     - Your logo and signature
     - Your footer note
     - Your watermark (for paid invoices)

4. **Preview Before Sending**
   - In the invoice preview screen, click "Regenerate"
   - See how your invoice looks with current branding + template
   - Make adjustments if needed

### For Developers

#### Template Architecture

Each template defines these style properties:

```dart
typedef TemplateStyle = {
  businessNameSize: int,      // Font size for company name
  invoiceTitleSize: int,      // Font size for "Invoice" title
  headerMargin: double,       // Spacing after header
  itemFontSize: int,          // Font size for line items
  totalFontSize: int,         // Font size for total amount
  addressFontSize: int,       // Font size for address text
  logoWidth: int              // Width in points for logo image
};
```

#### Adding New Templates

To add a new template:

1. **Add to BrandingProvider** (`lib/providers/branding_provider.dart`):
   ```dart
   static const String TEMPLATE_CUSTOM = "TEMPLATE_CUSTOM";
   
   static List<String> availableTemplates = [
     // ... existing templates ...
     TEMPLATE_CUSTOM,
   ];
   ```

2. **Add to TemplateGalleryScreen** (`lib/screens/settings/template_gallery_screen.dart`):
   ```dart
   final templates = [
     // ... existing templates ...
     {
       'id': 'TEMPLATE_CUSTOM',
       'name': 'Custom Template',
       'description': 'Your custom template description',
     },
   ];
   ```

3. **Add to Cloud Functions** (`functions/src/billing/generateInvoiceReceipt.ts`):
   ```typescript
   const templateStyles = {
     // ... existing templates ...
     "TEMPLATE_CUSTOM": {
       businessNameSize: 18,
       invoiceTitleSize: 20,
       headerMargin: 2,
       itemFontSize: 10,
       totalFontSize: 14,
       addressFontSize: 10,
       logoWidth: 120
     }
   };
   ```

4. **Same for generateInvoicePreview.ts** (`functions/src/billing/generateInvoicePreview.ts`)

#### Customizing Template Styling

To change template appearance, modify the styling in Cloud Functions:

**generateInvoiceReceipt.ts** - The styles applied to PDF generation:
```typescript
const styles = (templateStyles as any)[templateId] || (templateStyles as any)["TEMPLATE_CLASSIC"];

// Applied to various elements
doc.fontSize(styles.businessNameSize).text(businessName, ...);
doc.fontSize(styles.itemFontSize).text(item, ...);
doc.image(logo, x, y, { width: styles.logoWidth });
```

To add more styling properties, expand the template style interface and apply them in the PDF generation code.

#### Extending Branding Options

Current branding properties:
- `logoUrl`: Company logo
- `signatureUrl`: Signature image
- `primaryColor`: Primary brand color
- `accentColor`: Accent color
- `textColor`: Text color
- `footerNote`: Footer text
- `watermarkText`: Watermark for paid invoices
- `companyDetails`: Business information

To add new properties:

1. **Update Firestore document** in BrandingProvider:
   ```dart
   final settings = {
     // ... existing ...
     'newProperty': value,
   };
   ```

2. **Update UI in InvoiceBrandingScreen**:
   ```dart
   TextField(
     controller: _newPropertyController,
     decoration: InputDecoration(labelText: 'New Property'),
   )
   ```

3. **Apply in Cloud Functions**:
   ```typescript
   const branding = (await db.collection(...).get()).data();
   const newProperty = branding.newProperty;
   // Apply to PDF...
   ```

### Firestore Integration

All branding data is stored in:
```
users/{userId}/branding/settings
```

This document is automatically created when users first save branding settings. The structure is:

```json
{
  "logoUrl": "gs://bucket/path/logo.png",
  "signatureUrl": "gs://bucket/path/signature.png",
  "primaryColor": "#0A84FF",
  "accentColor": "#FFD700",
  "textColor": "#333333",
  "footerNote": "Thank you for your business",
  "watermarkText": "PAID",
  "templateId": "TEMPLATE_CLASSIC",
  "companyDetails": {
    "name": "Company Name",
    "address": "123 Main St",
    "phone": "555-1234",
    "email": "info@company.com",
    "website": "company.com"
  },
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### Firebase Storage

Images are stored in:
- Logos: `branding/{userId}/logo_{timestamp}.{ext}`
- Signatures: `branding/{userId}/signature_{timestamp}.{ext}`

File size limits:
- 5MB for receipts/invoices
- 10MB for general uploads

Storage rules enforce user ownership and file size limits.

### Testing the System

#### Manual Testing

1. **Branding Screen**
   - Upload a logo
   - Set colors
   - Save settings
   - Verify stored in Firestore

2. **Template Selection**
   - Click "Choose Template"
   - Select each template
   - Verify "TEMPLATE_X" appears in Firestore document

3. **Invoice Generation**
   - Generate invoice PDF
   - Open in viewer
   - Verify:
     - Logo displays with correct size
     - Colors match selections
     - Font sizes match template
     - Footer note appears
     - Watermark shows on paid invoices

#### Unit Testing (Coming Soon)

Can add tests for:
```dart
// Test template selection
test('selectTemplate saves template ID', () async {
  final provider = BrandingProvider();
  await provider.selectTemplate('uid123', 'TEMPLATE_MODERN');
  expect(provider.getTemplateId(), 'TEMPLATE_MODERN');
});

// Test branding save
test('saveBranding persists to Firestore', () async {
  final service = BrandingService();
  await service.saveBranding('uid123', {...settings});
  // Verify in Firestore
});
```

### Performance Considerations

- **Branding Loading**: Cached in BrandingProvider (loaded once per app session)
- **Template Selection**: Immediate update (no blocking operations)
- **PDF Generation**: Runs on Cloud Functions (no impact on app performance)
- **Image Uploads**: Queued in Firebase Storage (no app blocking)

### Troubleshooting

**Template not applying to PDF:**
- Verify `templateId` is saved in Firestore document
- Check Cloud Functions logs for errors
- Ensure `generateInvoiceReceipt.ts` is deployed

**Images not showing in PDF:**
- Check Firebase Storage has correct file paths
- Verify file download permissions in Storage rules
- Ensure URLs are signed correctly (especially for gs:// URLs)

**Colors not applying:**
- Verify color format is hex (#RRGGBB)
- Check primary/accent/text color fields in Firestore
- Test with web preview first to isolate Flutter rendering issues

## API Reference

### BrandingProvider

```dart
class BrandingProvider extends ChangeNotifier {
  // Load branding settings for user
  Future<void> load(String uid)
  
  // Save all branding settings
  Future<void> save(String uid, Map<String, dynamic> settings)
  
  // Select and save template
  Future<void> selectTemplate(String uid, String templateId)
  
  // Get current template ID
  String? getTemplateId()
}
```

### BrandingService

```dart
class BrandingService {
  // Upload file to Firebase Storage
  Future<String> uploadFile(String uid, File file, String destPath)
  
  // Save branding document to Firestore
  Future<void> saveBranding(String uid, Map<String, dynamic> settings)
}
```

### Cloud Functions

#### generateInvoiceReceipt

Input:
```typescript
{
  uid: string,           // User ID
  invoiceId: string      // Invoice document ID
}
```

Behavior:
- Loads invoice from Firestore
- Loads branding settings
- Applies template styling
- Generates PDF with images
- Uploads to Storage
- Returns file path

#### generateInvoicePreview

Input:
```typescript
{
  invoiceId: string,              // Invoice ID
  templateId?: string,            // Template to preview
  includeSignature?: boolean,      // Show signature section
  watermarkText?: string           // Custom watermark
}
```

Output:
```typescript
{
  success: boolean,
  pdfUrl: string,                 // Signed URL (1 hour expiry)
  message: string,
  generatedAt: string
}
```

## Files Reference

**Frontend:**
- `lib/providers/branding_provider.dart` - State management
- `lib/services/branding_service.dart` - Firebase operations
- `lib/screens/settings/invoice_branding_screen.dart` - Branding UI
- `lib/screens/settings/template_gallery_screen.dart` - Template selection
- `lib/config/app_routes.dart` - Route definitions

**Backend:**
- `functions/src/billing/generateInvoiceReceipt.ts` - PDF generation with templates
- `functions/src/billing/generateInvoicePreview.ts` - Preview PDF with templates

**Configuration:**
- `lib/app/app.dart` - Provider registration
- `firebase.json` - Firebase deployment config
- `pubspec.yaml` - Flutter dependencies

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Firestore document structure
3. Check Cloud Functions logs in Firebase Console
4. Verify all files are deployed correctly

