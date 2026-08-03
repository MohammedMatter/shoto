import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class GetManagedScreenshotCountUseCase {
  final ScreenshotRepository repository;
  GetManagedScreenshotCountUseCase(this.repository);

  Future<int> call() => repository.getManagedScreenshotCount();
}
