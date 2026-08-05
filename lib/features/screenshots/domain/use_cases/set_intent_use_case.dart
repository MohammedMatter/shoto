import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class SetIntentUseCase {
  final ScreenshotRepository repository;
  SetIntentUseCase(this.repository);

  Future<void> call(String assetId, IntentRef? intent) =>
      repository.setIntent(assetId, intent);
}
