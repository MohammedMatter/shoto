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

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
