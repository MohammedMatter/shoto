import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';

class GetFoldersUseCase {
  final FoldersRepository repository;
  GetFoldersUseCase(this.repository);

  Future<List<FolderEntity>> call() => repository.getFolders();
}
