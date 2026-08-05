import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// Backs the free-tier cap on user-authored intents.
class GetCustomIntentCountUseCase {
  final ScreenshotRepository repository;
  GetCustomIntentCountUseCase(this.repository);

  Future<int> call() => repository.getCustomIntentCount();
}
