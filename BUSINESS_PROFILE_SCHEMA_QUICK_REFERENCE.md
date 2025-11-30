# 🚀 Business Profile Schema v2.0 - Quick Reference

**Date:** November 28, 2025 | **Status:** ✅ Production Ready

---

## 🎯 New Fields at a Glance

| Field | Type | Purpose | Default |
|-------|------|---------|---------|
| **legalName** | String | Full legal business name | `""` |
| **vatNumber** | String | VAT/GST number | `""` |
| **stampUrl** | String | Company seal/stamp image | `""` |
| **signatureUrl** | String | Authorized signature image | `""` |
| **invoicePrefix** | String | Invoice number prefix | `"AS-"` |
| **invoiceNextNumber** | int | Next invoice number | `1` |
| **watermarkText** | String | Document watermark | `"AURASPHERE PRO"` |
| **documentFooter** | String | Document footer text | `"Thank you for doing business with us!"` |

---

## 💻 Usage Examples

### Create Business Profile with New Fields
```dart
final profile = BusinessProfile(
  userId: 'user123',
  businessName: 'Acme Corp',
  legalName: 'Acme Corporation Inc.',
  businessType: 'c_corp',
  industry: 'Technology',
  taxId: '12-3456789',
  vatNumber: 'IE1234567T',
  businessEmail: 'info@acme.com',
  businessPhone: '+1-555-0100',
  country: 'United States',
  
  // NEW FIELDS
  legalName: 'Acme Corporation Inc.',
  vatNumber: 'IE1234567T',
  stampUrl: 'gs://bucket/stamps/acme.png',
  signatureUrl: 'gs://bucket/signatures/ceo.png',
  invoicePrefix: 'INV-',
  invoiceNextNumber: 1001,
  watermarkText: 'CONFIDENTIAL',
  documentFooter: 'Thank you for your business!',
);
```

### Generate Invoice Number
```dart
String getNextInvoiceNumber(BusinessProfile profile) {
  return '${profile.invoicePrefix}${profile.invoiceNextNumber}';
}

// Usage
final invoiceNumber = getNextInvoiceNumber(business);
// Result: "INV-1001", "AS-001", etc.
```

### Add Document Watermark
```dart
// In PDF generation code
if (profile.watermarkText.isNotEmpty) {
  pdf.addWatermark(profile.watermarkText);
}
```

### Add Signature to Document
```dart
// In PDF generation code
if (profile.signatureUrl.isNotEmpty) {
  pdf.addImage(
    profile.signatureUrl,
    x: 50,
    y: 250,
    width: 100,
    height: 40,
  );
}
```

### Increment Invoice Number
```dart
// In service/provider
Future<void> incrementInvoiceNumber() async {
  await businessService.updateBusinessProfileFields({
    'invoiceNextNumber': business.invoiceNextNumber + 1,
  });
}
```

---

## 📊 Field Details

### Legal & Compliance Fields

**legalName**
- Used for official documents and compliance
- Separate from operating business name
- Required for tax filings

**vatNumber**
- VAT/GST registration number
- Format varies by country (IE1234567T, DE123456789, etc.)
- Used for cross-border compliance

### Document Asset Fields

**stampUrl**
- URL to company official stamp/seal image
- Stored in Firebase Storage
- Added to formal documents for authenticity

**signatureUrl**
- URL to authorized signer's signature image
- Stored in Firebase Storage
- Added to approvals/certifications

### Invoice Configuration Fields

**invoicePrefix**
- Prefix for sequential invoice numbering
- Examples: "AS-", "INV-", "INV-2024-"
- User-configurable per business

**invoiceNextNumber**
- Next sequential invoice number
- Automatically incremented after each invoice
- Ensures unique invoice numbers
- Type: integer

**watermarkText**
- Background watermark for documents
- Examples: "CONFIDENTIAL", "DRAFT", "AURASPHERE PRO"
- Displayed semi-transparently on PDFs

**documentFooter**
- Footer text on all business documents
- Examples: "Thank you for your business!"
- Company legal disclaimers

---

## 🔄 Firestore Integration

### Document Path
```
users/{userId}/business/profile
```

### Sample Document
```json
{
  "businessName": "Acme Corp",
  "legalName": "Acme Corporation Inc.",
  "taxId": "12-3456789",
  "vatNumber": "IE1234567T",
  "invoicePrefix": "INV-",
  "invoiceNextNumber": 1001,
  "watermarkText": "CONFIDENTIAL",
  "documentFooter": "Thank you for your business!",
  "stampUrl": "gs://bucket/stamps/acme.png",
  "signatureUrl": "gs://bucket/signatures/ceo.png"
}
```

