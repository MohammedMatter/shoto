import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_sort.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

ScreenshotEntity _shot(String id, DateTime taken, {bool favorite = false}) =>
    ScreenshotEntity(
      asset: AssetEntity(
        id: id,
        typeInt: 1,
        width: 100,
        height: 100,
        createDateSecond: taken.millisecondsSinceEpoch ~/ 1000,
      ),
      isFavorite: favorite,
      folderId: null,
    );

List<String> _ids(List<ScreenshotEntity> items) =>
    items.map((ScreenshotEntity s) => s.id).toList();

void main() {
  final DateTime day = DateTime(2026, 8, 4, 12);

  group('the grid is ordered by the chosen sort', () {
    // Deliberately handed to the state out of order, because that is what the
    // gallery does — the repository returns whatever the OS gave it, and
    // "newest first" cannot mean "however the OS felt today".
    final List<ScreenshotEntity> unordered = <ScreenshotEntity>[
      _shot('b', day.subtract(const Duration(days: 1))),
      _shot('c', day.subtract(const Duration(days: 5))),
      _shot('a', day),
    ];

    test('newest first is the default', () {
      final state = ScreenshotsLoadedState(screenshots: unordered);
      expect(state.sort, LibrarySort.newest);
      expect(_ids(state.visibleScreenshots), <String>['a', 'b', 'c']);
    });

    test('oldest first reverses it', () {
      final state = ScreenshotsLoadedState(
        screenshots: unordered,
        sort: LibrarySort.oldest,
      );
      expect(_ids(state.visibleScreenshots), <String>['c', 'b', 'a']);
    });

    test('the order holds while a filter is on', () {
      // Sorting is applied after narrowing, so a filtered grid is ordered too
      // — it used to be possible for the pills to change the order as a side
      // effect of changing the contents.
      final state = ScreenshotsLoadedState(
        screenshots: <ScreenshotEntity>[
          _shot('old', day.subtract(const Duration(days: 9)), favorite: true),
          _shot('mid', day.subtract(const Duration(days: 2))),
          _shot('new', day, favorite: true),
        ],
        filter: LibraryFilter.favorites,
        sort: LibrarySort.oldest,
      );
      expect(_ids(state.visibleScreenshots), <String>['old', 'new']);
    });
  });

  group('ties', () {
    test('two captures in the same second get a stable order', () {
      // A burst of taps on the shutter produces these, and an unstable
      // comparator makes them swap places on every rebuild.
      final DateTime same = DateTime(2026, 8, 4, 9, 30, 15);
      final state = ScreenshotsLoadedState(
        screenshots: <ScreenshotEntity>[
          _shot('zulu', same),
          _shot('alpha', same),
          _shot('mike', same),
        ],
      );

      final List<String> first = _ids(state.visibleScreenshots);
      final List<String> second = _ids(state.visibleScreenshots);
      expect(first, second);
      expect(first, hasLength(3));
    });

    test('flipping the sort flips the tie-break too', () {
      final DateTime same = DateTime(2026, 8, 4, 9, 30, 15);
      final List<ScreenshotEntity> shots = <ScreenshotEntity>[
        _shot('a', same),
        _shot('b', same),
      ];

      final newest = ScreenshotsLoadedState(screenshots: shots);
      final oldest = ScreenshotsLoadedState(
        screenshots: shots,
        sort: LibrarySort.oldest,
      );
      expect(
        _ids(newest.visibleScreenshots).reversed.toList(),
        _ids(oldest.visibleScreenshots),
      );
    });
  });

  group('the chosen order survives', () {
    test('copyWith keeps it when it is not the thing being changed', () {
      // The bug this guards against shipped once: a reload rebuilt the state
      // without carrying the sort, so any refresh — app resume, a new
      // screenshot arriving — silently put the grid back to newest-first
      // while the header button still claimed otherwise.
      final state = ScreenshotsLoadedState(
        screenshots: const <ScreenshotEntity>[],
        sort: LibrarySort.oldest,
      );
      expect(state.copyWith(filter: LibraryFilter.unsorted).sort,
          LibrarySort.oldest);
      expect(state.copyWith(selectedIds: const <String>{'x'}).sort,
          LibrarySort.oldest);
    });
  });
}
