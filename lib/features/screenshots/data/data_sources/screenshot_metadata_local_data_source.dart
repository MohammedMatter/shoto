import 'package:sqflite/sqflite.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/core/utils/visual_label_codec.dart';
import 'package:shoto/core/services/local_identity.dart';

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
  final LocalIdentity _localIdentity;
  ScreenshotMetadataLocalDataSource(this._appDatabase, this._localIdentity);

  String get _userId => _localIdentity.id;

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

  /// Sets, changes or clears what the user said they would do with any number
  /// of screenshots.
  ///
  /// Setting an intent always clears `intent_done_at`. Changing your mind
  /// about *what* you are going to do makes the old completion meaningless —
  /// having ticked off "reply" says nothing about whether you have bought it —
  /// and leaving the timestamp behind would file the screenshot as finished
  /// under a task nobody has started.
  ///
  /// Takes a list because answering the question for forty screenshots at once
  /// is how a library that predates the question ever gets answered at all.
  /// One transaction and one commit, and the existence check disappears into
  /// `update`'s row count — same pattern, and same reasoning, as
  /// [assignFolder].
  /// [doneAt] exists for restores, which are re-creating an intent that was
  /// ticked off at some known point in the past — the same reason
  /// [FoldersLocalDataSource.createFolder] takes a `createdAt`. Left off
  /// everywhere else, so setting an intent by hand always starts it waiting.
  Future<void> setIntent(
    List<String> assetIds,
    String? intentId, {
    DateTime? doneAt,
  }) async {
    if (assetIds.isEmpty) return;
    final Database db = await _appDatabase.database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int? doneMillis = intentId == null
        ? null
        : doneAt?.millisecondsSinceEpoch;

    await db.transaction((Transaction txn) async {
      for (final String assetId in assetIds) {
        final int updated = await txn.update(
          AppDatabase.screenshotMeta,
          <String, Object?>{
            'intent': intentId,
            'intent_done_at': doneMillis,
            'updated_at': now,
          },
          where: 'user_id = ? AND asset_id = ?',
          whereArgs: <Object?>[_userId, assetId],
        );
        if (updated == 0) {
          await txn.insert(AppDatabase.screenshotMeta, <String, Object?>{
            'user_id': _userId,
            'asset_id': assetId,
            'is_favorite': 0,
            'intent': intentId,
            'intent_done_at': doneMillis,
            'updated_at': now,
          });
        }
      }
    });
  }

  /// Sets or clears when the user asked to be reminded about a screenshot.
  ///
  /// Insert-if-missing like [setIntent], because a reminder can be the first
  /// thing anybody ever says about a screenshot — the row may not exist yet.
  ///
  /// **Deliberately independent of the intent**, even though the two are
  /// almost always set together. Clearing a reminder is not finishing a task
  /// and finishing a task is not cancelling a reminder; folding them into one
  /// write would mean a fired reminder looked like a completed intent, or a
  /// completed intent kept ringing.
  Future<void> setReminder(String assetId, DateTime? at) async {
    final Database db = await _appDatabase.database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int? atMillis = at?.millisecondsSinceEpoch;

    final int updated = await db.update(
      AppDatabase.screenshotMeta,
      <String, Object?>{'remind_at': atMillis, 'updated_at': now},
      where: 'user_id = ? AND asset_id = ?',
      whereArgs: <Object?>[_userId, assetId],
    );
    if (updated != 0) return;

    await db.insert(AppDatabase.screenshotMeta, <String, Object?>{
      'user_id': _userId,
      'asset_id': assetId,
      'is_favorite': 0,
      'remind_at': atMillis,
      'updated_at': now,
    });
  }

  /// Every reminder still ahead of [now], as `assetId -> when`.
  ///
  /// Used to put the alarms back when the app finds them missing — a reinstall,
  /// a restore, or a phone whose boot broadcast never arrived. Past reminders
  /// are excluded rather than re-armed: one that has already come and gone is
  /// history, and arming it now would fire it at the wrong moment entirely.
  Future<Map<String, DateTime>> getPendingReminders(DateTime now) async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.screenshotMeta,
      columns: <String>['asset_id', 'remind_at'],
      where: 'user_id = ? AND remind_at IS NOT NULL AND remind_at > ?',
      whereArgs: <Object?>[_userId, now.millisecondsSinceEpoch],
    );

    return <String, DateTime>{
      for (final Map<String, Object?> row in rows)
        row['asset_id'] as String: DateTime.fromMillisecondsSinceEpoch(
          row['remind_at'] as int,
        ),
    };
  }

  /// Ticks an intent off, or puts it back on the list.
  ///
  /// Reversible on purpose. This is the one action in the app whose whole
  /// point is that a number goes *down*, and a number that can only go down by
  /// accident is worse than one that never moves — an accidental tick with no
  /// way back would teach people not to use the tick at all.
  Future<void> setIntentDone(String assetId, bool isDone) async {
    final Database db = await _appDatabase.database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      AppDatabase.screenshotMeta,
      <String, Object?>{
        'intent_done_at': isDone ? now : null,
        'updated_at': now,
      },
      where: 'user_id = ? AND asset_id = ? AND intent IS NOT NULL',
      whereArgs: <Object?>[_userId, assetId],
    );
  }

  /// Every screenshot with an intent, as `assetId -> (intentId, doneAt)`.
  ///
  /// Read whole rather than per screenshot: Home needs the counts for the
  /// entire library on every appearance, and asking row by row would be one
  /// query per screenshot on the app's first screen.
  Future<Map<String, ({String intent, int? doneAt})>> getAllIntents() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.screenshotMeta,
      columns: <String>['asset_id', 'intent', 'intent_done_at'],
      where: 'user_id = ? AND intent IS NOT NULL',
      whereArgs: <Object?>[_userId],
    );
    return <String, ({String intent, int? doneAt})>{
      for (final Map<String, Object?> row in rows)
        row['asset_id'] as String: (
          intent: row['intent'] as String,
          doneAt: row['intent_done_at'] as int?,
        ),
    };
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
