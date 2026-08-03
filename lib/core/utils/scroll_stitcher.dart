import 'dart:typed_data';

/// A column-averaged brightness profile of one image — the only thing the
/// stitching maths ever looks at.
///
/// Each source row is squashed to [width] luminance samples, so a 1080-px-wide
/// screenshot becomes 48 numbers per row. That averaging is not just a speed
/// trick: it suppresses JPEG ringing and sub-pixel text rendering differences
/// that would otherwise make two captures of the *same* content compare as
/// different. Row count stays at full resolution because the seam has to land
/// on an exact pixel or the join is visible.
class RowProfile {
  final int width;
  final int height;

  /// `height * width` luminance bytes, row-major.
  final Uint8List luma;

  const RowProfile({
    required this.width,
    required this.height,
    required this.luma,
  });
}

/// Where two consecutive scrolling captures line up.
class ScrollSeam {
  /// Row in the *upper* image that the lower image's first scrolling row
  /// corresponds to. Everything below this row in the upper image is a
  /// repeat of what the lower image already shows.
  final int offset;

  /// Rows of non-scrolling chrome (status bar, sticky app bar) at the top of
  /// the lower image. Its content therefore starts at this row, not at 0.
  final int fixedTop;

  /// Rows of non-scrolling chrome at the bottom (nav bar, tab bar).
  final int fixedBottom;

  /// Mean absolute luminance difference across the matched region — 0 is a
  /// pixel-perfect match. Kept for diagnostics and for ranking.
  final double score;

  const ScrollSeam({
    required this.offset,
    required this.fixedTop,
    required this.fixedBottom,
    required this.score,
  });

  /// How far the content actually scrolled between the two captures.
  int get advance => offset - fixedTop;
}

/// One image's contribution to the finished tall image.
class StitchSlice {
  final int imageIndex;
  final int sourceTop;

  /// Exclusive.
  final int sourceBottom;
  final int destTop;

  const StitchSlice({
    required this.imageIndex,
    required this.sourceTop,
    required this.sourceBottom,
    required this.destTop,
  });

  int get height => sourceBottom - sourceTop;
}

/// Detects how a series of scrolling screenshots overlap, so they can be
/// merged into one tall image.
///
/// The problem is 1-dimensional: the user scrolled straight down, so the
/// images differ only by a vertical shift. That makes it tractable without
/// any feature detection or ML — we just have to find, for each pair, the
/// row alignment where the images agree.
///
/// Three things make a naive "slide until it matches" approach fail on real
/// screenshots, and each is handled explicitly below:
///
/// 1. **The status bar never scrolls.** Its clock even *changes* between
///    captures. Matching the lower image's row 0 against page content is
///    guaranteed to mismatch, poisoning every candidate offset. Fixed chrome
///    is therefore detected first (rows that are identical at the *same*
///    position in both images) and excluded from both matching and output.
/// 2. **Cost.** Comparing every offset at full resolution is O(height²) per
///    pair — hundreds of millions of byte comparisons on a 2400-px screenshot.
///    A coarse pass on 8x row-averaged profiles narrows it to a window, then
///    a fine pass recovers the exact row.
/// 3. **Wrong answers are worse than no answer.** A confident-looking match
///    can be pure coincidence on repetitive content (a chat list, a table).
///    A result is only returned when it clears an absolute similarity bar
///    *and* is decisively better than the next-best alternative.
abstract class ScrollStitcher {
  ScrollStitcher._();

  /// Luminance samples kept per row. Enough columns to keep layout structure
  /// distinguishable, few enough that a full search stays cheap.
  static const int profileWidth = 48;

  /// Per-row mean difference below which two rows count as "the same pixels".
  /// Non-zero because re-encoding, and the status bar clock ticking over,
  /// both perturb rows slightly without changing what they are.
  static const double _sameRowTolerance = 8.0;

  /// Fixed chrome can never plausibly be more than this share of the screen.
  /// Without the cap, two nearly-identical captures would be read as "all
  /// chrome" and produce nonsense.
  static const double _maxFixedFraction = 0.35;

  /// Below this much scrolling the pair is a re-take, not a scroll step.
  static const int _minAdvance = 8;

  /// How much the two images must still have in common for a match to mean
  /// anything. Matching on a sliver of rows is how false positives happen.
  static const double _minOverlapFraction = 0.12;
  static const int _minOverlapRows = 96;

  /// Absolute quality bar. True matches on real screenshots land near 0-4;
  /// this leaves headroom for heavy compression without admitting garbage.
  static const double _maxSeamScore = 10.0;

