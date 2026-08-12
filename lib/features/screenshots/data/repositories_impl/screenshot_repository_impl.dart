import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/core/utils/visual_vocabulary.dart';
import 'package:shoto/features/screenshots/data/data_sources/custom_intents_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/image_labeling_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/library_ownership_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_gallery_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_metadata_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/text_recognition_data_source.dart';
import 'package:shoto/features/screenshots/domain/entities/library_summary.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// Joins three things into one library: the images in Shoto's gallery album,
/// which account each of them belongs to, and how that account organized
/// them.
///
/// The ownership join is not an optimisation — it is the only thing making
/// the library per-account at all. The album is a single folder on the
/// device, so every read here goes through [_ownership] before anything
/// reaches the UI.
class ScreenshotRepositoryImpl implements ScreenshotRepository {
  final ScreenshotGalleryDataSource _gallery;
  final ScreenshotMetadataLocalDataSource _metadata;
  final CustomIntentsLocalDataSource _customIntents;
  final LibraryOwnershipLocalDataSource _ownership;
  final TextRecognitionDataSource _textRecognition;
  final ImageLabelingDataSource _imageLabeling;

  ScreenshotRepositoryImpl(
    this._gallery,
    this._metadata,
    this._customIntents,
    this._ownership,
    this._textRecognition,
    this._imageLabeling,
  );

  @override
  Future<PermissionState> requestPermission() => _gallery.requestPermission();

  @override
  Future<PermissionState> checkPermission() => _gallery.checkPermission();

  @override
  Future<List<ScreenshotEntity>> getAllScreenshots() async {
    final List<AssetEntity> assets = await _gallery.getScreenshotAssets();
    await _adoptLegacyLibrary(assets);

    final Set<String> owned = await _ownership.getOwnedAssetIds();
    final List<AssetEntity> mine = assets
        .where((asset) => owned.contains(asset.id))
        .toList();

    return _withMetadata(mine);
  }

  /// Home's numbers, without the gallery.
  ///
  /// Note what is *not* here: no `getScreenshotAssets`, no legacy adoption, no
  /// intersection against the album. This is one indexed read of two local
  /// tables, and it is the whole reason the first frame can carry real content
  /// — see [LibrarySummary].
  ///
  /// The custom-intent table is read only when some row actually points at one.
  /// It is a small table, but this runs on the path that exists to be short,
  /// and the great majority of libraries have no custom verbs in them at all.
  @override
  Future<LibrarySummary> getLibrarySummary() async {
    final List<Map<String, Object?>> rows = await _ownership
        .getOrganizationFacts();
    if (rows.isEmpty) return LibrarySummary.empty;

    final bool hasCustom = rows.any((Map<String, Object?> row) {
      final String? intentId = row['intent'] as String?;
      return intentId != null && IntentRef.isCustomId(intentId);
    });
    final Map<String, CustomIntent> customIntents = hasCustom
        ? <String, CustomIntent>{
            for (final CustomIntent intent
                in await _customIntents.getCustomIntents())
              intent.id: intent,
          }
        : const <String, CustomIntent>{};

    int unsorted = 0;
    final Map<IntentRef, int> waiting = <IntentRef, int>{};

    for (final Map<String, Object?> row in rows) {
      // The two conditions below are `ScreenshotEntity.isUnsorted` and
      // `IntentState.isWaiting` read straight off the columns they are built
      // from. They cannot literally call those getters — an entity needs an
      // `AssetEntity`, which is the gallery read this method exists to skip —
      // so if either definition ever changes, it changes here too.
      final bool isFavorite = (row['is_favorite'] as int?) == 1;
      final int? folderId = row['folder_id'] as int?;
      if (folderId == null && !isFavorite) unsorted++;

      if (row['intent_done_at'] != null) continue;
      final IntentRef? ref = _resolveIntent(
        row['intent'] as String?,
        customIntents,
      );
      if (ref == null) continue;
      waiting.update(ref, (int n) => n + 1, ifAbsent: () => 1);
    }

    final List<MapEntry<IntentRef, int>> ordered = waiting.entries.toList()
      ..sort(
        (MapEntry<IntentRef, int> a, MapEntry<IntentRef, int> b) =>
            IntentRef.pickerOrder(a.key).compareTo(IntentRef.pickerOrder(b.key)),
      );

    return LibrarySummary(
      total: rows.length,
      unsorted: unsorted,
      waiting: Map<IntentRef, int>.fromEntries(ordered),
    );
  }

