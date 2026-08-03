import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/features/rules/domain/entities/rule_run_result.dart';

abstract class RulesRepository {
  /// In priority order — the first rule that matches is the one that files.
  Future<List<FilingRule>> getRules();

  Future<FilingRule> createRule({
    required String name,
    required int folderId,
    required List<RuleCondition> conditions,
    required RuleMatch match,
  });

  /// Rewrites an existing rule, keeping its priority and enabled state.
  Future<void> updateRule({
    required int ruleId,
    required String name,
    required int folderId,
    required List<RuleCondition> conditions,
    required RuleMatch match,
  });

  /// Stores [orderedIds] as the priority order, highest priority first.
  Future<void> reorderRules(List<int> orderedIds);

  Future<void> setRuleEnabled(int ruleId, bool isEnabled);
  Future<void> deleteRule(int ruleId);

  /// Files [assetId] according to the rules, if any of them match.
  ///
  /// Returns the folder it was filed into, or null if no rule applied.
  /// Only reads facts already cached — it never triggers OCR or the vision
  /// model itself, so filing one screenshot can't turn into a library sweep.
  Future<int?> applyRulesTo(String assetId);

  /// Runs every rule over the screenshots that aren't in a folder yet.
  ///
  /// Deliberately limited to unfiled screenshots: re-filing something the
  /// user already put somewhere by hand would overrule a decision they made
  /// on purpose, which is the exact failure that killed automatic albums.
  Future<RuleRunResult> runRulesOnLibrary({
    void Function(int processed, int total)? onProgress,
  });
}
