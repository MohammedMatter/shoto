import 'package:shoto/features/stitch/domain/entities/stitch_outcome.dart';
import 'package:shoto/features/stitch/domain/repositories/stitch_repository.dart';

class StitchScreenshotsUseCase {
  final StitchRepository repository;
  StitchScreenshotsUseCase(this.repository);

  Future<StitchOutcome> call(
    List<String> assetIds, {
    void Function(int step, int total)? onProgress,
  }) {
    return repository.stitch(assetIds, onProgress: onProgress);
  }
}
