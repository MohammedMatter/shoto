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
  static const String _triageEnabledKey = 'pref_triage_enabled';
  static const String _triageAskedKey = 'pref_triage_asked';
  static const String _triageSinceKey = 'pref_triage_since';
  static const String _triageSnoozedKey = 'pref_triage_snoozed';
  static const String _photoAccessAskedKey = 'pref_photo_access_asked';

  bool _haptics = true;
  bool _confirmBeforeDelete = true;
  bool _hasSeenOnboarding = false;
  bool _triageEnabled = false;
  bool _triageAsked = false;
  int _triageSince = 0;
  int _triageSnoozedAt = 0;
  bool _photoAccessAsked = false;

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
  /// has been using Shoto for a month and simply signed out is telling them
  /// something they already know, in the way of what they were trying to do.
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  /// Whether Shoto may look at the device's Screenshots album to *offer* what
  /// is new.
  ///
  /// **Off until the user says otherwise, and it is asked as a question rather
  /// than assumed.** The library is opt-in and stays opt-in: this permits
  /// Shoto to show you what you captured, not to keep any of it. Everything
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

  /// Whether the system photo dialog has ever been put in front of this user.
  ///
  /// **Android cannot answer this itself.** `PermissionState` reports *denied*
  /// both for somebody who refused and for somebody who has never been asked,
  /// and the two need opposite screens: one is told how to reach system
  /// settings, the other is offered the dialog. Getting that backwards means
  /// a fresh install opens on "go to your phone's settings" for an app the
  /// user installed thirty seconds ago.
  ///
  /// Kept next to [triageAsked] because it is the same shape of fact: the
  /// question having been put is not the same as the answer to it.
  bool get photoAccessAsked => _photoAccessAsked;

  Future<void> markPhotoAccessAsked() async {
    if (_photoAccessAsked) return;
    _photoAccessAsked = true;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_photoAccessAskedKey, true);
  }

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
    _triageEnabled = prefs.getBool(_triageEnabledKey) ?? false;
    _triageAsked = prefs.getBool(_triageAskedKey) ?? false;
    _triageSnoozedAt = prefs.getInt(_triageSnoozedKey) ?? 0;
    _photoAccessAsked = prefs.getBool(_photoAccessAskedKey) ?? false;
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
