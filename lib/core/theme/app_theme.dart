import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App theme configuration following Material 3 design
class AppTheme {
  AppTheme._();

  static const Color baseColor = Color(0xFFF9F8EF);
  static const Color mainColor = Color(0xFF1B1802);
  static const Color accentColor = Color(0xFFEBD853);
  static const Color errorColor = Color(0xFFB3261E);

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

  static final ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: accentColor,
    onPrimary: mainColor,
    primaryContainer: _blendOnBase(accentColor, 0.22),
    onPrimaryContainer: mainColor,
    secondary: _blendOnBase(mainColor, 0.64),
    onSecondary: baseColor,
    secondaryContainer: _blendOnBase(mainColor, 0.06),
    onSecondaryContainer: mainColor,
    tertiary: _blendOnBase(mainColor, 0.74),
    onTertiary: baseColor,
    tertiaryContainer: _blendOnBase(mainColor, 0.1),
    onTertiaryContainer: mainColor,
    error: errorColor,
    onError: baseColor,
    errorContainer: _blendOnBase(errorColor, 0.1),
    onErrorContainer: errorColor,
    surface: baseColor,
    onSurface: mainColor,
    onSurfaceVariant: _blendOnBase(mainColor, 0.68),
    outline: _blendOnBase(mainColor, 0.22),
    outlineVariant: _blendOnBase(mainColor, 0.12),
    shadow: mainColor.withValues(alpha: 0.1),
    scrim: mainColor.withValues(alpha: 0.45),
    inverseSurface: mainColor,
    onInverseSurface: baseColor,
    inversePrimary: accentColor,
    surfaceTint: Colors.transparent,
    surfaceDim: _blendOnBase(mainColor, 0.028),
    surfaceBright: baseColor,
    surfaceContainerLowest: baseColor,
    surfaceContainerLow: _blendOnBase(mainColor, 0.015),
    surfaceContainer: _blendOnBase(mainColor, 0.03),
    surfaceContainerHigh: _blendOnBase(mainColor, 0.05),
    surfaceContainerHighest: _blendOnBase(mainColor, 0.07),
  );

  static final ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: accentColor,
    onPrimary: mainColor,
    primaryContainer: _blendOnMain(accentColor, 0.22),
    onPrimaryContainer: baseColor,
    secondary: _blendOnMain(baseColor, 0.74),
    onSecondary: mainColor,
    secondaryContainer: _blendOnMain(baseColor, 0.12),
    onSecondaryContainer: baseColor,
    tertiary: _blendOnMain(baseColor, 0.8),
    onTertiary: mainColor,
    tertiaryContainer: _blendOnMain(baseColor, 0.14),
    onTertiaryContainer: baseColor,
    error: const Color(0xFFFFB4AB),
    onError: mainColor,
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
    surface: mainColor,
    onSurface: baseColor,
    onSurfaceVariant: _blendOnMain(baseColor, 0.68),
    outline: _blendOnMain(baseColor, 0.24),
    outlineVariant: _blendOnMain(baseColor, 0.14),
    shadow: Colors.black.withValues(alpha: 0.32),
    scrim: Colors.black.withValues(alpha: 0.56),
    inverseSurface: baseColor,
    onInverseSurface: mainColor,
    inversePrimary: accentColor,
    surfaceTint: Colors.transparent,
    surfaceDim: _blendOnMain(baseColor, 0.02),
    surfaceBright: _blendOnMain(baseColor, 0.08),
    surfaceContainerLowest: mainColor,
    surfaceContainerLow: _blendOnMain(baseColor, 0.04),
    surfaceContainer: _blendOnMain(baseColor, 0.06),
    surfaceContainerHigh: _blendOnMain(baseColor, 0.09),
    surfaceContainerHighest: _blendOnMain(baseColor, 0.12),
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
        systemOverlayStyle: scheme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.headlineSmall,
        toolbarHeight: 64,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
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
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
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
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        disabledColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle:
            textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.08),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primaryContainer;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.all(scheme.outlineVariant),
      ),
      listTileTheme: ListTileThemeData(
        dense: false,
        horizontalTitleGap: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: scheme.onSurfaceVariant,
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
      displayLarge: baseTypography.displayLarge
          ?.copyWith(fontSize: 42, fontWeight: FontWeight.w700),
      displayMedium: baseTypography.displayMedium
          ?.copyWith(fontSize: 38, fontWeight: FontWeight.w700),
      displaySmall: baseTypography.displaySmall
          ?.copyWith(fontSize: 32, fontWeight: FontWeight.w700),
      headlineLarge: baseTypography.headlineLarge
          ?.copyWith(fontSize: 30, fontWeight: FontWeight.w700),
      headlineMedium: baseTypography.headlineMedium
          ?.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
      headlineSmall: baseTypography.headlineSmall
          ?.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: baseTypography.titleLarge
          ?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: baseTypography.titleMedium
          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall: baseTypography.titleSmall
          ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: baseTypography.bodyLarge?.copyWith(fontSize: 16, height: 1.6),
      bodyMedium:
          baseTypography.bodyMedium?.copyWith(fontSize: 15, height: 1.6),
      bodySmall: baseTypography.bodySmall?.copyWith(fontSize: 13, height: 1.5),
      labelLarge: baseTypography.labelLarge?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: baseTypography.labelMedium
          ?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      labelSmall: baseTypography.labelSmall
          ?.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
    );

    return textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      fontFamilyFallback: _fontFamilyFallback,
    );
  }

  static Color _blendOnBase(Color color, double alpha) {
    return Color.alphaBlend(color.withValues(alpha: alpha), baseColor);
  }

  static Color _blendOnMain(Color color, double alpha) {
    return Color.alphaBlend(color.withValues(alpha: alpha), mainColor);
  }
}
