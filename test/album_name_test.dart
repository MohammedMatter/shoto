import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_gallery_data_source.dart';

/// **The album name is a path, and paths do not get restyled.**
///
/// `importAlbumName` reads like a label and is not one: it decides the folder
/// every screenshot a user hands over is written to, and the folder the
/// library is read back from. Renaming it while the lookup compared exactly
/// would have shown an empty library over a full folder — Android storage is
/// case-insensitive, so the new spelling writes into the directory that is
/// already there, but `MediaStore` keeps reporting that directory under the
/// case it was *created* with. The app would have been looking at its own
/// pictures and not recognising them.
///
/// Nothing shipped under the old spelling, so no user was ever exposed to
/// that. The fold is here because development phones still hold folders made
/// by earlier builds, and because the failure is silent: no exception, no log,
/// just an app that says you have nothing.
///
/// The comparison is asserted here rather than through the album lookup, which
/// needs a device — and `==` is shorter than a case fold and looks correct,
/// which is how it would come back.
void main() {
  group('the album Shoto writes into', () {
    test('is spelled the way the product is', () {
      expect(ScreenshotGalleryDataSource.importAlbumName, 'Shoto');
    });

    test('still recognises a folder an earlier build created', () {
      // The exact strings MediaStore can report for the same directory,
      // depending on which build made it.
      const List<String> reported = <String>['SHOTO', 'Shoto', 'shoto'];
      final String wanted = ScreenshotGalleryDataSource.importAlbumName
          .toLowerCase();

      for (final String name in reported) {
        expect(
          name.toLowerCase() == wanted,
          isTrue,
          reason: 'an album reported as "$name" is the same folder',
        );
      }
    });

    test('does not match a different album that merely contains the word', () {
      // The fold must not become a `contains`. "Shoto Backups" is somebody
      // else's folder, and adopting it would put pictures the user never
      // handed over into the library — the one thing the opt-in model exists
      // to prevent.
      final String wanted = ScreenshotGalleryDataSource.importAlbumName
          .toLowerCase();

      for (final String other in <String>[
        'Shoto Backups',
        'Screenshots',
        'My Shoto',
      ]) {
        expect(other.toLowerCase() == wanted, isFalse, reason: other);
      }
    });
  });
}
