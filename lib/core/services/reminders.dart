import 'dart:io';

import 'package:flutter/services.dart';

/// Arms and cancels the alarms behind reminders.
///
/// Thin on purpose. Every decision about *when* — the presets, what "this
/// evening" means, whether an option is still honest at this hour — lives in
/// `reminder_times.dart`, where it is pure Dart and can be asked from both
/// sides of every edge without a device. What is here is only the part that
/// needs `AlarmManager`, and the platform half of it is documented in
/// `ReminderScheduler.kt`.
///
/// **Every method no-ops off Android**, rather than throwing. `ios/` has no
/// equivalent yet — see `docs/decisions/ios.md` — and the failure mode that
/// matters is the one where a user sets a reminder and nothing says otherwise.
/// [isSupported] is what the interface asks so the option can be withheld
/// instead of silently doing nothing.
class Reminders {
  static const MethodChannel _channel = MethodChannel('shoto/reminders');

  /// Whether reminders can be armed on this platform at all.
  static bool get isSupported => Platform.isAndroid;

  /// Arms one, replacing any earlier reminder for the same screenshot.
  ///
  /// Returns whether the notification will actually be seen — the alarm is set
  /// either way, but Android will drop the notification silently if the user
  /// has turned Shoto's off, and a reminder nobody will be shown is worth
  /// saying so about at the moment it is set rather than discovering later.
  ///
  /// [title] and [body] are passed in already translated. They are composed
  /// from the ARB files so a reminder speaks the language the app is set to,
  /// not the language the phone is set to — unlike the notification *channel*
  /// name, which Android draws in its own settings with no app running and
  /// therefore comes from `strings.xml`.
  static Future<bool> schedule({
    required String assetId,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    if (!isSupported) return false;

    try {
      final bool? visible = await _channel.invokeMethod<bool>('schedule', {
        'assetId': assetId,
        'at': at.millisecondsSinceEpoch,
        'title': title,
        'body': body,
      });
      return visible ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // The share sheet runs its own engine and does not register this
      // channel. Nothing there sets a reminder, but a stray call must not
      // take the sheet down.
      return false;
    }
  }

  static Future<void> cancel(String assetId) async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod<void>('cancel', {'assetId': assetId});
    } on PlatformException {
      // Cancelling something the platform has already forgotten is not a
      // failure worth reporting: the database row is the source of truth and
      // the caller has already cleared it.
    } on MissingPluginException {
      // See above.
    }
  }

  static Future<bool> notificationsEnabled() async {
    if (!isSupported) return false;

    try {
      final bool? enabled = await _channel.invokeMethod<bool>(
        'notificationsEnabled',
      );
      return enabled ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The screenshot a tapped reminder was about, once.
  ///
  /// Null on every ordinary launch. Consumed rather than read, on both sides:
  /// an activity keeps the intent that started it, so without clearing it the
  /// app would reopen the same screenshot every time it came back from the
  /// background, long after the reminder was dealt with.
  static Future<String?> consumeLaunchAssetId() async {
    if (!isSupported) return null;

    try {
      return await _channel.invokeMethod<String>('consumeLaunchAssetId');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
