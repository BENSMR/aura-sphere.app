/// Access Control Service
/// 
/// Centralized service for checking user permissions and feature access
/// across different roles and platforms.

import 'package:flutter/foundation.dart';
import '../models/role_model.dart';

class AccessControlService {
  /// Check if a user with the given role can access a feature
  static bool canAccessFeature(UserRole role, FeatureAccess feature) {
    return role.hasAccess(feature);
  }

  /// Check if a user can access a feature on a specific platform
  static bool canAccessFeatureOnPlatform(
    UserRole role,
    FeatureAccess feature,
    DevicePlatform platform,
  ) {
    return role.canAccessOnPlatform(feature, platform);
  }

  /// Get the appropriate navigation destination based on role and platform
  static String getInitialRoute(UserRole role, DevicePlatform platform) {
    switch (role) {
      case UserRole.owner:
        return '/dashboard';
      case UserRole.employee:
        // Employees always start with their mobile dashboard
        return '/employee/dashboard';
    }
  }

  /// Check if a feature is visible in the main navigation for this role/platform
  static bool isFeatureVisible(
    UserRole role,
    FeatureAccess feature,
    DevicePlatform platform,
  ) {
    // First check if accessible at all
    if (!canAccessFeatureOnPlatform(role, feature, platform)) {
      return false;
    }

    // Features hidden from nav on mobile (but still accessible via direct route)
    if (platform.isMobile && role == UserRole.owner) {
      // On mobile owner view, show main features only
      return Features.ownerMainFeatures.contains(feature);
    }

    return true;
  }

  /// Get visible features for a role on a specific platform
  static List<FeatureAccess> getVisibleFeatures(
    UserRole role,
    DevicePlatform platform,
  ) {
    switch (role) {
      case UserRole.owner:
        if (platform.isMobile) {
          // Mobile owners see main features only
          return Features.ownerMainFeatures;
        } else {
          // Desktop/web owners see all features
          return Features.allOwnerFeatures;
        }

      case UserRole.employee:
        if (platform.isMobile) {
          // Mobile employees see 6 features
          return Features.employeeMobileFeatures;
        } else {
          // Employees cannot access desktop/web at all
          return [];
        }
    }
  }

  /// Get features organized by category for the given role/platform
  static Map<String, List<FeatureAccess>> getCategorizedFeatures(
    UserRole role,
    DevicePlatform platform,
  ) {
    final Map<String, List<FeatureAccess>> categories = {};

    switch (role) {
      case UserRole.owner:
        if (platform.isMobile) {
          // Mobile owner: Just main features
          categories['Navigation'] = Features.ownerMainFeatures;
        } else {
          // Desktop/web owner: Main + Advanced
          categories['Main'] = Features.ownerMainFeatures;
          categories['Advanced'] = Features.ownerAdvancedFeatures;
        }
        break;

      case UserRole.employee:
        if (platform.isMobile) {
          // Employee: Only mobile features
          categories['Tasks & Expenses'] = Features.employeeMobileFeatures
              .where(
                  (f) => f.routeName.contains('tasks') || f.routeName.contains('expenses'))
              .toList();
          categories['Other'] = Features.employeeMobileFeatures
              .where((f) =>
                  !f.routeName.contains('tasks') && !f.routeName.contains('expenses'))
              .toList();
        }
        break;
    }

    return categories;
  }

  /// Check if user should see the "Advanced" section in navigation
  static bool shouldShowAdvancedSection(
    UserRole role,
    DevicePlatform platform,
  ) {
    return role == UserRole.owner && !platform.isMobile;
  }

  /// Check if a feature is only on desktop
  static bool isDesktopOnlyFeature(FeatureAccess feature) {
    return feature.desktopOnly;
  }

  /// Get a human-readable list of what role can access
  static String getAccessSummary(UserRole role, DevicePlatform platform) {
    final features = getVisibleFeatures(role, platform);
    if (features.isEmpty) {
      return 'No features available on this device';
    }

    final names = features.map((f) => f.featureName).join(', ');
    return 'Access to: $names';
  }

  /// Check if employee is trying to access owner-only feature
  static bool isUnauthorizedAccess(UserRole role, FeatureAccess feature) {
    return role == UserRole.employee && !feature.employeeAccess;
  }

  /// Get the redirect route when unauthorized
  static String getUnauthorizedRedirect(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return '/dashboard';
      case UserRole.employee:
        return '/employee/dashboard';
    }
  }

  /// Check if a route is accessible to a role on a platform
  static bool canAccessRoute(
    UserRole role,
    String routeName,
    DevicePlatform platform,
  ) {
    // Find matching feature by route
    FeatureAccess? feature;

    if (role == UserRole.employee) {
      feature = Features.employeeMobileFeatures.firstWhere(
        (f) => f.routeName == routeName,
        orElse: () => const FeatureAccess(
          featureName: 'Unknown',
          routeName: '',
          employeeAccess: false,
        ),
      );
    } else {
      // Check both main and advanced
      try {
        feature = [
          ...Features.ownerMainFeatures,
          ...Features.ownerAdvancedFeatures,
        ].firstWhere((f) => f.routeName == routeName);
      } catch (e) {
        return false; // Route not found in feature list
      }
    }

    return feature.routeName.isNotEmpty &&
        canAccessFeatureOnPlatform(role, feature, platform);
  }
}
