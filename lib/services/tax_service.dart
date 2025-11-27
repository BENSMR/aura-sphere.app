/// Tax Service - Country-aware VAT/GST/Sales Tax calculation
/// 
/// Supports VAT (EU), GST (Canada/Australia), and Sales Tax (USA)
/// Rates updated for 2025

import 'package:cloud_firestore/cloud_firestore.dart';

class TaxService {
  /// Detect standard VAT rate by country code
  /// Returns decimal rate (e.g., 0.20 for 20%)
  /// 
  /// Supported countries:
  /// - EU: FR, ES, MA, UK, DE, NL, BE, IT, AT, PL, GR, CZ, PT
  /// - North Africa: MA, TN, DZ, EG
  /// - Middle East: AE, SA, KW, QA, OM
  /// - Americas: US, CA, MX, BR, AR
  /// - APAC: AU, NZ, JP, SG, MY, TH
  static double detectVATRate(String countryCode) {
    switch (countryCode.toUpperCase()) {
      // European Union (VAT)
      case "FR":
        return 0.20; // France - TVA standard
      case "ES":
        return 0.21; // Spain - IVA standard
      case "MA":
        return 0.20; // Morocco - TVA standard
      case "UK":
        return 0.20; // United Kingdom - VAT standard
      case "DE":
        return 0.19; // Germany - Mehrwertsteuer
      case "NL":
        return 0.21; // Netherlands - BTW
      case "BE":
        return 0.21; // Belgium - TVA/BTW
      case "IT":
        return 0.22; // Italy - IVA standard
      case "AT":
        return 0.20; // Austria - Mehrwertsteuer
      case "PL":
        return 0.23; // Poland - VAT standard
      case "GR":
        return 0.24; // Greece - VAT standard
      case "CZ":
        return 0.21; // Czech Republic - DPH
      case "PT":
        return 0.23; // Portugal - IVA standard

      // North Africa (VAT)
      case "TN":
        return 0.19; // Tunisia - TVA
      case "DZ":
        return 0.19; // Algeria - TVA
      case "EG":
        return 0.14; // Egypt - VAT

      // Middle East (VAT)
      case "AE":
        return 0.05; // UAE - VAT
      case "SA":
        return 0.15; // Saudi Arabia - VAT
      case "KW":
        return 0.00; // Kuwait - No VAT
      case "QA":
        return 0.00; // Qatar - No VAT
      case "OM":
        return 0.00; // Oman - No VAT
      case "BH":
        return 0.00; // Bahrain - No VAT

      // North America (GST/HST/Sales Tax)
      case "US":
        return 0.00; // USA - No federal VAT (state-specific)
      case "CA":
        return 0.13; // Canada - average (5% GST + 8% PST/QST)
      case "MX":
        return 0.16; // Mexico - IVA

      // South America
      case "BR":
        return 0.17; // Brazil - ICMS/PIS/COFINS (simplified)
      case "AR":
        return 0.21; // Argentina - IVA standard
      case "CL":
        return 0.19; // Chile - IVA

      // Asia-Pacific (GST/VAT)
      case "AU":
        return 0.10; // Australia - GST
      case "NZ":
        return 0.15; // New Zealand - GST
      case "JP":
        return 0.10; // Japan - Consumption Tax
      case "SG":
        return 0.08; // Singapore - GST
      case "MY":
        return 0.06; // Malaysia - SST
      case "TH":
        return 0.07; // Thailand - VAT
      case "IN":
        return 0.18; // India - GST (standard)
      case "ID":
        return 0.10; // Indonesia - VAT

      // Default to 20% (common EU rate)
      default:
        return 0.20;
    }
  }

