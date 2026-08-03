import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';

abstract class SmartActionsRepository {
  /// Everything actionable found in [screenshot].
  ///
  /// Reuses text a previous OCR pass already cached and only runs
  /// recognition when there is none, so opening a screenshot that search or
  /// smart albums has already read costs nothing.
  Future<List<DetectedAction>> actionsFor(ScreenshotEntity screenshot);
}
