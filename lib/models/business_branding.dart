import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced business branding configuration for invoices and receipts
class BusinessBranding {
  final String? logoUrl;
  final String? primaryColor;
  final String? accentColor;
  final String? textColor;
  final String? footerNote;
  final String? watermarkText;
  final String? invoiceTemplateId;
  final String? receiptTemplateId;
  final bool showSignature;
  final String? signatureUrl;
  final CompanyDetails? companyDetails;

  const BusinessBranding({
    this.logoUrl,
    this.primaryColor,
    this.accentColor,
    this.textColor,
    this.footerNote,
    this.watermarkText,
    this.invoiceTemplateId,
    this.receiptTemplateId,
    this.showSignature = false,
    this.signatureUrl,
    this.companyDetails,
  });

  /// Create from Firestore document
  factory BusinessBranding.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return BusinessBranding();

    return BusinessBranding(
      logoUrl: data['logoUrl'] as String?,
      primaryColor: data['primaryColor'] as String?,
      accentColor: data['accentColor'] as String?,
      textColor: data['textColor'] as String?,
      footerNote: data['footerNote'] as String?,
      watermarkText: data['watermarkText'] as String?,
      invoiceTemplateId: data['invoiceTemplateId'] as String?,
      receiptTemplateId: data['receiptTemplateId'] as String?,
      showSignature: data['showSignature'] as bool? ?? false,
      signatureUrl: data['signatureUrl'] as String?,
      companyDetails: data['companyDetails'] != null
          ? CompanyDetails.fromMap(data['companyDetails'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'logoUrl': logoUrl,
      'primaryColor': primaryColor,
      'accentColor': accentColor,
      'textColor': textColor,
      'footerNote': footerNote,
      'watermarkText': watermarkText,
      'invoiceTemplateId': invoiceTemplateId,
      'receiptTemplateId': receiptTemplateId,
      'showSignature': showSignature,
      'signatureUrl': signatureUrl,
      'companyDetails': companyDetails?.toMap(),
    };
  }

  /// Copy with changes
  BusinessBranding copyWith({
    String? logoUrl,
    String? primaryColor,
    String? accentColor,
    String? textColor,
    String? footerNote,
    String? watermarkText,
    String? invoiceTemplateId,
    String? receiptTemplateId,
    bool? showSignature,
    String? signatureUrl,
    CompanyDetails? companyDetails,
  }) {
    return BusinessBranding(
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      textColor: textColor ?? this.textColor,
      footerNote: footerNote ?? this.footerNote,
      watermarkText: watermarkText ?? this.watermarkText,
      invoiceTemplateId: invoiceTemplateId ?? this.invoiceTemplateId,
      receiptTemplateId: receiptTemplateId ?? this.receiptTemplateId,
      showSignature: showSignature ?? this.showSignature,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      companyDetails: companyDetails ?? this.companyDetails,
    );
  }

  @override
  String toString() {
    return 'BusinessBranding(logoUrl: $logoUrl, primaryColor: $primaryColor, '
        'accentColor: $accentColor, textColor: $textColor, '
        'footerNote: $footerNote, watermarkText: $watermarkText, '
        'invoiceTemplateId: $invoiceTemplateId, receiptTemplateId: $receiptTemplateId, '
        'showSignature: $showSignature, companyDetails: $companyDetails)';
  }
}

/// Company details for branding
class CompanyDetails {
  final String name;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;

  const CompanyDetails({
    required this.name,
    this.phone,
    this.email,
    this.website,
    this.address,
  });

  /// Create from map
  factory CompanyDetails.fromMap(Map<String, dynamic> data) {
    return CompanyDetails(
      name: data['name'] as String? ?? 'Company',
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      website: data['website'] as String?,
      address: data['address'] as String?,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
    };
  }

  @override
  String toString() {
    return 'CompanyDetails(name: $name, phone: $phone, email: $email, '
        'website: $website, address: $address)';
  }
}
