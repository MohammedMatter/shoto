import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shoto/core/localization/l10n.dart';

/// The accent colours a subscriber may choose between.
///
/// **A tint is a hue, not a hex.** That distinction is the whole file, and it
/// is the reason this feature does not undo `app_colors.dart`.
///
/// Every hue in the palette is *solved* against a luminance target rather than
/// picked — 0.085 in light mode, 0.330 in dark — and that single constraint is
/// what makes five hues read as one family, what lets [AppPalette.onPrimary]
/// serve as the foreground on all of them, and what stops the accent hovering
/// above a dark screen the way an earlier teal did at 0.455. A colour picker
/// that shipped raw hexes would hand the user a switch labelled "break all of
/// that": a saturated yellow accent is luminance 0.6, so the near-white text
/// the app paints on filled controls would measure about 1.4:1 on it, and
/// every filled control in the app would be a lamp in dark mode.
///
/// So the user picks *where on the colour wheel*, and the app keeps the part
/// that was never a matter of taste. Each tint below is a hue and a pair of
/// saturations; the two colours it becomes are solved at runtime to the same
/// two luminance targets the shipped accent already hits.
///
/// ## Why the solver can be trusted
///
/// It reproduces two values that were arrived at independently, by hand, over
/// several revisions:
///
/// * [teal] at hue 178°/49% solves to `#1F5A59`. The shipped accent is
///   `#1F5B59` — one step of green apart.
/// * [slate] at 216°/43% solves to `#335381`. The palette's own `secondary` is
///   `#345381`, and `app_colors.dart` documents it as "hsl(216, 43%, 35%)".
///
/// Neither was fitted to the other. The solver was written from the WCAG
/// definition of relative luminance and pointed at the targets; those two fell
/// out of it. A third check lives in `app_tint_test.dart`, which asserts every
/// tint in this list clears AA as text on every surface it can land on, in
/// both modes — the test that would have caught the yellow above.
///
/// ## Saturation is the one thing left to choose
///
/// Luminance is fixed, so chroma is the only dial, and it is set per hue
/// rather than shared. The reason is physical: the eye's sensitivity is not
/// flat across the wheel, so at a *fixed* luminance a green needs far less
/// saturation to read as green than a yellow needs to read as yellow. At the
/// teal's own 49%, [amber] solves to `#634F22` — a bronze nobody would call
/// amber. At 90% it is `#684F05`, which is as close to amber as luminance
/// 0.085 permits, and the fact that it is still dark is not a bug: a light
/// amber cannot carry near-white text, and this app paints near-white text on
/// its accent.
///
/// ### The saturations were once set by eye, and they were set too low
///
/// **Every tint here used to spend about half the chroma available to it**, and
/// the whole picker read muddy because of it — the complaint was that the
/// colours were not pretty, and the cause was measurable rather than a matter
/// of taste. `slate` reached chroma 0.31 where its hue allows 0.73. `violet` in
/// dark mode reached 0.28 of a possible 0.60. Sixteen colours each holding back
/// half their chroma are sixteen colours that all look like the same slightly
/// dirty grey-of-a-hue, which is exactly what a picker must not be.
///
/// The fix is free, and that is the point worth writing down: **contrast is
/// guarded by luminance, and saturation does not touch it.** The solver holds
/// luminance fixed by construction, so raising a tint's saturation moves the
/// lightness it lands on and leaves every ratio in `app_tint_test.dart` exactly
/// where it was. There was never a reason for the restraint.
///
/// So the saturations are now *solved* too, against a chroma target rather than
/// chosen: **0.42 in light, 0.58 in dark**, per hue, capped at 90% saturation
/// so nothing lands on a pure hue. That is the same move the luminance targets
/// make, applied to the other axis — and it does the same job, which is to make
/// twenty-one colours read as one family rather than as twenty-one decisions
/// taken on twenty-one different days. A hue that cannot reach the target sits
/// at the cap and stays where physics leaves it: at luminance 0.085 the yellows
/// and greens top out around 0.35 whatever is asked of them.
///
/// **[teal] and [slate] are deliberately left out of it**, and they are the two
/// that look quietest as a result. Both are pinned by test to reproduce colours
/// the palette already ships — teal *is* the app's accent and slate *is* its
/// secondary — so re-tuning them here would either break that agreement or
/// silently restyle the whole app. The default being more restrained than the
/// choices around it is the right way round in any case.
///
/// ## The semantic hues, and an honest note about them
///
/// `app_colors.dart` argues that "an accent must not share a family with
/// anything that *means* something", and rejected a green default on exactly
/// that ground — [AppPalette.success] is a green. That argument was about the
/// colour the app chooses for everybody. It cannot survive contact with a
/// picker: reserving a 30° margin around success (145°), warning (43°) and
/// alert (6°) removes red, orange, yellow and green from the wheel, and a
/// colour picker offering only blues and purples is not one.
///
/// So [moss], [amber] and [rose] ship, sitting near a semantic each, and the
/// reason that is survivable is that no semantic colour in this app is ever
/// the only thing saying what it means. A delete row says "Delete" beside the
/// red; a finished intent is a *tick* on the green. Colour is the second
/// signal in every one of those places, which is what makes it safe to spend
/// the first one on the user.
@immutable
class AppTint {
  /// Persisted, so it must never change once shipped — the stored string is
  /// what a returning user's accent is read back from.
  final String id;

