import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'notification_audit_service.dart';

enum DevicePlatform { android, ios, web }

class DeviceNotificationPrefs {
  final bool anomalies;
  final bool invoices;
  final bool inventory;
  final bool all;

  DeviceNotificationPrefs({
    this.anomalies = true,
    this.invoices = true,
    this.inventory = true,
    this.all = true,
  });

  factory DeviceNotificationPrefs.fromMap(Map<String, dynamic> map) =>
      DeviceNotificationPrefs(
        anomalies: map['anomalies'] ?? true,
        invoices: map['invoices'] ?? true,
        inventory: map['inventory'] ?? true,
        all: map['all'] ?? true,
      );

  Map<String, dynamic> toMap() => {
    'anomalies': anomalies,
    'invoices': invoices,
    'inventory': inventory,
    'all': all,
  };
}

class DeviceInfo {
  final String deviceId;
  final String token;
  final DevicePlatform platform;
  final DateTime lastSeen;
  final DeviceNotificationPrefs prefs;
  final String? deviceName;
  final String? osVersion;

  DeviceInfo({
    required this.deviceId,
    required this.token,
    required this.platform,
    required this.lastSeen,
    required this.prefs,
    this.deviceName,
    this.osVersion,
  });

  factory DeviceInfo.fromMap(String id, Map<String, dynamic> map) =>
      DeviceInfo(
        deviceId: id,
        token: map['token'] ?? '',
        platform: DevicePlatform.values.byName(
          map['platform'] ?? 'web',
        ),
        lastSeen: (map['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
        prefs: DeviceNotificationPrefs.fromMap(map['prefs'] ?? {}),
        deviceName: map['deviceName'],
        osVersion: map['osVersion'],
      );

  Map<String, dynamic> toMap() => {
    'token': token,
    'platform': platform.name,
    'lastSeen': FieldValue.serverTimestamp(),
    'prefs': prefs.toMap(),
    'deviceName': deviceName,
    'osVersion': osVersion,
  };
}

class DeviceService {
  final FirebaseFirestore _firestore;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  DeviceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Register/update device with FCM token
  Future<bool> registerDevice({
    required String userId,
    required String deviceId,
    required String fcmToken,
    required DevicePlatform platform,
  }) async {
    try {
      final deviceName = await _getDeviceName();
      final osVersion = await _getOSVersion();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .set({
            'token': fcmToken,
            'platform': platform.name,
            'lastSeen': FieldValue.serverTimestamp(),
            'deviceName': deviceName,
            'osVersion': osVersion,
            'prefs': {
              'anomalies': true,
              'invoices': true,
              'inventory': true,
              'all': true,
            },
          }, SetOptions(merge: true));

      // Log audit event
      final auditService = NotificationAuditService();
      await auditService.recordAudit(
        actor: userId,
        targetUid: userId,
        type: NotificationAuditType.deviceRegistered,
        status: AuditStatus.sent,
        eventId: deviceId,
        metadata: {'platform': platform.name, 'deviceName': deviceName},
      );

      debugPrint('✅ Device registered: $deviceId ($platform)');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to register device: $e');
      return false;
    }
  }

  /// Get all user's registered devices
  Future<List<DeviceInfo>> getUserDevices(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .get();

      return snapshot.docs
          .map((doc) => DeviceInfo.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch devices: $e');
      return [];
    }
  }

  /// Stream user devices
  Stream<List<DeviceInfo>> streamUserDevices(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs
                .map((doc) => DeviceInfo.fromMap(doc.id, doc.data()))
                .toList());
  }

  /// Update notification preferences for device
  Future<bool> updateDevicePreferences({
    required String userId,
    required String deviceId,
    required DeviceNotificationPrefs prefs,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .update({
            'prefs': prefs.toMap(),
            'lastSeen': FieldValue.serverTimestamp(),
          });

      // Log audit event
      final auditService = NotificationAuditService();
      await auditService.recordAudit(
        actor: userId,
        targetUid: userId,
        type: NotificationAuditType.preferencesUpdated,
        status: AuditStatus.sent,
        eventId: deviceId,
        metadata: {'prefs': prefs.toMap()},
      );

      debugPrint('✅ Device preferences updated: $deviceId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to update preferences: $e');
      return false;
    }
  }

  /// Remove device
  Future<bool> removeDevice({
    required String userId,
    required String deviceId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .delete();

      // Log audit event
      final auditService = NotificationAuditService();
      await auditService.recordAudit(
        actor: userId,
        targetUid: userId,
        type: NotificationAuditType.deviceRemoved,
        status: AuditStatus.sent,
        eventId: deviceId,
      );

      debugPrint('✅ Device removed: $deviceId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to remove device: $e');
      return false;
    }
  }

  /// Update last seen timestamp
  Future<void> updateLastSeen({
    required String userId,
    required String deviceId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .update({
            'lastSeen': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('⚠️ Failed to update last seen: $e');
    }
  }

  /// Check if notification type enabled for device
  Future<bool> isNotificationTypeEnabled({
    required String userId,
    required String deviceId,
    required String notificationType, // 'anomalies', 'invoices', 'inventory', 'all'
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .get();

      if (!doc.exists) return false;

      final prefs = DeviceNotificationPrefs.fromMap(
        doc.data()?['prefs'] ?? {},
      );

      switch (notificationType) {
        case 'anomalies':
          return prefs.anomalies && prefs.all;
        case 'invoices':
          return prefs.invoices && prefs.all;
        case 'inventory':
          return prefs.inventory && prefs.all;
        default:
          return prefs.all;
      }
    } catch (e) {
      debugPrint('❌ Error checking notification type: $e');
      return false;
    }
  }

  /// Get device helper methods
  Future<String> _getDeviceName() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfo.androidInfo;
        return info.model;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfo.iosInfo;
        return info.utsname.machine ?? 'iOS Device';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  Future<String> _getOSVersion() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfo.androidInfo;
        return 'Android ${info.version.release}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfo.iosInfo;
        return 'iOS ${info.systemVersion}';
      }
      return 'Web';
    } catch (e) {
      return 'Unknown OS';
    }
  }
}
