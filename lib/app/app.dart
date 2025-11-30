import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../core/constants/config.dart';
import 'theme.dart';
import '../providers/user_provider.dart';
import '../providers/business_provider.dart';
import '../providers/crm_provider.dart';
import '../providers/crm_insights_provider.dart';
import '../providers/task_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/expense_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../services/firebase/auth_service.dart';
import '../config/app_routes.dart';

Future<void> bootstrap() async {
  // initialize firebase - config will be set locally per platform
  try {
    // On web, Firebase is initialized via the web config in index.html
    // On native platforms, we need to explicitly initialize
    if (!kIsWeb) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue even if Firebase fails - some features may not work
  }
}

class AuraSphereApp extends StatelessWidget {
  const AuraSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final authService = AuthService();
            final userProvider = UserProvider(authService);
            // Wire BusinessProvider to UserProvider for auto-initialization
            final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
            userProvider.setBusinessProvider(businessProvider);
            // Wire InvoiceProvider to UserProvider for lifecycle hooks
            final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
            userProvider.setInvoiceProvider(invoiceProvider);
            return userProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final currentUserId = userProvider.user?.uid;
            return CrmProvider()..setOwner(currentUserId ?? '');
          },
        ),
        ChangeNotifierProvider(create: (_) => CrmInsightsProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: MaterialApp(
        title: Config.appName,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.splash, // where lifecycle hooks are applied
        onGenerateRoute: AppRoutes.onGenerateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
