import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Careerly visual identity — editorial career OS.
/// Cobalt = interaction · Coral = signature · Mint = success · Cream/Lavender = warmth/AI.
abstract final class AppColors {
  // —— Brand palette ——
  static const inkNavy = Color(0xFF14213D);
  static const cobalt = Color(0xFF315CFF);
  static const coral = Color(0xFFFF6B5E);
  static const mint = Color(0xFF74D9B2);
  static const cream = Color(0xFFFFF8EE);
  static const lavender = Color(0xFFEEEAFE);
  static const iceBlue = Color(0xFFEAF3FF);
  static const softCoral = Color(0xFFFFF0ED);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF6F7FB);
  static const primaryText = Color(0xFF152033);
  static const secondaryText = Color(0xFF667085);
  static const border = Color(0xFFE3E8F0);
  static const warning = Color(0xFFE7A52B);
  static const critical = Color(0xFFE45B5B);

  // —— Legacy aliases (screens/widgets already import these) ——
  static const deepNavy = inkNavy;
  static const actionBlue = cobalt;
  static const success = mint;
  static const canvas = background;
  static const navyMuted = Color(0xFF3A4F6A);
  static const wash = iceBlue;
  static const navyDeep = Color(0xFF0E1830);
  static const navyLift = Color(0xFF1C2F52);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const page = 24.0;
}

abstract final class AppRadii {
  static const button = 14.0;
  static const card = 16.0;
  static const field = 14.0;
  static const chip = 10.0;
  static const sheet = 20.0;
  static const block = 18.0;
  static const iconWell = 14.0;
  static const iconWellLg = 20.0;
  static const pill = 999.0;
}

abstract final class AppSizes {
  static const minTouch = 44.0;
  static const iconWell = 40.0;
  static const iconWellLg = 64.0;
  static const processingWell = 88.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 240);
  static const score = Duration(milliseconds: 900);
}

ThemeData buildCareerlyTheme() {
  // Manrope = neo-grotesk editorial; Inter remains body-adjacent via Manrope scale.
  final base = GoogleFonts.manropeTextTheme();
  final textTheme = base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      height: 1.05,
      letterSpacing: -1.2,
      color: AppColors.primaryText,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.08,
      letterSpacing: -0.9,
      color: AppColors.primaryText,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.12,
      letterSpacing: -0.6,
      color: AppColors.primaryText,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.3,
      color: AppColors.primaryText,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryText,
      letterSpacing: -0.2,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryText,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 16,
      height: 1.45,
      color: AppColors.primaryText,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 15,
      height: 1.45,
      color: AppColors.secondaryText,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontSize: 13,
      height: 1.4,
      color: AppColors.secondaryText,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
      color: AppColors.secondaryText,
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: AppColors.secondaryText,
    ),
  );

  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.cobalt,
    onPrimary: Colors.white,
    secondary: AppColors.inkNavy,
    onSecondary: Colors.white,
    tertiary: AppColors.coral,
    onTertiary: Colors.white,
    error: AppColors.critical,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.primaryText,
    surfaceContainerHighest: AppColors.iceBlue,
    outline: AppColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.primaryText,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.cobalt, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.critical),
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
      labelStyle: textTheme.bodyMedium,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        backgroundColor: AppColors.cobalt,
        foregroundColor: Colors.white,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        side: const BorderSide(color: AppColors.border),
        foregroundColor: AppColors.inkNavy,
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
        foregroundColor: AppColors.cobalt,
        textStyle: textTheme.labelLarge,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: AppColors.surface,
      elevation: 0,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          letterSpacing: 0.4,
          fontSize: 11,
          color: selected ? AppColors.cobalt : AppColors.secondaryText,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.cobalt : AppColors.secondaryText,
          size: 22,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.inkNavy,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.cobalt,
    ),
  );
}
