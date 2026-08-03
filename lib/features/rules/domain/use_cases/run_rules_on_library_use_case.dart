import 'package:shoto/features/rules/domain/entities/rule_run_result.dart';
import 'package:shoto/features/rules/domain/repositories/rules_repository.dart';

class RunRulesOnLibraryUseCase {
  final RulesRepository repository;
  RunRulesOnLibraryUseCase(this.repository);

  Future<RuleRunResult> call({
    void Function(int processed, int total)? onProgress,
  }) => repository.runRulesOnLibrary(onProgress: onProgress);
}
