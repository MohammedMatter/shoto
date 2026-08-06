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
  static const String _triageEnabledKey = 'pref_triage_enabled';
  static const String _triageAskedKey = 'pref_triage_asked';
  static const String _triageSinceKey = 'pref_triage_since';
  static const String _triageSnoozedKey = 'pref_triage_snoozed';

  bool _haptics = true;
  bool _confirmBeforeDelete = true;
  bool _hasSeenOnboarding = false;
  String _ownerName = '';
  bool _triageEnabled = false;
  bool _triageAsked = false;
  int _triageSince = 0;
  int _triageSnoozedAt = 0;

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

  /// Whether SHOTO may look at the device's Screenshots album to *offer* what
  /// is new.
  ///
  /// **Off until the user says otherwise, and it is asked as a question rather
  /// than assumed.** The library is opt-in and stays opt-in: this permits
  /// SHOTO to show you what you captured, not to keep any of it. Everything
  /// still enters the library one deliberate decision at a time.
  ///
  /// It exists because opt-in on its own left a new install as an empty room,
  /// and the people with four hundred unfindable screenshots are precisely
  /// the people who will never curate them by hand.
  bool get triageEnabled => _triageEnabled;

  /// Whether the question above has been put to the user at all.
  ///
  /// Separate from the answer, because "no" and "not yet asked" are different
  /// states and an app that cannot tell them apart either nags somebody who
  /// declined or never offers at all.
  bool get triageAsked => _triageAsked;

  /// Everything captured before this has been decided about, one way or the
  /// other. See `ScreenshotGalleryDataSource.getDeviceCaptures`.
  DateTime get triageSince => DateTime.fromMillisecondsSinceEpoch(_triageSince);

  /// How many captures were waiting the last time the user said "not now".
  ///
  /// The queue used to have no way to be put down. It appeared whenever a
  /// single new capture existed, which for anybody who takes screenshots is
  /// *every day, permanently*, and the only way to be rid of it was to answer
  /// the whole queue. That is the difference between an inbox and a nag, and
  /// it is why the row was removed from Home.
  ///
  /// Storing the **count** rather than a timestamp is what makes "not now"
  /// mean the right thing. A snooze until tomorrow says nothing about whether
  /// anything changed; a snooze at eleven says *ask me again when there is
  /// genuinely more than eleven*. Reviewing the queue clears it back to zero.
  int get triageSnoozedAt => _triageSnoozedAt;

  Future<void> snoozeTriage(int waiting) async {
    _triageSnoozedAt = waiting;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_triageSnoozedKey, waiting);
  }

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _haptics = prefs.getBool(_hapticsKey) ?? true;
    _confirmBeforeDelete = prefs.getBool(_confirmDeleteKey) ?? true;
    _hasSeenOnboarding = prefs.getBool(_seenOnboardingKey) ?? false;
    _ownerName = prefs.getString(_ownerNameKey) ?? '';
    _triageEnabled = prefs.getBool(_triageEnabledKey) ?? false;
    _triageAsked = prefs.getBool(_triageAskedKey) ?? false;
    _triageSnoozedAt = prefs.getInt(_triageSnoozedKey) ?? 0;
    // Defaults to *now* rather than to zero. A user switching this on today is
    // asking what they have captured since; handing them every screenshot they
    // have ever taken is the gallery-mirror this app deliberately is not.
    _triageSince =
        prefs.getInt(_triageSinceKey) ?? DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  /// Records the answer to the triage question, whichever way it went.
  Future<void> setTriageEnabled(bool value) async {
    _triageEnabled = value;
    _triageAsked = true;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_triageEnabledKey, value);
    await prefs.setBool(_triageAskedKey, true);
  }

  /// Moves the watermark forward. Never backwards: a capture that has been
  /// decided about must not come back because a later read arrived out of
  /// order.
  Future<void> advanceTriageSince(DateTime moment) async {
    final int millis = moment.millisecondsSinceEpoch;
    if (millis <= _triageSince) return;

    _triageSince = millis;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_triageSinceKey, millis);
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
