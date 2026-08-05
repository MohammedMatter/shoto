import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

ScreenshotEntity _shot(String id, {bool favorite = false, int? folder}) {
  return ScreenshotEntity(
    asset: AssetEntity(id: id, typeInt: 1, width: 100, height: 200),
    isFavorite: favorite,
    folderId: folder,
  );
}

/// Four screenshots covering every status, so a lens can be shown to narrow
/// *within* a status rather than replacing it.
ScreenshotsLoadedState _state({
  LibraryFilter filter = LibraryFilter.all,
  ContentTrait? lens,
  Map<String, Set<ContentTrait>> traits = const {},
  bool traitsReady = true,
}) {
  return ScreenshotsLoadedState(
    screenshots: <ScreenshotEntity>[
      _shot('unsorted-link'),
      _shot('unsorted-plain'),
      _shot('fav-link', favorite: true),
      _shot('filed-card', folder: 3),
    ],
    filter: filter,
    lens: lens,
    traits: traits,
    traitsReady: traitsReady,
  );
}

const Map<String, Set<ContentTrait>> _allRead = <String, Set<ContentTrait>>{
  'unsorted-link': {ContentTrait.link},
  'unsorted-plain': <ContentTrait>{},
  'fav-link': {ContentTrait.link},
  'filed-card': {ContentTrait.sensitive},
};

void main() {
  group('the two axes are independent', () {
    test('a lens alone narrows the whole library', () {
      final state = _state(lens: ContentTrait.link, traits: _allRead);
      expect(
        state.visibleScreenshots.map((s) => s.id),
        <String>['unsorted-link', 'fav-link'],
      );
    });

    test('status and lens intersect rather than replace each other', () {
      final state = _state(
        filter: LibraryFilter.unsorted,
        lens: ContentTrait.link,
        traits: _allRead,
      );
      // fav-link has the trait but is not unsorted; unsorted-plain is unsorted
      // but lacks the trait. Only the screenshot satisfying both survives.
      expect(state.visibleScreenshots.map((s) => s.id), <String>[
        'unsorted-link',
      ]);
    });

    test('clearing the lens restores the status slice untouched', () {
      final state = _state(filter: LibraryFilter.favorites, traits: _allRead);
      expect(state.visibleScreenshots.map((s) => s.id), <String>['fav-link']);
    });
  });

  group('trait counts are scoped to the active status', () {
    // A Links pill reading 2 while "Unsorted" is lit and the grid can only
    // ever show 1 of them is a number answering a question nobody asked.
    test('counts follow the status filter', () {
      expect(
        _state(traits: _allRead).traitCount(ContentTrait.link),
        2,
      );
      expect(
        _state(
          filter: LibraryFilter.unsorted,
          traits: _allRead,
        ).traitCount(ContentTrait.link),
        1,
      );
      expect(
        _state(
          filter: LibraryFilter.favorites,
          traits: _allRead,
        ).traitCount(ContentTrait.link),
        1,
      );
    });

    test('a count always matches what the grid would show', () {
      for (final LibraryFilter filter in LibraryFilter.values) {
        for (final ContentTrait trait in ContentTrait.values) {
          final int count = _state(
            filter: filter,
            traits: _allRead,
          ).traitCount(trait);
          final int shown = _state(
            filter: filter,
            lens: trait,
            traits: _allRead,
          ).visibleScreenshots.length;
          expect(
            count,
            shown,
            reason: 'pill count disagrees with the grid for $filter / $trait',
          );
        }
      }
    });
  });

  group('read and never-read are different answers', () {
    // The whole honesty story rests on this: an absent key means nobody has
    // ever recognised that screenshot's text, and reporting it as "no traits"
    // would let an empty grid imply an absence the app cannot vouch for.
    test('an empty set counts as read', () {
      final state = _state(
        traits: const <String, Set<ContentTrait>>{
          'unsorted-plain': <ContentTrait>{},
        },
      );
      expect(state.unreadCount, 3);
    });

    test('a fully unread library reports every screenshot as unread', () {
      expect(_state().unreadCount, 4);
    });

    test('a fully read library reports nothing unread', () {
      expect(_state(traits: _allRead).unreadCount, 0);
    });

    test('an unread screenshot never matches a lens', () {
      final state = _state(
        lens: ContentTrait.link,
        traits: const <String, Set<ContentTrait>>{
          'unsorted-link': {ContentTrait.link},
        },
      );
      expect(state.visibleScreenshots.map((s) => s.id), <String>[
        'unsorted-link',
      ]);
      expect(state.unreadCount, 3);
    });
  });

  group('copyWith', () {
    // A nullable field cannot be cleared by passing null — that is
    // indistinguishable from omitting it — so the clear flag is load-bearing.
    test('clearLens turns the lens off', () {
      final state = _state(lens: ContentTrait.link, traits: _allRead);
      expect(state.copyWith(clearLens: true).lens, isNull);
    });

    test('omitting lens preserves the active one', () {
      final state = _state(lens: ContentTrait.link, traits: _allRead);
      expect(state.copyWith(filter: LibraryFilter.unsorted).lens,
          ContentTrait.link);
    });

    test('traits and readiness survive a status change', () {
      final state = _state(traits: _allRead);
      final next = state.copyWith(filter: LibraryFilter.favorites);
      expect(next.traits, _allRead);
      expect(next.traitsReady, isTrue);
    });
  });
}