  /// The winner must beat the best *unrelated* candidate by this factor.
  /// Guards against repetitive layouts where many offsets look plausible.
  static const double _ambiguityRatio = 0.7;

  /// Row-averaging factor for the coarse pass.
  static const int _coarseFactor = 8;

  /// Minimum gap, in coarse rows, before a candidate counts as a rival rather
  /// than a neighbour of the winner. Wide enough that the two refinement
  /// windows (±[_coarseFactor] rows each) can never overlap.
  static const int _rivalSeparation = 3;

  /// How many coarse candidates get re-scored at full resolution. Cheap
  /// insurance: each refinement touches only a handful of offsets, and it is
  /// what stops a misleading coarse ranking from losing the right answer.
  static const int _coarseCandidates = 5;

  /// Finds where [lower] continues on from [upper], or null when they don't
  /// convincingly overlap (unrelated shots, duplicates, or too little in
  /// common to be sure).
  static ScrollSeam? findSeam(RowProfile upper, RowProfile lower) {
    if (upper.width != lower.width) return null;
    if (upper.width != profileWidth) return null;

    final int comparableHeight = upper.height < lower.height
        ? upper.height
        : lower.height;
    if (comparableHeight < _minOverlapRows * 2) return null;

    // Two captures of the same unscrolled screen aren't a stitch — they're a
    // duplicate, and forcing a seam onto them invents content.
    if (_meanAbsDiff(upper, 0, lower, 0, comparableHeight) <=
        _sameRowTolerance) {
      return null;
    }

    final int maxFixed = (comparableHeight * _maxFixedFraction).round();
    final int fixedTop = _leadingSharedRows(upper, lower, maxFixed);
    final int fixedBottom = _trailingSharedRows(upper, lower, maxFixed);

    final int upperContentEnd = upper.height - fixedBottom;
    final int lowerContentEnd = lower.height - fixedBottom;
    final int lowerContentRows = lowerContentEnd - fixedTop;
    if (lowerContentRows < _minOverlapRows) return null;

    final int minOverlap =
        _minOverlapRows > (comparableHeight * _minOverlapFraction).round()
        ? _minOverlapRows
        : (comparableHeight * _minOverlapFraction).round();

    final int minOffset = fixedTop + _minAdvance;
    final int maxOffset = upperContentEnd - minOverlap;
    if (maxOffset < minOffset) return null;

    // ---- Coarse pass -------------------------------------------------
    // Both images are cropped to their scrolling content *before* the rows
    // get averaged. Averaging first would smear the chrome boundary across a
    // group of rows, so the lower image's first coarse row would be part
    // status bar and part content and could never match cleanly.
    final RowProfile upperContent = _crop(upper, 0, upperContentEnd);
    final RowProfile lowerContent = _crop(lower, fixedTop, lowerContentEnd);

    final RowProfile upperCoarse = _averageRows(upperContent, _coarseFactor);
    final RowProfile lowerCoarse = _averageRows(lowerContent, _coarseFactor);
    if (upperCoarse.height == 0 || lowerCoarse.height == 0) return null;

    final List<int> coarseCandidates = _locateCandidates(
      upper: upperCoarse,
      lower: lowerCoarse,
      upperContentEnd: upperCoarse.height,
      lowerContentEnd: lowerCoarse.height,
      minOffset: minOffset ~/ _coarseFactor,
      maxOffset: maxOffset ~/ _coarseFactor,
      minOverlap: minOverlap ~/ _coarseFactor,
    );
    if (coarseCandidates.isEmpty) return null;

    // ---- Fine pass ---------------------------------------------------
    // The coarse pass only *locates* candidates; it must never judge them.
    // Row-averaging degrades the true alignment whenever the real offset
    // falls between two coarse steps, and on pale, low-contrast content
    // (a document, a chat on a white background) averaging flattens the
    // differences so much that the correct region need not even rank first.
    // Several candidates are therefore re-scored at full resolution, where
    // an exact alignment scores ~0, and the decision is made only on those
    // honest scores.
    final List<_Candidate> refined = [];
    for (final int candidate in coarseCandidates) {
      final _Candidate? result = _refine(
        upper: upper,
        lower: lower,
        fixedTop: fixedTop,
        upperContentEnd: upperContentEnd,
        lowerContentEnd: lowerContentEnd,
        minOffset: minOffset,
        maxOffset: maxOffset,
        minOverlap: minOverlap,
        around: candidate * _coarseFactor,
      );
      if (result != null) refined.add(result);
    }
    if (refined.isEmpty) return null;

    refined.sort((a, b) => a.score.compareTo(b.score));
    final _Candidate best = refined.first;
    if (best.score > _maxSeamScore) return null;

    // Repetitive layouts (chat lists, tables, calendars) can align
    // convincingly in more than one place. When a genuinely different
    // alignment scores nearly as well there is no safe way to choose, and a
    // wrong join silently fabricates content that was never on screen.
    final int separation = _rivalSeparation * _coarseFactor;
    for (final _Candidate rival in refined.skip(1)) {
      if ((rival.offset - best.offset).abs() < separation) continue;
      if (best.score > rival.score * _ambiguityRatio) return null;
      break;
    }

    return ScrollSeam(
      offset: best.offset,
      fixedTop: fixedTop,
      fixedBottom: fixedBottom,
      score: best.score,
    );
  }

