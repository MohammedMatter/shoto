import 'package:shoto/features/folders/data/data_sources/folders_local_data_source.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/entities/folder_seed.dart';
import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';

class FoldersRepositoryImpl implements FoldersRepository {
  final FoldersLocalDataSource _localDataSource;
  FoldersRepositoryImpl(this._localDataSource);

  @override
  Future<List<FolderEntity>> getFolders() => _localDataSource.getFolders();

  @override
  Future<FolderEntity> createFolder(
    String name,
    int color, {
    bool isPrivate = false,
    String? iconKey,
  }) => _localDataSource.createFolder(
    name,
    color,
    isPrivate: isPrivate,
    iconKey: iconKey,
  );

  @override
  Future<void> updateFolder(
    int folderId, {
    required String name,
    required int color,
    String? iconKey,
  }) => _localDataSource.updateFolder(
    folderId,
    name: name,
    color: color,
    iconKey: iconKey,
  );

  @override
  Future<void> deleteFolder(int folderId) =>
      _localDataSource.deleteFolder(folderId);

  @override
  Future<bool> seedDefaultFolders(List<FolderSeed> seeds) =>
      _localDataSource.seedDefaultFolders(seeds);
}
