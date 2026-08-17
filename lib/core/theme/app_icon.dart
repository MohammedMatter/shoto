import 'package:flutter/material.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_brand.dart';
import 'package:shoto/core/theme/app_tint.dart';

/// The launcher icons a subscriber may choose between.
///
/// **Six fixed marks, not a mark that changes.** `app_brand.dart` says the
/// mark's colours are deliberately not mode-aware, because "a brand mark that
/// changes with the system theme is not one mark, it is two, and neither of
/// them is the one on the store listing". This does not contradict that: every
/// icon here is fixed, the geometry is identical across all six, and [ink] —
/// the one on the store listing — is the default and stays the default.
///
/// Only the slab moves. The tray, the three cards and the clipped corner are
/// the same drawing in every variant, which is what makes six icons read as
/// one product with a colourway rather than as six logos.
///
/// ## The colours are the accents, not new ones
///
/// Each slab is an [AppTint] solved at its **light** target — the deep end,
/// luminance 0.085. That is not a stylistic preference, it is the only band
/// that works: the mark's cards are [AppBrand.paper], so the slab has to be
/// dark enough to carry near-white on it. The default ink is 0.006 and these
/// land at 0.085, which is still deep enough for paper to clear 7:1 on every
/// one of them — the same relationship the original icon has, in a hue.
///
/// Reusing the accent hues rather than inventing icon colours means somebody
/// running the app in plum can put a plum icon on their home screen and the
/// two are the same colour, because they are literally the same solve.
@immutable
class AppIcon {
  /// Persisted, and the suffix of every resource this variant owns:
  /// `ic_launcher_<id>`, `ic_launcher_background_<id>`, and the
  /// `<activity-alias>` named `.MainActivity<Id>`. Changing one is a rename
  /// across four files and a lost icon for anyone who had chosen it.
  final String id;

  /// Null for [ink], which is the mark's own colour rather than an accent.
  final AppTint? tint;

  const AppIcon._({required this.id, this.tint});

  /// The mark as it ships: paper on ink.
  static const AppIcon ink = AppIcon._(id: 'ink');

  static const AppIcon teal = AppIcon._(id: 'teal', tint: AppTint.teal);
  static const AppIcon indigo = AppIcon._(id: 'indigo', tint: AppTint.indigo);
  static const AppIcon plum = AppIcon._(id: 'plum', tint: AppTint.plum);
  static const AppIcon ember = AppIcon._(id: 'ember', tint: AppTint.ember);
  static const AppIcon moss = AppIcon._(id: 'moss', tint: AppTint.moss);

  /// Six, and the hues are 178°, 262°, 318°, 24° and 130° apart from each
  /// other — deliberately the widest spread available, because these are
  /// judged at 48dp among thirty other icons on a home screen rather than side
  /// by side in a picker.
  static const List<AppIcon> all = <AppIcon>[
    ink,
    teal,
    indigo,
    plum,
    ember,
    moss,
  ];

  static const AppIcon fallback = ink;

  static AppIcon byId(String? id) =>
      all.firstWhere((AppIcon icon) => icon.id == id, orElse: () => fallback);

  /// The slab this variant paints.
  Color get slab => tint?.accent(isDark: false) ?? AppBrand.ink;

  /// The Android component this variant is served by.
  ///
  /// [ink] is `MainActivity` itself rather than an alias — there has to be one
  /// component that is always installed and enabled by default, or a fresh
  /// install would have no launcher entry at all. Everything else is an alias
  /// that ships disabled.
  String get component =>
      this == ink ? 'com.shoto.app.MainActivity' : 'com.shoto.app.Icon$_suffix';

  String get _suffix => id[0].toUpperCase() + id.substring(1);

  String label(BuildContext context) => switch (id) {
    'teal' => context.l10n.tintTeal,
    'indigo' => context.l10n.tintIndigo,
    'plum' => context.l10n.tintPlum,
    'ember' => context.l10n.tintEmber,
    'moss' => context.l10n.tintMoss,
    _ => context.l10n.appIconDefault,
  };

  @override
  bool operator ==(Object other) => other is AppIcon && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