  /// Re-scores the neighbourhood of a coarse candidate at full row
  /// resolution — the seam has to land on an exact pixel row or the join
  /// shows as a visible tear.
  static _Candidate? _refine({
    required RowProfile upper,
    required RowProfile lower,
    required int fixedTop,
    required int upperContentEnd,
    required int lowerContentEnd,
    required int minOffset,
    required int maxOffset,
    required int minOverlap,
    required int around,
  }) {
    final int from = _clamp(around - _coarseFactor, minOffset, maxOffset);
    final int to = _clamp(around + _coarseFactor, minOffset, maxOffset);

    int bestOffset = -1;
    double bestScore = double.infinity;

    for (int offset = from; offset <= to; offset++) {
      final int upperRows = upperContentEnd - offset;
      final int lowerRows = lowerContentEnd - fixedTop;
      final int rows = upperRows < lowerRows ? upperRows : lowerRows;
      if (rows < minOverlap) continue;

      final double score = _meanAbsDiff(upper, offset, lower, fixedTop, rows);
      if (score < bestScore) {
        bestScore = score;
        bestOffset = offset;
      }
    }

    if (bestOffset < 0) return null;
    return _Candidate(bestOffset, bestScore);
  }

  /// Turns per-pair seams into the exact source→destination rectangles that
  /// compose the final image, or null if the seams are mutually inconsistent
  /// (which would otherwise render as a torn or overlapping result).
  ///
  /// Each image hands over to the next at its seam offset, so the repeated
  /// content is dropped exactly once. Only the last image keeps its bottom
  /// chrome, and only the first keeps its top chrome.
  static List<StitchSlice>? buildSlices(
    List<int> imageHeights,
    List<ScrollSeam> seams,
  ) {
    if (imageHeights.length < 2) return null;
    if (seams.length != imageHeights.length - 1) return null;

    final List<StitchSlice> slices = [];
    int destTop = 0;

    for (int i = 0; i < imageHeights.length; i++) {
      // The first image keeps its header; later ones inherit the fixed-top
      // measurement from the seam that placed them.
      final int sourceTop = i == 0 ? 0 : seams[i - 1].fixedTop;
      // Every image except the last stops where its successor takes over.
      final int sourceBottom = i == imageHeights.length - 1
          ? imageHeights[i]
          : seams[i].offset;

      if (sourceBottom <= sourceTop) return null;
      if (sourceBottom > imageHeights[i]) return null;

      slices.add(
        StitchSlice(
          imageIndex: i,
          sourceTop: sourceTop,
          sourceBottom: sourceBottom,
          destTop: destTop,
        ),
      );
      destTop += sourceBottom - sourceTop;
    }

    return slices;
  }

  /// Total height of the composed image described by [slices].
  static int outputHeight(List<StitchSlice> slices) {
    if (slices.isEmpty) return 0;
    final StitchSlice last = slices.last;
    return last.destTop + last.height;
  }

  // -------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------