  /// Imports the images the user hand-picked in the system picker.
  ///
  /// Each one is a file the OS handed over, so this is the same operation as a
  /// screenshot shared into the app — [importSharedFile], copy and all. There is
  /// no gallery id to claim in place: the picker's contract is that the app gets
  /// the picked files and nothing else, which is the entire reason it is used.
  ///
  /// Failures are per file, not per batch. A picker can return an image whose
  /// bytes cannot be read (a cloud-only photo that never downloaded), and
  /// abandoning the other nine because the third failed is the wrong trade for
  /// a bulk action the user is watching.
  ///
  /// The failure is **logged, not swallowed**. This started life as a bare
  /// `catch (_) {}`, which turned every possible cause — no signed-in account,
  /// a gallery write refused by the OS, an unreadable file — into the same
  /// silent zero, and the user got one generic sentence for all of them. A
  /// catch-all that keeps a batch alive is right; one that destroys the reason
  /// is how a bug becomes unfixable.
  @override
  Future<int> importPickedFiles(List<String> filePaths) async {
    int imported = 0;
    for (final String path in filePaths) {
      try {
        await importSharedFile(path);
        imported++;
      } catch (error, stack) {
        debugPrint('Shoto import failed for $path: $error');
        debugPrintStack(stackTrace: stack, maxFrames: 6);
      }
    }
    return imported;
  }

  @override
  Future<List<AssetEntity>> getNewCaptures({required DateTime since}) {
    return _gallery.getDeviceCaptures(since: since);
  }

  /// Keeping a capture is importing it, and it goes through exactly the same
  /// path a picked file does — including the per-file failure handling, which
  /// matters more here: a triage queue is a bulk action the user is watching,
  /// and one unreadable capture must not end the review.
  ///
  /// The asset's file is resolved rather than its bytes read here, because
  /// `importSharedFile` already owns what an import *is* — the copy, the
  /// ownership row, the metadata. A second implementation of that, for a
  /// second entry point, is how two entry points start disagreeing about what
  /// is in the library.
  @override
  Future<int> keepCaptures(List<String> assetIds) async {
    final List<AssetEntity> assets = await _gallery.getAssetsByIds(assetIds);

    final List<String> paths = [];
    for (final AssetEntity asset in assets) {
      final File? file = await asset.originFile;
      if (file != null) paths.add(file.path);
    }

    return importPickedFiles(paths);
  }

  @override
  Future<List<ScreenshotEntity>> getScreenshotsByFolder(int folderId) async {
    // The ids come from this account's own metadata rows, so they are already
    // its screenshots — but the intersection below still runs, so a stale
    // metadata row can never put someone else's picture on screen.
    final List<String> assetIds = await _metadata.getAssetIdsInFolder(folderId);
    return getScreenshotsByIds(assetIds);
  }

  @override
  Future<List<ScreenshotEntity>> getScreenshotsByIds(
    List<String> assetIds,
  ) async {
    if (assetIds.isEmpty) return const [];

    final Set<String> owned = await _ownership.getOwnedAssetIds();
    final List<String> mineIds = assetIds
        .where((id) => owned.contains(id))
        .toList();
    if (mineIds.isEmpty) return const [];

    final List<AssetEntity> assets = await _gallery.getAssetsByIds(mineIds);
    return _withMetadata(assets);
  }

  @override
  Stream<void> get onLibraryChanged => _gallery.changes;

  @override
  Future<void> setFavorite(String assetId, bool isFavorite) =>
      _metadata.setFavorite(assetId, isFavorite);

  @override
  Future<void> setIntent(
    String assetId,
    IntentRef? intent, {
    DateTime? doneAt,
  }) => _metadata.setIntent(<String>[assetId], intent?.id, doneAt: doneAt);

  @override
  Future<void> setIntents(List<String> assetIds, IntentRef? intent) =>
      _metadata.setIntent(assetIds, intent?.id);

  @override
  Future<List<CustomIntent>> getCustomIntents() =>
      _customIntents.getCustomIntents();

  @override
  Future<int> getCustomIntentCount() => _customIntents.countCustomIntents();

  @override
  Future<CustomIntent> createCustomIntent({
    required String label,
    required String iconKey,
  }) => _customIntents.createCustomIntent(label: label, iconKey: iconKey);

  @override
  Future<void> updateCustomIntent({
    required String id,
    required String label,
    required String iconKey,
  }) =>
      _customIntents.updateCustomIntent(id: id, label: label, iconKey: iconKey);

  @override
  Future<void> deleteCustomIntent(String id) =>
      _customIntents.deleteCustomIntent(id);

