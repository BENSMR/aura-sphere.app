import 'package:cloud_firestore/cloud_firestore.dart';

enum BusinessType { sole_proprietor, llc, s_corp, c_corp, partnership, nonprofit }

enum BusinessStatus { setup, active, inactive, suspended }

/// Tax settings configuration for invoices
class TaxSettings {
  final double vatPercentage; // VAT percentage (e.g., 19.0 for 19%)
  final String country; // Tax jurisdiction country
  final String taxType; // Type: 'VAT', 'GST', 'Sales Tax', etc.

  TaxSettings({
    this.vatPercentage = 0.0,
    this.country = '',
    this.taxType = 'VAT',
  });

  factory TaxSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return TaxSettings();
    return TaxSettings(
      vatPercentage: (data['vatPercentage'] as num?)?.toDouble() ?? 0.0,
      country: data['country'] ?? '',
      taxType: data['taxType'] ?? 'VAT',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vatPercentage': vatPercentage,
      'country': country,
      'taxType': taxType,
    };
  }
}

/// Customer support information
class CustomerSupportInfo {
  final String supportEmail;
  final String supportPhone;
  final String supportUrl; // Help/support website URL
  final String supportHours; // e.g., "Mon-Fri 9AM-5PM"

  CustomerSupportInfo({
    this.supportEmail = '',
    this.supportPhone = '',
    this.supportUrl = '',
    this.supportHours = '',
  });

  factory CustomerSupportInfo.fromMap(Map<String, dynamic>? data) {
    if (data == null) return CustomerSupportInfo();
    return CustomerSupportInfo(
      supportEmail: data['supportEmail'] ?? '',
      supportPhone: data['supportPhone'] ?? '',
      supportUrl: data['supportUrl'] ?? '',
      supportHours: data['supportHours'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'supportUrl': supportUrl,
      'supportHours': supportHours,
    };
  }
}

class BusinessProfile {
  final String userId;
  final String businessName;
  final String legalName; // Full legal business name
  final String businessType;
  final String industry;
  final String taxId; // EIN, VAT ID, etc.
  final String vatNumber; // VAT/GST number
  final String businessEmail;
  final String businessPhone;
  final String website;
  final String description;
  
  // Address fields
  final String streetAddress;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  
  // Logo and branding
  final String logoUrl;
  final String stampUrl; // Company stamp/seal for documents
  final String signatureUrl; // Authorized signature image
  final String brandColor; // hex color code
  
  // Business details
  final String registrationNumber;
  final DateTime? foundedDate;
  final String status;
  final int? numberOfEmployees;
  
  // Financial info
  final String currency;
  final String fiscalYearEnd;
  
  // Contact person
  final String contactPersonName;
  final String contactPersonEmail;
  final String contactPersonPhone;
  
  // Banking (optional)
  final String bankAccountName;
  final String bankAccountNumber;
  final String routingNumber;
  final String swiftCode;
  
  // Invoice configuration
  final String invoicePrefix; // e.g., "AS-", "INV-"
  final int invoiceNextNumber; // Next invoice number
  final String watermarkText; // Document watermark
  final String documentFooter; // Footer text on documents
  final String invoiceTemplate; // Selected template: 'minimal', 'classic', 'modern'
  
  // Localization and compliance
  final String defaultLanguage; // e.g., 'en', 'de', 'fr'
  final String defaultCurrency; // e.g., 'USD', 'EUR', 'GBP'
  
  // Tax configuration
  final TaxSettings taxSettings;
  
  // Customer support
  final CustomerSupportInfo customerSupportInfo;
  
  // Social media
  final Map<String, String> socialMedia; // platform -> url
  
  // Metadata
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  BusinessProfile({
    required this.userId,
    required this.businessName,
    this.legalName = '',
    required this.businessType,
    required this.industry,
    required this.taxId,
    this.vatNumber = '',
    required this.businessEmail,
    required this.businessPhone,
    this.website = '',
    this.description = '',
    this.streetAddress = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.country = '',
    this.logoUrl = '',
    this.stampUrl = '',
    this.signatureUrl = '',
    this.brandColor = '#3A86FF',
    this.registrationNumber = '',
    this.foundedDate,
    this.status = 'setup',
    this.numberOfEmployees,
    this.currency = 'USD',
    this.fiscalYearEnd = 'December 31',
    this.contactPersonName = '',
    this.contactPersonEmail = '',
    this.contactPersonPhone = '',
    this.bankAccountName = '',
    this.bankAccountNumber = '',
    this.routingNumber = '',
    this.swiftCode = '',
    this.invoicePrefix = 'AS-',
    this.invoiceNextNumber = 1,
    this.watermarkText = 'AURASPHERE PRO',
    this.documentFooter = 'Thank you for doing business with us!',
    this.invoiceTemplate = 'classic',
    this.defaultLanguage = 'en',
    this.defaultCurrency = 'USD',
    TaxSettings? taxSettings,
    CustomerSupportInfo? customerSupportInfo,
    this.socialMedia = const {},
    this.createdAt,
    this.updatedAt,
  })  : taxSettings = taxSettings ?? TaxSettings(),
        customerSupportInfo = customerSupportInfo ?? CustomerSupportInfo();

