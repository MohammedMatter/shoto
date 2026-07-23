import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';

abstract class ScreenshotRepository {
  Future<PermissionState> requestPermission();
  Future<List<ScreenshotEntity>> getAllScreenshots();
  Future<List<ScreenshotEntity>> getScreenshotsByFolder(int folderId);
  Stream<void> get onLibraryChanged;
  Future<void> setFavorite(String assetId, bool isFavorite);
  Future<void> assignFolder(List<String> assetIds, int? folderId);
  Future<void> deleteScreenshots(List<String> assetIds);

  /// Saves a shared file into the device gallery and returns the id of the
  /// newly-created asset.
  Future<String> importSharedFile(String filePath);
}
