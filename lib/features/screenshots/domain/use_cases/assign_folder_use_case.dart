import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class AssignFolderUseCase {
  final ScreenshotRepository repository;
  AssignFolderUseCase(this.repository);

  Future<void> call(List<String> assetIds, int? folderId) =>
      repository.assignFolder(assetIds, folderId);
}
