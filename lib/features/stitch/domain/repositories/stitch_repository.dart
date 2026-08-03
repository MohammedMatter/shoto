import 'package:shoto/features/stitch/domain/entities/stitch_outcome.dart';

abstract class StitchRepository {
  /// Merges the given screenshots into one tall image, held in memory.
  ///
  /// Throws [StitchException] with a reason worth showing the user when the
  /// captures can't be merged. Ordering is handled internally — callers pass
  /// the selection as-is.
  Future<StitchOutcome> stitch(
    List<String> assetIds, {
    void Function(int step, int total)? onProgress,
  });

  /// Writes a finished stitch into the device gallery. Returns the new
  /// asset's id.
  Future<String> save(StitchOutcome outcome);
}
