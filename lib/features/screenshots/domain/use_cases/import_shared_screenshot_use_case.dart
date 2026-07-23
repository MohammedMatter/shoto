import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class ImportSharedScreenshotUseCase {
  final ScreenshotRepository repository;
  ImportSharedScreenshotUseCase(this.repository);

  Future<String> call(String filePath) => repository.importSharedFile(filePath);
}
