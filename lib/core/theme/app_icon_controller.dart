import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/theme/app_icon.dart';

/// Which launcher icon is in force.
///
/// **The only preference in this app whose truth lives outside it.** Every
/// other controller here owns its value: the stored string *is* the answer,
/// and nothing else can change it. This one records a request — the state that
/// matters is which Android component is enabled, and Android is free to
/// disagree with the preference if a swap was interrupted.
///
/// So [load] asks the platform rather than trusting the store, and the stored
/// value exists only to answer instantly on the first frame, before the
/// channel has replied. See [AppIconChannel] on the native side.
class AppIconController extends ChangeNotifier {
  static const String _prefsKey = 'app_icon';
  static const MethodChannel _channel = MethodChannel('shoto/app_icon');

  AppIcon _icon = AppIcon.fallback;
  AppIcon get icon => _icon;

  /// Whether the swap is in flight.
  ///
  /// Held because the platform call is slow enough to see — it is a package
  /// manager write, not a preference — and because a second tap during it
  /// would race two swaps against each other, each disabling what the other
  /// just enabled.
  bool _isChanging = false;
  bool get isChanging => _isChanging;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _icon = AppIcon.byId(prefs.getString(_prefsKey));
    notifyListeners();

    // Then the authoritative answer, which may differ from the one above.
    // Failures are swallowed: an old build without the channel, or a platform
    // that has no such concept, should leave the app on its default rather
    // than take down whatever is being drawn.
    try {
      final String? component = await _channel.invokeMethod<String>(
        'currentIcon',
      );
      final AppIcon actual = AppIcon.all.firstWhere(
        (AppIcon candidate) => candidate.component == component,
        orElse: () => AppIcon.fallback,
      );
      if (actual == _icon) return;
      _icon = actual;
      notifyListeners();
      await prefs.setString(_prefsKey, actual.id);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  /// Returns whether the icon actually changed.
  ///
  /// **The preference is written after the platform call, not before.** Every
  /// other controller here notifies first and writes to disk afterwards,
  /// because the repaint has to land under the finger. Nothing repaints here —
  /// the icon is on the home screen, not in the app — so there is no reason to
  /// record a change that might not happen. If the swap throws, the preference
  /// still says what is really on the launcher.
  Future<bool> setIcon(AppIcon icon) async {
    if (icon == _icon || _isChanging) return false;

    _isChanging = true;
    notifyListeners();

    try {
      await _channel.invokeMethod<String>('setIcon', <String, String>{
        'component': icon.component,
      });
    } on PlatformException {
      _isChanging = false;
      notifyListeners();
      return false;
    } on MissingPluginException {
      _isChanging = false;
      notifyListeners();
      return false;
    }

    _icon = icon;
    _isChanging = false;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, icon.id);
    return true;
  }
}
