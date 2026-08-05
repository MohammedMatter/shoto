import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences that change how the app behaves rather than how it looks
/// — theme and grid density have their own controllers because widgets watch
/// those directly to repaint.
///
/// Every setting here exists because it removes a real annoyance, not to pad
/// the screen. A settings list that is mostly switches nobody needs makes the
/// two that matter harder to find.
class AppPreferences extends ChangeNotifier {
  static const String _hapticsKey = 'pref_haptics';
  static const String _confirmDeleteKey = 'pref_confirm_delete';
  static const String _seenOnboardingKey = 'pref_seen_onboarding';
  static const String _ownerNameKey = 'pref_owner_name';

  bool _haptics = true;
  bool _confirmBeforeDelete = true;
  bool _hasSeenOnboarding = false;
  String _ownerName = '';

  /// Whether taps give physical feedback. Off is a genuine accessibility
  /// preference, and some people simply find it noisy.
  bool get haptics => _haptics;

  /// Whether deleting asks first. Defaults on and stays a choice rather than
  /// a hardcoded rule — but deleting is irreversible, so the *default* is
  /// never the silent one.
  bool get confirmBeforeDelete => _confirmBeforeDelete;

  /// Whether the introduction has already been shown, ever.
  ///
  /// Not a user-facing setting — a fact. Onboarding explains what the app is
  /// to somebody who has never opened it; showing it again to somebody who
  /// has been using SHOTO for a month and simply signed out is telling them
  /// something they already know, in the way of what they were trying to do.
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  /// The user's own name, as it appears *inside their screenshots*, or empty.
  ///
  /// Safe Share needs this: a name with no label in front of it is the one
  /// private detail no checksum or keyword can find. "Ahmed Khalil" on a line
  /// by itself is a name only if you already know whose screenshot this is.
  ///
  /// This used to come from the signed-in Google account, which was both a
  /// reason to demand an account and the wrong string — the name on somebody's
  /// email is often not the name their bank prints. It is typed, once,
  /// optional, and never leaves the device.
  String get ownerName => _ownerName;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _haptics = prefs.getBool(_hapticsKey) ?? true;
    _confirmBeforeDelete = prefs.getBool(_confirmDeleteKey) ?? true;
    _hasSeenOnboarding = prefs.getBool(_seenOnboardingKey) ?? false;
    _ownerName = prefs.getString(_ownerNameKey) ?? '';
    notifyListeners();
  }

  Future<void> setOwnerName(String value) async {
    _ownerName = value.trim();
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ownerNameKey, _ownerName);
  }

  Future<void> setHaptics(bool value) => _set(_hapticsKey, value, (v) {
    _haptics = v;
  });

  Future<void> setConfirmBeforeDelete(bool value) =>
      _set(_confirmDeleteKey, value, (v) {
        _confirmBeforeDelete = v;
      });

  /// Recorded when the intro is finished, so it is never shown twice.
  Future<void> markOnboardingSeen() => _set(_seenOnboardingKey, true, (v) {
    _hasSeenOnboarding = v;
  });

  Future<void> _set(String key, bool value, void Function(bool) apply) async {
    apply(value);
    // Notify before the write, not after: the switch should move under the
    // finger immediately rather than waiting on disk.
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
