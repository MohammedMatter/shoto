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

  /// Debug builds only, and deliberately not a switch anybody can flip back.
  ///
  /// While this was `true` in a release build, anyone who strings a
  /// decompiled APK finds both the tap count and the four digits, and gets
  /// every paid feature for nothing. Tying it to [kDebugMode] means the code
  /// path is compiled out of release entirely: there is nothing left in the
  /// binary to find, and no way to forget this at submission time.
  ///
  /// The cost is that the unlock no longer works in a release build installed
  /// for testing. Use a profile or debug build to demo the paid features, or
  /// a RevenueCat sandbox purchase once the store products exist.
  static const bool enabled = kDebugMode;

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
