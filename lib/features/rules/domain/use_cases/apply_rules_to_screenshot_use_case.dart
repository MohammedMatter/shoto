import 'package:shoto/features/rules/domain/repositories/rules_repository.dart';

/// Files a freshly-arrived screenshot if any rule claims it. Returns the
/// folder id it landed in, or null when nothing matched.
class ApplyRulesToScreenshotUseCase {
  final RulesRepository repository;
  ApplyRulesToScreenshotUseCase(this.repository);

  Future<int?> call(String assetId) => repository.applyRulesTo(assetId);
}
