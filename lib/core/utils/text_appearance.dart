import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// What a piece of text on a screenshot looks like: the colour behind it, the
/// colour of the letters, and how safe it is to paint over.
///
/// Substitution stands or falls on this. Drawing a believable replacement
/// needs the same two colours the original used — get the background a shade
/// wrong and the patch shows as a rectangle in raking light; get the ink
/// wrong and the new text is the only thing on the screen in that colour.
/// Both are obvious in a way a black bar never is, because a black bar is not
/// pretending.
///
/// [uniformity] is the third answer and the one that decides *whether* to
/// substitute at all. A chat bubble or a bank statement is a flat slab of one
/// colour, and a patch of that colour is invisible. A photo, a gradient
/// header or a map is not, and no single fill will ever sit right on it —
/// there the honest move is to cover rather than to pretend.
class TextAppearance {
  /// The dominant colour around and behind the letters.
  final Color background;

  /// The letters' own colour.
  final Color ink;

  /// How much of the sampled area is within a shade of [background], from 0
  /// to 1. High means a flat surface; low means a photo or a gradient.
  final double uniformity;

  /// The share of the text's own rectangle that is ink rather than
  /// background — roughly, how heavy the lettering is.
  ///
  /// It is the only evidence available about weight. OCR reports what a line
  /// says and where it sits and nothing whatever about how it was drawn, so
  /// a bold heading substituted in regular weight reads as a different
  /// element on the screen even when every colour is right.
  final double inkShare;

  const TextAppearance({
    required this.background,
    required this.ink,
    required this.uniformity,
    this.inkShare = 0,
  });

  /// Whether the original lettering was heavy enough to redraw in semibold.
  ///
  /// The threshold sits high on purpose. Regular text at ordinary sizes
  /// covers well under a fifth of its own box; anything above a third is a
  /// heading or a total. Guessing bold on a regular line is the more visible
  /// mistake of the two, because the substitute then outweighs the label
  /// sitting next to it.
  bool get isHeavy => inkShare >= 0.30;

  /// Whether a flat fill of [background] will pass unnoticed.
  ///
  /// The threshold is deliberately generous. Ordinary interface text sits on
  /// a solid fill and scores well above 0.5 even counting the letters
  /// themselves as "not background"; anything that fails this is genuinely
  /// textured, and on textured ground a substitution is worse than a cover
  /// because it claims to be part of the picture.
  bool get canBeRepainted => uniformity >= 0.55;

  /// True when the text is darker than what it sits on — the normal case,
  /// and the one that decides which way a fallback ink should go.
  bool get isDarkOnLight => _luminance(ink) < _luminance(background);

  static double _luminance(Color color) =>
      (0.299 * (color.r * 255) +
          0.587 * (color.g * 255) +
          0.114 * (color.b * 255)) /
      255.0;

  @override
  String toString() =>
      'TextAppearance(bg: $background, ink: $ink, uniformity: '
      '${uniformity.toStringAsFixed(2)})';
}

/// Reads [TextAppearance] out of raw image pixels.
///
/// Pure Dart over a plain RGBA buffer, with no `Image`, no canvas and no
/// platform — so every rule below can be tested against a handful of
/// synthesised pixels instead of a screenshot.
abstract class TextAppearanceProbe {
  TextAppearanceProbe._();

  /// Colours quantised to 5 bits per channel before counting.
  ///
  /// Anti-aliasing means a screenshot with "one" background colour really
  /// holds a few hundred near-identical ones, and counting exact values would
  /// split the true background across all of them and let a stray pixel win.
  static const int _quantiseShift = 3;

  /// How far from the background a colour must be to count as ink.
  ///
  /// Below this it is an anti-aliased edge of the background rather than a
  /// letter. Measured as plain RGB distance, where 441 is black to white.
  static const double _inkDistance = 48;

  /// How close to the background a colour must be to count towards
  /// [TextAppearance.uniformity].
  static const double _flatDistance = 26;

  /// A bucket has to hold this share of the sample before it can be called
  /// the ink colour — otherwise a single bright pixel of a notification dot
  /// decides what colour the text is.
  static const double _minimumInkShare = 0.012;

