import 'dart:io';

import 'package:flutter/services.dart';

/// What Android currently reports about the capture watcher.
///
/// Three separate facts, kept separate on purpose. The switch in Settings says
/// what the *user* asked for; this says what is actually true, and on this
/// feature the two come apart constantly — a force-stop, a battery optimiser
/// or a reboot each leave the preference on and the job gone.
class CaptureAlertsStatus {
  /// Android still has the job scheduled.
  final bool armed;

  /// When it last actually ran. Null means never, which on a phone that has
  /// taken a screenshot since is itself the answer.
  final DateTime? lastRun;

  /// Whether Shoto is permitted to post notifications at all. A watcher that
  /// is armed and muted looks identical to one that is broken.
  final bool notificationsAllowed;

  const CaptureAlertsStatus({
    required this.armed,
    required this.lastRun,
    required this.notificationsAllowed,
  });

  static const CaptureAlertsStatus unavailable = CaptureAlertsStatus(
    armed: false,
    lastRun: null,
    notificationsAllowed: false,
  );

  /// Whether everything needed for an offer to actually appear is in place.
  bool get healthy => armed && notificationsAllowed;
}

/// The watcher that offers to keep a screenshot at the moment it is taken.
///
/// **Android-only, and it can fail without saying so** — which is why this
/// exposes a status rather than only a switch. A content-trigger job does not
/// survive a reboot, is cancelled by a force-stop, and is throttled for apps
/// the user rarely opens. Every one of those leaves a settings screen claiming
/// the feature is on while nothing happens, and a feature that lies about being
/// on is worse than one that was never built.
abstract final class CaptureAlerts {
  static const MethodChannel _channel = MethodChannel('shoto/captures');

  static bool get isSupportedPlatform => Platform.isAndroid;

  /// Switches it on, asking for the notification permission if this is the
  /// first time. Returns the state Android reports immediately afterwards.
  static Future<CaptureAlertsStatus> enable() => _call('enable');

  static Future<CaptureAlertsStatus> disable() => _call('disable');

  static Future<CaptureAlertsStatus> status() => _call('status');

  /// Re-arms after the two things that cancel the job outright — a reboot and
  /// a force-stop — neither of which the app is told about.
  ///
  /// Called on launch. Passing the user's preference rather than reading it
  /// natively keeps one answer to "is this on", in the place that owns it.
  static Future<CaptureAlertsStatus> rearm({required bool wanted}) =>
      _call('rearm', wanted);

  /// Opens Shoto's page in the system notification settings.
  ///
  /// The one action the "notifications are off" warning could not offer for
  /// itself: it named a screen and left the user to find it. Nothing to
  /// report back — the answer arrives as a changed [status] when they return,
  /// which the settings row already refreshes on resume.
  static Future<void> openNotificationSettings() async {
    if (!isSupportedPlatform) return;
    try {
      await _channel.invokeMethod<void>('openNotificationSettings');
    } on PlatformException {
      // Nothing to say: the row is a shortcut, and the manual route it
      // describes is still open.
    } on MissingPluginException {
      // As above.
    }
  }

  static Future<CaptureAlertsStatus> _call(String method, [Object? argument]) async {
    if (!isSupportedPlatform) return CaptureAlertsStatus.unavailable;
    try {
      final Map<Object?, Object?>? answer = await _channel
          .invokeMethod<Map<Object?, Object?>>(method, argument);
      if (answer == null) return CaptureAlertsStatus.unavailable;

      final int lastRun = (answer['lastRun'] as int?) ?? 0;
      return CaptureAlertsStatus(
        armed: answer['armed'] == true,
        lastRun: lastRun <= 0
            ? null
            : DateTime.fromMillisecondsSinceEpoch(lastRun),
        notificationsAllowed: answer['notificationsAllowed'] == true,
      );
    } on PlatformException {
      return CaptureAlertsStatus.unavailable;
    } on MissingPluginException {
      return CaptureAlertsStatus.unavailable;
    }
  }
}
