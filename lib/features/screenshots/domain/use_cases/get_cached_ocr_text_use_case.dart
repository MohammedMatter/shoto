import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class GetCachedOcrTextUseCase {
  final ScreenshotRepository repository;
  GetCachedOcrTextUseCase(this.repository);

  Future<Map<String, String>> call() => repository.getCachedOcrText();
}