  /// Degrees on the colour wheel, 0–360.
  final double hue;

  /// Saturation in light mode.
  ///
  /// **It used to be higher than the dark value on every tint, and now it is
  /// usually lower.** That reads like a reversal and is the same rule applied
  /// properly. The reason given for the old arrangement was `app_colors.dart`'s
  /// point about the shipped accent — chroma reads stronger as a colour gets
  /// lighter, so holding the *apparent* colour equal across two very different
  /// lightnesses means dropping saturation on the lighter one. True, and it is
  /// about **apparent chroma**, not about the saturation number.
  ///
  /// Saturation is not chroma. At the light target the accent sits near
  /// lightness 0.25, where `chroma = (1 - |2L - 1|) x saturation` throws away
  /// half of whatever is asked for; at the dark target it sits near 0.5, where
  /// almost none is lost. So the *same* apparent colour needs a far higher
  /// saturation number in light than in dark, and the two now differ in
  /// whichever direction each hue's arithmetic demands. What is held equal is
  /// the thing that was always meant to be: the chroma the eye receives.
  final double saturationLight;

  final double saturationDark;

  const AppTint._({
    required this.id,
    required this.hue,
    required this.saturationLight,
    required this.saturationDark,
  });

  // ------------------------------------------------------------- the targets
  //
  // Read off the shipped accent rather than invented, which is what makes a
  // tinted palette the same object as the untinted one with the hue moved.

  /// `#1F5B59`, the light accent, measures 0.0849.
  static const double _accentLight = 0.0849;

  /// `#4CA9A6`, the dark accent, measures 0.3266 — documented in
  /// `app_colors.dart` as "stops at 0.332, the lowest value that still clears
  /// 4.5:1 as text on surfaceVariant".
  static const double _accentDark = 0.3266;

  /// `#1A4E4C`, the light `primaryVariant`, measures 0.0619.
  static const double _variantLight = 0.0619;

  /// `#449694`, the dark `primaryVariant`, measures 0.2517.
  static const double _variantDark = 0.2517;

  // ----------------------------------------------------------------- the list
  //
  // Twenty-one, spread around the wheel rather than clustered, because two
  // tints a user cannot tell apart in the picker are one tint and a wasted tap.
  // Their hues are 8, 18, 24, 45, 62, 80, 105, 130, 155, 178, 195, 205, 216,
  // 222, 235, 262, 288, 302, 318, 334 and 350.
  //
  // **This was sixteen, and the argument against going past it has since been
  // answered rather than ignored.** The note used to say that twenty is where a
  // set of choices becomes a colour chart, because 18° between neighbours is
  // under the width of the swatch showing them and two adjacent chips start
  // reading as a printing error. That was true *of the old saturations*: at
  // chroma 0.25 two hues 18° apart genuinely are the same colour twice. Once
  // every tint is solved to chroma 0.42, the same 18° is a visible step, so the
  // wheel can carry more of them. Crowding is a chroma problem wearing a hue
  // problem's clothes.
  //
  // The five that were added are not evenly sprinkled, for that reason: they go
  // where the eye has room. [sky], [orchid] and [fuchsia] fill real gaps in the
  // blues and pinks, which are the bands with the most chroma to spend. Nothing
  // new was added between 45 and 178 — the yellows and greens cannot exceed
  // chroma 0.35 at this luminance, so subdividing them would produce exactly
  // the printing error the old note warned about. [clay] and [graphite] are
  // separated from their neighbours by *saturation* instead of hue, which is
  // the second axis this file has always had and never used.
  //
  // **Twenty-one rather than eight because adding one costs three numbers.**
  // That is the return on solving instead of picking: a new accent is a hue and
  // two saturations, and the luminance, the contrast on four surfaces and the
  // foreground that reads on it all follow without a decision. A file of raw
  // hexes would have needed twenty-one colours hand-checked on four surfaces in
  // two modes — eighty-four judgement calls, each of them the sort that gets
  // made once in light mode and never revisited.

