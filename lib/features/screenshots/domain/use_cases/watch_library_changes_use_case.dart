import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class WatchLibraryChangesUseCase {
  final ScreenshotRepository repository;
  WatchLibraryChangesUseCase(this.repository);

  Stream<void> call() => repository.onLibraryChanged;
}
