import 'package:shoto/features/folders/domain/entities/folder_entity.dart';

abstract class FoldersRepository {
  Future<List<FolderEntity>> getFolders();
  Future<FolderEntity> createFolder(
    String name,
    int color, {
    bool isPrivate = false,
  });
  Future<void> renameFolder(int folderId, String name);
  Future<void> deleteFolder(int folderId);
}
