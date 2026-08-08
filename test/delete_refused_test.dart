import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/features/duplicates/domain/entities/duplicate_group.dart';
import 'package:shoto/features/duplicates/presentation/bloc/duplicates_state.dart';
import 'package:shoto/features/screenshots/data/data_sources/custom_intents_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/image_labeling_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/library_ownership_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_gallery_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_metadata_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/text_recognition_data_source.dart';
import 'package:shoto/features/screenshots/data/repositories_impl/screenshot_repository_impl.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';

import 'support/fake_gallery.dart';

/// **Refusing a deletion is an answer, not a failure.**
///
/// Tapping Delete on a screenshot raises a system prompt on Android 11+, and
/// that prompt has two buttons. The app used to act on one of them: it
/// released ownership and erased the metadata *before* asking, then discarded
/// what the OS said. Press **Deny** and the picture stayed in the gallery
/// while SHOTO forgot it existed — the folder it was filed in, the favourite,
/// the intent, all gone, for a screenshot the user had just refused to delete.
///
/// Found by pressing Deny once on a device. It is not an edge case: it is one
/// of the two things the system asks the user to choose between.
class _FakeGallery implements ScreenshotGalleryDataSource {
  /// What the system prompt "allows". Empty means the user pressed Deny.
  final List<String> allow;
  int deleteCalls = 0;

  _FakeGallery(this.allow);

  @override
  Future<List<String>> deleteAssets(List<String> ids) async {
    deleteCalls++;
    return ids.where(allow.contains).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _RecordingMetadata implements ScreenshotMetadataLocalDataSource {
  final List<String> erased = <String>[];

  @override
  Future<void> deleteMeta(List<String> assetIds) async =>
      erased.addAll(assetIds);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _RecordingOwnership implements LibraryOwnershipLocalDataSource {
  final List<String> released = <String>[];

  @override
  Future<void> release(Iterable<String> assetIds) async =>
      released.addAll(assetIds);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  ({
    ScreenshotRepositoryImpl repository,
    _RecordingMetadata metadata,
    _RecordingOwnership ownership,
  })
  build(List<String> allow) {
    final _RecordingMetadata metadata = _RecordingMetadata();
    final _RecordingOwnership ownership = _RecordingOwnership();
    return (
      repository: ScreenshotRepositoryImpl(
        _FakeGallery(allow),
        metadata,
        _Unused(),
        ownership,
        _Unused(),
        _Unused(),
      ),
      metadata: metadata,
      ownership: ownership,
    );
  }

  group('a refused delete changes nothing', () {
    test('the ids come back empty', () async {
      final built = build(const <String>[]);

      expect(
        await built.repository.deleteScreenshots(const <String>['a']),
        isEmpty,
      );
    });

    test('the record survives, because the picture did', () async {
      final built = build(const <String>[]);
      await built.repository.deleteScreenshots(const <String>['a']);

      // The two lines that used to run before the question was even asked.
      expect(built.metadata.erased, isEmpty);
      expect(built.ownership.released, isEmpty);
    });
  });

  group('an allowed delete still deletes', () {
    test('the record goes with the file', () async {
      final built = build(const <String>['a']);

      expect(
        await built.repository.deleteScreenshots(const <String>['a']),
        <String>['a'],
      );
      expect(built.metadata.erased, <String>['a']);
      expect(built.ownership.released, <String>['a']);
    });

    test('a partial answer is honoured item by item', () async {
      // Some Android versions prompt per item rather than per batch, so
      // "half of them" is a real answer and the survivors keep their records.
      final built = build(const <String>['a', 'c']);

      expect(
        await built.repository.deleteScreenshots(const <String>['a', 'b', 'c']),
        <String>['a', 'c'],
      );
      expect(built.metadata.erased, <String>['a', 'c']);
      expect(built.ownership.released, isNot(contains('b')));
    });
  });

  group('the duplicates screen reports what went', () {
    DuplicateCandidate candidate(int id, int bytes) => DuplicateCandidate(
      screenshot: ScreenshotEntity(
        asset: FakeGallery.asset(id),
        isFavorite: false,
        folderId: null,
      ),
      fileSizeBytes: bytes,
    );

    DuplicatesLoadedState state() => DuplicatesLoadedState(
      groups: <DuplicateGroup>[
        DuplicateGroup(
          candidates: <DuplicateCandidate>[candidate(1, 1000), candidate(2, 2000)],
          suggestedKeeperId: '1',
        ),
      ],
      selectedIds: const <String>{'1', '2'},
    );

    test('bytes are counted over the ids that were actually removed', () {
      // "Deleted 2 · freed 3 KB" was printed from the selection, so a refused
      // prompt still congratulated the user on storage they never got back.
      expect(state().selectedBytes, 3000);
      expect(state().bytesOf(const <String>{'2'}), 2000);
      expect(state().bytesOf(const <String>{}), 0);
    });
  });
}

/// The three collaborators `deleteScreenshots` never touches. Present only
/// because the constructor asks for them.
class _Unused implements
    CustomIntentsLocalDataSource,
    TextRecognitionDataSource,
    ImageLabelingDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
