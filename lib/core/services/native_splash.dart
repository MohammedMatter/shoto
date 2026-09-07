import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show ThemeMode;

/// Where the native launch screen left its mark, in **physical pixels**,
/// measured against Flutter's own view.
///
/// Physical rather than logical because that is what a `View` knows about
/// itself, and converting on the Kotlin side would mean two places agreeing
/// about a device pixel ratio for no gain. [SplashCurtain] divides once, where
/// it has a `MediaQuery` to divide by.
@immutable
class SplashHandoff {
  /// The centre of the platform's icon *view* — not of the drawing inside it.
  final Offset centre;

  /// The icon view's side. The mark occupies a known fraction of it; see
  /// `SplashMark.safeAreaRatio`.
  final double size;

  /// The colour the launch window was **actually showing**, read off the
  /// screen, or null where it could not be.
  ///
  /// Not the same thing as the colour the theme asked for. A vendor dark mode
  /// can repaint that window after we have specified it and before anybody sees
  /// it — see `SplashChannel.sampleField` for the measurement. Matching what is
  /// on the glass is the entire point of the handover, so this wins over
  /// anything computed whenever it exists.
  final Color? field;

  const SplashHandoff({
    required this.centre,
    required this.size,
    required this.field,
  });

  @override
  bool operator ==(Object other) =>
      other is SplashHandoff &&
      other.centre == centre &&
      other.size == size &&
      other.field == field;

  @override
  int get hashCode => Object.hash(centre, size, field);
}

/// The Flutter half of the cold-start handover. `SplashChannel.kt` is the other.
///
/// **The job is to make one moment invisible**: the instant the platform's
/// launch screen is taken away and Flutter's first frame is what the user is
/// looking at. Every app has that moment; almost every app spends a frame or
/// two of visible change on it, because the two pictures were never the same
/// picture.
///
/// Here they are. The native side holds its splash open, measures the icon it
/// is showing, and waits. Dart draws the same mark at the same size in the same
/// place, says so, and only then does the native view go. There is no
/// transition to design because there is nothing to transition between.
///
/// ---
///
/// **The geometry is pulled as well as pushed, and it has to be both.** The
/// splash exits when the platform decides, and the engine may have no handler
/// attached at that moment; equally, Dart's first frame may come up before the
/// exit. Whichever happens first wins — [handoff] is a notifier so the curtain
/// can simply react, rather than a future that would have to be created before
/// anybody knew which side would resolve it.
abstract class NativeSplash {
  NativeSplash._();

  static const MethodChannel _channel = MethodChannel('shoto/splash');

  /// Null until the native splash has exited and been measured, and null
  /// forever on any platform or path that has no native splash to measure.
  ///
  /// A null here is not a failure — the curtain centres the mark itself and the
  /// handover is merely good rather than perfect.
  static final ValueNotifier<SplashHandoff?> handoff =
      ValueNotifier<SplashHandoff?>(null);

  static bool _listening = false;

  /// Starts listening and asks once for anything that already happened.
  ///
  /// Idempotent: called from the curtain's `initState`, which runs once, but
  /// hot restart re-runs it against a native side that still remembers.
  static void begin() {
    if (!_supported) return;
    if (!_listening) {
      _listening = true;
      _channel.setMethodCallHandler((MethodCall call) async {
        if (call.method == 'handoff') _adopt(call.arguments);
      });
    }

    // Errors are swallowed rather than reported. The only thing on the far side
    // of this call is a rectangle to be exact about, and an app that refuses to
    // start because it could not be exact would be a strictly worse app than
    // one that is a few pixels out.
    _channel
        .invokeMethod<Map<Object?, Object?>>('handoff')
        .then(_adopt, onError: (Object _) {});
  }

  /// Tells the native side its splash may go — **after** the matching frame is
  /// on screen, never before.
  ///
  /// Native has its own timeout on this for the case where it never arrives, so
  /// a failure here costs a visible cut rather than a stuck launch screen.
  static void release() {
    if (!_supported) return;
    _channel.invokeMethod<void>('release').catchError((Object _) {});
  }

  /// Tells the system which mode Shoto is in, so the **next** cold start's
  /// launch window is painted in it.
  ///
  /// **The seam this closes cannot be closed from inside the app.** On Android
  /// 12 and up the platform builds its splash window before this process
  /// exists, resolving `values-night` against the system's mode — so a user who
  /// has pinned light inside Shoto on a phone in dark mode gets a near-black
  /// launch screen in front of a near-white app, and no amount of Dart run
  /// afterwards can un-paint it. `setApplicationNightMode` persists a
  /// per-application override that the system resolves against instead.
  ///
  /// Called from [ThemeController] whenever the setting is written, and once at
  /// startup so an app that already had a pinned mode before this existed
  /// repairs itself. It is one binder call and nothing waits on it.
  ///
  /// See `SplashChannel.pinNightMode` for what the platform does with it, and
  /// `SplashCurtain.destination` for what covers the launch where it has not
  /// applied yet.
  static void pinNightMode(ThemeMode mode) {
    if (!_supported) return;
    _channel
        .invokeMethod<void>('nightMode', mode.name)
        .catchError((Object _) {});
  }

  static void _adopt(Object? arguments) {
    if (arguments is! Map) return;
    final Object? x = arguments['centreX'];
    final Object? y = arguments['centreY'];
    final Object? size = arguments['size'];
    if (x is! num || y is! num || size is! num || size <= 0) return;

    final Object? field = arguments['field'];

    handoff.value = SplashHandoff(
      centre: Offset(x.toDouble(), y.toDouble()),
      size: size.toDouble(),
      // Opaque by construction — it came off a screen — but the alpha is forced
      // rather than trusted, because a field drawn at anything less than full
      // opacity would let the app show through the one frame that must not
      // change.
      field: field is int ? Color(field | 0xFF000000) : null,
    );
  }

  /// Android only. iOS hands its launch storyboard over on its own schedule
  /// with no hook to hold it, so the curtain there does the same work with a
  /// centred mark and no measurement — which is exactly the fallback path this
  /// class already has to have.
  static bool get _supported => !kIsWeb && Platform.isAndroid;
}
