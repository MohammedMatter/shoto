import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/utils/visual_vocabulary.dart';
import 'package:shoto/features/screenshots/data/data_sources/image_labeling_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/library_ownership_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_gallery_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_metadata_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/text_recognition_data_source.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// Joins three things into one library: the images in SHOTO's gallery album,
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
  final LibraryOwnershipLocalDataSource _ownership;
  final TextRecognitionDataSource _textRecognition;
  final ImageLabelingDataSource _imageLabeling;

  ScreenshotRepositoryImpl(
    this._gallery,
    this._metadata,
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
        debugPrint('SHOTO import failed for $path: $error');
        debugPrintStack(stackTrace: stack, maxFrames: 6);
      }
    }
    return imported;
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
  Future<void> assignFolder(List<String> assetIds, int? folderId) =>
      _metadata.assignFolder(assetIds, folderId);

  @override
  Future<void> deleteScreenshots(List<String> assetIds) async {
    // Leaving the library is always allowed; erasing the file is not. The
    // image is one file in a shared gallery, so it is only really deleted
    // once nobody else on this device still has it in their library.
    //
    // Every file a library holds is one SHOTO wrote into its own album —
    // importing copies, it never claims a picture where it already sits — so
    // there is no case here where this reaches a file the app didn't create.
    await _ownership.release(assetIds);
    final Set<String> keptByOthers = await _ownership.ownedByOthers(assetIds);
    final List<String> removable = assetIds
        .where((id) => !keptByOthers.contains(id))
        .toList();

    if (removable.isNotEmpty) {
      await _gallery.deleteAssets(removable);
    }
    // Always drops this account's rows, never anyone else's — deleteMeta is
    // itself user-scoped.
    await _metadata.deleteMeta(assetIds);
  }

  @override
  Future<String> importSharedFile(
    String filePath, {
    String? sourceAssetId,
  }) async {
    if (sourceAssetId != null && await _gallery.isInOurAlbum(sourceAssetId)) {
      // The file is already in SHOTO's album, put there by another account
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
    // Owned but no longer on disk means the file was removed outside SHOTO;
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
    return assets.map((asset) => _toEntity(asset, metaMap[asset.id])).toList();
  }

  /// Hands the images that predate ownership to the first account that opens
  /// the library after upgrading.
  ///
  /// Those images were imported when nothing recorded who imported them, so
  /// there is no honest way to attribute them — and dropping them would look
  /// exactly like the app losing the user's library. Anything the migration
  /// could already attribute (favorited or filed, so `screenshot_meta` names
  /// the account) is skipped, and the whole step runs at most once per
  /// device: every later account starts with an empty library, which is the
  /// behaviour this is all in aid of.
  Future<void> _adoptLegacyLibrary(List<AssetEntity> albumAssets) async {
    if (albumAssets.isEmpty || !_ownership.hasSignedInUser) return;
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

  ScreenshotEntity _toEntity(AssetEntity asset, Map<String, Object?>? meta) {
    return ScreenshotEntity(
      asset: asset,
      isFavorite: (meta?['is_favorite'] as int?) == 1,
      folderId: meta?['folder_id'] as int?,
    );
  }
}
