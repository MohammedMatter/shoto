import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class ImportSharedScreenshotUseCase {
  final ScreenshotRepository repository;
  ImportSharedScreenshotUseCase(this.repository);

  /// [sourceAssetId] is the gallery id the shared file came from, when the
  /// caller knows it — it lets an image already sitting in Shoto's album be
  /// taken into this account's library instead of copied again.
  Future<String> call(String filePath, {String? sourceAssetId}) =>
      repository.importSharedFile(filePath, sourceAssetId: sourceAssetId);
}
