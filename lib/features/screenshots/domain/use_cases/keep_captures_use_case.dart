import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// Brings the captures the user said yes to into the library.
///
/// Deliberately separate from the use case that *lists* them: listing is
/// allowed the moment the queue is switched on, keeping is a decision, and a
/// single class doing both is one refactor away from a list that quietly
/// imports what it lists.
class KeepCapturesUseCase {
  final ScreenshotRepository repository;

  KeepCapturesUseCase(this.repository);

  Future<int> call(List<String> assetIds) {
    if (assetIds.isEmpty) return Future<int>.value(0);
    return repository.keepCaptures(assetIds);
  }
}
