import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/theme/app_tint.dart';

/// Holds the user's chosen accent, persisting it across restarts.
///
/// The same shape as [ThemeController] deliberately — one preference, a
/// singleton in DI, `MyApp` listening and the Appearance page setting. The two
/// are kept apart rather than merged into one "appearance" controller because
/// they are read by different code at different times: the theme mode decides
/// which of two `ThemeData` objects `MaterialApp` uses, and the tint decides
/// what is *in* both of them.
///
/// **The id is stored, not the colour.** A hex in preferences would freeze a
/// user's accent at whatever the solver produced on the day they tapped it, so
/// a later correction to a hue or a saturation would reach new users and skip
/// everyone who had already chosen. Storing `'plum'` means the preference
/// records the decision and the app keeps ownership of what that decision
/// looks like.
class TintController extends ChangeNotifier {
  static const String _prefsKey = 'accent_tint';

  AppTint _tint = AppTint.fallback;
  AppTint get tint => _tint;

  /// Whether the user has actually chosen — as opposed to sitting on the
  /// default because they never opened the page.
  ///
  /// Needed because "chose teal" and "never chose" produce the same accent and
  /// must not produce the same *paywall* behaviour: a subscriber who lapses
  /// keeps a tint they paid for and stops being able to change it, which is
  /// the ordinary way subscriptions expire. Reverting their app to teal on the
  /// day their card fails would be taking something back rather than declining
  /// to sell more of it.
  bool get isCustom => _tint != AppTint.fallback;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _tint = AppTint.byId(prefs.getString(_prefsKey));
    notifyListeners();
  }

  Future<void> setTint(AppTint tint) async {
    if (tint == _tint) return;
    // Notified before the write, like [ThemeController.setThemeMode]: the
    // colour is the answer to a tap and must land on the next frame, not after
    // a round trip to disk.
    _tint = tint;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, tint.id);
  }
}
