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
  static const String _copyTextHintedKey = 'pref_copy_text_hinted';
  static const String _tileOfferedKey = 'pref_tile_offered';
  static const String _captureAlertsKey = 'pref_capture_alerts';
  static const String _reminderSwipedKey = 'pref_reminder_swiped';

  /// **Off until asked for.** Haptics were on by default, which meant every
  /// install began by adding a physical sensation to every press without the
  /// user having chosen one. A buzz is the one setting in this app that
  /// reaches past the screen and into the hand — it is the kind of thing to
  /// opt into rather than to discover and go looking for the switch to stop.
  ///
  /// The switch itself demonstrates the effect on the way on (see the settings
  /// row), so turning it on is also how you find out what it does.
  bool _haptics = false;
  bool _confirmBeforeDelete = true;
  bool _hasSeenOnboarding = false;
  bool _triageEnabled = false;
  bool _triageAsked = false;
  int _triageSince = 0;
  int _triageSnoozedAt = 0;
  bool _photoAccessAsked = false;
  bool _copyTextHinted = false;
  bool _tileOffered = false;
  bool _captureAlerts = false;
  bool _reminderSwiped = false;

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

  /// Whether the viewer has already said, once, that the words in a screenshot
  /// can be pressed and held.
  ///
  /// A fact rather than a setting, like [hasSeenOnboarding] — and it is
  /// recorded when the hint is *shown*, not when it is understood, because
  /// there is no way to know the second and showing it twice is how a hint
  /// turns into nagging.
  bool get hasSeenCopyTextHint => _copyTextHinted;

  /// Whether the Quick Settings shortcut has already been offered, once.
  ///
  /// **Recorded when the offer is made, not when it is accepted**, and the
  /// difference is the whole point. Android caps how many times an app may
  /// ask it to place a tile and stops showing the dialog at all once somebody
  /// has turned it down a few times — so a second offer is not merely
  /// nagging, it burns one of a small number of chances on a person who has
  /// already said no. Declining is an answer.
  ///
  /// Same shape of fact as [hasSeenCopyTextHint] and [photoAccessAsked]: a
  /// record that a question was put, which is not the same as its answer. The
  /// answer lives in the user's own Quick Settings panel, and Android will not
  /// tell an app what is in it.
  bool get tileOffered => _tileOffered;

  /// Whether the user has asked to be offered each new screenshot as it is
  /// taken.
  ///
  /// **This is the request, not the reality.** Whether an offer can actually
  /// appear depends on a scheduled job Android may have dropped and on a
  /// notification permission it may have revoked — see `CaptureAlerts.status`,
  /// which Settings renders beside this switch. Folding the two into one
  /// boolean would produce a control that turns itself off for reasons the
  /// user never chose, which is the worse of the two confusions.
  ///
  /// Off by default. A notification after every screenshot is a hundred
  /// interruptions a week for somebody who has not asked for any.
  bool get captureAlerts => _captureAlerts;

  /// Whether the user has ever swiped a reminder row, either way.
  ///
  /// **Recorded when the gesture is *used*, not when it is shown**, and the
  /// difference from [hasSeenCopyTextHint] is deliberate. That hint is a
  /// sentence about a thing you can press: there is no way to know it landed,
  /// so it is retired after one showing rather than nagged. A swipe leaves
  /// proof — the person either did it or did not — so the legend on the
  /// reminders screen can keep offering itself until it is no longer needed,
  /// and go away for good the moment it is.
  ///
  /// One flag for both directions. Somebody who has swiped a row to clear it
  /// has learnt that rows swipe; which side does what is the small half of
  /// that, and it is written on the surface the gesture reveals.
  bool get hasSwipedReminder => _reminderSwiped;

  Future<void> markReminderSwiped() async {
    if (_reminderSwiped) return;
    _reminderSwiped = true;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderSwipedKey, true);
  }

  Future<void> setCaptureAlerts(bool value) async {
    _captureAlerts = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_captureAlertsKey, value);
  }

  Future<void> markTileOffered() async {
    if (_tileOffered) return;
    _tileOffered = true;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tileOfferedKey, true);
  }

  Future<void> markCopyTextHintSeen() async {
    if (_copyTextHinted) return;
    _copyTextHinted = true;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_copyTextHintedKey, true);
  }

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
    _haptics = prefs.getBool(_hapticsKey) ?? false;
    _confirmBeforeDelete = prefs.getBool(_confirmDeleteKey) ?? true;
    _hasSeenOnboarding = prefs.getBool(_seenOnboardingKey) ?? false;
    _triageEnabled = prefs.getBool(_triageEnabledKey) ?? false;
    _triageAsked = prefs.getBool(_triageAskedKey) ?? false;
    _triageSnoozedAt = prefs.getInt(_triageSnoozedKey) ?? 0;
    _photoAccessAsked = prefs.getBool(_photoAccessAskedKey) ?? false;
    _copyTextHinted = prefs.getBool(_copyTextHintedKey) ?? false;
    _tileOffered = prefs.getBool(_tileOfferedKey) ?? false;
    _captureAlerts = prefs.getBool(_captureAlertsKey) ?? false;
    _reminderSwiped = prefs.getBool(_reminderSwipedKey) ?? false;
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
