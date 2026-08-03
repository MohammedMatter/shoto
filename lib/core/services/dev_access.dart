import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A switch, local to this phone, that makes SHOTO behave as if the user is
/// subscribed.
///
/// It exists because the paid features currently cannot be reached at all on
/// a real device: RevenueCat can only issue a genuine entitlement once the
/// Apple Developer and Play Console accounts and the store products exist
/// (DOCUMENTATION §8), so until then every premium screen is behind a paywall
/// that can never complete. This unlocks them for development and demos.
///
/// It is deliberately **not** a purchase. Nothing is recorded anywhere but
/// this device, and [SubscriptionRepositoryImpl] still asks RevenueCat first
/// — a real subscription always wins, so turning this off can never take away
/// something the user actually paid for.
class DevAccess extends ChangeNotifier {
  /// The four digits the hidden prompt asks for.
  ///
  /// Middle column of a phone keypad, top to bottom. Easy to remember and
  /// not a sequence anyone idly tries, which is the whole bar it has to
  /// clear — this is a convenience for the developer, not a secret.
  static const String unlockCode = '2580';

  /// Taps on the version label at the bottom of Settings that open the
  /// prompt. Nobody taps a version number three times by accident.
  static const int tapsToReveal = 3;

  /// How long the tap streak survives. Without a window, three taps spread
  /// over a week would still count.
  static const Duration tapWindow = Duration(seconds: 2);

  /// ⚠️ **Set this to `kDebugMode` before submitting to the stores.**
  ///
  /// While it is `true` in a release build, anyone who finds the tap and
  /// guesses four digits gets every paid feature for nothing. It is `true`
  /// now so the unlock also works in release builds installed for testing.
  /// Listed in DOCUMENTATION §8 so it is not forgotten at submission time.
  static const bool enabled = true;

  static const String _key = 'dev_premium_unlocked';

  bool _isUnlocked = false;

  /// Whether the app should currently treat the user as premium regardless
  /// of what the store says.
  bool get isUnlocked => enabled && _isUnlocked;

  Future<void> load() async {
    if (!enabled) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isUnlocked = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  /// Returns false when [code] is wrong, leaving the state untouched.
  Future<bool> unlock(String code) async {
    if (!enabled || code.trim() != unlockCode) return false;
    await _set(true);
    return true;
  }

  /// Back to the free tier. Being able to *leave* developer mode matters as
  /// much as entering it — otherwise the paywall and every free-tier limit
  /// become impossible to test on this device again.
  Future<void> lock() => _set(false);

  Future<void> _set(bool value) async {
    _isUnlocked = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
