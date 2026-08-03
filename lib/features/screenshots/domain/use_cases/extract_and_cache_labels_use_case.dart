import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class ExtractAndCacheLabelsUseCase {
  final ScreenshotRepository repository;
  ExtractAndCacheLabelsUseCase(this.repository);

  Future<List<String>> call(ScreenshotEntity screenshot) =>
      repository.extractAndCacheLabels(screenshot);
}