  @override
  Future<List<String>> getIntentIdsByRecentUse() =>
      _customIntents.getIntentIdsByRecentUse();

  @override
  Future<void> setIntentDone(String assetId, bool isDone) =>
      _metadata.setIntentDone(assetId, isDone);

  @override
  Future<void> assignFolder(List<String> assetIds, int? folderId) =>
      _metadata.assignFolder(assetIds, folderId);

  /// Deletes what the OS lets it delete, and returns exactly that.
  ///
  /// **The gallery is asked first, and its answer decides the rest.** On
  /// Android 11+ the delete is a system prompt the app cannot see the outcome
  /// of in advance; `deleteWithIds` returns the ids that actually went. This
  /// used to release ownership and erase the metadata *before* asking, and
  /// then ignore the answer — so tapping Delete and pressing **Deny** left the
  /// picture on the phone and threw away everything Shoto knew about it. The
  /// user refused a deletion and lost the folder it was filed in, the
  /// favourite, the intent, for a screenshot still sitting in their gallery.
  ///
  /// Refusing is not an error and is not rare: it is one of the two buttons
  /// the system offers, and it means "leave it alone" — which has to include
  /// leaving the record alone.
  ///
  /// Every file a library holds is one Shoto wrote into its own album —
  /// importing copies, it never claims a picture where it already sits — so
  /// there is no case here where this reaches a file the app didn't create.
  ///
  /// This used to also check whether a *second account on the same phone*
  /// still had the image, and skip the file delete if so. There are no
  /// second accounts any more: the library belongs to the device, so
  /// leaving it and erasing the file are now the same decision.
  @override
  Future<List<String>> deleteScreenshots(List<String> assetIds) async {
    final List<String> deleted = await _gallery.deleteAssets(assetIds);
    if (deleted.isEmpty) return const <String>[];

    // Scoped to what went, not to what was asked for. A partial result is
    // possible — the system prompt is per-batch on some versions and per-item
    // on others — and the ones that survived must keep their records.
    await _ownership.release(deleted);
    await _metadata.deleteMeta(deleted);
    return deleted;
  }

  @override
  Future<String> importSharedFile(
    String filePath, {
    String? sourceAssetId,
  }) async {
    if (sourceAssetId != null && await _gallery.isInOurAlbum(sourceAssetId)) {
      // The file is already in Shoto's album, put there by another account
      // (or by this one before it was signed in). Copying it would leave two
      // identical pictures in the user's gallery for no reason, so this
      // account just takes it into its own library as it stands.
      await _ownership.claim([sourceAssetId]);
      return sourceAssetId;
    }

    final AssetEntity asset = await _gallery.saveSharedImage(filePath);
    await _ownership.claim([asset.id]);
    return asset.id;
  }

  @override
  Future<String> saveGeneratedImage(
    Uint8List bytes, {
    required String filename,
    DateTime? createdAt,
  }) async {
    final AssetEntity asset = await _gallery.saveImageBytes(
      bytes,
      filename: filename,
      creationDate: createdAt,
    );
    await _ownership.claim([asset.id]);
    return asset.id;
  }

  @override
  Future<String?> findLibraryAsset(String assetId) async {
    if (!await _ownership.owns(assetId)) return null;
    // Owned but no longer on disk means the file was removed outside Shoto;
    // treating that as "already here" would leave the user unable to re-add
    // a screenshot the app can't actually show them.
    return await _gallery.isInOurAlbum(assetId) ? assetId : null;
  }

  @override
  Future<int> getManagedScreenshotCount() => _metadata.getManagedCount();

  @override
  Future<Map<String, String>> getCachedOcrText() => _metadata.getAllOcrText();

  @override
  Future<String> extractAndCacheText(ScreenshotEntity screenshot) async {
    final File? imageFile = await screenshot.asset.file;
    if (imageFile == null) return '';
    final String text = await _textRecognition.recognizeText(imageFile);
    await _metadata.saveOcrText(screenshot.id, text);
    return text;
  }

  @override
  /// Cached labels, with the medium-describing ones stripped on the way out.
  ///
  /// Filtering here rather than only at the point of use gives a free
  /// migration. Libraries indexed by the first version of the labeler are
  /// full of rows reading `["Screenshot"]` or `["Mobile phone","Screenshot"]`
  /// — technically cached, entirely useless. After filtering those come back
  /// empty, and every caller already treats "no labels" as "not read yet", so
  /// each one gets re-read once with the current labeler and its result
  /// replaces the junk. No migration script, no version flag.
  Future<Map<String, List<String>>> getCachedVisualLabels() async {
    final Map<String, List<String>> stored = await _metadata
        .getAllVisualLabels();
    return {
      for (final MapEntry<String, List<String>> entry in stored.entries)
        entry.key: VisualVocabulary.meaningful(entry.value),
    };
  }