### Reading from Firestore
```dart
final profile = businessProvider.business;
final legalName = profile.legalName;        // "Acme Corporation Inc."
final vatNumber = profile.vatNumber;        // "IE1234567T"
final stampUrl = profile.stampUrl;          // "gs://bucket/stamps/acme.png"
final invoiceNumber = profile.invoicePrefix + 
                      profile.invoiceNextNumber.toString();
// Result: "INV-1001"
```

---

## ✨ Common Patterns

### Pattern 1: Generate Unique Invoice Number
```dart
final nextNumber = '${business.invoicePrefix}'
                   '${business.invoiceNextNumber.toString().padLeft(4, '0')}';
// "INV-1001", "AS-0001", etc.
```

### Pattern 2: Custom Document Footer
```dart
final footer = '${business.businessName} | '
               '${business.businessEmail} | '
               '${business.businessPhone}';
```

### Pattern 3: Professional Document Header
```dart
final header = {
  'company': business.legalName,
  'tax_id': business.taxId,
  'vat_number': business.vatNumber,
  'website': business.website,
};
```

### Pattern 4: Invoice with All Branding
```dart
final invoice = {
  'number': '${business.invoicePrefix}${business.invoiceNextNumber}',
  'watermark': business.watermarkText,
  'footer': business.documentFooter,
  'logo': business.logoUrl,
  'stamp': business.stampUrl,
};
```

### Pattern 5: Compliance Record
```dart
final compliance = {
  'business_name': business.businessName,
  'legal_name': business.legalName,
  'tax_id': business.taxId,
  'vat_number': business.vatNumber,
  'registration_number': business.registrationNumber,
  'timestamp': DateTime.now(),
};
```

---

## 🔒 Security Notes

1. **Image URLs:** Always stored in Firebase Storage under `business/{userId}/`
2. **Access Control:** Only business owner can read/write
3. **Bank Account:** Full number stored, masked in UI
4. **VAT Number:** PII - handle with care
5. **Legal Name:** May differ from business name - keep separate

---

## 📈 Migration

### For Existing Businesses
No migration needed! New fields have defaults:
```dart
legalName: data['legalName'] ?? '',              // Empty string
vatNumber: data['vatNumber'] ?? '',              // Empty string
stampUrl: data['stampUrl'] ?? '',                // Empty string
signatureUrl: data['signatureUrl'] ?? '',        // Empty string
invoicePrefix: data['invoicePrefix'] ?? 'AS-',   // Default "AS-"
invoiceNextNumber: data['invoiceNextNumber'] ?? 1,         // 1
watermarkText: data['watermarkText'] ?? 'AURASPHERE PRO', // Default
documentFooter: data['documentFooter'] ?? 'Thank you...',  // Default
```

Existing documents automatically get defaults when loaded.

---

## 🎯 Next Steps

### For Developers
1. Use new fields in invoice generation
2. Add form fields for user input
3. Implement image uploads for stamp/signature
4. Add watermark to PDF generation
5. Update invoice numbering logic

### For Product Managers
1. Plan UI updates for new fields
2. Define invoice numbering scheme
3. Create document branding guidelines
4. Plan compliance features
5. Test with real invoices

### For DevOps
1. Update Firestore security rules
2. Update backup procedures (include images)
3. Monitor storage usage (images)
4. Update audit logging
5. Test disaster recovery

---

## 📚 Related Documentation

- **Full Schema Details:** [BUSINESS_PROFILE_SCHEMA_ENHANCEMENT.md](BUSINESS_PROFILE_SCHEMA_ENHANCEMENT.md)
- **Module Reference:** [BUSINESS_PROFILE_MODULE.md](BUSINESS_PROFILE_MODULE.md)
- **Integration Guide:** [BUSINESS_PROFILE_INTEGRATION_CHECKLIST.md](BUSINESS_PROFILE_INTEGRATION_CHECKLIST.md)
- **Visual Reference:** [BUSINESS_PROFILE_VISUAL_REFERENCE.md](BUSINESS_PROFILE_VISUAL_REFERENCE.md)

---

## ❓ FAQ

**Q: Can I change invoice prefix mid-year?**
A: Yes! It affects future invoices but not historical ones.

**Q: What if I don't upload a stamp/signature?**
A: URLs will be empty strings. Check before using in PDFs.

**Q: How do I backup stamp/signature images?**
A: They're in Firebase Storage under `business/{userId}/`. Firestore rules protect them.

**Q: Can multiple people sign documents?**
A: Currently one signature URL. For multiple, add signatureUrls array in future.

**Q: What format for stamp/signature images?**
A: PNG or transparent background recommended. Supports any image format Firebase supports.

---

## ✅ Status

**Version:** 2.0  
**Released:** November 28, 2025  
**Status:** ✅ Production Ready  
**Backward Compatible:** Yes  
**Requires Migration:** No  

Ready to use immediately!

---

*Last Updated: November 28, 2025*  
*Quick Reference Guide for Business Profile Schema v2.0*
