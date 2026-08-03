import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// Passive permission read — never prompts. Use this from anywhere that
/// reacts to app lifecycle; see [RequestPhotoPermissionUseCase] for the
/// prompting variant.
class CheckPhotoPermissionUseCase {
  final ScreenshotRepository repository;
  CheckPhotoPermissionUseCase(this.repository);

  Future<PermissionState> call() => repository.checkPermission();
}
