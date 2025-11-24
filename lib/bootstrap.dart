import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/constants.dart';
import 'config/app_theme.dart';
import 'screens/splash/splash_screen.dart';

Future<void> bootstrap() async {
  // initialize firebase - config will be set locally per platform
  await Firebase.initializeApp();
}

class AuraSphereApp extends StatelessWidget {
  const AuraSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Constants.appName,
      theme: AppTheme.light(),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