  /// The app's own accent, and the default. Solving it here rather than
  /// pointing at the shipped constant is deliberate: it means the default is
  /// produced by the same machinery as every other option, so there is no
  /// privileged path that could drift from the rest.
  static const AppTint teal = AppTint._(
    id: 'teal',
    hue: 178,
    saturationLight: 0.49,
    saturationDark: 0.38,
  );

  /// The palette's own `secondary`, promoted to a choice.
  static const AppTint slate = AppTint._(
    id: 'slate',
    hue: 216,
    saturationLight: 0.43,
    saturationDark: 0.32,
  );

  static const AppTint indigo = AppTint._(
    id: 'indigo',
    hue: 262,
    saturationLight: 0.48,
    saturationDark: 0.90,
  );

  static const AppTint plum = AppTint._(
    id: 'plum',
    hue: 318,
    saturationLight: 0.59,
    saturationDark: 0.89,
  );

  static const AppTint rose = AppTint._(
    id: 'rose',
    hue: 350,
    saturationLight: 0.56,
    saturationDark: 0.90,
  );

  static const AppTint ember = AppTint._(
    id: 'ember',
    hue: 24,
    saturationLight: 0.71,
    saturationDark: 0.69,
  );

  static const AppTint amber = AppTint._(
    id: 'amber',
    hue: 45,
    saturationLight: 0.90,
    saturationDark: 0.65,
  );

  static const AppTint moss = AppTint._(
    id: 'moss',
    hue: 130,
    saturationLight: 0.90,
    saturationDark: 0.70,
  );

  static const AppTint olive = AppTint._(
    id: 'olive',
    hue: 80,
    saturationLight: 0.90,
    saturationDark: 0.77,
  );

  static const AppTint cyan = AppTint._(
    id: 'cyan',
    hue: 195,
    saturationLight: 0.86,
    saturationDark: 0.59,
  );

  static const AppTint denim = AppTint._(
    id: 'denim',
    hue: 235,
    saturationLight: 0.46,
    saturationDark: 0.90,
  );

  static const AppTint violet = AppTint._(
    id: 'violet',
    hue: 288,
    saturationLight: 0.56,
    saturationDark: 0.90,
  );

  /// The deepest red the wheel allows here.
  ///
  /// Sits two degrees off [AppPalette.alert] and is the sharpest case of the
  /// semantic-collision note above — which is survivable for the reason given
  /// there and *only* for that reason: a destructive control in this app is
  /// never red alone, it is red beside the word "Delete".
  static const AppTint garnet = AppTint._(
    id: 'garnet',
    hue: 8,
    saturationLight: 0.59,
    saturationDark: 0.88,
  );

  static const AppTint brass = AppTint._(
    id: 'brass',
    hue: 62,
    saturationLight: 0.90,
    saturationDark: 0.85,
  );

  static const AppTint fern = AppTint._(
    id: 'fern',
    hue: 105,
    saturationLight: 0.90,
    saturationDark: 0.72,
  );

  static const AppTint jade = AppTint._(
    id: 'jade',
    hue: 155,
    saturationLight: 0.90,
    saturationDark: 0.72,
  );

  /// **A brown, and the one tint that is honest about the luminance target.**
  ///
  /// Every warm hue solves dark here — that is the whole subject of the note
  /// above — so a low-saturation orange arrives as a terracotta whatever it is
  /// called. Naming one of them for what it actually is turns the constraint
  /// into a choice: [ember] is the rust that wants to be an orange, and this is
  /// a brown that wants to be a brown.
  static const AppTint clay = AppTint._(
    id: 'clay',
    hue: 18,
    saturationLight: 0.32,
    saturationDark: 0.30,
  );

  /// The pink the picker did not have. [plum] is a magenta and [rose] is a red;
  /// the gap between them at 334 is where somebody looking for "pink" was
  /// finding nothing.
  static const AppTint fuchsia = AppTint._(
    id: 'fuchsia',
    hue: 334,
    saturationLight: 0.57,
    saturationDark: 0.90,
  );

  static const AppTint orchid = AppTint._(
    id: 'orchid',
    hue: 302,
    saturationLight: 0.62,
    saturationDark: 0.84,
  );

