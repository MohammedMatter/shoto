import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';

class DeleteFolderUseCase {
  final FoldersRepository repository;
  DeleteFolderUseCase(this.repository);

  Future<void> call(int folderId) => repository.deleteFolder(folderId);
}
