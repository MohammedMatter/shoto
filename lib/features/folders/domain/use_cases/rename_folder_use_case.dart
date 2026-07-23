import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';

class RenameFolderUseCase {
  final FoldersRepository repository;
  RenameFolderUseCase(this.repository);

  Future<void> call(int folderId, String name) =>
      repository.renameFolder(folderId, name);
}
