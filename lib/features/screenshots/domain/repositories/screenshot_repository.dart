import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';

/// Everything here is scoped to the signed-in account.
///
/// The screenshots live in one album shared by the whole device, so "the
/// library" is not what is on disk — it is what the current account has put
/// there. Reads return only that account's screenshots and writes only ever
/// affect that account, which is what keeps two people signing in on the
/// same phone from seeing each other's pictures.
abstract class ScreenshotRepository {
  /// May show the system permission dialog.
  Future<PermissionState> requestPermission();

  /// Reads the current permission without prompting — the only variant safe
  /// to call from an app-lifecycle listener.
  Future<PermissionState> checkPermission();
  Future<List<ScreenshotEntity>> getAllScreenshots();
  Future<List<ScreenshotEntity>> getScreenshotsByFolder(int folderId);
  Stream<void> get onLibraryChanged;
  Future<void> setFavorite(String assetId, bool isFavorite);
  Future<void> assignFolder(List<String> assetIds, int? folderId);

  Future<void> deleteScreenshots(List<String> assetIds);

  /// The screenshots with these ids that belong to the current account,
  /// in the order given. Ids the account doesn't own are simply absent.
  Future<List<ScreenshotEntity>> getScreenshotsByIds(List<String> assetIds);

  /// Saves a shared file into the current account's library and returns the
  /// id of the resulting asset.
  ///
  /// [sourceAssetId] is the gallery id the file came from, when the caller
  /// knows it. If that image is already sitting in SHOTO's album — because
  /// another account imported it — it is added to this account's library as
  /// it stands instead of a second identical file being written.
  Future<String> importSharedFile(String filePath, {String? sourceAssetId});

  /// Imports files the user hand-picked in the operating system's photo picker,
  /// and returns how many actually landed.
  ///
  /// The app does not choose these and does not browse for them: the OS shows
  /// the user their own photos and hands back only what was picked. Each file is
  /// then the same case as a screenshot shared in — see [importSharedFile].
  ///
  /// The count can be lower than [filePaths].length. An individual file can fail
  /// to import (an image the OS listed but cannot produce bytes for, typically
  /// one that lives in the cloud and never downloaded), and one of those must
  /// not take the rest of the batch down with it.
  Future<int> importPickedFiles(List<String> filePaths);

  /// Saves image bytes SHOTO produced itself (a stitched long screenshot,
  /// for instance) into the current account's library.
  Future<String> saveGeneratedImage(
    Uint8List bytes, {
    required String filename,
  });

  /// The id of the screenshot the *current account's* library already holds
  /// for [assetId], or null.
  ///
  /// Used by the share sheet to tell "a screenshot already in your SHOTO"
  /// apart from "an image to import". Without it, sharing your own screenshot
  /// back into SHOTO wrote a duplicate of something already on screen — and
  /// scoping it per account matters just as much, since an image another
  /// account imported is not yet in yours.
  Future<String?> findLibraryAsset(String assetId);

  /// Count of distinct screenshots ever favorited or filed into a folder —
  /// backs the free-tier 50-screenshot management cap.
  Future<int> getManagedScreenshotCount();

  /// Every asset id that already has OCR'd text cached, for search.
  Future<Map<String, String>> getCachedOcrText();

  /// Runs on-device OCR for [screenshot] and caches the result. Premium
  /// feature — callers are responsible for checking entitlement first.
  Future<String> extractAndCacheText(ScreenshotEntity screenshot);

  /// What an on-device vision model saw in each screenshot, keyed by asset
  /// id. Lets search reach pictures with no readable text in them — a photo
  /// of a cat has nothing for OCR to find.
  ///
  /// An entry present but empty means "looked, saw nothing confidently";
  /// absent means "never looked".
  Future<Map<String, List<String>>> getCachedVisualLabels();

  /// Runs the vision model over [screenshot] and caches what it saw. Premium,
  /// same as the OCR pair above.
  Future<List<String>> extractAndCacheLabels(ScreenshotEntity screenshot);

  /// Perceptual hashes cached by a previous duplicate scan, keyed by asset
  /// id. Same caching pattern as [getCachedOcrText].
  Future<Map<String, String>> getCachedPerceptualHashes();

  Future<void> cachePerceptualHashes(Map<String, String> hashesByAssetId);
}
