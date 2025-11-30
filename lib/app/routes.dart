import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/crm/crm_list_screen.dart';
import '../screens/crm/crm_contact_screen.dart';
import '../screens/crm/crm_contact_detail.dart';
import '../screens/crm/crm_ai_insights_screen.dart';
import '../screens/invoices/payment_history_screen.dart';
import '../data/models/crm_model.dart';

class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  
  // Main app routes
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  
  // Feature routes
  static const String expenses = '/expenses';
  static const String expenseScanner = '/expense-scanner';
  static const String expenseReview = '/expense-review';
  static const String expenseHistory = '/expense-history';
  
  static const String invoices = '/invoices';
  static const String invoiceCreate = '/invoice-create';
  static const String invoiceEdit = '/invoice-edit';
  static const String paymentHistory = '/payment-history';
  
  static const String crm = '/crm';
  static const String crmNew = '/crm/new';
  static const String crmContact = '/crm-contact';
  
  static const String projects = '/projects';
  static const String projectDetails = '/project-details';
  
  static const String ai = '/ai-assistant';
  static const String wallet = '/aura-wallet';
  
  // Settings routes
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case signup:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
          settings: settings,
        );
      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      case crm:
        return MaterialPageRoute(
          builder: (_) => const CrmListScreen(),
          settings: settings,
        );
      case crmNew:
        return MaterialPageRoute(
          builder: (_) => const CrmContactScreen(),
          settings: settings,
        );
      case crmContact:
        // For editing contact, pass Contact object via arguments
        final contact = settings.arguments as Contact?;
        return MaterialPageRoute(
          builder: (_) => CrmContactScreen(contact: contact),
          settings: settings,
        );
      case '/crm/insights':
        return MaterialPageRoute(
          builder: (_) => const CrmAiInsightsScreen(),
          settings: settings,
        );
      case paymentHistory:
        // For payment history, pass Invoice object via arguments
        final invoice = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => const PaymentHistoryScreen(),
          settings: settings,
        );
      default:
        // Handle dynamic routes like /crm/detail/:id
        final uri = Uri.parse(settings.name ?? '');
        if (uri.pathSegments.length == 3 && 
            uri.pathSegments[0] == 'crm' && 
            uri.pathSegments[1] == 'detail') {
          final contactId = uri.pathSegments[2];
          return MaterialPageRoute(
            builder: (_) => CrmContactDetail(contactId: contactId),
            settings: settings,
          );
        }
        
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
          settings: settings,
        );
    }
  }
}