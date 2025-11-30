// lib/models/business_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessProfile {
  final String businessName;
  final String legalName;
  final String taxId;
  final String vatNumber;
  final String address;
  final String city;
  final String postalCode;
  final String logoUrl;
  final String invoicePrefix;
  final String documentFooter;
  final String brandColor;
  final String watermarkText;
  final String invoiceTemplate;
  final String defaultCurrency;
  final String defaultLanguage;
  final Map<String, dynamic> taxSettings;
  final Timestamp? updatedAt;

  BusinessProfile({
    required this.businessName,
    required this.legalName,
    required this.taxId,
    required this.vatNumber,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.logoUrl,
    required this.invoicePrefix,
    required this.documentFooter,
    required this.brandColor,
    required this.watermarkText,
    required this.invoiceTemplate,
    required this.defaultCurrency,
    required this.defaultLanguage,
    required this.taxSettings,
    this.updatedAt,
  });

  factory BusinessProfile.fromMap(Map<String, dynamic> m) {
    return BusinessProfile(
      businessName: m['businessName'] ?? '',
      legalName: m['legalName'] ?? '',
      taxId: m['taxId'] ?? '',
      vatNumber: m['vatNumber'] ?? '',
      address: m['address'] ?? '',
      city: m['city'] ?? '',
      postalCode: m['postalCode'] ?? '',
      logoUrl: m['logoUrl'] ?? '',
      invoicePrefix: m['invoicePrefix'] ?? 'AS-',
      documentFooter: m['documentFooter'] ?? '',
      brandColor: m['brandColor'] ?? '#0A84FF',
      watermarkText: m['watermarkText'] ?? '',
      invoiceTemplate: m['invoiceTemplate'] ?? 'minimal',
      defaultCurrency: m['defaultCurrency'] ?? 'EUR',
      defaultLanguage: m['defaultLanguage'] ?? 'en',
      taxSettings: Map<String, dynamic>.from(m['taxSettings'] ?? {}),
      updatedAt: m['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'legalName': legalName,
      'taxId': taxId,
      'vatNumber': vatNumber,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'logoUrl': logoUrl,
      'invoicePrefix': invoicePrefix,
      'documentFooter': documentFooter,
      'brandColor': brandColor,
      'watermarkText': watermarkText,
      'invoiceTemplate': invoiceTemplate,
      'defaultCurrency': defaultCurrency,
      'defaultLanguage': defaultLanguage,
      'taxSettings': taxSettings,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Convenience getters for backwards compatibility
  String get streetAddress => address;
  String get contactPersonName => legalName;
  String get bankAccountName => '';
  Map<String, dynamic> get socialMedia => {};
  String? get userId => null;
  String get industry => '';
  String get description => '';
  String get status => 'active';
  String get businessType => '';
  String get registrationNumber => '';
  int get numberOfEmployees => 0;
  String get foundedDate => '';
  String get currency => defaultCurrency;
  String get fiscalYearEnd => '';
  String get state => '';
  String get zipCode => postalCode;
  String get country => '';
  String get contactPersonEmail => '';
  String get contactPersonPhone => '';
  String get bankAccountNumber => '';
  String get routingNumber => '';
  String get swiftCode => '';
  String get signatureUrl => '';

  /// Copy with method for partial updates
  BusinessProfile copyWith({
    String? businessName,
    String? legalName,
    String? taxId,
    String? vatNumber,
    String? address,
    String? city,
    String? postalCode,
    String? logoUrl,
    String? invoicePrefix,
    String? documentFooter,
    String? brandColor,
    String? watermarkText,
    String? invoiceTemplate,
    String? defaultCurrency,
    String? defaultLanguage,
    Map<String, dynamic>? taxSettings,
    Timestamp? updatedAt,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      legalName: legalName ?? this.legalName,
      taxId: taxId ?? this.taxId,
      vatNumber: vatNumber ?? this.vatNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      logoUrl: logoUrl ?? this.logoUrl,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      documentFooter: documentFooter ?? this.documentFooter,
      brandColor: brandColor ?? this.brandColor,
      watermarkText: watermarkText ?? this.watermarkText,
      invoiceTemplate: invoiceTemplate ?? this.invoiceTemplate,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      taxSettings: taxSettings ?? this.taxSettings,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
