import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFEFEEEE);
  static const Color primary = Color(0xFF26A69A);
  static const Color primaryLight = Color(0xFF80CBC4);
  static const Color textDark = Color(0xFF37474F);
  static const Color textLight = Color(0xFF90A4AE);

  static const Color shadowLight = Colors.white;
  static const Color shadowDark = Color(
    0xFFA3B1C6,
  ); // Slightly blueish grey for depth

  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      fontFamily: 'Roboto', // Or a similar sans-serif
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textDark,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        bodyLarge: TextStyle(color: textDark, fontSize: 16),
        bodyMedium: TextStyle(color: textLight, fontSize: 14),
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: primaryLight,
        surface: background,
      ),
    );
  }
}
