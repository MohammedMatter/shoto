import 'package:sqflite/sqflite.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';

/// The verbs this account wrote for itself.
///
/// Scoped to the current Firebase user for the same reason folders are: two
/// people signed into the same phone do not share a vocabulary, and one of
/// them renaming "for the shop" must not rewrite the other's library.
class CustomIntentsLocalDataSource {
  final AppDatabase _appDatabase;
  final AuthRepository _authRepository;

  CustomIntentsLocalDataSource(this._appDatabase, this._authRepository);

  String get _userId => _authRepository.currentUser!.id;

  Future<List<CustomIntent>> getCustomIntents() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.customIntents,
      where: 'user_id = ?',
      whereArgs: <Object?>[_userId],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<int> countCustomIntents() async {
    final Database db = await _appDatabase.database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${AppDatabase.customIntents} '
            'WHERE user_id = ?',
            <Object?>[_userId],
          ),
        ) ??
        0;
  }

  /// Adds one and hands it straight back, so the caller never has to re-read
  /// the table to learn the id it must now write onto a screenshot.
  ///
  /// The id is derived from the clock rather than from a counter: it has to be
  /// unique across accounts and across restores (a backup carries the row and
  /// its id with it), and a per-user `MAX(id) + 1` would hand two devices the
  /// same id for two different verbs the moment the same account used both.
  Future<CustomIntent> createCustomIntent({
    required String label,
    required String iconKey,
  }) async {
    final Database db = await _appDatabase.database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final String id =
        '${IntentRef.customPrefix}${DateTime.now().microsecondsSinceEpoch}';

    // Appended, not inserted: a new verb goes at the end of the list the user
    // has already learned the shape of. The picker promotes what gets used, so
    // a genuinely useful one reaches the front row on its own within a day.
    final int nextOrder =
        (Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT MAX(sort_order) FROM ${AppDatabase.customIntents} '
                'WHERE user_id = ?',
                <Object?>[_userId],
              ),
            ) ??
            -1) +
        1;

    await db.insert(AppDatabase.customIntents, <String, Object?>{
      'user_id': _userId,
      'id': id,
      'label': label,
      'icon_key': iconKey,
      'sort_order': nextOrder,
      'created_at': now,
    });

    return CustomIntent(
      id: id,
      label: label,
      iconKey: iconKey,
      sortOrder: nextOrder,
    );
  }

  Future<void> updateCustomIntent({
    required String id,
    required String label,
    required String iconKey,
  }) async {
    final Database db = await _appDatabase.database;
    await db.update(
      AppDatabase.customIntents,
      <String, Object?>{'label': label, 'icon_key': iconKey},
      where: 'user_id = ? AND id = ?',
      whereArgs: <Object?>[_userId, id],
    );
  }

  /// Removes a custom intent **and every reference to it**, in one
  /// transaction.
  ///
  /// The screenshots themselves survive untouched; only the answer to "what
  /// were you going to do with this" goes, because the words that answer it no
  /// longer exist. Leaving the references behind instead would strand those
  /// screenshots: still counted as waiting, under a heading nothing can name,
  /// reachable from no screen — the exact shape of the permanent number this
  /// whole feature was built to avoid.
  Future<void> deleteCustomIntent(String id) async {
    final Database db = await _appDatabase.database;
    await db.transaction((Transaction txn) async {
      await txn.update(
        AppDatabase.screenshotMeta,
        <String, Object?>{
          'intent': null,
          'intent_done_at': null,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'user_id = ? AND intent = ?',
        whereArgs: <Object?>[_userId, id],
      );
      await txn.delete(
        AppDatabase.customIntents,
        where: 'user_id = ? AND id = ?',
        whereArgs: <Object?>[_userId, id],
      );
    });
  }

  /// Intent ids in the order this person last used them, most recent first.
  ///
  /// This is what decides which five chips the picker shows without asking
  /// anybody to configure anything. Recency rather than total count on
  /// purpose: a month of buying things should not keep "buy" pinned to the
  /// front row through a week in which every screenshot is a recipe.
  ///
  /// Includes built-in and custom ids indiscriminately — the row does not
  /// distinguish them and neither should their ranking.
  Future<List<String>> getIntentIdsByRecentUse() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT intent, MAX(updated_at) AS last_used '
      'FROM ${AppDatabase.screenshotMeta} '
      'WHERE user_id = ? AND intent IS NOT NULL '
      'GROUP BY intent ORDER BY last_used DESC',
      <Object?>[_userId],
    );
    return rows
        .map((Map<String, Object?> row) => row['intent'] as String)
        .toList();
  }

  CustomIntent _fromRow(Map<String, Object?> row) => CustomIntent(
    id: row['id'] as String,
    label: row['label'] as String,
    iconKey: row['icon_key'] as String,
    sortOrder: row['sort_order'] as int,
  );
}
