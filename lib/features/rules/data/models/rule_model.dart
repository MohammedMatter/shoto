import 'dart:convert';

import 'package:shoto/core/utils/filing_rules.dart';

/// Reads and writes a [FilingRule] as one database row.
///
/// The conditions live in a single JSON column, so this is also the only
/// place that knows their stored shape. Anything it cannot parse is dropped
/// rather than thrown on: a rule whose conditions are unreadable becomes a
/// rule that matches nothing, which is safe, instead of an exception that
/// takes down the whole rule list and with it the screen where you would fix
/// it.
class RuleModel {
  const RuleModel._();

  static Map<String, Object?> toRow(
    FilingRule rule, {
    required String userId,
    required int createdAt,
    required int sortOrder,
  }) {
    return {
      'user_id': userId,
      'name': rule.name,
      'folder_id': rule.folderId,
      'conditions': encodeConditions(rule.conditions),
      'match_all': rule.match == RuleMatch.all ? 1 : 0,
      'is_enabled': rule.isEnabled ? 1 : 0,
      // Not carried on [FilingRule]: priority *is* the rule's position in the
      // list the user sees, so the entity has nothing to hold. The column
      // exists only to make that position survive a restart.
      'sort_order': sortOrder,
      'created_at': createdAt,
    };
  }

  static FilingRule fromRow(Map<String, Object?> row) {
    return FilingRule(
      id: row['id'] as int,
      name: row['name'] as String,
      folderId: row['folder_id'] as int,
      conditions: decodeConditions(row['conditions'] as String?),
      match: (row['match_all'] as int?) == 0 ? RuleMatch.any : RuleMatch.all,
      isEnabled: (row['is_enabled'] as int?) != 0,
    );
  }

  static String encodeConditions(List<RuleCondition> conditions) {
    return jsonEncode([
      for (final RuleCondition condition in conditions)
        {
          'type': condition.type.name,
          'value': condition.value,
          'negated': condition.isNegated,
        },
    ]);
  }

  static List<RuleCondition> decodeConditions(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final Object? parsed = jsonDecode(raw);
      if (parsed is! List) return const [];

      final List<RuleCondition> conditions = [];
      for (final Object? item in parsed) {
        if (item is! Map) continue;
        final ConditionType? type = _typeFor(item['type']);
        if (type == null) continue;
        conditions.add(
          RuleCondition(
            type: type,
            value: item['value'] as String? ?? '',
            isNegated: item['negated'] == true,
          ),
        );
      }
      return conditions;
    } catch (_) {
      return const [];
    }
  }

  /// Unknown names are skipped rather than defaulted. A condition type this
  /// build doesn't understand — written by a newer version, say — must not
  /// quietly become a different condition that files things somewhere else.
  static ConditionType? _typeFor(Object? name) {
    for (final ConditionType type in ConditionType.values) {
      if (type.name == name) return type;
    }
    return null;
  }
}
