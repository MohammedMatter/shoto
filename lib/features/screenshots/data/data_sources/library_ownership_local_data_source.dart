import 'package:sqflite/sqflite.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/core/services/local_identity.dart';

/// Answers the one question the device gallery cannot: is this screenshot
/// actually *in* SHOTO's library.
///
/// SHOTO keeps its images in a single album on the device, `Pictures/SHOTO`.
/// A folder on disk cannot distinguish an image the user deliberately saved
/// from one that merely landed there, so membership is recorded here and the
/// album is only ever read *through* it.
///
/// Note this is about visibility inside SHOTO, not secrecy: the files still
/// sit in the shared gallery, where the phone's own photo app can show them
/// to anyone holding the device. Hiding them from the gallery entirely would
/// mean giving up being real gallery assets, which the share, delete and
/// stitch flows are all built on.
class LibraryOwnershipLocalDataSource {
  final AppDatabase _appDatabase;
  final LocalIdentity _localIdentity;

  LibraryOwnershipLocalDataSource(this._appDatabase, this._localIdentity);

  /// Always present. This used to be the signed-in account's uid and was
  /// therefore nullable, which made every read below carry an "empty library"
  /// branch and every write a StateError it could throw. The device's own
  /// identity exists from first launch and never goes away, so all of that
  /// is gone: there is no state in which SHOTO does not know whose library
  /// this is.
  String get _userId => _localIdentity.id;

  /// Every asset id in this device's library.
  ///
  /// Returned as a set because the caller's job is always an intersection
  /// against the album's contents, and the album can hold hundreds of items.
  Future<Set<String>> getOwnedAssetIds() async {
    final String userId = _userId;
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.libraryAssets,
      columns: ['asset_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return {for (final row in rows) row['asset_id'] as String};
  }

  Future<bool> owns(String assetId) async {
    final String userId = _userId;
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.libraryAssets,
      columns: ['asset_id'],
      where: 'user_id = ? AND asset_id = ?',
      whereArgs: [userId, assetId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Adds [assetIds] to this device's library.
  ///
  /// Idempotent — claiming something already claimed is a no-op, which is
  /// what lets an image that is physically in the album be re-imported
  /// without copying the file.
  Future<void> claim(Iterable<String> assetIds) async {
    final List<String> ids = assetIds.toList();
    if (ids.isEmpty) return;

    final String userId = _userId;
    final Database db = await _appDatabase.database;
    final int now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      for (final String id in ids) {
        await txn.insert(AppDatabase.libraryAssets, {
          'user_id': userId,
          'asset_id': id,
          'added_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  /// Removes [assetIds] from this device's library.
  Future<void> release(Iterable<String> assetIds) async {
    final List<String> ids = assetIds.toList();
    if (ids.isEmpty) return;

    final String userId = _userId;
    final Database db = await _appDatabase.database;
    final String placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      AppDatabase.libraryAssets,
      where: 'user_id = ? AND asset_id IN ($placeholders)',
      whereArgs: [userId, ...ids],
    );
  }

  /// Asset ids claimed by anyone at all, used only by the legacy adoption
  /// step below to avoid taking an image that already has an owner.
  Future<Set<String>> getAssetIdsOwnedByAnyone() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.libraryAssets,
      columns: ['asset_id'],
      distinct: true,
    );
    return {for (final row in rows) row['asset_id'] as String};
  }

  /// True when this device still holds images that were imported before
  /// ownership was recorded and have not been handed to an account yet.
  ///
  /// The flag is written by the v9 migration and never exists on a fresh
  /// install, so a new phone can never adopt anything.
  Future<bool> hasPendingLegacyAdoption() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.appFlags,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [AppDatabase.legacyLibraryAdoptedFlag],
      limit: 1,
    );
    return rows.isNotEmpty && rows.first['value'] == '0';
  }

  Future<void> markLegacyAdoptionDone() async {
    final Database db = await _appDatabase.database;
    await db.update(
      AppDatabase.appFlags,
      {'value': '1'},
      where: 'key = ?',
      whereArgs: [AppDatabase.legacyLibraryAdoptedFlag],
    );
  }
}
