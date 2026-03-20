import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seed = Color(0xFF0F766E);
  static const Color _accent = Color(0xFFD97706);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      primary: _seed,
      secondary: _accent,
      surface: const Color(0xFFF6F7F2),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: Typography.blackMountainView.copyWith(
        displaySmall: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        headlineMedium: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: const TextStyle(
          fontSize: 15,
          height: 1.55,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.55,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      primary: const Color(0xFF49B4A7),
      secondary: const Color(0xFFF2A65A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF111714),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF18211D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
