import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/smart_actions/data/services/action_extractor.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';
import 'package:shoto/features/smart_actions/domain/repositories/smart_actions_repository.dart';

class SmartActionsRepositoryImpl implements SmartActionsRepository {
  final ScreenshotRepository _screenshots;

  SmartActionsRepositoryImpl(this._screenshots);

  @override
  Future<List<DetectedAction>> actionsFor(ScreenshotEntity screenshot) async {
    // Three features now share one OCR cache — search, smart albums and
    // this. Recognition is by far the expensive part, so it only ever runs
    // for text nobody has read yet.
    final Map<String, String> cached = await _screenshots.getCachedOcrText();
    String? text = cached[screenshot.id];
    text ??= await _screenshots.extractAndCacheText(screenshot);

    return ActionExtractor.extract(text);
  }
}
