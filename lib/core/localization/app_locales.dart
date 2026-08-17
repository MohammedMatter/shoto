import 'package:flutter/material.dart';

/// Every language Shoto ships in, and what each one needs beyond translation.
///
/// A language is more than a string table: some run right to left, some are
/// set in scripts that need more vertical room than Latin, and some have not
/// one glyph in the app's own typeface. Keeping those facts next to the locale
/// — rather than scattered through `if (locale == 'ar')` checks — is what
/// stops adding the eighth language from turning into an audit of the whole
/// codebase.
///
/// **The shipped set is every language the recogniser can actually read.**
/// Arabic, Urdu and Hindi were here first, and were replaced by German,
/// Italian, Portuguese and Dutch because ML Kit's on-device text recognition
/// has no model for their scripts — see
/// `docs/decisions/shipped-languages.md`. Every feature that matters in this
/// app reads the words inside a screenshot, so a UI translated into a language
/// the OCR is blind to promises a product that cannot be delivered.
///
/// **[isRightToLeft], [fontFallback] and [lineHeightScale] are all unused
/// today and none of them is dead code.** Every current language is Latin and
/// left-to-right, so all three sit at their defaults — and they are the exact
/// three things a non-Latin language needs. They stay so that adding one back
/// is these three fields and a string table, which is what it cost the first
/// time and what it must cost the next.
enum AppLanguage {
  english(code: 'en', endonym: 'English', englishName: 'English'),

  german(code: 'de', endonym: 'Deutsch', englishName: 'German'),

  spanish(code: 'es', endonym: 'Español', englishName: 'Spanish'),

  french(code: 'fr', endonym: 'Français', englishName: 'French'),

  italian(code: 'it', endonym: 'Italiano', englishName: 'Italian'),

  portuguese(code: 'pt', endonym: 'Português', englishName: 'Portuguese'),

  dutch(code: 'nl', endonym: 'Nederlands', englishName: 'Dutch');

  // The three optional parameters are unused *today* and that is the point —
  // see the class doc. The lint reports an argument nobody passes; here that
  // is the shipped language set being all-Latin, not dead code, and deleting
  // them would move the cost of the next non-Latin language from three fields
  // to an audit of the type scale and the whole widget tree.
  const AppLanguage({
    required this.code,
    required this.endonym,
    required this.englishName,
    // ignore: unused_element_parameter
    this.isRightToLeft = false,
    // ignore: unused_element_parameter
    this.fontFallback,
    // ignore: unused_element_parameter
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

  /// Whether the interface mirrors for this language.
  ///
  /// Read by [LocaleController.isRightToLeft], which the app consults before
  /// the first frame — earlier than [Directionality] exists. Everything drawn
  /// *after* that reads the inherited direction instead and needs no flag.
  ///
  /// Nothing about **content** direction goes through here. A screenshot full
  /// of Arabic is redacted right-to-left inside a Dutch-language app, because
  /// `RedactionService` decides that from the runs of text it recognised — the
  /// app's language says nothing about what somebody photographed.
  final bool isRightToLeft;

  /// The family that supplies the glyphs the app's own faces don't have.
  ///
  /// Null for every language today, because Archivo and IBM Plex Sans cover
  /// Latin and Latin is all that ships. The three Noto faces that used to be
  /// listed here went with the languages that needed them — 2.2MB of assets
  /// for scripts no shipped string is written in.
  ///
  /// **User-typed text in another script now falls back to the platform.**
  /// A folder named in Arabic inside a German-language app is drawn with
  /// Android's or iOS's own Noto, which both ship. That is a weaker guarantee
  /// than bundling the face and it is the right trade at this size; bundle
  /// again here if a shipped language ever needs it. Chinese would stay null
  /// either way — a CJK face costs ~17MB and every phone already has one.
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
