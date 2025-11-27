import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aurasphere_pro/screens/splash/splash_screen.dart';

void main() {
  testWidgets('Splash screen renders title and loader', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('AuraSphere'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
