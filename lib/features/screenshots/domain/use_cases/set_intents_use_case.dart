import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// One answer for many screenshots — what the selection bar calls.
class SetIntentsUseCase {
  final ScreenshotRepository repository;
  SetIntentsUseCase(this.repository);

  Future<void> call(List<String> assetIds, IntentRef? intent) =>
      repository.setIntents(assetIds, intent);
}