  /// Get country-specific tax name
  /// Returns localized tax name (e.g., "VAT", "GST", "IVA")
  static String getTaxName(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case "US":
      case "MX":
        return "Sales Tax";
      case "CA":
        return "GST/HST";
      case "AU":
      case "NZ":
      case "SG":
      case "MY":
      case "TH":
      case "IN":
      case "ID":
        return "GST";
      case "JP":
        return "Consumption Tax";
      case "BR":
      case "AR":
      case "CL":
        return "Tax";
      case "ES":
      case "IT":
      case "PT":
        return "IVA";
      case "FR":
      case "MA":
      case "TN":
      case "DZ":
        return "TVA";
      case "DE":
      case "AT":
        return "Mehrwertsteuer";
      case "NL":
      case "BE":
        return "BTW";
      case "CZ":
        return "DPH";
      case "AE":
      case "SA":
      case "EG":
        return "VAT";
      default:
        return "VAT";
    }
  }

  /// Calculate tax amount from gross price
  /// 
  /// Example:
  /// - Gross: 100 USD, Country: FR (20%)
  /// - Returns: 16.67 (tax portion of gross)
  static double calculateTaxFromGross(double grossAmount, String countryCode) {
    final rate = detectVATRate(countryCode);
    return grossAmount - (grossAmount / (1 + rate));
  }

  /// Calculate gross amount from net price + tax
  /// 
  /// Example:
  /// - Net: 100 USD, Country: FR (20%)
  /// - Returns: 120.00 (net + tax)
  static double calculateGrossFromNet(double netAmount, String countryCode) {
    final rate = detectVATRate(countryCode);
    return netAmount * (1 + rate);
  }

  /// Calculate net amount from gross price
  /// 
  /// Example:
  /// - Gross: 120 USD, Country: FR (20%)
  /// - Returns: 100.00 (without tax)
  static double calculateNetFromGross(double grossAmount, String countryCode) {
    final rate = detectVATRate(countryCode);
    if (rate == 0) return grossAmount;
    return grossAmount / (1 + rate);
  }

  /// Format tax display string
  /// 
  /// Example output: "VAT (20%)" or "GST (13%)"
  static String formatTaxDisplay(String countryCode) {
    final taxName = getTaxName(countryCode);
    final rate = (detectVATRate(countryCode) * 100).toStringAsFixed(0);
    return "$taxName ($rate%)";
  }

  /// Check if country is VAT-applicable (EU + selected others)
  static bool isVATApplicable(String countryCode) {
    final rate = detectVATRate(countryCode);
    return rate > 0;
  }

  /// Get full country details for tax purposes
  /// Returns: {code, name, taxName, rate, isVATApplicable}
  static Map<String, dynamic> getCountryTaxDetails(String countryCode) {
    final code = countryCode.toUpperCase();
    final countryNames = {
      "FR": "France",
      "ES": "Spain",
      "MA": "Morocco",
      "AE": "United Arab Emirates",
      "UK": "United Kingdom",
      "DE": "Germany",
      "NL": "Netherlands",
      "BE": "Belgium",
      "IT": "Italy",
      "AT": "Austria",
      "PL": "Poland",
      "GR": "Greece",
      "CZ": "Czech Republic",
      "PT": "Portugal",
      "TN": "Tunisia",
      "DZ": "Algeria",
      "EG": "Egypt",
      "SA": "Saudi Arabia",
      "KW": "Kuwait",
      "QA": "Qatar",
      "OM": "Oman",
      "BH": "Bahrain",
      "US": "United States",
      "CA": "Canada",
      "MX": "Mexico",
      "BR": "Brazil",
      "AR": "Argentina",
      "CL": "Chile",
      "AU": "Australia",
      "NZ": "New Zealand",
      "JP": "Japan",
      "SG": "Singapore",
      "MY": "Malaysia",
      "TH": "Thailand",
      "IN": "India",
      "ID": "Indonesia",
    };

    final rate = detectVATRate(code);
    final taxName = getTaxName(code);
    final countryName = countryNames[code] ?? "Unknown";

    return {
      "code": code,
      "name": countryName,
      "taxName": taxName,
      "rate": rate,
      "ratePercentage": "${(rate * 100).toStringAsFixed(0)}%",
      "isVATApplicable": rate > 0,
      "displayFormat": formatTaxDisplay(code),
    };
  }

  /// List all supported countries with tax details
  static List<Map<String, dynamic>> getAllSupportedCountries() {
    final codes = [
      "FR",
      "ES",
      "MA",
      "AE",
      "UK",
      "DE",
      "NL",
      "BE",
      "IT",
      "AT",
      "PL",
      "GR",
      "CZ",
      "PT",
      "TN",
      "DZ",
      "EG",
      "SA",
      "KW",
      "QA",
      "OM",
      "BH",
      "US",
      "CA",
      "MX",
      "BR",
      "AR",
      "CL",
      "AU",
      "NZ",
      "JP",
      "SG",
      "MY",
      "TH",
      "IN",
      "ID",
    ];
    return codes.map((code) => getCountryTaxDetails(code)).toList();
  }
}

  /// Detect VAT rate from user profile (async)
  /// 
  /// Fetches user's country from `users/{uid}/profile/country`
  /// and returns corresponding VAT rate
  /// 
  /// Example:
  /// ```dart
  /// final rate = await TaxService.detectVATRateForUserCountry(uid);
  /// ```
  static Future<double> detectVATRateForUserCountry(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final country =
          (userDoc.data()?['profile']?['country'] ?? 'US')
              .toString()
              .toUpperCase();

      return detectVATRate(country);
    } catch (e) {
      // Default to 20% on error
      return 0.20;
    }
  }
}

/// Example Usage:
/// 
/// ```dart
/// // Get VAT rate for France (sync)
/// final frenchRate = TaxService.detectVATRate('FR');
/// // Output: 0.20 (20%)
/// 
/// // Get VAT rate from user profile (async)
/// final userRate = await TaxService.detectVATRateForUserCountry(uid);
/// // Output: 0.20 (from user's country)
/// 
/// // Calculate gross from net
/// final gross = TaxService.calculateGrossFromNet(100, 'FR');
/// // Output: 120.00
/// 
/// // Calculate tax from gross
/// final tax = TaxService.calculateTaxFromGross(120, 'FR');
/// // Output: 20.00
/// 
/// // Get formatted display
/// final display = TaxService.formatTaxDisplay('FR');
/// // Output: "VAT (20%)"
/// 
/// // Get full country details
/// final details = TaxService.getCountryTaxDetails('AE');
/// // Output: {code: "AE", name: "United Arab Emirates", taxName: "VAT", 
/// //          rate: 0.05, ratePercentage: "5%", isVATApplicable: true,
/// //          displayFormat: "VAT (5%)"}
/// ```
