import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class DeleteScreenshotsUseCase {
  final ScreenshotRepository repository;
  DeleteScreenshotsUseCase(this.repository);

  /// Returns the ids that were actually deleted, which is not always the ones
  /// that were asked for — the system delete prompt can be refused.
  Future<List<String>> call(List<String> assetIds) =>
      repository.deleteScreenshots(assetIds);
}
