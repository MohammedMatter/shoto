import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';
import 'package:shoto/features/smart_actions/domain/repositories/smart_actions_repository.dart';

class GetScreenshotActionsUseCase {
  final SmartActionsRepository repository;
  GetScreenshotActionsUseCase(this.repository);

  Future<List<DetectedAction>> call(ScreenshotEntity screenshot) =>
      repository.actionsFor(screenshot);
}
