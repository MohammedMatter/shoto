import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/widgets/splash_curtain.dart';

/// **This file exists for one failure, and it is the only one that matters
/// here: a launch screen that never lifts.**
///
/// [SplashCurtain] is drawn in front of the app's entire bootstrap, so it is
/// the last thing between a person and Shoto. If it fails to leave, the app has
/// not started — and it looks exactly like a hang, on the one screen where a
/// user has no way to tell the difference and no control to press. That is a
/// worse bug than the flicker the curtain was built to fix, and it is
/// introduced by the fix, which is precisely why it is pinned here.
///
/// Everything else about the curtain is a judgement about how it looks and can
/// only be made by eye, on a device. These are the two facts that can be
/// stated: it goes when the app is ready, and not before.
///
/// The native handover is absent by construction — `NativeSplash` only talks to
/// Android, so on a test host it never resolves a rectangle and the curtain
/// takes its own fallback path. That is deliberate rather than a gap: the
/// fallback is what runs on iOS and on any device that answers late, so it is
/// the path most worth knowing still terminates.
void main() {
  const ({Color field, Color ink}) destination = (
    field: AppPalette.canvasLight,
    ink: AppPalette.ink,
  );

  Future<void> pumpCurtain(
    WidgetTester tester, {
    required bool ready,
    required VoidCallback onGone,
  }) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SplashCurtain(
        ready: ready,
        destination: destination,
        onGone: onGone,
      ),
    ),
  );

  /// Runs [frames] real frames of 16ms each.
  ///
  /// **A loop rather than one long `pump`, and the difference is the whole
  /// test.** A single `pump(Duration(seconds: 10))` advances the clock ten
  /// seconds but produces exactly one frame, so a curtain that was stuck
  /// because nothing was driving it would pass just as happily as one that was
  /// correctly waiting. The machinery here is a chain of `endOfFrame` awaits
  /// and two controllers; it only advances if frames actually happen.
  Future<void> beat(WidgetTester tester, int frames) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('lifts once the app behind it is ready', (tester) async {
    bool gone = false;

    await pumpCurtain(tester, ready: false, onGone: () => gone = true);
    // The handover gives up on a rectangle that is never coming, then the mark
    // settles. Neither is instant, and the curtain must not leave during
    // either.
    await beat(tester, 125);
    expect(gone, isFalse);

    await pumpCurtain(tester, ready: true, onGone: () => gone = true);
    await tester.pumpAndSettle();

    expect(
      gone,
      isTrue,
      reason: 'the curtain is the last thing between the user and the app',
    );
  });

  testWidgets('stays up while the app is still starting', (tester) async {
    bool gone = false;

    await pumpCurtain(tester, ready: false, onGone: () => gone = true);
    // Ten seconds of real frames — far longer than the whole choreography. A
    // curtain that left on a timer rather than on the app being ready would put
    // the blank field back, which is the original bug with extra steps.
    await beat(tester, 625);

    expect(gone, isFalse);
  });
}
