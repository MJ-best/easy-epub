import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App theme configuration following Material 3 design
class AppTheme {
  AppTheme._();

  static const List<String> _fontFamilyFallback = [
    'Noto Sans KR',
    'Apple SD Gothic Neo',
    'Malgun Gothic',
    'Roboto',
    'Segoe UI',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  // Color Schemes - Minimalist iPhone-style colors
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: const Color(0xFF007AFF),
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF1C1C1E),
    secondary: const Color(0xFF8E8E93),
    tertiary: const Color(0xFF5AC8FA),
    error: const Color(0xFFFF3B30),
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: const Color(0xFF0A84FF),
    surface: const Color(0xFF1C1C1E),
    onSurface: const Color(0xFFE5E5EA),
    secondary: const Color(0xFF8E8E93),
    tertiary: const Color(0xFF64D2FF),
    error: const Color(0xFFFF453A),
  );

  /// Light theme configuration - Minimalist iPhone style
  static ThemeData get lightTheme => _createTheme(_lightColorScheme);

  /// Dark theme configuration - Minimalist iPhone style
  static ThemeData get darkTheme => _createTheme(_darkColorScheme);

  static ThemeData _createTheme(ColorScheme scheme) {
    final textTheme = _buildTextTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      typography: Typography.material2021(),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        scrolledUnderElevation: 0,
        systemOverlayStyle:
            scheme.brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.headlineSmall,
        toolbarHeight: 64,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: textTheme.bodyMedium,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 0.6,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        dense: false,
        horizontalTitleGap: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: scheme.secondary,
        textColor: scheme.onSurface,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    final baseTypography = scheme.brightness == Brightness.dark
        ? Typography.material2021(platform: TargetPlatform.iOS).white
        : Typography.material2021(platform: TargetPlatform.iOS).black;

    final textTheme = baseTypography.copyWith(
      displayLarge: baseTypography.displayLarge?.copyWith(fontSize: 42, fontWeight: FontWeight.w700),
      displayMedium: baseTypography.displayMedium?.copyWith(fontSize: 38, fontWeight: FontWeight.w700),
      displaySmall: baseTypography.displaySmall?.copyWith(fontSize: 32, fontWeight: FontWeight.w700),
      headlineLarge: baseTypography.headlineLarge?.copyWith(fontSize: 30, fontWeight: FontWeight.w700),
      headlineMedium: baseTypography.headlineMedium?.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
      headlineSmall: baseTypography.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: baseTypography.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: baseTypography.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall: baseTypography.titleSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: baseTypography.bodyLarge?.copyWith(fontSize: 16, height: 1.6),
      bodyMedium: baseTypography.bodyMedium?.copyWith(fontSize: 15, height: 1.6),
      bodySmall: baseTypography.bodySmall?.copyWith(fontSize: 13, height: 1.5),
      labelLarge: baseTypography.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: baseTypography.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      labelSmall: baseTypography.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
    );

    return textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      fontFamilyFallback: _fontFamilyFallback,
    );
  }
}
