import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/crm/crm_ai_insights_screen.dart';
import '../screens/tasks/tasks_list_screen.dart';
import '../screens/invoices/invoice_creator_screen.dart';
import '../screens/expenses/expense_scanner_screen.dart';
import '../screens/waitlist_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String expenseScanner = '/expense-scanner';
  static const String aiAssistant = '/ai-assistant';
  static const String crm = '/crm';
  static const String crmAiInsights = '/crm/ai-insights';
  static const String tasks = '/tasks';
  static const String projects = '/projects';
  static const String invoices = '/invoices';
  static const String invoiceCreate = '/invoice/create';
  static const String invoiceDetails = '/invoice/details';
  static const String crypto = '/crypto';
  static const String profile = '/profile';
  static const String waitlist = '/waitlist';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case expenseScanner:
        return MaterialPageRoute(builder: (_) => const ExpenseScannerScreen());
      case crmAiInsights:
        return MaterialPageRoute(builder: (_) => const CrmAiInsightsScreen());
      case tasks:
        return MaterialPageRoute(builder: (_) => const TasksListScreen());
      case invoiceCreate:
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        final initialInvoice = args?['invoice'];
        if (userId == null) {
          return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
        return MaterialPageRoute(
          builder: (_) => InvoiceCreatorScreen(
            userId: userId,
            initialInvoice: initialInvoice,
          ),
        );
      case waitlist:
        final args = settings.arguments as Map<String, dynamic>?;
        final feature = args?['feature'] as String? ?? 'Feature';
        return MaterialPageRoute(
          builder: (_) => WaitlistScreen(feature: feature),
        );
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
