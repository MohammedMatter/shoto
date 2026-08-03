import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// Builds the two [ThemeData] objects handed to `MaterialApp.router`. These
/// are independent of [AppColors]'s mutable brightness flag on purpose —
/// both `theme` and `darkTheme` are constructed in the same `build()` call,
/// so if they read the same mutable flag, whichever one evaluates last would
/// silently win for every custom widget in the app. Keeping their palettes
/// as fixed literals here (mirroring [AppColors] token-for-token) avoids
/// that entirely; only [AppColors] itself needs to be brightness-aware,
/// since that's what the hand-built widgets actually read from.
abstract class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => _build(
    brightness: Brightness.dark,
    background: AppColors.ink,
    surface: const Color(0xFF212121),
    surfaceVariant: const Color(0xFF292929),
    border: const Color(0xFF303030),
    textPrimary: AppColors.paper,
    textSecondary: const Color(0xFF9E9E9E),
  );

  static ThemeData get lightTheme => _build(
    brightness: Brightness.light,
    background: AppColors.paper,
    surface: const Color(0xFFFFFFFF),
    surfaceVariant: const Color(0xFFF0F0F0),
    border: const Color(0xFFE2E2E2),
    textPrimary: AppColors.ink,
    textSecondary: AppColors.graphite,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: AppColors.primary,
      // Material's ink splash fights the app's own press animations, which
      // scale and dim the whole control instead of painting a ripple inside
      // it. Two competing feedbacks on one tap read as lag.
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onPrimary,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariant,
        outline: border,
        error: AppColors.error,
        onError: Colors.white,
      ),
      // Every slot is filled, including the ones the app never asks for by
      // name. An unfilled entry does not go unused — it falls back to
      // Material's own typography, which means Roboto at Material's sizes,
      // and a Flutter-supplied widget reaching for `titleMedium` or
      // `labelLarge` would quietly render in a family this app does not
      // bundle. One stray control in the wrong typeface is the kind of thing
      // that reads as "off" long before anyone works out why.
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayLarge,
        displaySmall: AppTextStyles.headlineLarge,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleSmall,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.sectionLabel,
        labelSmall: AppTextStyles.overline,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        // Was a hard-coded `#34363D`, a leftover from the old cool-grey
        // ramp that no longer matches any surface in the app.
        backgroundColor: brightness == Brightness.dark
            ? AppColors.surfaceElevated
            : AppColors.ink,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: brightness == Brightness.dark
              ? AppColors.textPrimary
              : AppColors.paper,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: textPrimary),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.25),
        selectionHandleColor: AppColors.primary,
      ),
      iconTheme: IconThemeData(color: textSecondary),
    );
  }
}