  /// The blue between [cyan]'s petrol and [slate]'s steel, and the one most
  /// people mean when they say blue.
  static const AppTint sky = AppTint._(
    id: 'sky',
    hue: 205,
    saturationLight: 0.70,
    saturationDark: 0.70,
  );

  /// **Nearly no hue at all, on purpose.**
  ///
  /// 9% saturation is below the point where anybody would name a colour, which
  /// makes this the one option that answers "I do not want an accent". It is
  /// still a tint rather than a special case — solved to the same luminance,
  /// carrying the same foreground — so every filled control in the app goes
  /// quiet together and nothing downstream has to know that this one is grey.
  static const AppTint graphite = AppTint._(
    id: 'graphite',
    hue: 222,
    saturationLight: 0.09,
    saturationDark: 0.09,
  );

  /// **The twelve on the page**, and the reason there is a "more" behind them.
  ///
  /// Twenty-one swatches under a heading is a colour chart; a person opening
  /// Settings to make the app theirs wants a spread of good answers, not an
  /// inventory. So a grid is laid out where the decision is being made and the
  /// rest are one tap away — which is also the only honest way to add a
  /// twenty-second later without the page growing a row every time.
  ///
  /// **This was six, then nine, and the six were the real mistake.** They were
  /// all cool or dark — teal, slate, indigo, plum, rose, amber — which is a
  /// defensible spread on paper and the wrong impression in practice. The one
  /// question a colour picker has to answer on sight is "is my colour in
  /// here?", and somebody who does not find theirs concludes it does not
  /// exist; nobody taps "more colours" looking for a colour they have already
  /// been shown the app does not have.
  ///
  /// Twelve, three across, four rows, laid out as a walk: blue-green along the
  /// top, violet and pink through the middle, red to gold below it, and the
  /// green and the grey last. So the grid reads as a spectrum rather than as a
  /// bag of samples, and every family anybody would go looking for is on screen
  /// without opening anything.
  static const List<AppTint> front = <AppTint>[
    teal,
    sky,
    slate,
    indigo,
    violet,
    plum,
    fuchsia,
    rose,
    ember,
    amber,
    moss,
    graphite,
  ];

  /// Every tint, in wheel order starting from the default.
  ///
  /// Wheel order rather than the [front] twelve first: the full sheet is where
  /// somebody goes to *compare*, and a spectrum compares — laid out four
  /// across, each row is a quarter of the wheel and the eye can walk it. Teal
  /// leads because it is the one to return to.
  ///
  /// [graphite] sits at its own hue (222) rather than being exiled to the end,
  /// even though it is barely a hue at all. Somewhere in the blues is where a
  /// near-neutral steel grey belongs to the eye, and a grey chip parked after
  /// the spectrum reads as an afterthought rather than as an option.
  static const List<AppTint> all = <AppTint>[
    teal,
    jade,
    moss,
    fern,
    olive,
    brass,
    amber,
    ember,
    clay,
    garnet,
    rose,
    fuchsia,
    plum,
    orchid,
    violet,
    indigo,
    denim,
    graphite,
    slate,
    sky,
    cyan,
  ];

  /// What an unset or unrecognised preference resolves to.
  ///
  /// Unrecognised matters as much as unset: an id that was dropped from [all]
  /// in a later version is still sitting in somebody's preferences, and the
  /// app has to open in *a* colour rather than throw on the first frame.
  static const AppTint fallback = teal;

  static AppTint byId(String? id) =>
      all.firstWhere((AppTint tint) => tint.id == id, orElse: () => fallback);

  /// Translated, like every other name the user reads.
  ///
  /// Takes a context rather than storing a string for the reason
  /// `GridDensityController.labelFor` records: a const list of English
  /// literals is how a picker ends up speaking English in all eight languages.
  String label(BuildContext context) => switch (id) {
    'teal' => context.l10n.tintTeal,
    'cyan' => context.l10n.tintCyan,
    'slate' => context.l10n.tintSlate,
    'denim' => context.l10n.tintDenim,
    'indigo' => context.l10n.tintIndigo,
    'violet' => context.l10n.tintViolet,
    'orchid' => context.l10n.tintOrchid,
    'fuchsia' => context.l10n.tintFuchsia,
    'sky' => context.l10n.tintSky,
    'clay' => context.l10n.tintClay,
    'graphite' => context.l10n.tintGraphite,
    'plum' => context.l10n.tintPlum,
    'rose' => context.l10n.tintRose,
    'garnet' => context.l10n.tintGarnet,
    'ember' => context.l10n.tintEmber,
    'amber' => context.l10n.tintAmber,
    'brass' => context.l10n.tintBrass,
    'olive' => context.l10n.tintOlive,
    'fern' => context.l10n.tintFern,
    'jade' => context.l10n.tintJade,
    _ => context.l10n.tintMoss,
  };

