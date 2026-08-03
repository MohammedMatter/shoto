import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/widgets/lazy_indexed_stack.dart';

/// The shell's four tabs used to be built before the app drew its first
/// frame — including the Library grid, which starts decoding thumbnails as it
/// builds, and Settings, which reads the cache directory off disk.
///
/// Both halves of the replacement matter and both are easy to break silently,
/// so both are pinned here: a tab must not be built until it is opened, and it
/// must never be thrown away once it has been.
void main() {
  /// Records every build and every `initState`, so the test can tell "built
  /// again" apart from "rebuilt from scratch".
  final List<String> built = <String>[];
  final List<String> created = <String>[];

  Widget tab(String name) => _Tab(name: name, built: built, created: created);

  setUp(() {
    built.clear();
    created.clear();
  });

  Future<void> pumpAt(WidgetTester tester, int index) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LazyIndexedStack(
          index: index,
          children: [tab('a'), tab('b'), tab('c'), tab('d')],
        ),
      ),
    );
  }

  testWidgets('only the opening tab is built', (tester) async {
    await pumpAt(tester, 0);
    expect(created, ['a']);
  });

  testWidgets('a tab is built the first time it is opened', (tester) async {
    await pumpAt(tester, 0);
    await pumpAt(tester, 2);
    expect(created, ['a', 'c']);
    expect(
      created,
      isNot(contains('b')),
      reason: 'a tab that was skipped over must stay unbuilt',
    );
  });

  testWidgets('a tab that has been opened keeps its state', (tester) async {
    await pumpAt(tester, 0);
    await pumpAt(tester, 2);
    created.clear();
    await pumpAt(tester, 0);
    await pumpAt(tester, 2);

    expect(
      created,
      isEmpty,
      reason:
          'switching back must not re-create a tab — the Folders counts '
          'and the Library scroll position depend on it staying alive',
    );
  });
}

class _Tab extends StatefulWidget {
  final String name;
  final List<String> built;
  final List<String> created;

  const _Tab({required this.name, required this.built, required this.created});

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  @override
  void initState() {
    super.initState();
    widget.created.add(widget.name);
  }

  @override
  Widget build(BuildContext context) {
    widget.built.add(widget.name);
    return Text(widget.name, textDirection: TextDirection.ltr);
  }
}
