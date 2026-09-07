import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/theme/app_motion.dart';

/// Pins down the behaviour behind a bug that has now been reported twice:
/// scrolling the Settings page made it shudder.
///
/// The mechanism is not obvious and is worth stating, because the first fix
/// addressed the wrong half of it. Press feedback inside a scrollable is
/// *speculative* — the framework reports a press before it can know whether
/// the finger is tapping or about to drag, then withdraws it when the drag
/// wins. A delay only moves the threshold: rest a finger for a beat first, as
/// people do at the end of a long page, and the press still lands and is
/// still withdrawn. The fix is to make the withdrawal invisible, which means
/// full-width rows must not answer a press by changing *size*.
void main() {
  Widget list({
    required PressFeedback feedback,
    void Function(int)? onTap,
    ScrollController? controller,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          controller: controller,
          itemCount: 30,
          itemBuilder: (context, i) => PressableScale(
            feedback: feedback,
            scale: 0.985,
            haptic: false,
            onTap: () => onTap?.call(i),
            child: Container(
              key: ValueKey<int>(i),
              height: 70,
              color: Colors.grey,
              alignment: Alignment.center,
              child: Text('row $i'),
            ),
          ),
        ),
      ),
    );
  }

  Finder row(int i) => find.byKey(ValueKey<int>(i));

  /// Holds a still finger long enough for the press to be reported *and* for
  /// the implicit animation it triggers to actually run — a single long
  /// `pump` advances the clock but only builds one frame, so an
  /// AnimatedScale would still be at its starting value and every assertion
  /// about size would pass for the wrong reason.
  Future<void> holdStill(WidgetTester tester) async {
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('a highlighted row never changes size under a press', (
    tester,
  ) async {
    await tester.pumpWidget(list(feedback: PressFeedback.highlight));

    final Rect atRest = tester.getRect(row(2));

    // A finger lands and rests before dragging — the case a delay cannot
    // cover, and the one that produced the report.
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(row(2)),
    );
    await holdStill(tester);
    expect(
      tester.getRect(row(2)),
      atRest,
      reason: 'the row must not move while pressed',
    );

    for (int step = 0; step < 6; step++) {
      await gesture.moveBy(const Offset(0, -6));
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        tester.getRect(row(2)).size,
        atRest.size,
        reason: 'the row must not resize as the drag takes over',
      );
    }

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('scaling under the same gesture is what used to shudder', (
    tester,
  ) async {
    await tester.pumpWidget(list(feedback: PressFeedback.scale));

    final Size atRest = tester.getRect(row(2)).size;
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(row(2)),
    );
    await holdStill(tester);

    // Documents the difference rather than asserting the old behaviour is
    // gone: scale feedback is still correct for buttons, chips and
    // thumbnails, which is why it is still the default.
    expect(tester.getRect(row(2)).size.width, lessThan(atRest.width));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a press never begins on a list that is already moving', (
    tester,
  ) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      list(feedback: PressFeedback.scale, controller: controller),
    );

    await tester.fling(find.byType(ListView), const Offset(0, -400), 1200);
    await tester.pump(const Duration(milliseconds: 60));
    expect(controller.position.isScrollingNotifier.value, isTrue);

    // The finger that stops a fling is not pressing anything.
    final Size before = tester.getRect(row(8)).size;
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(row(8)),
    );
    await holdStill(tester);
    expect(tester.getRect(row(8)).size, before);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('off a scrollable, a press is answered on the next frame', (
    tester,
  ) async {
    // The delay above exists to hide a withdrawal that only a scrollable can
    // cause. A row on a bottom sheet, a button in a dialog, a tile in a plain
    // `Column`: nothing can take the gesture away, so there is nothing to hide
    // and the wait is 55ms of a touched control looking untouched. That is
    // most of what "sluggish" means for a tap target, and every control in the
    // app that is not in a list was paying it.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PressableScale(
              scale: 0.9,
              haptic: false,
              onTap: () {},
              child: const SizedBox(
                key: ValueKey<String>('lone'),
                height: 70,
                width: 200,
              ),
            ),
          ),
        ),
      ),
    );

    final Finder lone = find.byKey(const ValueKey<String>('lone'));
    final Size atRest = tester.getRect(lone).size;

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(lone),
    );
    // One frame to report the press, then the length of the press animation.
    await tester.pump();
    await tester.pump(AppMotion.press);

    expect(
      tester.getRect(lone).size.width,
      lessThan(atRest.width),
      reason: 'a control with nothing to lose the gesture to must not wait',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a highlighted row still reports its tap', (tester) async {
    final List<int> tapped = [];
    await tester.pumpWidget(
      list(feedback: PressFeedback.highlight, onTap: tapped.add),
    );

    await tester.tap(row(3));
    await tester.pumpAndSettle();
    expect(tapped, [3]);
  });
}
