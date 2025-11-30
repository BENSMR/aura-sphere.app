import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/crm/crm_ai_insights_screen.dart';
import '../screens/crm/crm_list_screen.dart';
import '../screens/crm/crm_contact_detail.dart';
import '../screens/crm/crm_contact_screen.dart';
import '../screens/tasks/tasks_list_screen.dart';
// import '../screens/invoices/invoice_creator_screen.dart'; // Temporarily disabled
import '../screens/invoice/invoice_template_select_screen.dart';
import '../screens/invoices/payment_history_screen.dart';
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
  static const String crmCreate = '/crm/create';
  static const String crmDetail = '/crm/:id';
  static const String crmAiInsights = '/crm/ai-insights';
  static const String tasks = '/tasks';
  static const String projects = '/projects';
  static const String invoices = '/invoices';
  static const String invoiceCreate = '/invoice/create';
  static const String invoiceTemplates = '/invoice/templates';
  static const String invoiceDetails = '/invoice/details';
  static const String paymentHistory = '/payment-history';
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
      case crm:
        return MaterialPageRoute(builder: (_) => const CrmListScreen());
      case crmCreate:
        return MaterialPageRoute(builder: (_) => const CrmContactScreen());
      case crmAiInsights:
        return MaterialPageRoute(builder: (_) => const CrmAiInsightsScreen());
      case tasks:
        return MaterialPageRoute(builder: (_) => const TasksListScreen());
      case invoiceCreate:
        // Temporarily disabled - InvoiceCreatorScreen not available
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case invoiceTemplates:
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        if (userId == null) {
          return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
        return MaterialPageRoute(
          builder: (_) => InvoiceTemplateSelectScreen(userId: userId),
        );
      case paymentHistory:
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => const PaymentHistoryScreen(),
          settings: settings,
        );
      case waitlist:
        final args = settings.arguments as Map<String, dynamic>?;
        final feature = args?['feature'] as String? ?? 'Feature';
        return MaterialPageRoute(
          builder: (_) => WaitlistScreen(feature: feature),
        );
      default:
        // Handle dynamic CRM detail route: /crm/:id
        if (settings.name != null && settings.name!.startsWith('/crm/') && settings.name != '/crm/ai-insights') {
          final contactId = settings.name!.replaceFirst('/crm/', '');
          return MaterialPageRoute(
            builder: (_) => CrmContactDetail(contactId: contactId),
          );
        }
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
