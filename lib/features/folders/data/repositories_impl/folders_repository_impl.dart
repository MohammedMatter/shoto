import 'package:shoto/features/folders/data/data_sources/folders_local_data_source.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';

class FoldersRepositoryImpl implements FoldersRepository {
  final FoldersLocalDataSource _localDataSource;
  FoldersRepositoryImpl(this._localDataSource);

  @override
  Future<List<FolderEntity>> getFolders() => _localDataSource.getFolders();

  @override
  Future<FolderEntity> createFolder(String name, int color) =>
      _localDataSource.createFolder(name, color);

  @override
  Future<void> renameFolder(int folderId, String name) =>
      _localDataSource.renameFolder(folderId, name);

  @override
  Future<void> deleteFolder(int folderId) =>
      _localDataSource.deleteFolder(folderId);
}
