import 'package:shoto/features/rules/domain/repositories/rules_repository.dart';

/// Sets which rule wins when several of them want the same screenshot.
///
/// A screenshot lives in exactly one folder, so with two matching rules
/// something has to break the tie. It used to be creation order, invisibly.
/// This makes it the order on screen, which is the only version of the answer
/// the user can check.
class ReorderRulesUseCase {
  final RulesRepository repository;
  ReorderRulesUseCase(this.repository);

  Future<void> call(List<int> orderedIds) => repository.reorderRules(orderedIds);
}