  /// The most promising alignments in the coarse profile, spread out so they
  /// represent genuinely different places rather than one place sampled
  /// repeatedly.
  ///
  /// Returns several because a coarse score is an unreliable ranking: it is
  /// computed on row-averaged data, which both blurs a true alignment that
  /// falls between steps and washes out the contrast that distinguishes
  /// regions of a pale document. The correct region reliably appears in this
  /// shortlist even when it doesn't top it.
  static List<int> _locateCandidates({
    required RowProfile upper,
    required RowProfile lower,
    required int upperContentEnd,
    required int lowerContentEnd,
    required int minOffset,
    required int maxOffset,
    required int minOverlap,
  }) {
    if (maxOffset < minOffset) return const [];

    final int span = maxOffset - minOffset + 1;
    final Float64List scores = Float64List(span);
    final int lowerRows = lowerContentEnd;

    for (int i = 0; i < span; i++) {
      final int offset = minOffset + i;
      // How many rows the two images can be compared over at this alignment:
      // limited both by what is left of the upper image and by how much
      // scrolling content the lower one has.
      final int upperRows = upperContentEnd - offset;
      final int rows = upperRows < lowerRows ? upperRows : lowerRows;
      scores[i] = rows < minOverlap
          ? double.infinity
          : _meanAbsDiff(upper, offset, lower, 0, rows);
    }

    // Greedy non-maximum suppression: take the best remaining offset, then
    // blank out its neighbourhood so the next pick is a different alignment
    // rather than the same one one row over.
    final List<int> picked = [];
    for (int n = 0; n < _coarseCandidates; n++) {
      int bestIndex = -1;
      double bestScore = double.infinity;
      for (int i = 0; i < span; i++) {
        if (scores[i] < bestScore) {
          bestScore = scores[i];
          bestIndex = i;
        }
      }
      if (bestIndex < 0) break;

      picked.add(minOffset + bestIndex);
      final int from = bestIndex - _rivalSeparation;
      final int to = bestIndex + _rivalSeparation;
      for (int i = from < 0 ? 0 : from; i <= to && i < span; i++) {
        scores[i] = double.infinity;
      }
    }

    return picked;
  }

  /// Mean absolute luminance difference between [rows] rows of each profile.
  static double _meanAbsDiff(
    RowProfile a,
    int aStart,
    RowProfile b,
    int bStart,
    int rows,
  ) {
    final int width = a.width;
    final int count = rows * width;
    if (count <= 0) return double.infinity;

    final Uint8List aLuma = a.luma;
    final Uint8List bLuma = b.luma;
    final int aBase = aStart * width;
    final int bBase = bStart * width;

    int total = 0;
    for (int i = 0; i < count; i++) {
      final int diff = aLuma[aBase + i] - bLuma[bBase + i];
      total += diff < 0 ? -diff : diff;
    }
    return total / count;
  }

  /// Rows from the top that are the same in both images *at the same
  /// position* — i.e. content that didn't move when the user scrolled, which
  /// is by definition fixed chrome.
  static int _leadingSharedRows(RowProfile a, RowProfile b, int limit) {
    int rows = 0;
    while (rows < limit) {
      if (_meanAbsDiff(a, rows, b, rows, 1) > _sameRowTolerance) break;
      rows++;
    }
    return rows;
  }

  static int _trailingSharedRows(RowProfile a, RowProfile b, int limit) {
    int rows = 0;
    while (rows < limit) {
      final int aRow = a.height - 1 - rows;
      final int bRow = b.height - 1 - rows;
      if (aRow < 0 || bRow < 0) break;
      if (_meanAbsDiff(a, aRow, b, bRow, 1) > _sameRowTolerance) break;
      rows++;
    }
    return rows;
  }

  /// Collapses groups of [factor] rows into one averaged row, for the coarse
  /// search. Averaging rather than sampling matters — dropping rows would
  /// alias fine horizontal detail like text baselines and could make the
  /// correct alignment score worse than a wrong one.
  static RowProfile _averageRows(RowProfile source, int factor) {
    final int width = source.width;
    final int height = source.height ~/ factor;
    final Uint8List out = Uint8List(height * width);

    for (int y = 0; y < height; y++) {
      final int sourceBase = y * factor * width;
      final int outBase = y * width;
      for (int x = 0; x < width; x++) {
        int sum = 0;
        for (int i = 0; i < factor; i++) {
          sum += source.luma[sourceBase + i * width + x];
        }
        out[outBase + x] = sum ~/ factor;
      }
    }

    return RowProfile(width: width, height: height, luma: out);
  }

  /// Rows `[top, bottom)` of [source] as a standalone profile.
  static RowProfile _crop(RowProfile source, int top, int bottom) {
    final int width = source.width;
    final int height = bottom - top;
    if (height <= 0) {
      return RowProfile(width: width, height: 0, luma: Uint8List(0));
    }
    return RowProfile(
      width: width,
      height: height,
      luma: Uint8List.sublistView(source.luma, top * width, bottom * width),
    );
  }

  static int _clamp(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

class _Candidate {
  final int offset;
  final double score;

  const _Candidate(this.offset, this.score);
}
