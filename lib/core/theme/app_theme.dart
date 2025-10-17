import 'package:flutter/material.dart';

/// App theme configuration following Material 3 design
class AppTheme {
  AppTheme._();

  // Color Schemes - Minimalist iPhone-style colors
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF007AFF), // iOS blue
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE3F2FD),
    onPrimaryContainer: Color(0xFF001A33),
    secondary: Color(0xFF8E8E93), // iOS gray
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF2F2F7),
    onSecondaryContainer: Color(0xFF1C1C1E),
    tertiary: Color(0xFF5AC8FA), // iOS light blue
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE0F7FA),
    onTertiaryContainer: Color(0xFF001A1F),
    error: Color(0xFFFF3B30), // iOS red
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFEBEE),
    onErrorContainer: Color(0xFF330000),
    background: Color(0xFFF2F2F7), // iOS background
    onBackground: Color(0xFF000000),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
    surfaceVariant: Color(0xFFF2F2F7),
    onSurfaceVariant: Color(0xFF48484A),
    outline: Color(0xFFC6C6C8),
    outlineVariant: Color(0xFFE5E5EA),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1C1C1E),
    onInverseSurface: Color(0xFFFFFFFF),
    inversePrimary: Color(0xFF0A84FF),
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF0A84FF), // iOS blue dark mode
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF004080),
    onPrimaryContainer: Color(0xFFD0E8FF),
    secondary: Color(0xFF8E8E93), // iOS gray dark
    onSecondary: Color(0xFF1C1C1E),
    secondaryContainer: Color(0xFF2C2C2E),
    onSecondaryContainer: Color(0xFFE5E5EA),
    tertiary: Color(0xFF64D2FF), // iOS light blue dark
    onTertiary: Color(0xFF1C1C1E),
    tertiaryContainer: Color(0xFF003D4A),
    onTertiaryContainer: Color(0xFFB3E5FC),
    error: Color(0xFFFF453A), // iOS red dark mode
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF660000),
    onErrorContainer: Color(0xFFFFCDD2),
    background: Color(0xFF000000), // iOS dark background
    onBackground: Color(0xFFFFFFFF),
    surface: Color(0xFF1C1C1E),
    onSurface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFF2C2C2E),
    onSurfaceVariant: Color(0xFFAEAEB2),
    outline: Color(0xFF48484A),
    outlineVariant: Color(0xFF38383A),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFFFFFFF),
    onInverseSurface: Color(0xFF000000),
    inversePrimary: Color(0xFF007AFF),
  );

  /// Light theme configuration - Minimalist iPhone style
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: _lightColorScheme.surface,
        foregroundColor: _lightColorScheme.onSurface,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _lightColorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 50),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: _lightColorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightColorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: _lightColorScheme.primary,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: _lightColorScheme.outlineVariant,
        thickness: 0.5,
      ),
    );
  }

  /// Dark theme configuration - Minimalist iPhone style
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: _darkColorScheme.onSurface,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkColorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 50),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: _darkColorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkColorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: _darkColorScheme.primary,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: _darkColorScheme.outlineVariant,
        thickness: 0.5,
      ),
    );
  }
}