  factory BusinessProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BusinessProfile(
      userId: data['userId'] ?? '',
      businessName: data['businessName'] ?? '',
      legalName: data['legalName'] ?? '',
      businessType: data['businessType'] ?? 'sole_proprietor',
      industry: data['industry'] ?? '',
      taxId: data['taxId'] ?? '',
      vatNumber: data['vatNumber'] ?? '',
      businessEmail: data['businessEmail'] ?? '',
      businessPhone: data['businessPhone'] ?? '',
      website: data['website'] ?? '',
      description: data['description'] ?? '',
      streetAddress: data['streetAddress'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      country: data['country'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      stampUrl: data['stampUrl'] ?? '',
      signatureUrl: data['signatureUrl'] ?? '',
      brandColor: data['brandColor'] ?? '#3A86FF',
      registrationNumber: data['registrationNumber'] ?? '',
      foundedDate: data['foundedDate'] != null ? (data['foundedDate'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'setup',
      numberOfEmployees: data['numberOfEmployees'],
      currency: data['currency'] ?? 'USD',
      fiscalYearEnd: data['fiscalYearEnd'] ?? 'December 31',
      contactPersonName: data['contactPersonName'] ?? '',
      contactPersonEmail: data['contactPersonEmail'] ?? '',
      contactPersonPhone: data['contactPersonPhone'] ?? '',
      bankAccountName: data['bankAccountName'] ?? '',
      bankAccountNumber: data['bankAccountNumber'] ?? '',
      routingNumber: data['routingNumber'] ?? '',
      swiftCode: data['swiftCode'] ?? '',
      invoicePrefix: data['invoicePrefix'] ?? 'AS-',
      invoiceNextNumber: data['invoiceNextNumber'] ?? 1,
      watermarkText: data['watermarkText'] ?? 'AURASPHERE PRO',
      documentFooter: data['documentFooter'] ?? 'Thank you for doing business with us!',
      invoiceTemplate: data['invoiceTemplate'] ?? 'classic',
      defaultLanguage: data['defaultLanguage'] ?? 'en',
      defaultCurrency: data['defaultCurrency'] ?? 'USD',
      taxSettings: TaxSettings.fromMap(data['taxSettings'] as Map<String, dynamic>?),
      customerSupportInfo: CustomerSupportInfo.fromMap(data['customerSupportInfo'] as Map<String, dynamic>?),
      socialMedia: Map<String, String>.from(data['socialMedia'] ?? {}),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'userId': userId,
      'businessName': businessName,
      'legalName': legalName,
      'businessType': businessType,
      'industry': industry,
      'taxId': taxId,
      'vatNumber': vatNumber,
      'businessEmail': businessEmail,
      'businessPhone': businessPhone,
      'website': website,
      'description': description,
      'streetAddress': streetAddress,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'logoUrl': logoUrl,
      'stampUrl': stampUrl,
      'signatureUrl': signatureUrl,
      'brandColor': brandColor,
      'registrationNumber': registrationNumber,
      'foundedDate': foundedDate != null ? Timestamp.fromDate(foundedDate!) : null,
      'status': status,
      'numberOfEmployees': numberOfEmployees,
      'currency': currency,
      'fiscalYearEnd': fiscalYearEnd,
      'contactPersonName': contactPersonName,
      'contactPersonEmail': contactPersonEmail,
      'contactPersonPhone': contactPersonPhone,
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
      'routingNumber': routingNumber,
      'swiftCode': swiftCode,
      'invoicePrefix': invoicePrefix,
      'invoiceNextNumber': invoiceNextNumber,
      'watermarkText': watermarkText,
      'documentFooter': documentFooter,
      'invoiceTemplate': invoiceTemplate,
      'defaultLanguage': defaultLanguage,
      'defaultCurrency': defaultCurrency,
      'taxSettings': taxSettings.toMap(),
      'customerSupportInfo': customerSupportInfo.toMap(),
      'socialMedia': socialMedia,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'businessName': businessName,
      'legalName': legalName,
      'businessType': businessType,
      'industry': industry,
      'taxId': taxId,
      'vatNumber': vatNumber,
      'businessEmail': businessEmail,
      'businessPhone': businessPhone,
      'website': website,
      'description': description,
      'streetAddress': streetAddress,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'logoUrl': logoUrl,
      'stampUrl': stampUrl,
      'signatureUrl': signatureUrl,
      'brandColor': brandColor,
      'registrationNumber': registrationNumber,
      'foundedDate': foundedDate != null ? Timestamp.fromDate(foundedDate!) : null,
      'status': status,
      'numberOfEmployees': numberOfEmployees,
      'currency': currency,
      'fiscalYearEnd': fiscalYearEnd,
      'contactPersonName': contactPersonName,
      'contactPersonEmail': contactPersonEmail,
      'contactPersonPhone': contactPersonPhone,
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
      'routingNumber': routingNumber,
      'swiftCode': swiftCode,
      'invoicePrefix': invoicePrefix,
      'invoiceNextNumber': invoiceNextNumber,
      'watermarkText': watermarkText,
      'documentFooter': documentFooter,
      'invoiceTemplate': invoiceTemplate,
      'defaultLanguage': defaultLanguage,
      'defaultCurrency': defaultCurrency,
      'taxSettings': taxSettings.toMap(),
      'customerSupportInfo': customerSupportInfo.toMap(),
      'socialMedia': socialMedia,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  BusinessProfile copyWith({
    String? userId,
    String? businessName,
    String? legalName,
    String? businessType,
    String? industry,
    String? taxId,
    String? vatNumber,
    String? businessEmail,
    String? businessPhone,
    String? website,
    String? description,
    String? streetAddress,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? logoUrl,
    String? stampUrl,
    String? signatureUrl,
    String? brandColor,
    String? registrationNumber,
    DateTime? foundedDate,
    String? status,
    int? numberOfEmployees,
    String? currency,
    String? fiscalYearEnd,
    String? contactPersonName,
    String? contactPersonEmail,
    String? contactPersonPhone,
    String? bankAccountName,
    String? bankAccountNumber,
    String? routingNumber,
    String? swiftCode,
    String? invoicePrefix,
    int? invoiceNextNumber,
    String? watermarkText,
    String? documentFooter,
    String? invoiceTemplate,
    String? defaultLanguage,
    String? defaultCurrency,
    TaxSettings? taxSettings,
    CustomerSupportInfo? customerSupportInfo,
    Map<String, String>? socialMedia,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return BusinessProfile(
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      legalName: legalName ?? this.legalName,
      businessType: businessType ?? this.businessType,
      industry: industry ?? this.industry,
      taxId: taxId ?? this.taxId,
      vatNumber: vatNumber ?? this.vatNumber,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      website: website ?? this.website,
      description: description ?? this.description,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      logoUrl: logoUrl ?? this.logoUrl,
      stampUrl: stampUrl ?? this.stampUrl,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      brandColor: brandColor ?? this.brandColor,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      foundedDate: foundedDate ?? this.foundedDate,
      status: status ?? this.status,
      numberOfEmployees: numberOfEmployees ?? this.numberOfEmployees,
      currency: currency ?? this.currency,
      fiscalYearEnd: fiscalYearEnd ?? this.fiscalYearEnd,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactPersonEmail: contactPersonEmail ?? this.contactPersonEmail,
      contactPersonPhone: contactPersonPhone ?? this.contactPersonPhone,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      routingNumber: routingNumber ?? this.routingNumber,
      swiftCode: swiftCode ?? this.swiftCode,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      invoiceNextNumber: invoiceNextNumber ?? this.invoiceNextNumber,
      watermarkText: watermarkText ?? this.watermarkText,
      documentFooter: documentFooter ?? this.documentFooter,
      invoiceTemplate: invoiceTemplate ?? this.invoiceTemplate,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      taxSettings: taxSettings ?? this.taxSettings,
      customerSupportInfo: customerSupportInfo ?? this.customerSupportInfo,
      socialMedia: socialMedia ?? this.socialMedia,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'BusinessProfile(userId: $userId, businessName: $businessName, status: $status)';
}
