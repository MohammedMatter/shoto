import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class GetScreenshotsByFolderUseCase {
  final ScreenshotRepository repository;
  GetScreenshotsByFolderUseCase(this.repository);

  Future<List<ScreenshotEntity>> call(int folderId) =>
      repository.getScreenshotsByFolder(folderId);
}
