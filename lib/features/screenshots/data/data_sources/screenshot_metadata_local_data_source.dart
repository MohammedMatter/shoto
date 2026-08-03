import 'package:sqflite/sqflite.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/core/utils/visual_label_codec.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';

/// Owns the locally-stored organization metadata (favorite flag, folder
/// assignment) keyed by the gallery asset id. Never stores image bytes.
///
/// Every row is scoped to the current Firebase user id — screenshots on the
/// device are shared (they come from the OS gallery), but which folder a
/// screenshot is filed under or whether it's favorited is per-account, so
/// two people signed into different accounts on the same phone never see
/// each other's organization.
class ScreenshotMetadataLocalDataSource {
  final AppDatabase _appDatabase;
  final AuthRepository _authRepository;
  ScreenshotMetadataLocalDataSource(this._appDatabase, this._authRepository);

  String get _userId => _authRepository.currentUser!.id;

  Future<Map<String, Map<String, Object?>>> getAllMeta() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.screenshotMeta,
      where: 'user_id = ?',
      whereArgs: [_userId],
    );
    return {for (final row in rows) row['asset_id'] as String: row};
  }

  Future<Map<String, Object?>?> _getMeta(Database db, String assetId) async {
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.screenshotMeta,
      where: 'user_id = ? AND asset_id = ?',
      whereArgs: [_userId, assetId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> setFavorite(String assetId, bool isFavorite) async {
    await _upsert(assetId, isFavorite: isFavorite);
  }

  /// Files (or unfiles) any number of screenshots in **one transaction**.
  ///
  /// This used to call the single-row upsert in a loop, which is two round
  /// trips to the database per screenshot — a read to see whether a row
  /// exists, then a write — each in its own implicit transaction, and each
  /// waiting for the one before it. Filing thirty selected screenshots was
  /// sixty sequential trips with sixty commits behind them, and the sheet sat
  /// there while they finished.
  ///
  /// One transaction, one commit, and the read disappears entirely: `update`
  /// already reports how many rows it changed, so a zero is exactly the
  /// "there was no row yet" case. Same pattern as [savePerceptualHashes].
  Future<void> assignFolder(List<String> assetIds, int? folderId) async {
    if (assetIds.isEmpty) return;
    final Database db = await _appDatabase.database;
    final int now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      for (final String id in assetIds) {
        final int updated = await txn.update(
          AppDatabase.screenshotMeta,
          {'folder_id': folderId, 'updated_at': now},
          where: 'user_id = ? AND asset_id = ?',
          whereArgs: [_userId, id],
        );
        if (updated == 0) {
          await txn.insert(AppDatabase.screenshotMeta, {
            'user_id': _userId,
            'asset_id': id,
            'folder_id': folderId,
            'is_favorite': 0,
            'updated_at': now,
          });
        }
      }
    });
  }

  Future<void> saveOcrText(String assetId, String text) async {
    await _upsert(assetId, ocrText: text);
  }

  /// Stores what a vision model saw, so it never has to look twice.
  ///
  /// An empty list is written as an empty JSON array, not left NULL —
  /// "looked, found nothing above the confidence floor" and "never looked"
  /// have to be distinguishable or every unlabellable screenshot is
  /// re-processed on every visit to search.
  Future<void> saveVisualLabels(String assetId, List<String> labels) async {
    await _upsert(assetId, visualLabels: VisualLabelCodec.encode(labels));
  }

  Future<Map<String, List<String>>> getAllVisualLabels() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.screenshotMeta,
      columns: ['asset_id', 'visual_labels'],
      where: 'user_id = ? AND visual_labels IS NOT NULL',
      whereArgs: [_userId],
    );
    return {
      for (final row in rows)
        row['asset_id'] as String: VisualLabelCodec.decode(
          row['visual_labels'] as String?,
        ),
    };
  }

  Future<Map<String, String>> getAllOcrText() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.screenshotMeta,
      columns: ['asset_id', 'ocr_text'],
      where: 'user_id = ? AND ocr_text IS NOT NULL',
      whereArgs: [_userId],
    );
    return {
      for (final row in rows)
        row['asset_id'] as String: row['ocr_text'] as String,
    };
  }

  /// Caches perceptual hashes in bulk after a duplicate scan. Batched into
  /// a single transaction — a scan can touch hundreds of rows, and one
  /// transaction is dramatically faster than hundreds of separate writes.
  Future<void> savePerceptualHashes(Map<String, String> hashesByAssetId) async {
    if (hashesByAssetId.isEmpty) return;
    final Database db = await _appDatabase.database;
    final int now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      for (final MapEntry<String, String> entry in hashesByAssetId.entries) {
        final int updated = await txn.update(
          AppDatabase.screenshotMeta,
          {'phash': entry.value, 'updated_at': now},
          where: 'user_id = ? AND asset_id = ?',
          whereArgs: [_userId, entry.key],
        );
        if (updated == 0) {
          await txn.insert(AppDatabase.screenshotMeta, {
            'user_id': _userId,
            'asset_id': entry.key,
            'folder_id': null,
            'is_favorite': 0,
            'phash': entry.value,
            'updated_at': now,
          });
        }
      }
    });
  }

  Future<Map<String, String>> getAllPerceptualHashes() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.screenshotMeta,
      columns: ['asset_id', 'phash'],
      where: 'user_id = ? AND phash IS NOT NULL',
      whereArgs: [_userId],
    );
    return {
      for (final row in rows) row['asset_id'] as String: row['phash'] as String,
    };
  }

  Future<void> _upsert(
    String assetId, {
    bool? isFavorite,
    int? folderId,
    bool clearFolder = false,
    String? ocrText,
    String? visualLabels,
  }) async {
    final Database db = await _appDatabase.database;
    final Map<String, Object?>? existing = await _getMeta(db, assetId);
    final int now = DateTime.now().millisecondsSinceEpoch;

    if (existing == null) {
      await db.insert(AppDatabase.screenshotMeta, {
        'user_id': _userId,
        'asset_id': assetId,
        'folder_id': clearFolder ? null : folderId,
        'is_favorite': (isFavorite ?? false) ? 1 : 0,
        'ocr_text': ocrText,
        'visual_labels': visualLabels,
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
          'ocr_text': ocrText ?? existing['ocr_text'],
          'visual_labels': visualLabels ?? existing['visual_labels'],
          'updated_at': now,
        },
        where: 'user_id = ? AND asset_id = ?',
        whereArgs: [_userId, assetId],
      );
    }
  }

  /// Count of distinct screenshots that have ever been favorited or filed
  /// into a folder for the current user — the free-tier "managed" cap.
  Future<int> getManagedCount() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.screenshotMeta,
      columns: ['asset_id'],
      where: 'user_id = ? AND (is_favorite = 1 OR folder_id IS NOT NULL)',
      whereArgs: [_userId],
    );
    return rows.length;
  }

  Future<List<String>> getAssetIdsInFolder(int folderId) async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.screenshotMeta,
      columns: ['asset_id'],
      where: 'user_id = ? AND folder_id = ?',
      whereArgs: [_userId, folderId],
    );
    return rows.map((row) => row['asset_id'] as String).toList();
  }

  Future<void> deleteMeta(List<String> assetIds) async {
    if (assetIds.isEmpty) return;
    final Database db = await _appDatabase.database;
    final String placeholders = List.filled(assetIds.length, '?').join(',');
    await db.delete(
      AppDatabase.screenshotMeta,
      where: 'user_id = ? AND asset_id IN ($placeholders)',
      whereArgs: [_userId, ...assetIds],
    );
  }
}
