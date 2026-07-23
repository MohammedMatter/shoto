import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_gallery_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_metadata_local_data_source.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class ScreenshotRepositoryImpl implements ScreenshotRepository {
  final ScreenshotGalleryDataSource _gallery;
  final ScreenshotMetadataLocalDataSource _metadata;

  ScreenshotRepositoryImpl(this._gallery, this._metadata);

  @override
  Future<PermissionState> requestPermission() => _gallery.requestPermission();

  @override
  Future<List<ScreenshotEntity>> getAllScreenshots() async {
    final List<AssetEntity> assets = await _gallery.getScreenshotAssets();
    final Map<String, Map<String, Object?>> metaMap = await _metadata
        .getAllMeta();
    return assets.map((asset) => _toEntity(asset, metaMap[asset.id])).toList();
  }

  @override
  Future<List<ScreenshotEntity>> getScreenshotsByFolder(int folderId) async {
    final List<String> assetIds = await _metadata.getAssetIdsInFolder(
      folderId,
    );
    final List<AssetEntity> assets = await _gallery.getAssetsByIds(assetIds);
    final Map<String, Map<String, Object?>> metaMap = await _metadata
        .getAllMeta();
    return assets.map((asset) => _toEntity(asset, metaMap[asset.id])).toList();
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
    final List<String> deletedIds = await _gallery.deleteAssets(assetIds);
    await _metadata.deleteMeta(deletedIds);
  }

  @override
  Future<String> importSharedFile(String filePath) async {
    final AssetEntity asset = await _gallery.saveSharedImage(filePath);
    return asset.id;
  }

  ScreenshotEntity _toEntity(AssetEntity asset, Map<String, Object?>? meta) {
    return ScreenshotEntity(
      asset: asset,
      isFavorite: (meta?['is_favorite'] as int?) == 1,
      folderId: meta?['folder_id'] as int?,
    );
  }
}
