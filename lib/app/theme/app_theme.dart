import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

/// Careerly visual identity — editorial career OS.
/// Cobalt = interaction · Coral = signature · Mint = success · Cream/Lavender = warmth/AI.
abstract final class AppColors {
  // —— Brand palette ——
  static const inkNavy = Color(0xFF262724);
  // Legacy interaction token stays readable on pale surfaces.
  static const cobalt = Color(0xFF30332C);
  static const brandYellow = Color(0xFFFFD329);
  static const purple = Color(0xFFA68AF7);
  static const cyan = Color(0xFF06AAD7);
  static const olive = Color(0xFFA9B736);
  static const coral = Color(0xFFFF6B5E);
  static const mint = Color(0xFF08A77B);
  static const cream = Color(0xFFFFF7D6);
  static const lavender = Color(0xFFF0EBFF);
  static const iceBlue = Color(0xFFE7F5EF);
  static const softCoral = Color(0xFFFFF0ED);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFFAFAF8);
  static const primaryText = Color(0xFF262724);
  static const secondaryText = Color(0xFF70726D);
  static const border = Color(0xFFE9EAE5);
  static const warning = Color(0xFFE7A52B);
  static const critical = Color(0xFFE45B5B);

  // —— Legacy aliases (screens/widgets already import these) ——
  static const deepNavy = inkNavy;
  static const actionBlue = cobalt;
  static const success = mint;
  static const canvas = background;
  static const navyMuted = Color(0xFF575B52);
  static const wash = iceBlue;
  static const navyDeep = Color(0xFF1B1D19);
  static const navyLift = Color(0xFF35382F);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const tight = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const section = 40.0;
  static const xxl = 48.0;
  static const hero = 64.0;
  static const page = 24.0;

  /// Keeps page gutters comfortable on phones while preventing very wide
  /// content on tablets and desktop-sized debug surfaces.
  static EdgeInsets pageInsets(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 720 ? 40.0 : (width < 360 ? 16.0 : page);
    return EdgeInsets.symmetric(horizontal: horizontal);
  }
}

abstract final class AppRadii {
  static const small = 10.0;
  static const medium = 16.0;
  static const large = 22.0;
  static const xl = 28.0;
  static const button = 14.0;
  static const card = 24.0;
  static const field = 14.0;
  static const chip = 10.0;
  static const sheet = 28.0;
  static const block = 26.0;
  static const iconWell = 14.0;
  static const iconWellLg = 20.0;
  static const pill = 999.0;
}

abstract final class AppShadows {
  static const nav = [
    BoxShadow(color: Color(0x0C14213D), blurRadius: 18, offset: Offset(0, -6)),
  ];
  static const floating = [
    BoxShadow(color: Color(0x1414213D), blurRadius: 22, offset: Offset(0, 8)),
  ];
}

abstract final class AppSizes {
  static const minTouch = 44.0;
  static const iconWell = 40.0;
  static const iconWellLg = 64.0;
  static const processingWell = 88.0;
}

abstract final class AppMotion {
  static const instant = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 220);
  static const normal = Duration(milliseconds: 240);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 450);
  static const hero = Duration(milliseconds: 640);
  static const score = Duration(milliseconds: 780);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;
}

ThemeData buildCareerlyTheme() {
  // Manrope = neo-grotesk editorial; Inter remains body-adjacent via Manrope scale.
  final base = GoogleFonts.manropeTextTheme();
  final textTheme = base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      height: 1.16,
      letterSpacing: -1.2,
      color: AppColors.primaryText,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.2,
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
      letterSpacing: 0.2,
      color: AppColors.secondaryText,
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: AppColors.secondaryText,
    ),
  );

  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brandYellow,
    onPrimary: AppColors.primaryText,
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
      centerTitle: true,
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
        backgroundColor: AppColors.brandYellow,
        foregroundColor: AppColors.primaryText,
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
      height: 72,
      backgroundColor: AppColors.surface,
      elevation: 0,
      indicatorColor: AppColors.cobalt.withValues(alpha: 0.10),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
      color: AppColors.mint,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sheet),
      ),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}

/// System dark-mode companion for the light editorial theme.
/// The same semantic tokens are retained so screens do not need separate
/// layout code for dark surfaces.
ThemeData buildCareerlyDarkTheme() {
  final light = buildCareerlyTheme();
  final base = GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme);
  final textTheme = base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      height: 1.05,
      letterSpacing: -1.2,
      color: Colors.white,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.08,
      letterSpacing: -0.9,
      color: Colors.white,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 16,
      height: 1.45,
      color: const Color(0xFFF1F4FA),
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 15,
      height: 1.45,
      color: const Color(0xFFB7C0D1),
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontSize: 13,
      height: 1.4,
      color: const Color(0xFFB7C0D1),
    ),
  );
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.cobalt,
    brightness: Brightness.dark,
    surface: const Color(0xFF17223B),
    onSurface: Colors.white,
    error: AppColors.critical,
  );

  return light.copyWith(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF0E1830),
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: light.appBarTheme.copyWith(
      backgroundColor: const Color(0xFF0E1830),
      foregroundColor: Colors.white,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: light.cardTheme.copyWith(
      color: const Color(0xFF17223B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: Color(0xFF2B3855)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF2B3855)),
    inputDecorationTheme: light.inputDecorationTheme.copyWith(
      fillColor: const Color(0xFF17223B),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: Color(0xFF2B3855)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.cobalt, width: 1.5),
      ),
      hintStyle: textTheme.bodyMedium,
      labelStyle: textTheme.bodyMedium,
    ),
    navigationBarTheme: light.navigationBarTheme.copyWith(
      backgroundColor: const Color(0xFF17223B),
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
    ),
  );
}
