import 'package:shoto/core/localization/app_message.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/stitch/data/services/image_stitch_service.dart';
import 'package:shoto/features/stitch/domain/entities/stitch_outcome.dart';
import 'package:shoto/features/stitch/domain/repositories/stitch_repository.dart';

/// Goes through [ScreenshotRepository] rather than the gallery directly, so a
/// stitch can only ever read screenshots the signed-in account owns and the
/// result lands in that same account's library. Writing to the gallery here
/// would put the merged image in a place every account can see.
class StitchRepositoryImpl implements StitchRepository {
  final ScreenshotRepository _screenshots;
  final ImageStitchService _stitcher;

  StitchRepositoryImpl(this._screenshots, this._stitcher);

  @override
  Future<StitchOutcome> stitch(
    List<String> assetIds, {
    void Function(int step, int total)? onProgress,
  }) async {
    final List<ScreenshotEntity> screenshots = await _screenshots
        .getScreenshotsByIds(assetIds);
    if (screenshots.length != assetIds.length) {
      throw const StitchException(AppMessage.stitchUnreadable);
    }

    final List<AssetEntity> assets = screenshots
        .map((screenshot) => screenshot.asset)
        .toList();

    // A scroll runs top-to-bottom in time: the earliest capture shows the
    // top of the page. The gallery hands screenshots back newest-first, and
    // a user's selection order means nothing, so capture time is the only
    // trustworthy ordering.
    assets.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));

    return _stitcher.stitch(assets, onProgress: onProgress);
  }

  @override
  Future<String> save(StitchOutcome outcome) {
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    return _screenshots.saveGeneratedImage(
      outcome.pngBytes,
      filename: 'shoto_long_$stamp.png',
    );
  }
}