  /// Samples the area of [bounds], plus a margin of clean background around
  /// it.
  ///
  /// The margin matters: OCR rectangles hug the glyphs, so inside one the
  /// letters can be a third of the pixels. Widening the sample by half the
  /// line's height brings in enough untouched surface that the background is
  /// unambiguously the most common colour, without reaching so far that it
  /// picks up the next element.
  static TextAppearance sample({
    required Uint8List rgba,
    required int imageWidth,
    required int imageHeight,
    required Rect bounds,
  }) {
    final double margin = math.max(2, bounds.height * 0.5);
    final Rect padded = bounds.inflate(margin);

    final int left = padded.left.floor().clamp(0, imageWidth - 1);
    final int top = padded.top.floor().clamp(0, imageHeight - 1);
    final int right = padded.right.ceil().clamp(left + 1, imageWidth);
    final int bottom = padded.bottom.ceil().clamp(top + 1, imageHeight);

    // The tight rectangle, kept separately: uniformity and the background
    // want the margin, but ink coverage must be measured over the letters
    // alone or the padding dilutes it into meaninglessness.
    final int inkLeft = bounds.left.floor().clamp(0, imageWidth);
    final int inkTop = bounds.top.floor().clamp(0, imageHeight);
    final int inkRight = bounds.right.ceil().clamp(0, imageWidth);
    final int inkBottom = bounds.bottom.ceil().clamp(0, imageHeight);

    final Map<int, _Bucket> histogram = <int, _Bucket>{};
    int total = 0;

    for (int y = top; y < bottom; y++) {
      int offset = (y * imageWidth + left) * 4;
      final bool insideRows = y >= inkTop && y < inkBottom;
      for (int x = left; x < right; x++) {
        final int r = rgba[offset];
        final int g = rgba[offset + 1];
        final int b = rgba[offset + 2];
        offset += 4;

        final int key =
            ((r >> _quantiseShift) << 10) |
            ((g >> _quantiseShift) << 5) |
            (b >> _quantiseShift);
        (histogram[key] ??= _Bucket()).add(
          r,
          g,
          b,
          insideRows && x >= inkLeft && x < inkRight,
        );
        total++;
      }
    }

    if (total == 0 || histogram.isEmpty) {
      return const TextAppearance(
        background: Color(0xFFFFFFFF),
        ink: Color(0xFF000000),
        uniformity: 0,
      );
    }

    _Bucket best = histogram.values.first;
    for (final _Bucket bucket in histogram.values) {
      if (bucket.count > best.count) best = bucket;
    }
    final Color background = best.colour;

    // Ink is the colour furthest from the background that still occupies
    // enough of the area to be a letter rather than a speck.
    final int minimumCount = math.max(2, (total * _minimumInkShare).round());
    Color? ink;
    double furthest = _inkDistance;
    double flat = 0;
    int inked = 0;
    int tight = 0;

    for (final _Bucket bucket in histogram.values) {
      final double distance = _distance(bucket.colour, background);
      tight += bucket.tightCount;
      if (distance <= _flatDistance) {
        flat += bucket.count;
      } else {
        inked += bucket.tightCount;
      }
      if (bucket.count < minimumCount) continue;
      if (distance > furthest) {
        furthest = distance;
        ink = bucket.colour;
      }
    }

    return TextAppearance(
      inkShare: tight == 0 ? 0 : inked / tight,
      background: background,
      // No candidate means the sample is one flat colour — an empty margin,
      // or a line the recogniser saw and the pixels do not show. Falling back
      // to the opposite end of the scale keeps whatever gets drawn legible
      // instead of invisible.
      ink: ink ?? _contrastingInk(background),
      uniformity: flat / total,
    );
  }

  static Color _contrastingInk(Color background) =>
      TextAppearance._luminance(background) > 0.5
      ? const Color(0xFF1A1A1A)
      : const Color(0xFFF5F5F5);

  static double _distance(Color a, Color b) {
    final double dr = (a.r - b.r) * 255;
    final double dg = (a.g - b.g) * 255;
    final double db = (a.b - b.b) * 255;
    return math.sqrt(dr * dr + dg * dg + db * db);
  }
}

/// One quantised colour, with the true average of the pixels that fell into
/// it — so the fill uses the screenshot's actual colour, not the rounded-off
/// bucket centre it was counted under.
class _Bucket {
  int count = 0;

  /// How many of those pixels fell inside the text's own rectangle rather
  /// than the margin around it.
  int tightCount = 0;

  int _r = 0;
  int _g = 0;
  int _b = 0;

  void add(int r, int g, int b, bool tight) {
    count++;
    if (tight) tightCount++;
    _r += r;
    _g += g;
    _b += b;
  }

  Color get colour => Color.fromARGB(
    255,
    (_r / count).round(),
    (_g / count).round(),
    (_b / count).round(),
  );
}
