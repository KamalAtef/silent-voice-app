import 'package:flutter/material.dart';

class AppTheme {
  static bool _isArabic(Locale locale) => locale.languageCode == 'ar';

  // 🌞 LIGHT THEME
  static ThemeData light(Locale locale) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3FA66B),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: _isArabic(locale) ? 'MontserratArabic' : 'Poppins',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );


  // 🌙 DARK THEME
  static ThemeData dark(Locale locale) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3FA66B),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F1115),
    fontFamily: _isArabic(locale) ? 'MontserratArabic' : 'Poppins',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
    ),
  );
}
