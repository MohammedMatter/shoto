import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class GetScreenshotsUseCase {
  final ScreenshotRepository repository;
  GetScreenshotsUseCase(this.repository);

  Future<List<ScreenshotEntity>> call() => repository.getAllScreenshots();
}
