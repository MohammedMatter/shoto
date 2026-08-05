import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class GetCustomIntentsUseCase {
  final ScreenshotRepository repository;
  GetCustomIntentsUseCase(this.repository);

  Future<List<CustomIntent>> call() => repository.getCustomIntents();
}
