import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// What the picker's front row is ordered by.
class GetIntentIdsByRecentUseUseCase {
  final ScreenshotRepository repository;
  GetIntentIdsByRecentUseUseCase(this.repository);

  Future<List<String>> call() => repository.getIntentIdsByRecentUse();
}
