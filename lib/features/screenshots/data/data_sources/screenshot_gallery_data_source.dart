import 'dart:async';

import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

/// Owns SHOTO's own album — and, only when the user has switched it on, reads
/// the device's Screenshots album to *offer* what is new.
///
/// **The library is still opt-in and nothing here changes that.** SHOTO used
/// to list every screenshot on the phone automatically, which made the library
/// a mirror of the gallery; that was reversed on purpose, and a screenshot
/// still only enters SHOTO when the user hands it over. [getScreenshotAssets]
/// — the one method the library is built on — reads [importAlbumName] and
/// nothing else.
///
/// "Hands it over" is now three things:
///
/// * the share sheet;
/// * the **manual import button**, which opens the operating system's own
///   picker, so the OS shows the user their photos and gives the app only the
///   files that were picked;
/// * the **triage queue** — [getDeviceCaptures] — which lists captures newer
///   than a watermark so the user can keep or skip each one.
///
/// The third is the one that needed a decision, because it does enumerate
/// pictures the user has not chosen yet, and that is what the opt-in reversal
/// was about. It is defensible on three conditions, all of which the code
/// upholds:
///
/// 1. **It is off until switched on**, and the switch is a question the app
///    asks in plain words (see `AppPreferences.triageEnabled`).
/// 2. **Nothing enters the library implicitly.** Keeping a capture runs the
///    same import a picked file runs. Skipping one moves a watermark and
///    touches nothing.
/// 3. **It never deletes or modifies anything in the gallery**, and it reads
///    only the Screenshots album — not the camera roll, not everything.
///
/// The empty room this fixes was real: opt-in means a new install is an empty
/// app, and it stays as full as the user's willpower. See
/// `docs/decisions/library-intake.md`.
class ScreenshotGalleryDataSource {
  static const String importAlbumName = 'SHOTO';

  /// What the OS calls the album a screen capture lands in.
  ///
  /// Android's is "Screenshots" in every locale the platform ships — the album
  /// name comes from the directory `Pictures/Screenshots`, not from a
  /// translated string — and iOS exposes its own as a smart album rather than
  /// by name, which is one more reason the iOS side of this is unbuilt rather
  /// than half-built. See `docs/decisions/ios.md`.
  static const List<String> _captureAlbumNames = ['Screenshots', 'Screenshot'];

  StreamController<void>? _changeController;

