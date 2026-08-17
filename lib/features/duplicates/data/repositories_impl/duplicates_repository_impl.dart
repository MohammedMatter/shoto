import 'dart:io';

import 'package:shoto/core/utils/perceptual_hash.dart';
import 'package:shoto/features/duplicates/data/data_sources/perceptual_hash_data_source.dart';
import 'package:shoto/features/duplicates/domain/entities/duplicate_group.dart';
import 'package:shoto/features/duplicates/domain/repositories/duplicates_repository.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class DuplicatesRepositoryImpl implements DuplicatesRepository {
  final ScreenshotRepository _screenshotRepository;
  final PerceptualHashDataSource _hasher;

  DuplicatesRepositoryImpl(this._screenshotRepository, this._hasher);

  @override
  Future<List<DuplicateGroup>> findDuplicates({
    void Function(int processed, int total)? onProgress,
  }) async {
    final List<ScreenshotEntity> screenshots = await _screenshotRepository
        .getAllScreenshots();
    if (screenshots.length < 2) return [];

    final Map<String, String> hashes = await _resolveHashes(
      screenshots,
      onProgress,
    );

    final List<List<ScreenshotEntity>> clusters = _cluster(screenshots, hashes);
    final List<DuplicateGroup> groups = [];
    for (final List<ScreenshotEntity> cluster in clusters) {
      groups.add(await _toGroup(cluster));
    }

    // Biggest wins first — the user sees the most impactful cleanup up top.
    groups.sort((a, b) => b.reclaimableBytes.compareTo(a.reclaimableBytes));
    return groups;
  }

  @override
  Future<List<String>> deleteScreenshots(List<String> assetIds) =>
      _screenshotRepository.deleteScreenshots(assetIds);

  /// Returns a hash per asset id, computing only the ones not already
  /// cached from a previous scan.
  Future<Map<String, String>> _resolveHashes(
    List<ScreenshotEntity> screenshots,
    void Function(int processed, int total)? onProgress,
  ) async {
    final Map<String, String> cached = await _screenshotRepository
        .getCachedPerceptualHashes();

    final Map<String, String> resolved = {};
    final Map<String, String> newlyComputed = {};
    final int total = screenshots.length;

    for (int i = 0; i < total; i++) {
      final ScreenshotEntity screenshot = screenshots[i];
      final String? existing = cached[screenshot.id];

      if (existing != null) {
        resolved[screenshot.id] = existing;
      } else {
        final String? hash = await _hasher.computeHash(screenshot.asset);
        if (hash != null) {
          resolved[screenshot.id] = hash;
          newlyComputed[screenshot.id] = hash;
        }
      }
      onProgress?.call(i + 1, total);
    }

    if (newlyComputed.isNotEmpty) {
      await _screenshotRepository.cachePerceptualHashes(newlyComputed);
    }
    return resolved;
  }

  /// Groups screenshots whose hashes are within
  /// [PerceptualHash.duplicateThreshold] bits of each other.
  ///
  /// Uses union-find so that similarity chains merge correctly: if A matches
  /// B and B matches C, all three end up in one group even when A and C
  /// aren't a direct match on their own.
  List<List<ScreenshotEntity>> _cluster(
    List<ScreenshotEntity> screenshots,
    Map<String, String> hashes,
  ) {
    final List<ScreenshotEntity> hashable = screenshots
        .where((screenshot) => hashes.containsKey(screenshot.id))
        .toList();
    if (hashable.length < 2) return [];

    final List<int> parent = List<int>.generate(hashable.length, (i) => i);

    int find(int node) {
      int root = node;
      while (parent[root] != root) {
        parent[root] = parent[parent[root]]; // path compression
        root = parent[root];
      }
      return root;
    }

    void union(int a, int b) {
      final int rootA = find(a);
      final int rootB = find(b);
      if (rootA != rootB) parent[rootB] = rootA;
    }

    // **Parsed once, outside the loop that runs n²/2 times.**
    //
    // This compared hex *strings*, so every one of half a million pairs at a
    // thousand screenshots paid sixteen `substring` allocations and sixteen
    // `int.tryParse` calls. Measured: 445ms at a thousand, 1.5 seconds at two
    // thousand — synchronous, on the thread drawing the progress bar that was
    // meant to be reassuring somebody. The same comparisons over packed
    // integers take 11ms and 45ms, and produce identical groupings.
    final List<int> packed = <int>[
      for (final ScreenshotEntity screenshot in hashable)
        PerceptualHash.packed(hashes[screenshot.id]!) ?? 0,
    ];

    for (int i = 0; i < hashable.length; i++) {
      final int hashI = packed[i];
      for (int j = i + 1; j < hashable.length; j++) {
        final int distance = PerceptualHash.distanceBetween(hashI, packed[j]);
        if (distance <= PerceptualHash.duplicateThreshold) union(i, j);
      }
    }

    final Map<int, List<ScreenshotEntity>> byRoot = {};
    for (int i = 0; i < hashable.length; i++) {
      byRoot.putIfAbsent(find(i), () => []).add(hashable[i]);
    }

    // Singletons aren't duplicates of anything.
    return byRoot.values.where((cluster) => cluster.length > 1).toList();
  }

  Future<DuplicateGroup> _toGroup(List<ScreenshotEntity> cluster) async {
    final List<DuplicateCandidate> candidates = [];
    for (final ScreenshotEntity screenshot in cluster) {
      candidates.add(
        DuplicateCandidate(
          screenshot: screenshot,
          fileSizeBytes: await _fileSize(screenshot),
        ),
      );
    }

    candidates.sort((a, b) => _keeperRank(a, b));
    return DuplicateGroup(
      candidates: candidates,
      suggestedKeeperId: candidates.first.id,
    );
  }

  /// Orders candidates best-keeper-first.
  ///
  /// The strongest signal is that the user already *organized* a copy
  /// (favorited it or filed it into a folder) — deleting that one would
  /// throw away their work, so it always wins. Failing that, prefer the
  /// higher-resolution copy, then the larger file, then the original
  /// (oldest) capture.
  int _keeperRank(DuplicateCandidate a, DuplicateCandidate b) {
    final int organized = _organizedScore(
      b.screenshot,
    ).compareTo(_organizedScore(a.screenshot));
    if (organized != 0) return organized;

    final int pixels = _pixelCount(
      b.screenshot,
    ).compareTo(_pixelCount(a.screenshot));
    if (pixels != 0) return pixels;

    final int size = b.fileSizeBytes.compareTo(a.fileSizeBytes);
    if (size != 0) return size;

    return a.screenshot.asset.createDateTime.compareTo(
      b.screenshot.asset.createDateTime,
    );
  }

  int _organizedScore(ScreenshotEntity screenshot) {
    int score = 0;
    if (screenshot.isFavorite) score += 2;
    if (screenshot.folderId != null) score += 1;
    return score;
  }

  int _pixelCount(ScreenshotEntity screenshot) =>
      screenshot.asset.width * screenshot.asset.height;

  Future<int> _fileSize(ScreenshotEntity screenshot) async {
    try {
      final File? file = await screenshot.asset.file;
      if (file == null) return 0;
      return await file.length();
    } catch (_) {
      // Size is only used for the "frees up X MB" estimate — a failure here
      // shouldn't drop the screenshot out of its duplicate group.
      return 0;
    }
  }
}
