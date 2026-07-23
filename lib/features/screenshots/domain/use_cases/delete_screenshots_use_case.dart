import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class DeleteScreenshotsUseCase {
  final ScreenshotRepository repository;
  DeleteScreenshotsUseCase(this.repository);

  Future<void> call(List<String> assetIds) =>
      repository.deleteScreenshots(assetIds);
}
