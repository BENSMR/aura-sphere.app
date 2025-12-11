import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // Light theme colors
  static const Color lightPrimary = Color(0xFF667eea);
  static const Color lightSecondary = Color(0xFF764ba2);
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1F2937);
  static const Color lightError = Color(0xFFDC2626);

  // Dark theme colors
  static const Color darkPrimary = Color(0xFF667eea);
  static const Color darkSecondary = Color(0xFF764ba2);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkError = Color(0xFFFCA5A5);

  /// Light theme
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        error: lightError,
        surface: lightSurface,
        background: lightBackground,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: lightSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: lightText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: lightPrimary,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
        ),
      ),
    );
  }

  /// Dark theme
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        error: darkError,
        surface: darkSurface,
        background: darkBackground,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: darkText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFFA1A5B0),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: darkPrimary,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
        ),
      ),
    );
  }
}

/// Theme provider using ChangeNotifier
class ThemeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  late String _userId;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initialize theme from Firestore
  Future<void> initialize(String userId) async {
    _userId = userId;
    await _loadThemePreference();
  }

  /// Load theme preference from Firestore
  Future<void> _loadThemePreference() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('preferences')
          .doc('theme')
          .get();

      if (doc.exists) {
        _isDarkMode = doc.data()?['isDarkMode'] ?? false;
      } else {
        // Use system theme as default
        _isDarkMode = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load theme preference: $e');
    }
  }

  /// Toggle theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveThemePreference();
  }

  /// Set theme to light
  Future<void> setLightTheme() async {
    _isDarkMode = false;
    notifyListeners();
    await _saveThemePreference();
  }

  /// Set theme to dark
  Future<void> setDarkTheme() async {
    _isDarkMode = true;
    notifyListeners();
    await _saveThemePreference();
  }

  /// Save theme preference to Firestore
  Future<void> _saveThemePreference() async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('preferences')
          .doc('theme')
          .set({
            'isDarkMode': _isDarkMode,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Failed to save theme preference: $e');
    }
  }

  /// Get current theme data
  ThemeData getTheme() {
    return _isDarkMode ? AppTheme.darkTheme() : AppTheme.lightTheme();
  }

  /// Stream theme changes
  Stream<bool> streamThemeChanges() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('preferences')
        .doc('theme')
        .snapshots()
        .map((snap) => snap.data()?['isDarkMode'] ?? false);
  }
}
