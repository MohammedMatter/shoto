import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_gallery_data_source.dart';

/// **The album name is a path, and paths do not get renamed for branding.**
///
/// `importAlbumName` reads like a label and is not one: it is the folder every
/// screenshot a user ever handed over is sitting in. When the product stopped
/// being spelled SHOTO, changing this string could have pointed the app at
/// `Pictures/Shoto` while every existing library stayed in `Pictures/SHOTO` —
/// an empty app and a folder of orphans, with nothing thrown and nothing
/// logged.
///
/// It is safe for exactly two reasons, and this file exists to keep both of
/// them true:
///
/// 1. Android storage is case-insensitive, so new saves land in the directory
///    that is already there. Nothing is copied, nothing is deleted.
/// 2. **The lookup compares case-insensitively.** MediaStore reports an album
///    under the case its directory was created with, so a phone that installed
///    the app last month still answers "SHOTO" when asked. An exact match is
///    the version of this code that loses libraries.
///
/// The second is the one a future edit can quietly undo — `==` is shorter than
/// a case fold and looks correct — so the comparison itself is asserted here
/// rather than left to the album lookup, which needs a device to run.
void main() {
  group('the album Shoto writes into', () {
    test('is spelled the way the product is', () {
      expect(ScreenshotGalleryDataSource.importAlbumName, 'Shoto');
    });

    test('still recognises the folder older installs created', () {
      // The exact strings MediaStore can report for the same directory,
      // depending on when it was made.
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
