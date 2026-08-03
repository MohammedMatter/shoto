import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class GetCachedVisualLabelsUseCase {
  final ScreenshotRepository repository;
  GetCachedVisualLabelsUseCase(this.repository);

  Future<Map<String, List<String>>> call() =>
      repository.getCachedVisualLabels();
}
