import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/features/rules/domain/repositories/rules_repository.dart';

class GetRulesUseCase {
  final RulesRepository repository;
  GetRulesUseCase(this.repository);

  Future<List<FilingRule>> call() => repository.getRules();
}
