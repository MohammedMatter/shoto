import 'package:sqflite/sqflite.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/core/services/local_identity.dart';
import 'package:shoto/features/folders/data/models/folder_model.dart';
import 'package:shoto/features/folders/domain/entities/folder_seed.dart';

/// Folders are scoped to the current Firebase user id, same reasoning as
/// [ScreenshotMetadataLocalDataSource] — different accounts on the same
/// device never see each other's folders.
class FoldersLocalDataSource {
  final AppDatabase _appDatabase;
  final LocalIdentity _localIdentity;
  FoldersLocalDataSource(this._appDatabase, this._localIdentity);

  String get _userId => _localIdentity.id;

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
    String? iconKey,
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
      'icon_key': iconKey,
      'created_at': now,
    });
    return FolderModel(
      id: id,
      name: name,
      color: color,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      isPrivate: isPrivate,
      iconKey: iconKey,
    );
  }

  Future<void> updateFolder(
    int folderId, {
    required String name,
    required int color,
    String? iconKey,
  }) async {
    final Database db = await _appDatabase.database;
    await db.update(
      AppDatabase.folders,
      {'name': name, 'color': color, 'icon_key': iconKey},
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

  /// Writes the starter folders, once in the lifetime of the install.
  ///
  /// **Guarded by a flag rather than by "are there any folders yet".** The
  /// obvious test — seed when the table is empty — re-seeds the moment somebody
  /// deletes the last folder they kept, which is the single loudest way an app
  /// can say it was not listening. The flag row says *the offer has been made*,
  /// and that stays true however the user answered it.
  ///
  /// One transaction, so a kill mid-write cannot leave three of seven folders
  /// behind a flag that says the job is done.
  Future<bool> seedDefaultFolders(List<FolderSeed> seeds) async {
    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> flag = await db.query(
      AppDatabase.appFlags,
      where: 'key = ?',
      whereArgs: [_seededFlagKey],
      limit: 1,
    );
    if (flag.isNotEmpty) return false;

    final int now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      for (int i = 0; i < seeds.length; i++) {
        final FolderSeed seed = seeds[i];
        await txn.insert(AppDatabase.folders, {
          'user_id': _userId,
          'name': seed.name,
          'color': seed.color,
          'is_private': 0,
          'icon_key': seed.iconKey,
          // Descending by a millisecond each, so the seven come out of
          // `getFolders` — which orders by `created_at DESC` — in the order
          // they are listed rather than in whatever order a single shared
          // timestamp leaves them.
          'created_at': now - i,
        });
      }
      await txn.insert(AppDatabase.appFlags, {
        'key': _seededFlagKey,
        'value': '1',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    return true;
  }

  /// Device-wide rather than per-user, matching what `user_id` has meant since
  /// v17: one identity per phone. `app_flags` is keyed by a bare string, and
  /// there is no second account left for it to be ambiguous between.
  static const String _seededFlagKey = 'default_folders_seeded';
}
