import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/localization/app_locales.dart';

/// Holds the app's language, persisted across restarts.
///
/// Same shape as `ThemeController`: a `ChangeNotifier` singleton that both
/// `MyApp` (to rebuild) and Settings (to change it) read from DI.
///
/// A null [language] means "follow the phone", which is the right default —
/// somebody whose device is in Spanish should not have to find a setting to
/// be spoken to in Spanish. But it stays an explicit *choice* rather than the
/// only behaviour, because plenty of people run a phone in one language and
/// prefer their apps in another.
class LocaleController extends ChangeNotifier {
  static const String _prefsKey = 'app_language';

  AppLanguage? _language;

  /// The user's explicit pick, or null when following the system.
  AppLanguage? get language => _language;

  /// What `MaterialApp.locale` wants: null lets Flutter resolve the system
  /// locale against `supportedLocales` on its own.
  Locale? get locale => _language?.locale;

  /// The language actually being rendered, whether chosen or inherited.
  ///
  /// Needed because typography has to know: a language can ask for looser
  /// lines or its own face, and it gets them regardless of *how* the app
  /// ended up in that language. No language shipping today asks for either —
  /// see [AppLanguage].
  AppLanguage get effectiveLanguage {
    if (_language != null) return _language!;

    // Flutter's own resolution is not available before the first frame, and
    // the type scale is read during it, so the same match is done here:
    // first the device's preferred locales, then English.
    for (final Locale candidate in PlatformDispatcher.instance.locales) {
      final AppLanguage? match = AppLanguage.fromCode(candidate.languageCode);
      if (match != null) return match;
    }
    return AppLanguage.english;
  }

  /// Asked of the language rather than listed here, so a right-to-left
  /// language arrives as one flag on [AppLanguage] instead of an `||` somebody
  /// has to remember to extend. False for every language shipping today.
  bool get isRightToLeft => effectiveLanguage.isRightToLeft;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _language = AppLanguage.fromCode(prefs.getString(_prefsKey));
    notifyListeners();
  }

  /// Pass null to go back to following the device.
  Future<void> setLanguage(AppLanguage? language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (language == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, language.code);
    }
  }
}
