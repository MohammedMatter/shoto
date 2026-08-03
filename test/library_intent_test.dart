import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

/// The rules that keep the two guided jobs from bleeding into each other.
///
/// Safe share takes one screenshot and merging takes two or more, and the
/// selection toolbar used to choose its buttons from the **count alone**. So
/// picking a second screenshot while protecting one made the Protect button
/// vanish and a Merge button appear in its place: the app quietly swapped the
/// job the user had asked for, which is exactly how it was reported.
///
/// These are state-level assertions rather than widget ones because that is
/// where the rules actually live now — the toolbar only reads them.
void main() {
  ScreenshotsLoadedState state({
    Set<String> selected = const {},
    LibraryIntent intent = LibraryIntent.none,
  }) => ScreenshotsLoadedState(
    screenshots: const [],
    selectedIds: selected,
    intent: intent,
  );

  group('selection mode', () {
    /// Selection the user starts themselves cannot exist with nothing picked
    /// — a long-press both enters the mode and picks the first tile. A guided
    /// one is the opposite: it exists precisely so the Library can sit waiting
    /// for a choice, which is what makes the prompt possible.
    test('a guided intent puts the Library in selection mode with nothing '
        'picked', () {
      expect(state().isSelectionMode, isFalse);
      expect(state(intent: LibraryIntent.merge).isSelectionMode, isTrue);
      expect(state(intent: LibraryIntent.protect).isSelectionMode, isTrue);
    });
  });

  group('the prompt stays up until the job can actually run', () {
    test('merging asks until two are picked', () {
      const LibraryIntent merge = LibraryIntent.merge;
      expect(state(intent: merge).intentUnsatisfied, isTrue);
      expect(state(selected: {'a'}, intent: merge).intentUnsatisfied, isTrue);
      expect(
        state(selected: {'a', 'b'}, intent: merge).intentUnsatisfied,
        isFalse,
      );
    });

    /// Not "at least one" — **exactly** one. Protecting two screenshots is not
    /// a thing safe share can do, so two has to read as unfinished rather than
    /// as done.
    test('protecting asks until exactly one is picked', () {
      const LibraryIntent protect = LibraryIntent.protect;
      expect(state(intent: protect).intentUnsatisfied, isTrue);
      expect(
        state(selected: {'a'}, intent: protect).intentUnsatisfied,
        isFalse,
      );
      expect(
        state(selected: {'a', 'b'}, intent: protect).intentUnsatisfied,
        isTrue,
      );
    });

    test('selection the user started themselves is never prompted', () {
      expect(state(selected: {'a'}).intentUnsatisfied, isFalse);
      expect(state(selected: {'a', 'b', 'c'}).intentUnsatisfied, isFalse);
    });
  });

  group('isGuided', () {
    test('only a job someone else started counts as guided', () {
      expect(LibraryIntent.none.isGuided, isFalse);
      expect(LibraryIntent.merge.isGuided, isTrue);
      expect(LibraryIntent.protect.isGuided, isTrue);
    });
  });
}
