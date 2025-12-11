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
import '../screens/crm/clients_list_screen.dart';
import '../screens/crm/client_details_screen.dart';
import '../screens/crm/add_client_screen.dart';
import '../screens/crm/deals_pipeline_screen.dart';
import '../screens/clients/client_list_screen.dart';
import '../screens/clients/client_detail_screen.dart';
import '../screens/clients/edit_client_screen.dart';
import '../screens/tasks/tasks_list_screen.dart';
// import '../screens/invoices/invoice_creator_screen.dart'; // Temporarily disabled
import '../screens/invoice/invoice_template_select_screen.dart';
import '../screens/invoices/payment_history_screen.dart';
import '../screens/invoices/invoice_settings_screen.dart';
import '../screens/expenses/expense_scanner_screen.dart';
import '../screens/settings/invoice_branding_screen.dart';
import '../screens/settings/template_gallery_screen.dart';
import '../screens/audit/invoice_audit_screen.dart';
import '../screens/waitlist_screen.dart';
import '../screens/finance/finance_dashboard_screen.dart';
import '../screens/finance/finance_goals_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/suppliers/supplier_screen.dart';
import '../screens/purchase_orders/po_pdf_preview_screen.dart';
import '../screens/purchase_orders/po_email_modal.dart';
import '../screens/expenses/expense_list_screen.dart';
import '../screens/expenses/expense_scan_screen.dart';
import '../screens/expenses/expense_review_screen.dart';
import '../screens/expenses/expense_detail_screen.dart';

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
  static const String crmList = '/crm/list';
  static const String crmDetails = '/crm/details';
  static const String crmAdd = '/crm/add';
  static const String dealsPipeline = '/deals/pipeline';
  static const String crmEdit = '/crm/edit';
  static const String clients = '/clients';
  static const String clientsCreate = '/clients/create';
  static const String clientsDetail = '/clients/:id';
  static const String tasks = '/tasks';
  static const String projects = '/projects';
  static const String invoices = '/invoices';
  static const String invoiceCreate = '/invoice/create';
  static const String invoiceTemplates = '/invoice/templates';
  static const String invoiceDetails = '/invoice/details';
  static const String paymentHistory = '/payment-history';
  static const String crypto = '/crypto';
  static const String profile = '/profile';
  static const String invoiceBranding = '/settings/invoice-branding';
  static const String invoiceSettings = '/settings/invoice-settings';
  static const String templateGallery = '/settings/templates';
  static const String invoiceAudit = '/invoices/audit';
  static const String waitlist = '/waitlist';
  static const String financeDashboard = '/finance/dashboard';
  static const String financeGoals = '/finance/goals';
  static const String inventory = '/inventory';
  static const String suppliers = '/suppliers';
  static const String poPdfPreview = '/po/pdf';
  static const String poEmail = '/po/email';
  static const String expensesList = '/expenses';
  static const String expensesScan = '/expenses/scan';
  static const String expensesReview = '/expenses/review';
  static const String expensesDetail = '/expenses/detail';

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
      case crmList:
        return MaterialPageRoute(builder: (_) => const ClientsListScreen());
      case crmDetails:
        final args = ModalRoute.of(_)!.settings.arguments;
        final clientId = (args is String)
            ? args
            : (args is Map<String, dynamic>
                ? args['clientId']
                : null);
        if (clientId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Missing clientId')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ClientDetailsScreen(clientId: clientId),
          settings: settings,
        );
      case crmAdd:
        return MaterialPageRoute(builder: (_) => const CRMAddClientScreen());
      case crmEdit:
        final clientId = settings.arguments as String?;
        if (clientId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Missing clientId')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => EditClientScreen(clientId: clientId),
          settings: settings,
        );
      case dealsPipeline:
        return MaterialPageRoute(builder: (_) => const DealsPipelineScreen());
      case clients:
        return MaterialPageRoute(builder: (_) => const ClientListScreen());
      case clientsCreate:
        return MaterialPageRoute(builder: (_) => const EditClientScreen());
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
      case invoiceBranding:
        return MaterialPageRoute(builder: (_) => const InvoiceBrandingScreen());
      case templateGallery:
        return MaterialPageRoute(builder: (_) => const TemplateGalleryScreen());
      case invoiceSettings:
        return MaterialPageRoute(builder: (_) => const InvoiceSettingsScreen());
      case invoiceAudit:
        return MaterialPageRoute(builder: (_) => const InvoiceAuditScreen());
      case waitlist:
        final args = settings.arguments as Map<String, dynamic>?;
        final feature = args?['feature'] as String? ?? 'Feature';
        return MaterialPageRoute(
          builder: (_) => WaitlistScreen(feature: feature),
        );
      case financeDashboard:
        return MaterialPageRoute(builder: (_) => const FinanceDashboardScreen());
      case financeGoals:
        return MaterialPageRoute(builder: (_) => const FinanceGoalsScreen());
      case inventory:
        return MaterialPageRoute(builder: (_) => const InventoryScreen());
      case suppliers:
        return MaterialPageRoute(builder: (_) => const SupplierScreen());
      case poPdfPreview:
        final poId = settings.arguments as String?;
        if (poId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Missing poId')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => POPDFPreviewScreen(poId: poId),
          settings: settings,
        );
      case poEmail:
        final args = settings.arguments as Map<String, dynamic>?;
        final poId = args?['poId'] as String?;
        final defaultTo = args?['defaultTo'] as String?;
        if (poId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Missing poId')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => POEmailModal(
            poId: poId,
            defaultTo: defaultTo,
          ),
          settings: settings,
        );
      case expensesList:
        return MaterialPageRoute(builder: (_) => const ExpenseListScreen());
      case expensesScan:
        return MaterialPageRoute(builder: (_) => const ExpenseScanScreen());
      case expensesReview:
        final args = settings.arguments as Map<String, dynamic>?;
        final expenseId = args?['expenseId'] as String?;
        if (expenseId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Missing expenseId')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ExpenseReviewScreen(expenseId: expenseId),
          settings: settings,
        );
      case expensesDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final expenseId = args?['expenseId'] as String?;
        if (expenseId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Missing expenseId')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ExpenseDetailScreen(expenseId: expenseId),
          settings: settings,
        );
      default:
        // Handle dynamic CRM detail route: /crm/:id
        if (settings.name != null && settings.name!.startsWith('/crm/') && settings.name != '/crm/ai-insights') {
          final contactId = settings.name!.replaceFirst('/crm/', '');
          return MaterialPageRoute(
            builder: (_) => CrmContactDetail(contactId: contactId),
          );
        }
        // Handle dynamic Client detail route: /clients/:id
        if (settings.name != null && settings.name!.startsWith('/clients/') && settings.name != '/clients/create') {
          final clientId = settings.name!.replaceFirst('/clients/', '');
          final client = settings.arguments as ClientModel?;
          if (client != null) {
            return MaterialPageRoute(
              builder: (_) => ClientDetailScreen(client: client),
            );
          }
        }
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