  @override
  Future<List<String>> extractAndCacheLabels(
    ScreenshotEntity screenshot,
  ) async {
    final File? imageFile = await screenshot.asset.file;
    if (imageFile == null) return const [];
    final List<String> labels = await _imageLabeling.label(imageFile);
    // Written even when empty — see saveVisualLabels: otherwise a screenshot
    // the model finds nothing in is re-processed on every visit to search.
    await _metadata.saveVisualLabels(screenshot.id, labels);
    return labels;
  }

  @override
  Future<Map<String, String>> getCachedPerceptualHashes() =>
      _metadata.getAllPerceptualHashes();

  @override
  Future<void> cachePerceptualHashes(Map<String, String> hashesByAssetId) =>
      _metadata.savePerceptualHashes(hashesByAssetId);

  Future<List<ScreenshotEntity>> _withMetadata(List<AssetEntity> assets) async {
    if (assets.isEmpty) return const [];
    final Map<String, Map<String, Object?>> metaMap = await _metadata
        .getAllMeta();
    // Read once for the whole library rather than per screenshot. There are a
    // handful of these and thousands of screenshots, and the alternative is a
    // query per row on the app's first screen.
    final Map<String, CustomIntent> customIntents = <String, CustomIntent>{
      for (final CustomIntent intent in await _customIntents.getCustomIntents())
        intent.id: intent,
    };
    return assets
        .map(
          (AssetEntity asset) =>
              _toEntity(asset, metaMap[asset.id], customIntents),
        )
        .toList();
  }

  /// Hands the images that predate ownership to this device's library.
  ///
  /// Those images were imported when nothing recorded who imported them, so
  /// there is no honest way to attribute them — and dropping them would look
  /// exactly like the app losing the user's library. Anything the migration
  /// could already attribute (favorited or filed, so `screenshot_meta` names
  /// it) is skipped, and the whole step runs at most once per device.
  Future<void> _adoptLegacyLibrary(List<AssetEntity> albumAssets) async {
    if (albumAssets.isEmpty) return;
    if (!await _ownership.hasPendingLegacyAdoption()) return;

    final Set<String> alreadyOwned = await _ownership
        .getAssetIdsOwnedByAnyone();
    final List<String> unclaimed = albumAssets
        .map((asset) => asset.id)
        .where((id) => !alreadyOwned.contains(id))
        .toList();

    await _ownership.claim(unclaimed);
    await _ownership.markLegacyAdoptionDone();
  }

  /// The verb a stored `screenshot_meta.intent` names, or null.
  ///
  /// An unresolvable id yields no intent rather than a guess. That covers a
  /// value written by a newer build, and also a custom intent this account has
  /// since deleted — deletion clears the references itself, so reaching this
  /// with a `c:` id means the two are momentarily out of step, and "none set"
  /// is the honest reading of that, not whichever constant happens to sit first
  /// in the enum.
  ///
  /// Its own method because [getLibrarySummary] resolves the same column
  /// without ever building an entity, and Home draws one straight after the
  /// other — two readings of one string is exactly how the count shown for a
  /// custom verb would come out different in the two frames.
  IntentRef? _resolveIntent(
    String? intentId,
    Map<String, CustomIntent> customIntents,
  ) {
    if (intentId == null) return null;
    if (IntentRef.isCustomId(intentId)) return customIntents[intentId];
    return switch (ScreenshotIntent.fromId(intentId)) {
      final ScreenshotIntent intent => BuiltInIntent(intent),
      null => null,
    };
  }

  ScreenshotEntity _toEntity(
    AssetEntity asset,
    Map<String, Object?>? meta,
    Map<String, CustomIntent> customIntents,
  ) {
    final IntentRef? ref = _resolveIntent(
      meta?['intent'] as String?,
      customIntents,
    );
    final int? doneAt = meta?['intent_done_at'] as int?;

    return ScreenshotEntity(
      asset: asset,
      isFavorite: (meta?['is_favorite'] as int?) == 1,
      folderId: meta?['folder_id'] as int?,
      intent: ref == null
          ? null
          : IntentState(
              ref: ref,
              doneAt: doneAt == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(doneAt),
            ),
    );
  }
}
