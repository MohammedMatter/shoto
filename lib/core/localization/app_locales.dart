import 'package:flutter/material.dart';

/// Every language SHOTO ships in, and what each one needs beyond translation.
///
/// A language is more than a string table. Arabic and Urdu run right to left,
/// Urdu is set in a sloping calligraphic script that needs more vertical room
/// than Latin, and none of Arabic, Urdu or Hindi have a single glyph in the
/// app's Latin typeface. Keeping those facts next to the locale — rather than
/// scattered through `if (locale == 'ar')` checks — is what stops adding the
/// seventh language from turning into an audit of the whole codebase.
enum AppLanguage {
  english(code: 'en', endonym: 'English', englishName: 'English'),

  /// Listed second on purpose: it is the author's own language and the first
  /// one this app was ever asked for.
  arabic(
    code: 'ar',
    endonym: 'العربية',
    englishName: 'Arabic',
    fontFallback: 'NotoSansArabic',
  ),

  urdu(
    code: 'ur',
    endonym: 'اردو',
    englishName: 'Urdu',
    fontFallback: 'NotoNastaliqUrdu',
    // Nastaliq letterforms cascade downward within a word, so they occupy far
    // more vertical space than any upright script. At the app's own line
    // heights the descenders of one line collide with the next; this widens
    // every line for Urdu only.
    lineHeightScale: 1.45,
  ),

  spanish(code: 'es', endonym: 'Español', englishName: 'Spanish'),

  french(code: 'fr', endonym: 'Français', englishName: 'French'),

  hindi(
    code: 'hi',
    endonym: 'हिन्दी',
    englishName: 'Hindi',
    fontFallback: 'NotoSansDevanagari',
  );

  const AppLanguage({
    required this.code,
    required this.endonym,
    required this.englishName,
    this.fontFallback,
    this.lineHeightScale = 1,
  });

  /// The ISO code, which is also the `.arb` file's suffix.
  final String code;

  /// The language's name **in itself** — العربية, not "Arabic".
  ///
  /// A picker that lists languages in a language you cannot read is useless
  /// to the exact person who needs it. Somebody hunting for Urdu is looking
  /// for اردو.
  final String endonym;

  /// Only for the picker's subtitle, so an English speaker helping someone
  /// else set the app up can still find the row.
  final String englishName;

  /// The family that supplies the glyphs the app's own faces don't have.
  ///
  /// Archivo and IBM Plex Sans are Latin, so Arabic, Urdu and Devanagari each
  /// need a Noto face behind them — see the `fonts:` block in pubspec.yaml and
  /// [fontFallbacks], which hands the whole list to every style so a folder
  /// named in Arabic still renders inside a French-language app.
  ///
  /// Null means Latin covers it. Chinese would also be null if it shipped:
  /// bundling a CJK face costs ~17MB, and every phone already has one.
  final String? fontFallback;

  /// Multiplies every line height in the type scale.
  final double lineHeightScale;

  Locale get locale => Locale(code);

  static AppLanguage? fromCode(String? code) {
    if (code == null) return null;
    for (final AppLanguage language in values) {
      if (language.code == code) return language;
    }
    return null;
  }

  /// What [Localizations] should hand to `supportedLocales`.
  static List<Locale> get supportedLocales => [
    for (final AppLanguage language in values) language.locale,
  ];

  /// Every non-Latin family, in a fixed order.
  ///
  /// The *whole* list is attached to every text style rather than only the
  /// active language's, because a screen is routinely mixed: a folder the
  /// user named in Arabic while the app is set to French has to render, and
  /// the app language is no guide to what people type into it.
  static List<String> get fontFallbacks => [
    for (final AppLanguage language in values)
      if (language.fontFallback != null) language.fontFallback!,
  ];
}
