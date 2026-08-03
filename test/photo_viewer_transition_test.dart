import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/routes/photo_viewer_route.dart';
import 'package:shoto/core/widgets/photo_hero.dart';

/// What this pins down is the *geometry* of opening a screenshot: that the
/// page itself does not travel while the picture does, and that the picture's
/// corner opens out over the flight rather than squaring off on the first
/// frame.
///
/// Both are things an assertion can see and a person looking at a 280ms
/// animation cannot reliably describe, which is exactly the split worth
/// automating — the *feel* still has to be judged on a phone.
void main() {
  const Key destKey = Key('viewer-photo');
  const Key sourceKey = Key('grid-tile');
  const double tileRadius = 18;

  Widget harness() => MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: GestureDetector(
            key: const Key('tile-tap'),
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              PhotoViewerRoute(
                builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: PhotoHero(
                      tag: 'photo',
                      child: SizedBox(
                        key: destKey,
                        width: 300,
                        height: 600,
                        child: const ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            child: const PhotoHero(
              tag: 'photo',
              radius: tileRadius,
              child: SizedBox(key: sourceKey, width: 100, height: 100),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('the picture lands exactly where it settles', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.byKey(const Key('tile-tap')));
    await tester.pump();

    late Rect lastFlightFrame;
    for (int i = 0; i < 7; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      lastFlightFrame = tester.getRect(find.byKey(destKey));
    }
    await tester.pumpAndSettle();

    // No jump on the handover from the flying picture to the real one.
    expect(lastFlightFrame, tester.getRect(find.byKey(destKey)));
  });

  testWidgets('the viewer page fades without travelling', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.byKey(const Key('tile-tap')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    // The page is mid-transition: the black surround is on its way in...
    final double midOpacity = tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.byType(Scaffold).last,
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;
    expect(midOpacity, greaterThan(0));
    expect(midOpacity, lessThan(1));

    // ...and the page it belongs to is already exactly where it will stay. A
    // sliding page would put a second, unrelated translation under a picture
    // that is already moving.
    final Rect midPage = tester.getRect(find.byType(Scaffold).last);
    await tester.pumpAndSettle();
    expect(midPage, tester.getRect(find.byType(Scaffold).last));
  });

  testWidgets('the corner opens out over the flight', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.byKey(const Key('tile-tap')));
    await tester.pump();

    double flyingRadius() {
      final ClipRRect clip = tester.widget<ClipRRect>(
        find
            .ancestor(of: find.byKey(destKey), matching: find.byType(ClipRRect))
            .first,
      );
      return (clip.borderRadius as BorderRadius).topLeft.x;
    }

    // Starts at the tile's own radius rather than at a square corner...
    await tester.pump(const Duration(milliseconds: 1));
    expect(flyingRadius(), closeTo(tileRadius, 0.5));

    // ...and has opened out by the time the picture is most of the way there.
    await tester.pump(const Duration(milliseconds: 200));
    final double late = flyingRadius();
    expect(late, lessThan(tileRadius / 2));
    expect(late, greaterThanOrEqualTo(0));
  });
}
