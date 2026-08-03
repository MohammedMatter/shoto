import 'package:shoto/features/rules/domain/repositories/rules_repository.dart';

class SetRuleEnabledUseCase {
  final RulesRepository repository;
  SetRuleEnabledUseCase(this.repository);

  Future<void> call(int ruleId, bool isEnabled) =>
      repository.setRuleEnabled(ruleId, isEnabled);
}
