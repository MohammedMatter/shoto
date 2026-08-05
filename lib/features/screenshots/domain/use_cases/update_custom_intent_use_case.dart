import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class UpdateCustomIntentUseCase {
  final ScreenshotRepository repository;
  UpdateCustomIntentUseCase(this.repository);

  Future<void> call({
    required String id,
    required String label,
    required String iconKey,
  }) => repository.updateCustomIntent(id: id, label: label, iconKey: iconKey);
}
