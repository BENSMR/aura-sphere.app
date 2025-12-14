/// Role-based access control models for AuraSphere Pro
/// 
/// Defines user roles (Owner, Employee) and their permissions
/// across mobile and desktop platforms.

enum UserRole {
  owner,      // Full access to all features
  employee,   // Limited mobile access only
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Business Owner';
      case UserRole.employee:
        return 'Employee';
    }
  }

  String get description {
    switch (this) {
      case UserRole.owner:
        return 'Full access to all features across all devices';
      case UserRole.employee:
        return 'Limited access to assigned tasks and expenses on mobile only';
    }
  }

  /// Whether this role has access to a specific feature
  bool hasAccess(FeatureAccess feature) {
    switch (this) {
      case UserRole.owner:
        return true; // Owner has access to everything
      case UserRole.employee:
        // Employee has access only to specific features
        return feature.employeeAccess;
    }
  }

  /// Whether this role can access a feature on a specific platform
  bool canAccessOnPlatform(FeatureAccess feature, DevicePlatform platform) {
    if (!hasAccess(feature)) return false;

    switch (this) {
      case UserRole.owner:
        // Owner can access on all platforms
        return true;
      case UserRole.employee:
        // Employee can only access on mobile
        return platform == DevicePlatform.mobile;
    }
  }
}

/// Device platform classification
enum DevicePlatform {
  mobile,    // iOS, Android phones
  tablet,    // iOS, Android tablets
  web,       // Web browser
  desktop,   // Windows, macOS, Linux
}

extension DevicePlatformExtension on DevicePlatform {
  String get displayName {
    switch (this) {
      case DevicePlatform.mobile:
        return 'Mobile Phone';
      case DevicePlatform.tablet:
        return 'Tablet';
      case DevicePlatform.web:
        return 'Web Browser';
      case DevicePlatform.desktop:
        return 'Desktop';
    }
  }

  bool get isMobile => this == DevicePlatform.mobile || this == DevicePlatform.tablet;
  bool get isDesktop => this == DevicePlatform.desktop || this == DevicePlatform.web;
}

/// Feature access control configuration
class FeatureAccess {
  final String featureName;
  final String routeName;
  
  /// Whether employees can access this feature
  final bool employeeAccess;
  
  /// Whether this feature is visible to owners on desktop only
  final bool desktopOnly;

  const FeatureAccess({
    required this.featureName,
    required this.routeName,
    this.employeeAccess = false,
    this.desktopOnly = false,
  });
}

/// Feature catalog with access rules
class Features {
  // ==================== Employee Features (6 features) ====================
  
  static const FeatureAccess tasksAssigned = FeatureAccess(
    featureName: 'Assigned Tasks',
    routeName: '/tasks/assigned',
    employeeAccess: true,
    desktopOnly: false,
  );

  static const FeatureAccess expenseLog = FeatureAccess(
    featureName: 'Log Expense',
    routeName: '/expenses/log',
    employeeAccess: true,
    desktopOnly: false,
  );

  static const FeatureAccess clientsView = FeatureAccess(
    featureName: 'View Clients',
    routeName: '/clients/view/:id',
    employeeAccess: true,
    desktopOnly: false,
  );

  static const FeatureAccess jobsComplete = FeatureAccess(
    featureName: 'Mark Job Complete',
    routeName: '/jobs/complete/:id',
    employeeAccess: true,
    desktopOnly: false,
  );

  static const FeatureAccess employeeProfile = FeatureAccess(
    featureName: 'Profile',
    routeName: '/profile',
    employeeAccess: true,
    desktopOnly: false,
  );

  static const FeatureAccess syncStatus = FeatureAccess(
    featureName: 'Sync Status',
    routeName: '/sync-status',
    employeeAccess: true,
    desktopOnly: false,
  );

  // ==================== Owner Features (Core Modules) ====================
  
