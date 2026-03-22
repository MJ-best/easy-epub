import 'package:easypub/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme palette', () {
    test('light theme maps the warm neutral palette to primary surfaces', () {
      final scheme = AppTheme.lightTheme.colorScheme;

      expect(AppTheme.baseColor, const Color(0xFFF9F8EF));
      expect(AppTheme.mainColor, const Color(0xFF1B1802));
      expect(AppTheme.accentColor, const Color(0xFFEBD853));
      expect(scheme.surface, const Color(0xFFF9F8EF));
      expect(scheme.onSurface, const Color(0xFF1B1802));
      expect(scheme.primary, const Color(0xFFEBD853));
      expect(scheme.onPrimary, const Color(0xFF1B1802));
      expect(AppTheme.lightTheme.inputDecorationTheme.fillColor, isNotNull);
    });

    test('dark theme keeps the same palette family with warm contrast', () {
      final scheme = AppTheme.darkTheme.colorScheme;

      expect(scheme.surface, const Color(0xFF1B1802));
      expect(scheme.onSurface, const Color(0xFFF9F8EF));
      expect(scheme.primary, const Color(0xFFEBD853));
      expect(scheme.onPrimary, const Color(0xFF1B1802));
      expect(scheme.primaryContainer, isNot(equals(scheme.primary)));
      expect(
        AppTheme.darkTheme.floatingActionButtonTheme.backgroundColor,
        const Color(0xFFEBD853),
      );
    });
  });
}
