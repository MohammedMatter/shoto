import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Crash reports, **off until the user turns them on**.
///
/// Without this the app ships blind in the one way that matters most: a crash
/// on somebody else's phone is invisible. They see a screen stop responding,
/// they uninstall, and nothing about it ever reaches the person who could fix
/// it. Support mail arrives from well under a tenth of the people who hit a
/// bug; the rest leave quietly, and a report is the only way to hear from
/// them.
///
/// **Why it is a switch rather than a default.** A crash report leaves the
/// device — the stack trace, the device model, the app version — and this app
/// is built on the claim that nothing does. So the claim keeps its shape: the
/// default is off, the switch is in Settings in plain words, and the privacy
/// note names it alongside the other two things the user can choose to turn
/// on. See `docs/decisions/accounts.md` for the rule about that note.
///
/// **What is never in a report.** No screenshot, no OCR text, no folder name,
/// no email address. Crashlytics is given a stack trace and the device
/// metadata it collects itself; nothing in this app ever calls
/// `setCustomKey`, and the day something wants to, that is a decision to take
/// in the open rather than a line to add quietly.
class CrashReporting extends ChangeNotifier {
  static const String _key = 'pref_crash_reports';

  bool _enabled = false;

  /// Whether reports are being collected right now.
  bool get isEnabled => _enabled;

  /// Reads the stored answer and tells Crashlytics about it.
  ///
  /// Must run after `Firebase.initializeApp` and before the first frame:
  /// collection is a property of the SDK, and leaving it at its default until
  /// somebody opens Settings would send whatever crashed in between.
  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? false;
    await _apply();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    await _apply();
  }

  Future<void> _apply() async {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        _enabled,
      );

      // **Off has to mean nothing was kept, not nothing was sent yet.**
      //
      // Disabling collection stops Crashlytics *uploading*, and it keeps
      // writing reports to disk. Turning the switch on later then sends the
      // backlog — every crash that happened while the answer was no. Watched
      // that happen: three crashes forced on a test device, two of them with
      // the switch off, and all three arrived in the console the moment it
      // went on.
      //
      // That is a defensible SDK default and the wrong promise for this app.
      // The switch says reports are off; a pile of them waiting for a change
      // of mind is not off, it is deferred consent nobody asked for.
      if (!_enabled) {
        await FirebaseCrashlytics.instance.deleteUnsentReports();
      }
    } catch (error) {
      // A device with no Play services, or a Firebase app that failed to
      // initialize, must not take the app down over an *optional* diagnostic.
      debugPrint('SHOTO: could not set crash collection: $error');
    }
  }

  /// Routes Flutter's two error channels into Crashlytics.
  ///
  /// Installed unconditionally, and that is safe: with collection disabled
  /// the SDK drops everything it is handed rather than queueing it, so the
  /// switch is the only thing deciding whether a report exists. Wiring these
  /// behind the preference instead would mean a user who turns reports on
  /// mid-session gets nothing until they restart.
  ///
  /// `FlutterError.onError` catches errors thrown inside the framework —
  /// build, layout and paint. `PlatformDispatcher.onError` catches everything
  /// else: an unawaited future rejecting, a platform channel throwing. The
  /// second is the one people forget, and it is where a crash in this app is
  /// most likely to come from, because so much of it is async work over
  /// channels.
  void install() {
    final FlutterExceptionHandler? existing = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // The framework's own handler still runs, so a debug build keeps
      // printing the red screen and the console trace.
      existing?.call(details);
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      // False lets the platform continue with its default handling instead of
      // swallowing an error the developer console should still show.
      return false;
    };
  }
}