  static const FeatureAccess dashboard = FeatureAccess(
    featureName: 'Dashboard',
    routeName: '/dashboard',
    employeeAccess: false,
    desktopOnly: false,
  );

  static const FeatureAccess crm = FeatureAccess(
    featureName: 'CRM',
    routeName: '/crm',
    employeeAccess: false,
    desktopOnly: false,
  );

  static const FeatureAccess clients = FeatureAccess(
    featureName: 'Clients',
    routeName: '/clients',
    employeeAccess: false,
    desktopOnly: false,
  );

  static const FeatureAccess invoices = FeatureAccess(
    featureName: 'Invoices',
    routeName: '/invoices',
    employeeAccess: false,
    desktopOnly: false,
  );

  static const FeatureAccess tasks = FeatureAccess(
    featureName: 'Tasks',
    routeName: '/tasks',
    employeeAccess: false,
    desktopOnly: false,
  );

  static const FeatureAccess expenses = FeatureAccess(
    featureName: 'Expenses',
    routeName: '/expenses',
    employeeAccess: false,
    desktopOnly: false,
  );

  static const FeatureAccess projects = FeatureAccess(
    featureName: 'Projects',
    routeName: '/projects',
    employeeAccess: false,
    desktopOnly: false,
  );

  // ==================== Owner Features (Advanced Modules) ====================
  // These are hidden in a collapsible "Advanced" section on desktop
  
  static const FeatureAccess inventory = FeatureAccess(
    featureName: 'Inventory',
    routeName: '/inventory',
    employeeAccess: false,
    desktopOnly: true,
  );

  static const FeatureAccess suppliers = FeatureAccess(
    featureName: 'Suppliers',
    routeName: '/suppliers',
    employeeAccess: false,
    desktopOnly: true,
  );

  static const FeatureAccess purchaseOrders = FeatureAccess(
    featureName: 'Purchase Orders',
    routeName: '/po/pdf',
    employeeAccess: false,
    desktopOnly: true,
  );

  static const FeatureAccess finance = FeatureAccess(
    featureName: 'Finance',
    routeName: '/finance/dashboard',
    employeeAccess: false,
    desktopOnly: true,
  );

  static const FeatureAccess loyalty = FeatureAccess(
    featureName: 'Loyalty',
    routeName: '/loyalty',
    employeeAccess: false,
    desktopOnly: true,
  );

  static const FeatureAccess wallet = FeatureAccess(
    featureName: 'Wallet & Billing',
    routeName: '/billing/tokens',
    employeeAccess: false,
    desktopOnly: true,
  );

  static const FeatureAccess anomalies = FeatureAccess(
    featureName: 'Anomaly Detection',
    routeName: '/anomalies',
    employeeAccess: false,
    desktopOnly: true,
  );

  static const FeatureAccess adminPanel = FeatureAccess(
    featureName: 'Admin Panel',
    routeName: '/admin/loyalty',
    employeeAccess: false,
    desktopOnly: true,
  );

  // ==================== Employee Mobile-Only Features ====================
  
  static const List<FeatureAccess> employeeMobileFeatures = [
    tasksAssigned,
    expenseLog,
    clientsView,
    jobsComplete,
    employeeProfile,
    syncStatus,
  ];

  // ==================== Owner Main Features (Sidebar/Bottom Nav) ====================
  
  static const List<FeatureAccess> ownerMainFeatures = [
    dashboard,
    clients,
    invoices,
    tasks,
    expenses,
    projects,
  ];

  // ==================== Owner Advanced Features (Collapsible) ====================
  
  static const List<FeatureAccess> ownerAdvancedFeatures = [
    inventory,
    suppliers,
    purchaseOrders,
    finance,
    loyalty,
    wallet,
    anomalies,
    adminPanel,
  ];

  // ==================== All Owner Features ====================
  
  static const List<FeatureAccess> allOwnerFeatures = [
    ...ownerMainFeatures,
    ...ownerAdvancedFeatures,
  ];
}
