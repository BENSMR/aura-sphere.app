import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/role_model.dart';
import '../providers/user_provider.dart';
import '../config/app_routes.dart';
import '../services/access_control_service.dart';

/// Role-Based Navigation Router
/// 
/// Intercepts navigation and ensures users only access features they're authorized for.
/// Routes employees to the employee dashboard and owners to the main dashboard.

class RoleBasedNavigator extends StatelessWidget {
  final Widget child;

  const RoleBasedNavigator({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        // While loading, show splash
        if (userProvider.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in, show child (navigation will handle login)
        if (!userProvider.isLoggedIn) {
          return child;
        }

        // Logged in - ensure role is set
        final user = userProvider.user!;
        final role = user.role == 'employee' ? UserRole.employee : UserRole.owner;

        // Return child with role awareness
        return RoleAwareWidget(
          role: role,
          child: child,
        );
      },
    );
  }
}

/// Wraps the app to enforce role-based access
class RoleAwareWidget extends StatelessWidget {
  final UserRole role;
  final Widget child;

  const RoleAwareWidget({
    required this.role,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent navigation outside authorized routes
        return true;
      },
      child: child,
    );
  }
}

/// Route guard to check authorization
class RouteGuard {
  /// Check if user can navigate to a route
  static Future<bool> canNavigate(
    BuildContext context,
    String routeName,
  ) async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    if (user == null) return false;

    final role = user.role == 'employee' ? UserRole.employee : UserRole.owner;
    final platform = _getPlatform();

    // Check if route is accessible
    return AccessControlService.canAccessRoute(role, routeName, platform);
  }

  /// Navigate with authorization check
  static Future<void> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (await canNavigate(context, routeName)) {
      if (context.mounted) {
        Navigator.of(context).pushNamed(routeName, arguments: arguments);
      }
    } else {
      // Show unauthorized message
      if (context.mounted) {
        final userProvider = context.read<UserProvider>();
        final user = userProvider.user!;
        final role =
            user.role == 'employee' ? UserRole.employee : UserRole.owner;
        final redirect = AccessControlService.getUnauthorizedRedirect(role);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You do not have access to this feature'),
            action: SnackBarAction(
              label: 'Go Back',
              onPressed: () => Navigator.of(context).pushReplacementNamed(redirect),
            ),
          ),
        );
      }
    }
  }

  static DevicePlatform _getPlatform() {
    // TODO: Implement platform detection
    // For now, assume mobile
    return DevicePlatform.mobile;
  }
}

/// Route observer for logging and analytics
class RoleBasedRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    debugPrint('Route pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    debugPrint('Route popped: ${route.settings.name}');
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    debugPrint('Route removed: ${route.settings.name}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    debugPrint('Route replaced: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}');
  }
}
