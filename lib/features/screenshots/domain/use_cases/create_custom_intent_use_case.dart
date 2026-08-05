import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class CreateCustomIntentUseCase {
  final ScreenshotRepository repository;
  CreateCustomIntentUseCase(this.repository);

  Future<CustomIntent> call({
    required String label,
    required String iconKey,
  }) => repository.createCustomIntent(label: label, iconKey: iconKey);
}
