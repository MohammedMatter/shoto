import 'package:flutter/material.dart';
import 'package:shoto/core/localization/app_locales.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/app_theme.dart';

/// The app's real theme, for a widget test that pumps its own `MaterialApp`.
///
/// Passing this is no longer optional. These tests used to call
/// `AppColors.setBrightness(brightness)` and then pump a *bare* `MaterialApp`,
/// because every widget read the palette from a static field and none of them
/// looked at `ThemeData` at all. Now that the palette and the type scale ride
/// on the theme as extensions, a `MaterialApp` without one renders against
/// `AppPalette.dark` no matter what the test asked for — so a light-mode
/// golden would quietly come out dark.
ThemeData testTheme(Brightness brightness) => brightness == Brightness.dark
    ? AppTheme.dark(AppLanguage.english)
    : AppTheme.light(AppLanguage.english);

/// The palette a test needs when it is building its own scaffolding — a
/// backdrop colour, a swatch — outside any widget that has a `BuildContext`.
AppPalette testPalette(Brightness brightness) => AppPalette.of(brightness);

/// The matching type scale, for the same reason.
AppTypography testTypography(Brightness brightness) => AppTypography(
  language: AppLanguage.english,
  palette: AppPalette.of(brightness),
);
