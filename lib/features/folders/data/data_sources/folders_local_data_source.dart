import 'package:sqflite/sqflite.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/folders/data/models/folder_model.dart';

/// Folders are scoped to the current Firebase user id, same reasoning as
/// [ScreenshotMetadataLocalDataSource] — different accounts on the same
/// device never see each other's folders.
class FoldersLocalDataSource {
  final AppDatabase _appDatabase;
  final AuthRepository _authRepository;
  FoldersLocalDataSource(this._appDatabase, this._authRepository);

  String get _userId => _authRepository.currentUser!.id;

  Future<List<FolderModel>> getFolders() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> folderRows = await db.query(
      AppDatabase.folders,
      where: 'user_id = ?',
      whereArgs: [_userId],
      orderBy: 'created_at DESC',
    );

    final List<Map<String, Object?>> countRows = await db.rawQuery(
      'SELECT folder_id, COUNT(*) as count FROM ${AppDatabase.screenshotMeta} '
      'WHERE user_id = ? AND folder_id IS NOT NULL GROUP BY folder_id',
      [_userId],
    );
    final Map<int, int> counts = {
      for (final row in countRows) row['folder_id'] as int: row['count'] as int,
    };

    return folderRows
        .map(
          (row) => FolderModel.fromMap(
            row,
            screenshotCount: counts[row['id'] as int] ?? 0,
          ),
        )
        .toList();
  }

  /// [createdAt] exists for restores, which are re-creating a folder that was
  /// made at some known point in the past. Left off everywhere else, so a
  /// folder made by hand is still stamped with the moment it was made.
  Future<FolderModel> createFolder(
    String name,
    int color, {
    bool isPrivate = false,
    DateTime? createdAt,
  }) async {
    final Database db = await _appDatabase.database;
    final int now =
        createdAt?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    final int id = await db.insert(AppDatabase.folders, {
      'user_id': _userId,
      'name': name,
      'color': color,
      'is_private': isPrivate ? 1 : 0,
      'created_at': now,
    });
    return FolderModel(
      id: id,
      name: name,
      color: color,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      isPrivate: isPrivate,
    );
  }

  Future<void> renameFolder(int folderId, String name) async {
    final Database db = await _appDatabase.database;
    await db.update(
      AppDatabase.folders,
      {'name': name},
      where: 'user_id = ? AND id = ?',
      whereArgs: [_userId, folderId],
    );
  }

  Future<void> deleteFolder(int folderId) async {
    final Database db = await _appDatabase.database;
    await db.delete(
      AppDatabase.folders,
      where: 'user_id = ? AND id = ?',
      whereArgs: [_userId, folderId],
    );
  }
}
