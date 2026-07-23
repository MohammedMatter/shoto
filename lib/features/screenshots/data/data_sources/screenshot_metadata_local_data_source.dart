import 'package:sqflite/sqflite.dart';
import 'package:shoto/core/database/app_database.dart';

/// Owns the locally-stored organization metadata (favorite flag, folder
/// assignment) keyed by the gallery asset id. Never stores image bytes.
class ScreenshotMetadataLocalDataSource {
  final AppDatabase _appDatabase;
  ScreenshotMetadataLocalDataSource(this._appDatabase);

  Future<Map<String, Map<String, Object?>>> getAllMeta() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.screenshotMeta,
    );
    return {for (final row in rows) row['asset_id'] as String: row};
  }

  Future<Map<String, Object?>?> _getMeta(Database db, String assetId) async {
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.screenshotMeta,
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> setFavorite(String assetId, bool isFavorite) async {
    await _upsert(assetId, isFavorite: isFavorite);
  }

  Future<void> assignFolder(List<String> assetIds, int? folderId) async {
    for (final String id in assetIds) {
      await _upsert(id, folderId: folderId, clearFolder: folderId == null);
    }
  }

  Future<void> _upsert(
    String assetId, {
    bool? isFavorite,
    int? folderId,
    bool clearFolder = false,
  }) async {
    final Database db = await _appDatabase.database;
    final Map<String, Object?>? existing = await _getMeta(db, assetId);
    final int now = DateTime.now().millisecondsSinceEpoch;

    if (existing == null) {
      await db.insert(AppDatabase.screenshotMeta, {
        'asset_id': assetId,
        'folder_id': clearFolder ? null : folderId,
        'is_favorite': (isFavorite ?? false) ? 1 : 0,
        'updated_at': now,
      });
    } else {
      await db.update(
        AppDatabase.screenshotMeta,
        {
          'folder_id': clearFolder ? null : (folderId ?? existing['folder_id']),
          'is_favorite': isFavorite == null
              ? existing['is_favorite']
              : (isFavorite ? 1 : 0),
          'updated_at': now,
        },
        where: 'asset_id = ?',
        whereArgs: [assetId],
      );
    }
  }

  Future<List<String>> getAssetIdsInFolder(int folderId) async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.screenshotMeta,
      columns: ['asset_id'],
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
    return rows.map((row) => row['asset_id'] as String).toList();
  }

  Future<void> deleteMeta(List<String> assetIds) async {
    if (assetIds.isEmpty) return;
    final Database db = await _appDatabase.database;
    final String placeholders = List.filled(assetIds.length, '?').join(',');
    await db.delete(
      AppDatabase.screenshotMeta,
      where: 'asset_id IN ($placeholders)',
      whereArgs: assetIds,
    );
  }
}
