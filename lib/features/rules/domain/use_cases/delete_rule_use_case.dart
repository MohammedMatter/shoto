import 'package:shoto/features/rules/domain/repositories/rules_repository.dart';

class DeleteRuleUseCase {
  final RulesRepository repository;
  DeleteRuleUseCase(this.repository);

  Future<void> call(int ruleId) => repository.deleteRule(ruleId);
}
