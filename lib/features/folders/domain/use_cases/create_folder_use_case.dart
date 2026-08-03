import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';

class CreateFolderUseCase {
  final FoldersRepository repository;
  CreateFolderUseCase(this.repository);

  Future<FolderEntity> call(String name, int color, {bool isPrivate = false}) =>
      repository.createFolder(name, color, isPrivate: isPrivate);
}
