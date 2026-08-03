import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/features/rules/domain/repositories/rules_repository.dart';

class CreateRuleUseCase {
  final RulesRepository repository;
  CreateRuleUseCase(this.repository);

  Future<FilingRule> call({
    required String name,
    required int folderId,
    required List<RuleCondition> conditions,
    required RuleMatch match,
  }) {
    return repository.createRule(
      name: name,
      folderId: folderId,
      conditions: conditions,
      match: match,
    );
  }
}
