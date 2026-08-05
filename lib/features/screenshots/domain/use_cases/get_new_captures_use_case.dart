import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// What the user has captured since they last looked, if they have asked to
/// be shown it.
///
/// The preference check lives here rather than at each call site on purpose.
/// Home asks this, the triage page asks this, and a settings row will ask it
/// next; three copies of `if (triageEnabled)` is how a feature that is
/// supposed to be off ends up running for somebody who declined it.
class GetNewCapturesUseCase {
  final ScreenshotRepository repository;
  final AppPreferences preferences;

  GetNewCapturesUseCase(this.repository, this.preferences);

  Future<List<AssetEntity>> call() async {
    if (!preferences.triageEnabled) return const [];
    return repository.getNewCaptures(since: preferences.triageSince);
  }
}
