import 'package:flutter/material.dart';

/// [AppTheme] — Material 3 theme seeded from Material Pink 500.
/// Used by [Application] for the whole app.
class AppTheme {
  AppTheme._();

  /// Brand pink — used as the [ColorScheme] seed and as the calendar's
  /// period-day accent.
  static const Color pink = Color(0xFFE91E63);

  /// Complementary teal — used for ovulation-day markers so they stand
  /// out against pink period days without clashing.
  static const Color ovulationTeal = Color(0xFF26A69A);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: pink,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
