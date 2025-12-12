import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:intl/intl.dart';

/// Initializes device-detected timezone, locale, and country on first app launch
/// Runs once per user to populate Firestore with device detection data
class DeviceInitService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Detects device timezone, locale, and country code
  /// Returns map with detected values
  Future<Map<String, String>> detectDeviceInfo() async {
    try {
      // Detect timezone (IANA format)
      final tz = await FlutterNativeTimezone.getLocalTimezone();
      
      // Get device locale (e.g., 'en_US')
      final loc = Intl.getCurrentLocale();
      
      // Guess country code from locale (e.g., 'US' from 'en_US')
      String countryCode = loc.split('_').length > 1 ? loc.split('_')[1] : 'US';
      
      return {
        'timezone': tz,
        'locale': loc,
        'country': countryCode,
      };
    } catch (e) {
      // Fallback to defaults if detection fails
      return {
        'timezone': 'UTC',
        'locale': 'en-US',
        'country': 'US',
      };
    }
  }

  /// Initializes user's Firestore document with device-detected values
  /// Only writes if document doesn't exist or timezone field is 'detect' (placeholder)
  Future<void> initializeUserDeviceInfo({String? uid}) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return;

    final userRef = _db.collection('users').doc(userId);
    
    try {
      // Check if user doc exists and has valid timezone
      final userSnap = await userRef.get();
      
      // Skip if timezone is already set to a real value (not 'detect' placeholder)
      if (userSnap.exists) {
        final data = userSnap.data() as Map<String, dynamic>?;
        final tz = data?['timezone'] as String?;
        
        // If timezone is not 'detect' placeholder, user already initialized
        if (tz != null && tz != 'detect') {
          return;
        }
      }

      // Detect device info
      final deviceInfo = await detectDeviceInfo();

      // Write to Firestore (merge to preserve other fields)
      await userRef.set(
        {
          'timezone': deviceInfo['timezone'],
          'locale': deviceInfo['locale'],
          'country': deviceInfo['country'],
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print('[DeviceInitService] Error initializing device info: $e');
      // Don't throw - allow app to continue even if init fails
    }
  }
}
