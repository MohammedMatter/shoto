import 'package:flutter/material.dart';
import 'package:shoto/core/localization/app_locales.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// Builds the two [ThemeData] objects handed to `MaterialApp.router`.
///
/// Both palettes are now *carried by* the themes rather than mirrored beside
/// them. [AppPalette] and [AppTypography] are registered as `ThemeData`
/// extensions here, which is what `context.colors` and `context.text` read —
/// so the light theme is built from light tokens and the dark theme from dark
/// ones, and there is no longer a mutable flag that both of them consult.
///
/// That flag is worth remembering, because it failed quietly. `theme:` and
/// `darkTheme:` are both constructed in the same `build()` call, so when the
/// palette was a set of static getters over one brightness field, whichever
/// theme was built second overwrote nothing — they simply both received the
/// *current* mode's accent. It happened to look right because the mode that
/// was current was also the one being displayed. Nothing about that was load
/// bearing on purpose.
abstract class AppTheme {
  AppTheme._();

  static ThemeData light(AppLanguage language) =>
      _build(AppPalette.light, language);

  static ThemeData dark(AppLanguage language) =>
      _build(AppPalette.dark, language);

  static ThemeData _build(AppPalette palette, AppLanguage language) {
    final AppTypography text = AppTypography(
      language: language,
      palette: palette,
    );
    final Brightness brightness = palette.isDark
        ? Brightness.dark
        : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // The two the app's own widgets read. Everything below this line is for
      // Material-supplied widgets, which cannot know about either.
      extensions: <ThemeExtension<dynamic>>[palette, text],
      scaffoldBackgroundColor: palette.background,
      primaryColor: palette.primary,
      // Material's ink splash fights the app's own press animations, which
      // scale and dim the whole control instead of painting a ripple inside
      // it. Two competing feedbacks on one tap read as lag.
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.primary,
        onPrimary: palette.onPrimary,
        secondary: palette.secondary,
        onSecondary: palette.onPrimary,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        surfaceContainerHighest: palette.surfaceVariant,
        outline: palette.border,
        error: palette.error,
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
        displayLarge: text.displayLarge,
        displayMedium: text.displayLarge,
        displaySmall: text.headlineLarge,
        headlineLarge: text.headlineLarge,
        headlineMedium: text.headlineMedium,
        headlineSmall: text.headlineMedium,
        titleLarge: text.titleLarge,
        titleMedium: text.titleSmall,
        titleSmall: text.titleSmall,
        bodyLarge: text.bodyLarge,
        bodyMedium: text.bodyMedium,
        bodySmall: text.bodySmall,
        labelLarge: text.button,
        labelMedium: text.sectionLabel,
        labelSmall: text.overline,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        // Was a hard-coded `#34363D`, a leftover from the old cool-grey
        // ramp that no longer matches any surface in the app.
        backgroundColor: palette.isDark
            ? palette.surfaceElevated
            : AppPalette.ink,
        contentTextStyle: text.bodyMedium.copyWith(
          color: palette.isDark ? palette.textPrimary : AppPalette.paper,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: palette.textPrimary),
        titleTextStyle: text.titleLarge.copyWith(color: palette.textPrimary),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.primary,
        selectionColor: palette.primary.withValues(alpha: 0.25),
        selectionHandleColor: palette.primary,
      ),
      iconTheme: IconThemeData(color: palette.textSecondary),
    );
  }
}
