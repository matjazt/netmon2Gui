import 'package:flutter/material.dart';

/// Light and dark [ThemeData] definitions for the app.
///
/// Both themes share the same seed colour and use Material 3. Switch between
/// them by passing [lightTheme] or [darkTheme] to [MaterialApp].
class AppTheme {
  AppTheme._();

  // Primary brand colour — change here to restyle the entire app.
  static const Color _seedColor = Color(0xFF1565C0); // deep blue

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    colorSchemeSeed: _seedColor,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorSchemeSeed: _seedColor,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
  );
}
