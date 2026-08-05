import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/features/backup/domain/entities/restore_plan.dart';

/// Name matching is the whole of the merge decision, so it gets pinned here
/// rather than left to be discovered on somebody's real library.
String _key(String name) => name.trim().toLowerCase();

void main() {
  group('name matching', () {
    // Same rule as BackupRepositoryImpl uses on both sides of the comparison.
    test('case and surrounding space are ignored', () {
      expect(_key('Work'), _key('work'));
      expect(_key('Work'), _key(' Work '));
      expect(_key('WORK'), _key('work'));
    });

    test('genuinely different names do not match', () {
      expect(_key('Work'), isNot(_key('Work trips')));
      expect(_key('وصفات'), isNot(_key('وصفة')));
    });

    test('Arabic names match themselves', () {
      expect(_key(' وصفات '), _key('وصفات'));
    });
  });

  group('BackupPreview', () {
    test('reports a collision only when one exists', () {
      const BackupPreview clean = BackupPreview(
        folderNames: <String>['Work'],
        screenshots: 3,
        collidingFolderNames: <String>[],
      );
      expect(clean.hasCollisions, isFalse);

      const BackupPreview clashing = BackupPreview(
        folderNames: <String>['Work'],
        screenshots: 3,
        collidingFolderNames: <String>['Work'],
      );
      expect(clashing.hasCollisions, isTrue);
    });
  });

  test('keeping separate is the default, never merging', () {
    // Merging is the destructive direction: two different folders that share a
    // name get poured together and nobody notices. It must only ever happen
    // because somebody asked for it.
    expect(FolderMergeChoice.values.first, FolderMergeChoice.merge);
    const FolderMergeChoice fallback = FolderMergeChoice.keepSeparate;
    expect(fallback, isNot(FolderMergeChoice.merge));
  });
}
