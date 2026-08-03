import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/features/rules/domain/repositories/rules_repository.dart';

/// Rewrites a rule the user already wrote.
///
/// Its own use case rather than a delete-then-create, because those are not
/// equivalent: a rule's priority and its on/off switch are part of it, and
/// rebuilding it from scratch to fix one misspelled word would move it to the
/// bottom of the priority order and turn it back on.
class UpdateRuleUseCase {
  final RulesRepository repository;
  UpdateRuleUseCase(this.repository);

  Future<void> call({
    required int ruleId,
    required String name,
    required int folderId,
    required List<RuleCondition> conditions,
    required RuleMatch match,
  }) {
    return repository.updateRule(
      ruleId: ruleId,
      name: name,
      folderId: folderId,
      conditions: conditions,
      match: match,
    );
  }
}