  /// Images only — SHOTO never reads video, and asking for more than the app
  /// needs actively breaks it.
  ///
  /// photo_manager defaults to [RequestType.common], which is image **and**
  /// video, so it asks Android for `READ_MEDIA_VIDEO` as well. That
  /// permission isn't declared in our manifest (we don't want it), and a
  /// permission that isn't declared can never be granted — so the plugin's
  /// own `containsVideo && !hasVideoPermission` check failed every single
  /// time and reported `denied` no matter how many times the user allowed
  /// photo access. Pinning the type to [RequestType.image] lines the request
  /// up with both the manifest and what the app actually uses.
  static const PermissionRequestOption _imagesOnly = PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.image,
      mediaLocation: false,
    ),
  );

  /// Asks the OS for photo access, showing the system permission dialog if
  /// it hasn't been answered yet. Only safe to call in response to a user
  /// action or a first load — see [checkPermission] for the passive variant.
  Future<PermissionState> requestPermission() {
    return PhotoManager.requestPermissionExtend(requestOption: _imagesOnly);
  }

  /// Reads the current permission **without** prompting.
  ///
  /// Critical distinction: [requestPermission] can put a system dialog on
  /// screen, and a dialog appearing/dismissing is itself an app-lifecycle
  /// event. Calling the requesting variant from a lifecycle listener
  /// therefore feeds itself — dialog → resume → request → dialog — and spins
  /// forever. Anything reacting to lifecycle must use this instead.
  Future<PermissionState> checkPermission() {
    return PhotoManager.getPermissionState(requestOption: _imagesOnly);
  }

  /// Every image the user has saved into SHOTO, newest first.
  ///
  /// Scoped to [importAlbumName] on purpose — see the class doc. There is no
  /// fallback that widens the search, because widening it is exactly the
  /// behaviour being avoided.
  Future<List<AssetEntity>> getScreenshotAssets() async {
    final AssetPathEntity? album = await _ourAlbum();
    if (album == null) return const [];

    final int count = await album.assetCountAsync;
    if (count == 0) return const [];

    final List<AssetEntity> assets = await album.getAssetListRange(
      start: 0,
      end: count,
    );
    assets.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return assets;
  }

  /// Screen captures taken after [since], **oldest first**, that are not
  /// already SHOTO's own.
  ///
  /// Oldest first is not a display preference, it is what makes a half-done
  /// review resumable. The caller advances its watermark to the last capture
  /// the user decided about, so a queue worked through from the oldest end
  /// leaves an unambiguous "everything before this is handled". Newest first
  /// would mean abandoning the queue halfway either re-asks about decided
  /// captures or silently swallows undecided ones, and there is no third
  /// option that does not need a table of ids that grows forever.
  ///
  /// [limit] is a floor under the worst case rather than a page size: a phone
  /// that has not been opened in a year should not hand back four thousand
  /// assets to build a queue nobody will finish.
  Future<List<AssetEntity>> getDeviceCaptures({
    required DateTime since,
    int limit = 60,
  }) async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        // Asked of the platform rather than filtered in Dart, so a gallery
        // with ten thousand pictures in it costs one narrow query instead of
        // ten thousand rows crossing the channel to be thrown away here.
        createTimeCond: DateTimeCond(
          min: since,
          max: DateTime.now(),
        ),
        orders: [const OrderOption(type: OrderOptionType.createDate)],
      ),
    );

    final AssetPathEntity? captures = _bestNamed(albums, _captureAlbumNames);
    if (captures == null) return const [];

    final int count = await captures.assetCountAsync;
    if (count == 0) return const [];

    final List<AssetEntity> assets = await captures.getAssetListRange(
      start: 0,
      end: count < limit ? count : limit,
    );

    // Anything already in SHOTO's album is something the user has answered
    // about — asking again is how a queue loses its credibility.
    final List<AssetEntity> fresh = [];
    for (final AssetEntity asset in assets) {
      final String location = (asset.relativePath ?? '').toLowerCase();
      if (location.contains(importAlbumName.toLowerCase())) continue;
      fresh.add(asset);
    }

    fresh.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
    return fresh;
  }

  AssetPathEntity? _bestNamed(
    List<AssetPathEntity> albums,
    List<String> names,
  ) {
    for (final String name in names) {
      for (final AssetPathEntity album in albums) {
        if (album.name.toLowerCase() == name.toLowerCase()) return album;
      }
    }
    return null;
  }

  Future<AssetPathEntity?> _ourAlbum() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
    return _bestMatch(
      paths.where((path) => path.name == importAlbumName).toList(),
    );
  }

  Future<AssetPathEntity?> _bestMatch(List<AssetPathEntity> candidates) async {
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    AssetPathEntity best = candidates.first;
    int bestCount = await best.assetCountAsync;
    for (final AssetPathEntity path in candidates.skip(1)) {
      final int count = await path.assetCountAsync;
      if (count > bestCount) {
        best = path;
        bestCount = count;
      }
    }
    return best;
  }

  /// Saves a file (e.g. one shared into the app from another app) into the
  /// device gallery under the dedicated "SHOTO" album, so it becomes a real
  /// asset that shows up in [getScreenshotAssets] like any other screenshot.
  Future<AssetEntity> saveSharedImage(String filePath, {String? title}) {
    return PhotoManager.editor.saveImageWithPath(
      filePath,
      title: title,
      relativePath: 'Pictures/$importAlbumName',
    );
  }

  /// Writes raw image bytes into the gallery under the app's own album —
  /// used for images SHOTO generates itself, such as a merged long
  /// screenshot, as opposed to [saveSharedImage] which copies an existing
  /// file in.
  Future<AssetEntity> saveImageBytes(
    Uint8List bytes, {
    required String filename,
    DateTime? creationDate,
  }) {
    return PhotoManager.editor.saveImage(
      bytes,
      filename: filename,
      title: filename,
      relativePath: 'Pictures/$importAlbumName',
      // Null for anything genuinely new, so the gallery stamps it now. Set
      // only by a restore, which is putting back a picture that already has a
      // date and must not claim to have been taken today.
      creationDate: creationDate,
    );
  }

  /// Whether [assetId] points at an image already sitting in SHOTO's own
  /// album on disk.
  ///
  /// Only our own album counts: a screenshot sitting elsewhere in the user's
  /// gallery is *not* in SHOTO — that is the entire point of the opt-in
  /// model — so sharing one in is a genuine import.
  ///
  /// This says nothing about *whose* library the image belongs to. The album
  /// is shared by every account on the device; membership is per-account and
  /// lives in the database. See [LibraryOwnershipLocalDataSource].
  Future<bool> isInOurAlbum(String assetId) async {
    final AssetEntity? asset = await AssetEntity.fromId(assetId);
    if (asset == null) return false;

    final String location = (asset.relativePath ?? '').toLowerCase();
    return location.contains(importAlbumName.toLowerCase());
  }

  /// Resolves ids to assets, **in parallel, in the order asked for**.
  ///
  /// Each `fromId` is a round trip over the platform channel, and awaiting
  /// them one at a time meant a folder of fifty screenshots paid fifty round
  /// trips end to end before anything could be drawn — the spinner you see
  /// when opening a folder was almost entirely this. Issuing them together
  /// costs the platform the same total work but only one round trip's worth
  /// of waiting.
  ///
  /// Chunked rather than one giant [Future.wait] so a very large folder
  /// cannot put thousands of calls in flight at once; the chunk size is well
  /// above what a screenful needs.
  Future<List<AssetEntity>> getAssetsByIds(List<String> ids) async {
    const int chunk = 24;
    final List<AssetEntity> result = [];

    for (int start = 0; start < ids.length; start += chunk) {
      final List<String> slice = ids.sublist(
        start,
        start + chunk > ids.length ? ids.length : start + chunk,
      );
      final List<AssetEntity?> resolved = await Future.wait(
        slice.map(AssetEntity.fromId),
      );
      // Future.wait preserves order, so the caller's ordering survives.
      result.addAll(resolved.whereType<AssetEntity>());
    }

    return result;
  }

  Future<List<String>> deleteAssets(List<String> ids) {
    return PhotoManager.editor.deleteWithIds(ids);
  }

  Stream<void> get changes {
    _changeController ??= StreamController<void>.broadcast(
      onListen: () {
        PhotoManager.addChangeCallback(_onChange);
        PhotoManager.startChangeNotify();
      },
      onCancel: () {
        PhotoManager.removeChangeCallback(_onChange);
        PhotoManager.stopChangeNotify();
      },
    );
    return _changeController!.stream;
  }

  void _onChange(MethodCall call) {
    _changeController?.add(null);
  }
}
