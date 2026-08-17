import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Clears the app's temporary directory (thumbnail/OCR scratch files, share
/// intent staging files) — not the sqflite database or gallery photos.
class CacheService {
  Future<int> getCacheSizeBytes() async {
    final Directory dir = await getTemporaryDirectory();
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final FileSystemEntity entity in dir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {
          // File may have been deleted concurrently — skip it.
        }
      }
    }
    return total;
  }

  Future<void> clearCache() async {
    final Directory dir = await getTemporaryDirectory();
    if (!await dir.exists()) return;
    await for (final FileSystemEntity entity in dir.list(followLinks: false)) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {
        // Best-effort — some files may be locked/in use.
      }
    }
  }

  // **There used to be a `formatBytes` here and it had no callers.**
  //
  // Two other copies of the same function do have them: `byte_formatter.dart`,
  // which the duplicates screen uses, and a private one in
  // `settings_tiles.dart`. The settings one is not a duplicate that should be
  // folded in — it wraps its result in U+2066/U+2069 so a size keeps its unit
  // when it lands in a right-to-left paragraph, which the shared helper does
  // not do. A third, unused copy sitting on this service was only ever going to
  // be picked up by the next person who needed a size formatted, and it is the
  // one of the three that is wrong for that job.
}
