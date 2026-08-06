import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/app_locales.dart';
import 'package:shoto/core/theme/app_colors.dart';

/// Typography for the whole app.
///
/// Three families, each with a job: **Archivo** for screen titles, **IBM Plex
/// Sans** for everything else, **IBM Plex Mono** for strings read one
/// character at a time. A display face earns its keep by being rare.
///
/// Four conventions run through the scale:
///
/// * **Weight lives on the `wght` axis, not on `fontWeight`.** See
///   [_variable] — this is the one genuinely surprising thing in the file.
/// * **Nothing is heavier than [semiBold].** The scale used to run to w800.
///   Weight is the crudest way to signal hierarchy and the first one to make
///   a screen feel loud; size, colour and spacing do it without shouting.
/// * **Tracking tightens as size grows.** Headlines at default tracking look
///   loose and unresolved; body text at negative tracking gets hard to read.
///   Each step is tuned instead of inheriting one global value.
/// * **Line height is always explicit.** Left to the font's own default,
///   vertical rhythm drifts between screens and nothing aligns.
///
/// ---
///
/// Read through `context.text`, for the same reason [AppPalette] is read
/// through `context.colors`: this was a set of static getters over a mutable
/// `_language` field, and a static read cannot tell a `const` subtree that
/// anything changed. Both of the two things that vary — the palette that
/// colours a style and the script that sets its line height — now arrive as
/// [ThemeData] extensions, so a widget depends on them by reading them.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({required this.language, required this.palette});

  /// Whose line heights are in force.
  ///
  /// Scripts differ in how much vertical room they need for the same point
  /// size. Nastaliq is the extreme case — its words step downward as they are
  /// written, so lines set at Latin spacing overlap.
  final AppLanguage language;

  /// The palette a style takes its default colour from.
  ///
  /// Held rather than looked up, so a `TextStyle` from this scale is complete
  /// on its own and a call site never has to remember to colour it.
  final AppPalette palette;

  /// The bundled families declared in pubspec.yaml.
  ///
  /// Deliberately not `GoogleFonts.*`: that fetches the typeface over the
  /// network on first use, so opening the app without a connection threw an
  /// unhandled exception and nothing rendered. A font is not optional
  /// content — it ships with the binary.
  ///
  /// Body and UI. Everything that is not a screen title.
  static const String fontFamily = 'IBMPlexSans';

  /// Screen titles only, and only ever one per screen.
  ///
  /// Used on every heading it stops being a voice and becomes another size in
  /// the scale — which is the state the app was in when one family did all
  /// the work.
  static const String displayFamily = 'Archivo';

  /// Strings read one character at a time: card numbers, IBANs, codes,
  /// dimensions, byte counts, counters that tick.
  ///
  /// The only **static** family of the three — two real files, 400 and 600.
  static const String monoFamily = 'IBMPlexMono';

  /// The app's entire weight vocabulary.
  ///
  /// Three steps, and [semiBold] is the ceiling. Anything heavier on a screen
  /// this dense stops reading as emphasis and starts reading as noise.
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;

  double _line(double height) => height * language.lineHeightScale;

  /// Builds a style on one of the two **variable** families.
  ///
  /// Weight is carried by [TextStyle.fontVariations] — the `wght` axis — and
  /// deliberately *not* by `fontWeight`, which is left unset. The reason is
  /// worth writing down, because the obvious code does the wrong thing
  /// silently:
  ///
  /// Archivo and IBM Plex Sans each ship as a single variable file registered
  /// at one weight. `fontWeight` does not select a weight from inside that
  /// file — it only picks *which registered file* to use. Ask for a weight no
  /// registered file has and the engine matches the one file there is and
  /// then thickens the outlines itself. That synthetic bold is a blur, not a
  /// typeface, and it is what made every title in the app read as smeared and
  /// over-dark. Meanwhile the real weights — Archivo carries 100–900 — went
  /// unused, and w500 and w800 rendered identically.
  ///
  /// Archivo makes it worse than a no-op: its variable default is `wght=600`,
  /// so every title was already semibold *before* being emboldened again.
  ///
  /// Leaving `fontWeight` unset keeps the file match exact for the primary
  /// family and for every fallback in [AppLanguage.fontFallbacks], which are
  /// registered the same way. The axis then applies to whichever of them
  /// actually renders the glyph, so Arabic and Devanagari get their true
  /// weights too, clamped to each face's own range.
  ///
  /// Every style carries the *full* fallback list, not just the active
  /// language's font. The app's language says nothing about what is on
  /// screen: folder names, rule names and the text read out of screenshots
  /// are all the user's own, in whatever language they wrote them. A
  /// French-language app showing an Arabic folder name must still render it.
  TextStyle _variable({
    required String family,
    required double size,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: AppLanguage.fontFallbacks,
      color: color ?? palette.textPrimary,
      fontSize: size,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      height: _line(height),
      letterSpacing: letterSpacing,
    );
  }

  TextStyle _sans({
    required double size,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
    Color? color,
  }) => _variable(
    family: fontFamily,
    size: size,
    weight: weight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );

  TextStyle _display({
    required double size,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
  }) => _variable(
    family: displayFamily,
    size: size,
    weight: weight,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// The largest thing in the app, and there is exactly one of it: the count
  /// of unfiled screenshots on Home.
  ///
  /// A display face earns its keep by being rare, and it earns it twice at a
  /// size nothing else comes near. This is what replaced the filled accent
  /// card that used to hold that number — a figure set this large does the
  /// job of drawing the eye without a coloured slab under it, which is the
  /// trade the whole screen is built on.
  ///
  /// It does not need to be as large as it was to do that job, and at a real
  /// semibold rather than a synthetic extra-bold it holds the eye on shape
  /// instead of on sheer mass.
  TextStyle get displayHero => _display(
    size: 44.sp,
    weight: semiBold,
    height: 1.04,
    // Negative tracking, but nothing like the -3 this used to carry. At that
    // setting the digits collided; the aim is for them to sit together as one
    // shape, not to overlap.
    letterSpacing: -1.4,
  );

  TextStyle get displayLarge => _display(
    size: 28.sp,
    weight: semiBold,
    height: 1.18,
    letterSpacing: -0.6,
  );

  TextStyle get headlineLarge => _display(
    size: 23.sp,
    weight: semiBold,
    height: 1.25,
    letterSpacing: -0.4,
  );

  TextStyle get headlineMedium =>
      _display(size: 19.sp, weight: semiBold, height: 1.3, letterSpacing: -0.2);

  TextStyle get titleLarge =>
      _sans(size: 16.sp, weight: semiBold, height: 1.35, letterSpacing: -0.1);

  TextStyle get titleSmall =>
      _sans(size: 14.sp, weight: semiBold, height: 1.35);

  /// Quiet section markers, in sentence case.
  ///
  /// [overline] is still here for anywhere that genuinely wants small caps,
  /// but Home no longer shouts `RECENT` and `WHAT SHOTO CAN DO` at itself.
  /// All-caps everywhere is a tell: it is what a layout reaches for when the
  /// hierarchy is not doing the work.
  TextStyle get sectionLabel => _sans(
    size: 12.sp,
    weight: medium,
    height: 1.35,
    color: palette.textSecondary,
  );

  /// Body copy sits at [regular]. It was w500 — a half-step of extra weight
  /// applied to every paragraph in the app, which is the kind of thing that
  /// reads as "heavy" without anything on screen looking obviously wrong.
  TextStyle get bodyLarge => _sans(size: 14.5.sp, weight: regular, height: 1.5);

  TextStyle get bodyMedium => _sans(
    size: 13.sp,
    weight: regular,
    height: 1.55,
    color: palette.textSecondary,
  );

  TextStyle get bodySmall => _sans(
    size: 12.sp,
    weight: regular,
    height: 1.5,
    color: palette.textSecondary,
  );

  TextStyle get button => _sans(size: 14.5.sp, weight: medium, height: 1.2);

  /// The line under a label: a row's description, a chip's count, a caveat.
  ///
  /// **[AppPalette.textSecondary], not [AppPalette.textDisabled]**, and the
  /// difference is not a shade — it is a measurement. At 11.5sp this is small
  /// text, which WCAG asks to clear 4.5:1, and `textDisabled` clears **3.0:1**
  /// on a card and **2.3:1** in light mode. Every description in Settings, in
  /// the safe-share findings and on the Home tools was failing, which is most
  /// of why those screens read as washed out: the sentence that explains what
  /// a row *does* was whispering.
  ///
  /// It was also the wrong word. The line under "Find duplicates" is not
  /// disabled; nothing about it is unavailable. `textDisabled` belongs to
  /// controls that cannot be used — see [SettingsNavTile]'s tint when it has
  /// no `onTap` — and borrowing it for ordinary prose made the app quieter
  /// than it meant to be.
  TextStyle get caption => _sans(
    size: 11.5.sp,
    weight: regular,
    height: 1.45,
    color: palette.textSecondary,
  );

  /// Small section markers. The tracking is what keeps small text from
  /// reading as a smudge.
  ///
  /// Same contrast correction as [caption], and it matters more here: a
  /// section heading is the thing a user scans to find where they are, and
  /// at 10.5sp it was the least legible text in the app.
  TextStyle get overline => _sans(
    size: 10.5.sp,
    weight: medium,
    height: 1.35,
    letterSpacing: 0.9,
    color: palette.textSecondary,
  );

  /// Tabular by default — a counter that shifts sideways as it counts is the
  /// kind of small wrongness people feel without being able to name.
  ///
  /// Unlike the two families above this one is static, so its weight comes
  /// from `fontWeight` in the ordinary way and the `wght` axis does not
  /// apply. Both weights it is asked for, [regular] and [semiBold], are real
  /// files — see pubspec.yaml — so nothing is synthesised here either.
  TextStyle get mono => TextStyle(
    fontFamily: monoFamily,
    fontFamilyFallback: AppLanguage.fontFallbacks,
    color: palette.textPrimary,
    fontWeight: regular,
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: 0,
  );

  /// A machine string set inline at body size — an IBAN, a verification code,
  /// the sort of thing that is copied rather than read.
  ///
  /// Exists so those call sites stop reaching for the platform's generic
  /// `'monospace'`, which is a different typeface on every device and none of
  /// them this one.
  TextStyle get monoBody =>
      mono.copyWith(fontSize: 14.5.sp, height: _line(1.5));

  /// Counts and figures that must not shift while they change — with
  /// proportional digits a live number visibly jitters as it updates.
  TextStyle get numeric => mono.copyWith(
    fontSize: 21.sp,
    fontWeight: semiBold,
    height: _line(1.15),
    letterSpacing: -0.3,
  );

  @override
  AppTypography copyWith({AppLanguage? language, AppPalette? palette}) =>
      AppTypography(
        language: language ?? this.language,
        palette: palette ?? this.palette,
      );

  /// Same reasoning as [AppPalette.lerp]: the theme swaps rather than
  /// animates, so there is no intermediate state to describe. Interpolating a
  /// *language* would be meaningless in any case.
  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppTypography &&
          other.language == language &&
          other.palette == palette;

  @override
  int get hashCode => Object.hash(language, palette);
}

