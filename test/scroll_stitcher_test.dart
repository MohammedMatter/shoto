import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/scroll_stitcher.dart';

/// The tests build a tall synthetic "page", then cut viewport-sized captures
/// out of it at known scroll positions — exactly what a user's screenshots
/// are. Because the scroll distance is known up front, every assertion can
/// demand the *exact* row rather than an approximate one: a seam that is off
/// by a single pixel produces a visible tear in the real feature.
void main() {
  const int width = ScrollStitcher.profileWidth;
  const int viewport = 800;
  const int statusBar = 60;
  const int navBar = 48;

  /// Dense per-pixel noise — every row is unique. Isolates "can it find the
  /// right alignment" from "is the content distinguishable".
  int noiseValue(int row, int col) {
    int h = (row * 73856093) ^ (col * 19349663);
    h = (h ^ (h >> 13)) * 1274126177;
    return (h ^ (h >> 16)) & 0xFF;
  }

  /// Closer to a real screenshot: near-white background with occasional dark
  /// text lines. Most rows are blank and identical to each other, which is
  /// the situation that makes naive matchers guess wrong.
  ///
  /// Rows within one line of text are varied rather than duplicated, matching
  /// how anti-aliased glyphs actually render — an ascender row is not the
  /// same pixels as the baseline row. Duplicating them instead would build a
  /// genuine ±1-row ambiguity into the fixture, and then punish the algorithm
  /// for correctly declining to guess between two identical-looking answers.
  int documentValue(int row, int col) {
    final int band = row % 7;
    if (band >= 3) return 250; // blank gap between lines of text
    final int seed = ((row ~/ 7) * 2654435761) ^ (col * 40503) ^ (band * 6151);
    final int mixed = (seed ^ (seed >> 15)) & 0xFF;
    return mixed < 110 ? 30 + (mixed % 40) : 250; // glyph or paper
  }

  Uint8List buildPage(int height, int Function(int, int) generator) {
    final Uint8List page = Uint8List(height * width);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        page[y * width + x] = generator(y, x);
      }
    }
    return page;
  }

  /// Cuts one capture out of [page] at [scroll], optionally framed by fixed
  /// chrome. [clockShift] perturbs a couple of status-bar columns the way a
  /// ticking clock does between two real screenshots.
  RowProfile capture(
    Uint8List page, {
    required int scroll,
    int top = 0,
    int bottom = 0,
    int clockShift = 0,
    int noise = 0,
  }) {
    final Uint8List out = Uint8List(viewport * width);
    final Random random = Random(scroll * 7919 + 13);

    for (int y = 0; y < viewport; y++) {
      for (int x = 0; x < width; x++) {
        int value;
        if (y < top) {
          value = 200; // status bar: constant across every capture...
          if (clockShift != 0 && y >= 20 && y < 40 && x >= 40 && x < 42) {
            value = 200 - clockShift; // ...except the clock digits
          }
        } else if (y >= viewport - bottom) {
          value = 180; // nav bar
        } else {
          final int pageRow = scroll + y - top;
          value = page[pageRow * width + x];
        }
        if (noise != 0) {
          value = (value + random.nextInt(noise * 2 + 1) - noise).clamp(0, 255);
        }
        out[y * width + x] = value;
      }
    }

    return RowProfile(width: width, height: viewport, luma: out);
  }

  group('finds the exact seam', () {
    test('plain scroll with no chrome', () {
      final Uint8List page = buildPage(4000, noiseValue);
      final RowProfile a = capture(page, scroll: 0);
      final RowProfile b = capture(page, scroll: 420);

      final ScrollSeam? seam = ScrollStitcher.findSeam(a, b);

      expect(seam, isNotNull);
      expect(seam!.fixedTop, 0);
      expect(seam.offset, 420);
      expect(seam.advance, 420);
    });

    test('status bar is excluded and the seam still lands exactly', () {
      final Uint8List page = buildPage(4000, noiseValue);
      final RowProfile a = capture(page, scroll: 0, top: statusBar);
      final RowProfile b = capture(page, scroll: 500, top: statusBar);

      final ScrollSeam? seam = ScrollStitcher.findSeam(a, b);

      expect(seam, isNotNull);
      expect(seam!.fixedTop, statusBar);
      // Content that sits at row `statusBar` of the lower capture appeared
      // `advance` rows further down in the upper one.
      expect(seam.advance, 500);
      expect(seam.advance, 500);
    });

    test('a ticking clock does not break chrome detection', () {
      final Uint8List page = buildPage(4000, noiseValue);
      final RowProfile a = capture(page, scroll: 0, top: statusBar);
      final RowProfile b = capture(
        page,
        scroll: 360,
        top: statusBar,
        clockShift: 120,
      );

      final ScrollSeam? seam = ScrollStitcher.findSeam(a, b);

      expect(seam, isNotNull);
      expect(seam!.fixedTop, statusBar);
      expect(seam.advance, 360);
    });

    test('detects a fixed bottom bar as well', () {
      final Uint8List page = buildPage(4000, noiseValue);
      final RowProfile a = capture(
        page,
        scroll: 0,
        top: statusBar,
        bottom: navBar,
      );
      final RowProfile b = capture(
        page,
        scroll: 300,
        top: statusBar,
        bottom: navBar,
      );

      final ScrollSeam? seam = ScrollStitcher.findSeam(a, b);

      expect(seam, isNotNull);
      expect(seam!.fixedTop, statusBar);
      expect(seam.fixedBottom, navBar);
      expect(seam.advance, 300);
    });

    test('sparse document content, mostly blank rows', () {
      final Uint8List page = buildPage(4000, documentValue);
      final RowProfile a = capture(page, scroll: 0, top: statusBar);
      final RowProfile b = capture(page, scroll: 455, top: statusBar);

      final ScrollSeam? seam = ScrollStitcher.findSeam(a, b);

      expect(seam, isNotNull);
      expect(seam!.advance, 455);
    });

    test('survives re-compression noise', () {
      final Uint8List page = buildPage(4000, noiseValue);
      final RowProfile a = capture(page, scroll: 0, top: statusBar, noise: 4);
      final RowProfile b = capture(page, scroll: 275, top: statusBar, noise: 4);

      final ScrollSeam? seam = ScrollStitcher.findSeam(a, b);

      expect(seam, isNotNull);
      expect(seam!.advance, 275);
    });
  });

  // Hand-picked offsets hide bugs that only strike at particular alignments:
  // an early version of this algorithm worked for almost every scroll
  // distance but failed whenever the true offset landed exactly half way
  // between two coarse search steps. Sweeping the whole supported range is
  // the only way to be sure no such blind spot remains.
  //
  // These assert `advance`, not `offset`. When the first rows of scrolling
  // content happen to be identical in both captures, they are — by
  // definition — indistinguishable from fixed chrome, so the detector folds
  // them into `fixedTop` and `offset` shifts by the same amount. The pair
  // stays self-consistent and the composed image is byte-for-byte the same,
  // because what actually determines the output geometry is the scroll
  // distance: `offset - fixedTop`.
  group('exhaustive offset sweep', () {
    test('every scroll distance is recovered exactly', () {
      final Uint8List page = buildPage(6000, noiseValue);
      final RowProfile upper = capture(page, scroll: 0, top: statusBar);

      final List<String> failures = [];
      for (int advance = 16; advance <= 620; advance++) {
        final ScrollSeam? seam = ScrollStitcher.findSeam(
          upper,
          capture(page, scroll: advance, top: statusBar),
        );
        if (seam == null) {
          failures.add('$advance:refused');
        } else if (seam.advance != advance) {
          failures.add('$advance:got ${seam.advance}');
        }
      }

      expect(
        failures,
        isEmpty,
        reason: 'scroll distances mishandled: $failures',
      );
    });

    test('document-like content sweeps cleanly too', () {
      final Uint8List page = buildPage(6000, documentValue);
      final RowProfile upper = capture(page, scroll: 0, top: statusBar);

      final List<String> failures = [];
      for (int advance = 20; advance <= 600; advance++) {
        final ScrollSeam? seam = ScrollStitcher.findSeam(
          upper,
          capture(page, scroll: advance, top: statusBar),
        );
        if (seam == null) {
          failures.add('$advance:refused');
        } else if (seam.advance != advance) {
          failures.add('$advance:got ${seam.advance}');
        }
      }

      expect(
        failures,
        isEmpty,
        reason: 'scroll distances mishandled: $failures',
      );
    });

    test('a seam stays self-consistent even when chrome absorbs content', () {
      // Whatever the split between fixedTop and offset, the two must always
      // describe the same alignment — that identity is what buildSlices
      // relies on to produce a seamless join.
      final Uint8List page = buildPage(6000, documentValue);
      final RowProfile upper = capture(page, scroll: 0, top: statusBar);

      for (int advance = 100; advance <= 500; advance += 37) {
        final ScrollSeam seam = ScrollStitcher.findSeam(
          upper,
          capture(page, scroll: advance, top: statusBar),
        )!;
        expect(seam.offset - seam.fixedTop, seam.advance);
        expect(seam.advance, advance);
        // The composed height is driven purely by the scroll distance.
        final List<StitchSlice> slices = ScrollStitcher.buildSlices(
          [viewport, viewport],
          [seam],
        )!;
        expect(ScrollStitcher.outputHeight(slices), viewport + advance);
      }
    });
  });

  group('refuses rather than guessing', () {
    test('unrelated screenshots', () {
      final Uint8List pageA = buildPage(4000, noiseValue);
      final Uint8List pageB = buildPage(
        4000,
        (row, col) => noiseValue(row + 99991, col),
      );

      final ScrollSeam? seam = ScrollStitcher.findSeam(
        capture(pageA, scroll: 0),
        capture(pageB, scroll: 0),
      );

      expect(seam, isNull);
    });

    test('identical captures are a duplicate, not a scroll', () {
      final Uint8List page = buildPage(4000, noiseValue);

      final ScrollSeam? seam = ScrollStitcher.findSeam(
        capture(page, scroll: 200, top: statusBar),
        capture(page, scroll: 200, top: statusBar),
      );

      expect(seam, isNull);
    });

    test('scrolled so far there is nothing left in common', () {
      final Uint8List page = buildPage(4000, noiseValue);
      // Past a full viewport of scrolling the two captures share no content.
      final ScrollSeam? seam = ScrollStitcher.findSeam(
        capture(page, scroll: 0, top: statusBar),
        capture(page, scroll: 900, top: statusBar),
      );

      expect(seam, isNull);
    });

    test('mismatched widths', () {
      final Uint8List page = buildPage(4000, noiseValue);
      final RowProfile a = capture(page, scroll: 0);
      final RowProfile narrow = RowProfile(
        width: width - 1,
        height: viewport,
        luma: Uint8List(viewport * (width - 1)),
      );

      expect(ScrollStitcher.findSeam(a, narrow), isNull);
    });
  });

  group('slice planning', () {
    test('three captures compose without gaps or repeats', () {
      final Uint8List page = buildPage(6000, noiseValue);
      final RowProfile a = capture(page, scroll: 0, top: statusBar);
      final RowProfile b = capture(page, scroll: 400, top: statusBar);
      final RowProfile c = capture(page, scroll: 800, top: statusBar);

      final ScrollSeam? ab = ScrollStitcher.findSeam(a, b);
      final ScrollSeam? bc = ScrollStitcher.findSeam(b, c);
      expect(ab, isNotNull);
      expect(bc, isNotNull);

      final List<StitchSlice>? slices = ScrollStitcher.buildSlices(
        [viewport, viewport, viewport],
        [ab!, bc!],
      );
      expect(slices, isNotNull);
      expect(slices!.length, 3);

      // Every slice must start exactly where the previous one ended.
      for (int i = 1; i < slices.length; i++) {
        expect(slices[i].destTop, slices[i - 1].destTop + slices[i - 1].height);
      }

      // First capture keeps its status bar, the others drop theirs.
      expect(slices[0].sourceTop, 0);
      expect(slices[1].sourceTop, statusBar);
      expect(slices[2].sourceTop, statusBar);

      // Only the final capture runs to the bottom of its source.
      expect(slices[2].sourceBottom, viewport);

      // Total = one viewport plus the two scroll distances: nothing is
      // duplicated and nothing is lost.
      expect(ScrollStitcher.outputHeight(slices), viewport + 400 + 400);
    });

    test('rejects seam counts that do not match the images', () {
      const ScrollSeam seam = ScrollSeam(
        offset: 100,
        fixedTop: 0,
        fixedBottom: 0,
        score: 0,
      );
      expect(ScrollStitcher.buildSlices([800, 800, 800], [seam]), isNull);
      expect(ScrollStitcher.buildSlices([800], []), isNull);
    });

    test('rejects seams that would produce an empty slice', () {
      // A seam whose offset sits above the next image's own header would
      // mean the middle capture contributes nothing.
      const ScrollSeam first = ScrollSeam(
        offset: 700,
        fixedTop: 60,
        fixedBottom: 0,
        score: 0,
      );
      const ScrollSeam second = ScrollSeam(
        offset: 40,
        fixedTop: 60,
        fixedBottom: 0,
        score: 0,
      );
      expect(
        ScrollStitcher.buildSlices([800, 800, 800], [first, second]),
        isNull,
      );
    });
  });
}
