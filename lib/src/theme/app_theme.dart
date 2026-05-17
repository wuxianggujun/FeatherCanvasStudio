import 'package:flutter/material.dart';

import 'layout_constants.dart';

class AppColorsLight {
  const AppColorsLight._();

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryHover = Color(0xFF4338CA);
  static const Color primaryActive = Color(0xFF3730A3);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF0EA5E9);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F2F6);
  static const Color surfaceContainer = Color(0xFFFAFAFC);
  static const Color surfaceContainerHigh = Color(0xFFEFF1F5);
  static const Color outline = Color(0xFFE2E4EA);
  static const Color outlineVariant = Color(0xFFEDEEF2);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
}

class AppColorsDark {
  const AppColorsDark._();

  static const Color primary = Color(0xFF818CF8);
  static const Color primaryHover = Color(0xFF6366F1);
  static const Color primaryActive = Color(0xFF4F46E5);
  static const Color onPrimary = Color(0xFF1E1B4B);

  static const Color secondary = Color(0xFF38BDF8);
  static const Color onSecondary = Color(0xFF0C4A6E);

  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  static const Color background = Color(0xFF0F1115);
  static const Color surface = Color(0xFF181A20);
  static const Color surfaceVariant = Color(0xFF1F222A);
  static const Color surfaceContainer = Color(0xFF15171D);
  static const Color surfaceContainerHigh = Color(0xFF252832);
  static const Color outline = Color(0xFF2E323C);
  static const Color outlineVariant = Color(0xFF272A33);

  static const Color textPrimary = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFFB4B7C0);
  static const Color textTertiary = Color(0xFF9097A1);
  static const Color textDisabled = Color(0xFF5C6270);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark ? _darkScheme : _lightScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 12),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: AppRadius.radiusSm,
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
      ),
      textTheme: _buildTextTheme(scheme),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 14, color: scheme.onSurface, height: 1.5),
      bodyMedium: TextStyle(fontSize: 13, color: scheme.onSurface, height: 1.5),
      bodySmall: TextStyle(
        fontSize: 12,
        color: scheme.onSurfaceVariant,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColorsLight.primary,
    onPrimary: AppColorsLight.onPrimary,
    primaryContainer: Color(0xFFE0E7FF),
    onPrimaryContainer: Color(0xFF1E1B4B),
    secondary: AppColorsLight.secondary,
    onSecondary: AppColorsLight.onSecondary,
    secondaryContainer: Color(0xFFE0F2FE),
    onSecondaryContainer: Color(0xFF0C4A6E),
    tertiary: Color(0xFF7C3AED),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFEDE9FE),
    onTertiaryContainer: Color(0xFF4C1D95),
    error: AppColorsLight.danger,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: AppColorsLight.surface,
    onSurface: AppColorsLight.textPrimary,
    onSurfaceVariant: AppColorsLight.textSecondary,
    outline: AppColorsLight.outline,
    outlineVariant: AppColorsLight.outlineVariant,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFAFAFC),
    surfaceContainer: AppColorsLight.surfaceContainer,
    surfaceContainerHigh: AppColorsLight.surfaceContainerHigh,
    surfaceContainerHighest: Color(0xFFEAECEF),
    inverseSurface: Color(0xFF1F2937),
    onInverseSurface: Color(0xFFF3F4F6),
    inversePrimary: Color(0xFFA5B4FC),
    shadow: Color(0x1A000000),
    scrim: Color(0x66000000),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColorsDark.primary,
    onPrimary: AppColorsDark.onPrimary,
    primaryContainer: Color(0xFF3730A3),
    onPrimaryContainer: Color(0xFFE0E7FF),
    secondary: AppColorsDark.secondary,
    onSecondary: AppColorsDark.onSecondary,
    secondaryContainer: Color(0xFF075985),
    onSecondaryContainer: Color(0xFFE0F2FE),
    tertiary: Color(0xFFA78BFA),
    onTertiary: Color(0xFF2E1065),
    tertiaryContainer: Color(0xFF5B21B6),
    onTertiaryContainer: Color(0xFFEDE9FE),
    error: AppColorsDark.danger,
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFF991B1B),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: AppColorsDark.surface,
    onSurface: AppColorsDark.textPrimary,
    onSurfaceVariant: AppColorsDark.textSecondary,
    outline: AppColorsDark.outline,
    outlineVariant: AppColorsDark.outlineVariant,
    surfaceContainerLowest: Color(0xFF0B0D11),
    surfaceContainerLow: Color(0xFF13151B),
    surfaceContainer: AppColorsDark.surfaceContainer,
    surfaceContainerHigh: AppColorsDark.surfaceContainerHigh,
    surfaceContainerHighest: Color(0xFF2C303B),
    inverseSurface: Color(0xFFE5E7EB),
    onInverseSurface: Color(0xFF1F2937),
    inversePrimary: Color(0xFF4F46E5),
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
  );
}