/// `context.text.bodyLarge`, everywhere a style is read.
extension AppTypographyX on BuildContext {
  /// Falls back to the English scale on the dark palette when no extension is
  /// registered — see [AppPaletteX.colors] for why this does not throw.
  AppTypography get text =>
      Theme.of(this).extension<AppTypography>() ??
      const AppTypography(
        language: AppLanguage.english,
        palette: AppPalette.dark,
      );
}

/// Re-weights a style from the app's scale.
///
/// The only supported way to change weight at a call site. `copyWith`'s
/// `fontWeight:` looks like it works and quietly does nothing on the two UI
/// families, because they are variable and take their weight from the `wght`
/// axis instead — the whole story is on [AppTypography._variable].
///
/// This sets the axis, and for the static mono family sets the plain weight
/// as well, so one call is correct for every style in the scale.
extension AppTextWeight on TextStyle {
  TextStyle weight(FontWeight value) => copyWith(
    fontVariations: [FontVariation('wght', value.value.toDouble())],
    // `copyWith` treats null as "leave it alone", so the variable families
    // keep the unset `fontWeight` their exact file match depends on.
    fontWeight: fontFamily == AppTypography.monoFamily ? value : null,
  );

  TextStyle get asRegular => weight(AppTypography.regular);

  TextStyle get asMedium => weight(AppTypography.medium);

  TextStyle get asSemiBold => weight(AppTypography.semiBold);
}
