import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/widgets/animated_id_grid.dart';

/// The point of these tests is not that the animation looks nice — that can
/// only be judged by eye. It is that the two pieces of state inside
/// [AnimatedIdGrid] never disagree.
///
/// The grid keeps its own item count, and the widget keeps the list it draws
/// from. If a diff ever updates one without the other, `AnimatedGrid` asks for
/// an index that no longer exists and the library screen throws a `RangeError`
/// mid-scroll. That is the failure this file exists to catch, and it is
/// exactly the failure that cannot be reached by tapping through the app.

Widget _host(List<String> items) => MaterialApp(
  home: Scaffold(
    body: AnimatedIdGrid<String>(
      items: items,
      idOf: (item) => item,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemBuilder: (context, item, index, animation) =>
          FadeTransition(opacity: animation, child: Text(item)),
    ),
  ),
);

/// Rebuilds with [items], lets the post-frame diff run, then lets every
/// entrance and exit finish.
Future<void> _settle(WidgetTester tester, List<String> items) async {
  await tester.pumpWidget(_host(items));
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders every item it is given', (tester) async {
    await _settle(tester, ['a', 'b', 'c']);

    expect(find.text('a'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
  });

  testWidgets('a removed item keeps drawing while it animates out', (
    tester,
  ) async {
    await _settle(tester, ['a', 'b', 'c']);

    await tester.pumpWidget(_host(['a', 'c']));
    // The post-frame diff has not run yet: nothing has changed on screen.
    expect(find.text('b'), findsOneWidget);

    await tester.pump();
    // Now it is out of the list but still on screen, animating away. This is
    // the whole feature — without it the tile would simply vanish.
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('b'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('b'), findsNothing);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
  });

  testWidgets('removing the last item does not go out of range', (
    tester,
  ) async {
    await _settle(tester, ['a', 'b', 'c']);
    await _settle(tester, ['a', 'b']);

    expect(tester.takeException(), isNull);
    expect(find.text('c'), findsNothing);
  });

  testWidgets('removing several at once keeps the counts in step', (
    tester,
  ) async {
    await _settle(tester, ['a', 'b', 'c', 'd', 'e']);
    await _settle(tester, ['b', 'd']);

    expect(tester.takeException(), isNull);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('d'), findsOneWidget);
    expect(find.text('a'), findsNothing);
    expect(find.text('e'), findsNothing);
  });

  testWidgets('emptying the grid entirely is safe', (tester) async {
    await _settle(tester, ['a', 'b']);
    await _settle(tester, <String>[]);

    expect(tester.takeException(), isNull);
    expect(find.text('a'), findsNothing);
  });

  testWidgets('a new item arriving at the front is inserted, not reset', (
    tester,
  ) async {
    await _settle(tester, ['b', 'c']);
    await _settle(tester, ['a', 'b', 'c']);

    expect(tester.takeException(), isNull);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
  });

  testWidgets('a removal and an insertion in the same update', (tester) async {
    await _settle(tester, ['b', 'c']);
    await _settle(tester, ['a', 'c']);

    expect(tester.takeException(), isNull);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
    expect(find.text('b'), findsNothing);
  });

  testWidgets('a reorder falls back to an instant rebuild without throwing', (
    tester,
  ) async {
    await _settle(tester, ['a', 'b', 'c']);
    await _settle(tester, ['c', 'b', 'a']);

    expect(tester.takeException(), isNull);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
  });

  testWidgets('a wholesale replacement falls back to an instant rebuild', (
    tester,
  ) async {
    await _settle(tester, ['a', 'b', 'c']);
    await _settle(tester, ['x', 'y']);

    expect(tester.takeException(), isNull);
    expect(find.text('x'), findsOneWidget);
    expect(find.text('y'), findsOneWidget);
    expect(find.text('a'), findsNothing);
  });

  testWidgets('two updates landing before the diff runs do not desync', (
    tester,
  ) async {
    await _settle(tester, ['a', 'b', 'c', 'd']);

    // Both rebuilds happen before the post-frame callback fires, so the diff
    // only ever sees the final list. This is the case that would leave the
    // grid's count describing a list that never existed.
    await tester.pumpWidget(_host(['a', 'b', 'c']));
    await tester.pumpWidget(_host(['a', 'b']));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsNothing);
    expect(find.text('d'), findsNothing);
  });

  testWidgets('same ids with changed data update in place', (tester) async {
    // Identity is the first character; the rest is payload that changes.
    Widget host(List<String> items) => MaterialApp(
      home: Scaffold(
        body: AnimatedIdGrid<String>(
          items: items,
          idOf: (item) => item[0],
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemBuilder: (context, item, index, animation) => Text(item),
        ),
      ),
    );

    await tester.pumpWidget(host(['a1', 'b1']));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(['a2', 'b2']));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('a2'), findsOneWidget);
    expect(find.text('b2'), findsOneWidget);
    expect(find.text('a1'), findsNothing);
  });
}
