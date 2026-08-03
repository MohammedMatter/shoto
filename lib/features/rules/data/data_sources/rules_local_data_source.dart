import 'package:sqflite/sqflite.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/rules/data/models/rule_model.dart';

/// Filing rules are per-account, same reasoning as folders: a rule points at
/// a folder, and folders already belong to one account.
class RulesLocalDataSource {
  final AppDatabase _appDatabase;
  final AuthRepository _authRepository;

  RulesLocalDataSource(this._appDatabase, this._authRepository);

  String get _userId => _authRepository.currentUser!.id;

  /// In priority order: the rule that wins a contested screenshot first.
  ///
  /// This is the *only* thing that decides which of two competing rules gets
  /// a screenshot, so the order this returns has to be the order the user is
  /// shown and can change — anything else is a decision made on their behalf
  /// that they cannot see. `created_at` breaks ties so the order is total
  /// even for rows that predate [reorderRules] and share a `sort_order`.
  Future<List<FilingRule>> getRules() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.filingRules,
      where: 'user_id = ?',
      whereArgs: [_userId],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(RuleModel.fromRow).toList();
  }

  Future<FilingRule> createRule({
    required String name,
    required int folderId,
    required List<RuleCondition> conditions,
    required RuleMatch match,
  }) async {
    final Database db = await _appDatabase.database;
    final int now = DateTime.now().millisecondsSinceEpoch;

    final int id = await db.insert(
      AppDatabase.filingRules,
      RuleModel.toRow(
        FilingRule(
          id: 0,
          name: name,
          folderId: folderId,
          conditions: conditions,
          match: match,
        ),
        userId: _userId,
        createdAt: now,
        // Last, so a new rule never quietly outranks one already relied on.
        // Moving it up is one tap on the list; discovering that a rule you
        // wrote months ago stopped firing is not.
        sortOrder: await _nextSortOrder(db),
      ),
    );

    return FilingRule(
      id: id,
      name: name,
      folderId: folderId,
      conditions: conditions,
      match: match,
    );
  }

  /// Rewrites a rule in place, keeping its id, its priority and whether it is
  /// switched on.
  ///
  /// Editing used to mean deleting and rebuilding, which is not the same
  /// thing: it dropped the rule's place in the priority order and its
  /// enabled state, so fixing a typo could change which rule wins.
  Future<void> updateRule({
    required int ruleId,
    required String name,
    required int folderId,
    required List<RuleCondition> conditions,
    required RuleMatch match,
  }) async {
    final Database db = await _appDatabase.database;
    await db.update(
      AppDatabase.filingRules,
      {
        'name': name,
        'folder_id': folderId,
        'conditions': RuleModel.encodeConditions(conditions),
        'match_all': match == RuleMatch.all ? 1 : 0,
      },
      where: 'user_id = ? AND id = ?',
      whereArgs: [_userId, ruleId],
    );
  }

  /// Stores [orderedIds] as the new priority order, first wins.
  ///
  /// One transaction, because a half-applied reorder is a priority order that
  /// matches neither what the user saw nor what they asked for — and the next
  /// screenshot to arrive would be filed by it.
  Future<void> reorderRules(List<int> orderedIds) async {
    final Database db = await _appDatabase.database;
    await db.transaction((txn) async {
      for (int i = 0; i < orderedIds.length; i++) {
        await txn.update(
          AppDatabase.filingRules,
          {'sort_order': i},
          where: 'user_id = ? AND id = ?',
          whereArgs: [_userId, orderedIds[i]],
        );
      }
    });
  }

  Future<int> _nextSortOrder(Database db) async {
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT MAX(sort_order) AS max_order FROM ${AppDatabase.filingRules} '
      'WHERE user_id = ?',
      [_userId],
    );
    final Object? highest = rows.isEmpty ? null : rows.first['max_order'];
    return highest is int ? highest + 1 : 0;
  }

  Future<void> setEnabled(int ruleId, bool isEnabled) async {
    final Database db = await _appDatabase.database;
    await db.update(
      AppDatabase.filingRules,
      {'is_enabled': isEnabled ? 1 : 0},
      where: 'user_id = ? AND id = ?',
      whereArgs: [_userId, ruleId],
    );
  }

  Future<void> deleteRule(int ruleId) async {
    final Database db = await _appDatabase.database;
    await db.delete(
      AppDatabase.filingRules,
      where: 'user_id = ? AND id = ?',
      whereArgs: [_userId, ruleId],
    );
  }
}
