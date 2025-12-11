/**
 * admin_service.dart
 *
 * Service for managing admin users and roles
 *
 * Usage:
 * ```dart
 * final admin = AdminService();
 * 
 * // Grant admin to user
 * final result = await admin.grantAdminRole('user-uid-123');
 * 
 * // Check if current user is admin
 * final isAdmin = await admin.isCurrentUserAdmin();
 * 
 * // List all admins (admin-only)
 * final admins = await admin.listAdmins();
 * ```
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_functions/firebase_functions.dart';

class AdminService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _functions = FirebaseFunctions.instance;

  /// Grant admin role to a user
  ///
  /// Callable only by existing admins
  /// Creates /admins/{uid} doc and sets custom claim
  Future<bool> grantAdminRole(String targetUid) async {
    try {
      final result = await _functions
          .httpsCallable('grantAdminRole')
          .call({'targetUid': targetUid});

      return result.data['success'] == true;
    } catch (e) {
      print('[admin-error] grantAdminRole: $e');
      rethrow;
    }
  }

  /// Revoke admin role from a user
  ///
  /// Callable only by existing admins
  /// Deletes /admins/{uid} doc and removes custom claim
  /// Cannot revoke own admin access (safety)
  Future<bool> revokeAdminRole(String targetUid) async {
    try {
      final result = await _functions
          .httpsCallable('revokeAdminRole')
          .call({'targetUid': targetUid});

      return result.data['success'] == true;
    } catch (e) {
      print('[admin-error] revokeAdminRole: $e');
      rethrow;
    }
  }

  /// List all admin users
  ///
  /// Returns list of admin UIDs with metadata
  /// Callable only by admins
  Future<List<Map<String, dynamic>>> listAdmins() async {
    try {
      final result = await _functions.httpsCallable('listAdmins').call();

      final admins = result.data['admins'] as List?;
      return admins?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      print('[admin-error] listAdmins: $e');
      rethrow;
    }
  }

  /// Check if specific user is admin
  Future<bool> isUserAdmin(String uid) async {
    try {
      final result = await _functions
          .httpsCallable('getAdminStatus')
          .call({'targetUid': uid});

      return result.data['isAdmin'] == true;
    } catch (e) {
      print('[admin-error] isUserAdmin: $e');
      rethrow;
    }
  }

  /// Check if current user is admin
  ///
  /// Fast check using custom claims
  /// Fallback to Firestore if claims not set
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check custom claims (faster)
    final claims = user.customClaims ?? {};
    if (claims['admin'] == true) return true;

    // Fallback: check Firestore (for case where claims not yet set)
    try {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      print('[admin-error] isCurrentUserAdmin: $e');
      return false;
    }
  }

  /// Get admin document for user
  ///
  /// Returns metadata about when admin access was granted
  Future<AdminMetadata?> getAdminMetadata(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      if (!doc.exists) return null;

      return AdminMetadata.fromJson({...doc.data() ?? {}, 'uid': uid});
    } catch (e) {
      print('[admin-error] getAdminMetadata: $e');
      return null;
    }
  }

  /// Watch admin status for current user (realtime)
  Stream<bool> watchCurrentUserAdminStatus() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('admins')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Watch admin list (realtime)
  Stream<List<AdminMetadata>> watchAdmins() {
    return _firestore
        .collection('admins')
        .snapshots()
        .map((snap) =>
            snap.docs
                .map((doc) =>
                    AdminMetadata.fromJson({...doc.data(), 'uid': doc.id}))
                .toList())
        .handleError((e) {
          print('[admin-error] watchAdmins: $e');
        });
  }
}

/// Admin metadata model
class AdminMetadata {
  final String uid;
  final DateTime? grantedAt;
  final String? grantedBy;
  final bool? isFirstAdmin;

  AdminMetadata({
    required this.uid,
    this.grantedAt,
    this.grantedBy,
    this.isFirstAdmin = false,
  });

  factory AdminMetadata.fromJson(Map<String, dynamic> json) {
    return AdminMetadata(
      uid: json['uid'] as String? ?? '',
      grantedAt: (json['grantedAt'] as Timestamp?)?.toDate(),
      grantedBy: json['grantedBy'] as String?,
      isFirstAdmin: json['isFirstAdmin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'grantedAt': grantedAt,
        'grantedBy': grantedBy,
        'isFirstAdmin': isFirstAdmin,
      };

  String get displayName => isFirstAdmin == true ? '$uid (first)' : uid;
}
