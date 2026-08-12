import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/entities/folder_seed.dart';

abstract class FoldersRepository {
  Future<List<FolderEntity>> getFolders();
  Future<FolderEntity> createFolder(
    String name,
    int color, {
    bool isPrivate = false,
    String? iconKey,
  });

  /// Name, colour and glyph in one write.
  ///
  /// Replaces a rename-only path. The sheet that edits a folder is the same
  /// sheet that made it, so it hands back all three of the things it showed —
  /// and three separate statements would let a folder be half-edited if one of
  /// them failed.
  Future<void> updateFolder(
    int folderId, {
    required String name,
    required int color,
    String? iconKey,
  });
  Future<void> deleteFolder(int folderId);

  /// Creates [seeds] the first time this device ever asks, and never again.
  ///
  /// Returns whether anything was written, so a caller can avoid reloading a
  /// list that cannot have changed.
  Future<bool> seedDefaultFolders(List<FolderSeed> seeds);
}
