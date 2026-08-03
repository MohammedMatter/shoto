import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';

/// The only way this app vibrates.
///
/// Three things were wrong, and the first two were opposites of each other.
///
/// **Nothing was felt when the setting was on.** Every tap in the app went
/// through `HapticFeedback.selectionClick()`, which on Android maps to
/// `HapticFeedbackConstants.CLOCK_TICK` — the faintest constant the platform
/// has. It is meant for scrolling past an item in a picker.
///
/// **And the setting could not fully turn it off.** Several call sites reached
/// for `HapticFeedback` directly without consulting the preference, so
/// switching haptics off still left the app buzzing on confirmations, filter
/// chips and the primary button.
///
/// **Then, with both fixed, it was still imperceptible.** Every
/// `HapticFeedback` method is a `View.performHapticFeedback` call, and those
/// constants are only *suggestions* — each Android skin decides what they map
/// to, and on plenty of them the ones an app may use map to no motion at all.
/// The user's own device had system haptics enabled at maximum strength and
/// still felt nothing. So on Android this now drives the vibrator directly
/// through `shoto/haptics` (see `HapticsChannel.kt`), where the effect asked
/// for is the effect that plays.
///
/// iOS is left on `HapticFeedback`: the Taptic Engine is excellent and Apple's
/// own APIs are what it is tuned for.
abstract class Haptics {
  Haptics._();

  static const MethodChannel _channel = MethodChannel('shoto/haptics');

  /// Set once the native side reports it cannot vibrate — no motor, or an
  /// engine with no handler attached. After that we stop asking and use
  /// Flutter's haptics, which at worst do nothing, same as now.
  static bool _nativeUnavailable = false;

  /// The everyday one: a tap landed, a tab changed, a chip toggled.
  static void tap() => _fire('tap', HapticFeedback.lightImpact);

  /// Something committed: saved, filed, deleted, unlocked.
  static void confirm() => _fire('confirm', HapticFeedback.mediumImpact);

  /// Something refused: a wrong code, a failed action. Deliberately the
  /// strongest, because it is the one you want to feel without looking.
  static void reject() => _fire('reject', HapticFeedback.heavyImpact);

  /// A long press registered, before whatever it opens appears.
  static void longPress() => _fire('longPress', HapticFeedback.mediumImpact);

  /// Ignores the preference on purpose — used when the user *switches
  /// haptics on*, so the thing they just enabled demonstrates itself. A
  /// toggle whose effect you can only discover later is a toggle people
  /// assume is broken.
  static void demo() => _play('confirm', HapticFeedback.mediumImpact);

  /// Reads the preference at call time rather than caching it, so flipping
  /// the setting takes effect on the very next tap.
  static void _fire(String effect, VoidCallback fallback) {
    if (!sl<AppPreferences>().haptics) return;
    _play(effect, fallback);
  }

  /// Deliberately not awaited. A vibration is feedback about something that
  /// already happened; making the caller wait on a platform round-trip to
  /// deliver it would add latency to the exact interactions this exists to
  /// make feel immediate.
  static void _play(String effect, VoidCallback fallback) {
    if (_nativeUnavailable || !_isAndroid) {
      fallback();
      return;
    }

    _channel
        .invokeMethod<bool>(effect)
        .then((bool? played) {
          if (played == true) return;
          _nativeUnavailable = true;
          fallback();
        })
        .catchError((Object _) {
          _nativeUnavailable = true;
          fallback();
        });
  }

  /// `Platform` throws on web, and this is a UI-layer utility that must never
  /// be the reason a build fails to run somewhere.
  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;
}
