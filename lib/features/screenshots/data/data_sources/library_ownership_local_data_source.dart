import 'package:sqflite/sqflite.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';

/// Answers the one question the device gallery cannot: *whose* library is
/// this screenshot in.
///
/// SHOTO keeps its images in a single album on the device, `Pictures/SHOTO`.
/// A folder on disk has no notion of accounts, so listing that album meant
/// every account signing in on the same phone inherited every other
/// account's screenshots. Membership is therefore recorded here, per user,
/// and the album is only ever read *through* it.
///
/// Note this is about visibility inside SHOTO, not secrecy: the files still
/// sit in the shared gallery, where the phone's own photo app can show them
/// to anyone holding the device. Hiding them from the gallery entirely would
/// mean giving up being real gallery assets, which the share, delete and
/// stitch flows are all built on.
class LibraryOwnershipLocalDataSource {
  final AppDatabase _appDatabase;
  final AuthRepository _authRepository;

  LibraryOwnershipLocalDataSource(this._appDatabase, this._authRepository);

  /// Null while nobody is signed in. Reads treat that as an empty library
  /// rather than throwing — the share sheet can legitimately run before the
  /// user has ever opened the app. Writes require a real account, because
  /// claiming an image for nobody would file it where no one can reach it.
  String? get _userId => _authRepository.currentUser?.id;

  /// Whether there is an account to attribute anything to. Callers that are
  /// about to write check this rather than letting [_requireUserId] throw.
  bool get hasSignedInUser => _userId != null;

  String get _requireUserId {
    final String? id = _userId;
    if (id == null) {
      throw StateError('Cannot change library ownership while signed out.');
    }
    return id;
  }

  /// Every asset id the signed-in account has in its library.
  ///
  /// Returned as a set because the caller's job is always an intersection
  /// against the album's contents, and the album can hold hundreds of items.
  Future<Set<String>> getOwnedAssetIds() async {
    final String? userId = _userId;
    if (userId == null) return <String>{};

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
    final String? userId = _userId;
    if (userId == null) return false;

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

  /// Adds [assetIds] to the signed-in account's library.
  ///
  /// Idempotent — claiming something already claimed is a no-op, which is
  /// what lets an image that is physically in the album be adopted by a
  /// second account without copying the file.
  Future<void> claim(Iterable<String> assetIds) async {
    final List<String> ids = assetIds.toList();
    if (ids.isEmpty) return;

    final String userId = _requireUserId;
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

  /// Removes [assetIds] from the signed-in account's library, leaving other
  /// accounts' claims on the same image untouched.
  Future<void> release(Iterable<String> assetIds) async {
    final List<String> ids = assetIds.toList();
    if (ids.isEmpty) return;

    final String userId = _requireUserId;
    final Database db = await _appDatabase.database;
    final String placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      AppDatabase.libraryAssets,
      where: 'user_id = ? AND asset_id IN ($placeholders)',
      whereArgs: [userId, ...ids],
    );
  }

  /// Which of [assetIds] some *other* account still has in its library.
  ///
  /// Deleting is the one operation that touches the file itself, and the file
  /// is shared. Removing a screenshot from your library must not take it out
  /// of somebody else's, so the actual delete is limited to what this returns
  /// nothing for.
  Future<Set<String>> ownedByOthers(Iterable<String> assetIds) async {
    final List<String> ids = assetIds.toList();
    if (ids.isEmpty) return <String>{};

    final Database db = await _appDatabase.database;
    final String placeholders = List.filled(ids.length, '?').join(',');
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.libraryAssets,
      columns: ['asset_id'],
      where: 'asset_id IN ($placeholders) AND user_id != ?',
      whereArgs: [...ids, _userId ?? ''],
    );
    return {for (final row in rows) row['asset_id'] as String};
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