  // -------------------------------------------------------------- the colours

  /// The accent for [isDark], solved to the target above.
  Color accent({required bool isDark}) => _solved(
    saturation: isDark ? saturationDark : saturationLight,
    target: isDark ? _accentDark : _accentLight,
  );

  /// The pressed/secondary step of the accent — `primaryVariant`.
  ///
  /// A *lower luminance target* rather than a blend with black, so it holds
  /// its hue at the same chroma instead of going grey. The two targets are
  /// the shipped variant's own measurements, which puts it at roughly 73% of
  /// the accent's light luminance and 77% of its dark one.
  Color variant({required bool isDark}) => _solved(
    saturation: isDark ? saturationDark : saturationLight,
    target: isDark ? _variantDark : _variantLight,
  );

  /// Memoised across the app's lifetime.
  ///
  /// Eight tints times two colours times two modes is thirty-two possible
  /// answers, each of them a fixed point of a deterministic function — so they
  /// are worth computing once. Without this the picker would re-run sixteen
  /// binary searches on every frame it is rebuilt, which is every frame of the
  /// scroll it lives in.
  static final Map<String, Color> _memo = <String, Color>{};

  Color _solved({required double saturation, required double target}) =>
      _memo.putIfAbsent(
        '$id:$saturation:$target',
        () => _solveForLuminance(
          hue: hue,
          saturation: saturation,
          target: target,
        ),
      );

  /// Finds the lightness at which `hsl(hue, saturation, l)` has exactly
  /// [target] relative luminance.
  ///
  /// A binary search rather than algebra: luminance is a sum of three
  /// piecewise-defined powers of the channels, and the channels are a
  /// piecewise function of lightness, so inverting it in closed form means
  /// handling six cases to arrive somewhere less readable than this. It is
  /// monotonic in lightness at fixed hue and saturation, which is the only
  /// property a bisection needs.
  ///
  /// Forty iterations halves the interval far past the point where the result
  /// still changes after being rounded to eight bits per channel — the answer
  /// is exact for every input, and the loop is bounded rather than
  /// convergence-tested so it cannot spin.
  static Color _solveForLuminance({
    required double hue,
    required double saturation,
    required double target,
  }) {
    double low = 0;
    double high = 1;
    for (int i = 0; i < 40; i++) {
      final double mid = (low + high) / 2;
      if (_luminanceOf(_hslToColor(hue, saturation, mid)) < target) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return _hslToColor(hue, saturation, (low + high) / 2);
  }

  /// **Not** `HSLColor.fromAHSL(...).toColor()`, which would do exactly this.
  ///
  /// Written out because the search above calls it forty times per solve and
  /// the Flutter version allocates an `HSLColor` for each of them. The maths
  /// is the standard conversion and is verified against `HSLColor` in
  /// `app_tint_test.dart`, so the shortcut cannot quietly diverge from the
  /// framework's own answer.
  static Color _hslToColor(double hue, double saturation, double lightness) {
    final double chroma = (1 - (2 * lightness - 1).abs()) * saturation;
    final double sector = hue / 60;
    final double second = chroma * (1 - ((sector % 2) - 1).abs());
    final double offset = lightness - chroma / 2;

    final (double r, double g, double b) = switch (sector) {
      < 1 => (chroma, second, 0.0),
      < 2 => (second, chroma, 0.0),
      < 3 => (0.0, chroma, second),
      < 4 => (0.0, second, chroma),
      < 5 => (second, 0.0, chroma),
      _ => (chroma, 0.0, second),
    };

    return Color.fromARGB(
      255,
      ((r + offset) * 255).round().clamp(0, 255),
      ((g + offset) * 255).round().clamp(0, 255),
      ((b + offset) * 255).round().clamp(0, 255),
    );
  }

  /// WCAG relative luminance.
  ///
  /// Flutter's own `Color.computeLuminance` is the same formula and is used in
  /// the test to check this one. It is not used *here* because the search
  /// needs it forty times per solve on a colour it has just built, and this
  /// form skips the channel-object round trip.
  static double _luminanceOf(Color color) =>
      0.2126 * _toLinear((color.r * 255).roundToDouble() / 255) +
      0.7152 * _toLinear((color.g * 255).roundToDouble() / 255) +
      0.0722 * _toLinear((color.b * 255).roundToDouble() / 255);

  static double _toLinear(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

  @override
  bool operator ==(Object other) => other is AppTint && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
