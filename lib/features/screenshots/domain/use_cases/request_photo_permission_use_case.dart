import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class RequestPhotoPermissionUseCase {
  final ScreenshotRepository repository;
  RequestPhotoPermissionUseCase(this.repository);

  Future<PermissionState> call() => repository.requestPermission();
}
