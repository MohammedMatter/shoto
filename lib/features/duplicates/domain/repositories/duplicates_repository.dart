import 'package:shoto/features/duplicates/domain/entities/duplicate_group.dart';

abstract class DuplicatesRepository {
  /// Scans the library for visually-identical screenshots.
  ///
  /// Hashing every image is the slow part (it decodes a thumbnail per
  /// screenshot), so [onProgress] fires as work completes to drive a
  /// progress bar. Hashes are cached, making repeat scans near-instant for
  /// screenshots that haven't changed.
  Future<List<DuplicateGroup>> findDuplicates({
    void Function(int processed, int total)? onProgress,
  });

  /// Permanently deletes the given screenshots from the device gallery.
  /// Returns the ids actually deleted — the system prompt can be refused.
  Future<List<String>> deleteScreenshots(List<String> assetIds);
}
