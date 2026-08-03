import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class ExtractAndCacheTextUseCase {
  final ScreenshotRepository repository;
  ExtractAndCacheTextUseCase(this.repository);

  Future<String> call(ScreenshotEntity screenshot) =>
      repository.extractAndCacheText(screenshot);
}
