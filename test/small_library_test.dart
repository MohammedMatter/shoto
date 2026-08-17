import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

import 'support/fake_gallery.dart';

/// **A control that cannot change what you see is not a control.**
///
/// The Library drew its three status pills unconditionally, so a fresh install
/// opened on `All · 0`, `Unsorted · 0`, `Favorites · 0` — the widest row on the
/// screen, spending itself on the answer "nothing", three times, directly above
/// an empty state that had already said so. With one screenshot it was no
/// better: every pill described the same single picture.
///
/// The rule is derived rather than thresholded. "Show them past four
/// screenshots" is a number somebody has to defend later and nobody can; this
/// asks the question the row exists to answer — *would any of these show me
/// something different?* — so the row appears exactly when the user has made
/// the first distinction it could act on, and never before.
ScreenshotEntity _shot(int id, {bool favorite = false, int? folder}) =>
    ScreenshotEntity(
      asset: FakeGallery.asset(id),
      isFavorite: favorite,
      folderId: folder,
    );

ScreenshotsLoadedState _library(List<ScreenshotEntity> items) =>
    ScreenshotsLoadedState(screenshots: items);

void main() {
  group('the filter row stays out of the way until it can do something', () {
    test('an empty library offers nothing to narrow', () {
      expect(_library(const []).filtersWouldNarrow, isFalse);
    });

    test('a library where everything is unsorted offers nothing either', () {
      // Every pill would show the same three pictures, and Favorites would
      // show none. Three chips, one answer.
      expect(
        _library([_shot(1), _shot(2), _shot(3)]).filtersWouldNarrow,
        isFalse,
      );
    });

    test('filing one screenshot is the first distinction', () {
      // `isUnsorted` is false once a screenshot has a folder, so Unsorted and
      // All now differ — which is the moment the row starts answering a real
      // question.
      expect(
        _library([_shot(1, folder: 7), _shot(2)]).filtersWouldNarrow,
        isTrue,
      );
    });

    test('favouriting one is the other', () {
      expect(
        _library([_shot(1, favorite: true), _shot(2)]).filtersWouldNarrow,
        isTrue,
      );
    });

    test('a single favourited screenshot counts, small as it is', () {
      // Not a size rule. One favourite in a library of one still means the
      // Favorites pill and the All pill say different things.
      expect(_library([_shot(1, favorite: true)]).filtersWouldNarrow, isTrue);
    });
  });
}
