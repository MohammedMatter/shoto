import 'dart:async';

import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

/// Talks to the device's photo library. Screenshots aren't a first-class
/// concept on either platform — we approximate them by looking for the
/// gallery album whose name contains "screenshot" (both Android's and
/// iOS's system albums are literally named "Screenshots"), plus a
/// dedicated "SHOTO" album we create ourselves for images shared into the
/// app from elsewhere (see [saveSharedImage]).
class ScreenshotGalleryDataSource {
  static const String importAlbumName = 'SHOTO';

  StreamController<void>? _changeController;

  Future<PermissionState> requestPermission() {
    return PhotoManager.requestPermissionExtend();
  }

  Future<List<AssetEntity>> getScreenshotAssets() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    final AssetPathEntity? screenshotsAlbum = await _bestMatch(
      paths.where((path) => path.name.toLowerCase().contains('screenshot')).toList(),
    );
    final AssetPathEntity? importedAlbum = await _bestMatch(
      paths.where((path) => path.name == importAlbumName).toList(),
    );

    final List<AssetEntity> results = [];
    final Set<String> seenIds = {};

    for (final AssetPathEntity? album in [screenshotsAlbum, importedAlbum]) {
      if (album == null) continue;
      final int count = await album.assetCountAsync;
      if (count == 0) continue;
      final List<AssetEntity> assets = await album.getAssetListRange(
        start: 0,
        end: count,
      );
      for (final AssetEntity asset in assets) {
        if (seenIds.add(asset.id)) results.add(asset);
      }
    }

    results.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return results;
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

  Future<List<AssetEntity>> getAssetsByIds(List<String> ids) async {
    final List<AssetEntity> result = [];
    for (final String id in ids) {
      final AssetEntity? asset = await AssetEntity.fromId(id);
      if (asset != null) result.add(asset);
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
