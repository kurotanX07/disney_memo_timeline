import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 1.0; // 1.0 is normal size

  ThemeProvider() {
    _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;

  ThemeData get theme {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? 1.0;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    notifyListeners();
  }

  // Light Theme
  ThemeData get _lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: Colors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        color: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: _getTextTheme(Brightness.light),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.grey[100],
    );
  }

  // Dark Theme
  ThemeData get _darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: Colors.indigo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        color: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: _getTextTheme(Brightness.dark),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.grey[900],
    );
  }

  TextTheme _getTextTheme(Brightness brightness) {
    final baseTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: 26 * _fontSize,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: 22 * _fontSize,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: 18 * _fontSize,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: 16 * _fontSize,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontSize: 15 * _fontSize,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: 14 * _fontSize,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: 13 * _fontSize,
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontSize: 14 * _fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
