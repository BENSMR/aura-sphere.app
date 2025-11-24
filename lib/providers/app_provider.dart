import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {
  bool _isDarkMode = false;
  Locale _locale = const Locale('en');

  bool get isDarkMode => _isDarkMode;
  Locale get locale => _locale;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
