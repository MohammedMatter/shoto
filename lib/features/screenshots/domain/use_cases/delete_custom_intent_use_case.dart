import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// Deleting one also clears it off every screenshot that carried it — see
/// [ScreenshotRepository.deleteCustomIntent].
class DeleteCustomIntentUseCase {
  final ScreenshotRepository repository;
  DeleteCustomIntentUseCase(this.repository);

  Future<void> call(String id) => repository.deleteCustomIntent(id);
}
