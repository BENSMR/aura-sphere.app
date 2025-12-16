import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../core/constants/config.dart';
import '../providers/user_provider.dart';
import '../providers/business_provider.dart';
import '../providers/client_provider.dart';
import '../providers/crm_provider.dart';
import '../providers/crm_insights_provider.dart';
import '../providers/task_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/branding_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firebase/auth_service.dart';
import '../services/deep_link_service.dart';
import '../services/wallet_service.dart';
import '../screens/wallet/payment_result_handler.dart';
import '../config/app_routes.dart';

late DeepLinkService _deepLinkService;

Future<void> bootstrap() async {
  // initialize firebase - config will be set locally per platform
  try {
    // On web, Firebase is initialized via the web config in index.html
    // On native platforms, we need to explicitly initialize
    if (!kIsWeb) {
      await Firebase.initializeApp();
    }
    
    // Configure Firebase Crashlytics
    final crashlytics = FirebaseCrashlytics.instance;
    crashlytics.setCrashlyticsCollectionEnabled(true);
    
    // Enable Firestore offline persistence (100MB cache)
    final firestore = FirebaseFirestore.instance;
    await firestore.disableNetwork();
    await firestore.enableNetwork();
    
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 104857600, // 100MB
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue even if Firebase fails - some features may not work
  }

  // Initialize deep link service for payment redirects
  try {
    _deepLinkService = DeepLinkService();
    _deepLinkService.init();
  } catch (e) {
    debugPrint('Deep link service initialization error: $e');
    // Continue - wallet features will be limited
  }
}

class AuraSphereApp extends StatelessWidget {
  const AuraSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => BusinessProvider()),
          ChangeNotifierProvider(create: (_) => InvoiceProvider()),
          ChangeNotifierProvider(create: (_) => ClientProvider()),
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
              // Initialize theme provider when user logs in
              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
              userProvider.addListener(() {
                if (userProvider.user != null) {
                  themeProvider.initialize(userProvider.user!.uid);
                }
              });
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
          ChangeNotifierProvider(create: (_) => BrandingProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            // Create a fallback MaterialApp if initialization hasn't completed
            final materialApp = MaterialApp(
              title: Config.appName,
              theme: themeProvider.getTheme(),
              initialRoute: AppRoutes.splash,
              onGenerateRoute: AppRoutes.onGenerateRoute,
              debugShowCheckedModeBanner: false,
            );

            // Wrap with PaymentResultHandler only if deepLinkService is initialized
            try {
              return PaymentResultHandler(
                deepLinkService: _deepLinkService,
                walletService: WalletService(),
                child: materialApp,
              );
            } catch (e) {
              debugPrint('Error creating PaymentResultHandler: $e');
              return materialApp; // Fallback to basic app
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('Error in AuraSphereApp.build: $e');
      return MaterialApp(
        title: 'Error',
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      );
    }
  }
}
