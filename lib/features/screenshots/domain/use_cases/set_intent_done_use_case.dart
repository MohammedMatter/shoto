import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class SetIntentDoneUseCase {
  final ScreenshotRepository repository;
  SetIntentDoneUseCase(this.repository);

  Future<void> call(String assetId, bool isDone) =>
      repository.setIntentDone(assetId, isDone);
}
