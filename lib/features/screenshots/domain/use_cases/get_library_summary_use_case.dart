import 'package:shoto/features/screenshots/domain/entities/library_summary.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class GetLibrarySummaryUseCase {
  final ScreenshotRepository repository;
  GetLibrarySummaryUseCase(this.repository);

  Future<LibrarySummary> call() => repository.getLibrarySummary();
}
