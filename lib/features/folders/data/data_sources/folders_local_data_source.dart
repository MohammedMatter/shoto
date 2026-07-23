import 'package:sqflite/sqflite.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/features/folders/data/models/folder_model.dart';

class FoldersLocalDataSource {
  final AppDatabase _appDatabase;
  FoldersLocalDataSource(this._appDatabase);

  Future<List<FolderModel>> getFolders() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> folderRows = await db.query(
      AppDatabase.folders,
      orderBy: 'created_at DESC',
    );

    final List<Map<String, Object?>> countRows = await db.rawQuery(
      'SELECT folder_id, COUNT(*) as count FROM ${AppDatabase.screenshotMeta} '
      'WHERE folder_id IS NOT NULL GROUP BY folder_id',
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

  Future<FolderModel> createFolder(String name, int color) async {
    final Database db = await _appDatabase.database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int id = await db.insert(AppDatabase.folders, {
      'name': name,
      'color': color,
      'created_at': now,
    });
    return FolderModel(
      id: id,
      name: name,
      color: color,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  Future<void> renameFolder(int folderId, String name) async {
    final Database db = await _appDatabase.database;
    await db.update(
      AppDatabase.folders,
      {'name': name},
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }

  Future<void> deleteFolder(int folderId) async {
    final Database db = await _appDatabase.database;
    await db.delete(AppDatabase.folders, where: 'id = ?', whereArgs: [folderId]);
  }
}
