import 'dart:math' as math;
import 'dart:ui';

/// Reads two stacked lines of a screenshot as one sentence.
///
/// Text recognition returns lines, and a form field is routinely split across
/// two of them — the label on one, the value underneath. Scanning each line on
/// its own can never see that: "رقم الهوية" alone carries no number, and
/// "1234567890" alone is ten digits that could be anything, so the labelled
/// detectors in `sensitive_data.dart` correctly refuse both. The detectors are
/// right; what reaches them is too small a unit.
///
/// Nothing here decides what is private. It only decides **which two lines are
/// allowed to be read as one string**, and can say where a span found in that
/// string really lives. Keeping it to that is what makes the whole thing
/// testable without an image, a recogniser or a device — same split as
/// `text_line_geometry.dart`.
///
/// The pairing is deliberately strict. Joining lines that merely happen to
/// follow each other in the list would let a detector run a pattern across two
/// unrelated columns of a receipt and cover both — so a pair must come from
/// the same recognised block, sit one directly under the other, overlap
/// horizontally, and be close enough vertically that a wrapped field is a more
/// likely explanation than a coincidence.
class StitchLine {
  final String text;
  final Rect bounds;

  /// Which recognised block the line belongs to.
  ///
  /// The recogniser already grouped lines that read together, and this is the
  /// cheapest way to keep that judgement instead of re-deriving it from
  /// geometry. Two lines from different blocks are never joined however close
  /// they look.
  final int blockId;

  const StitchLine({
    required this.text,
    required this.bounds,
    required this.blockId,
  });
}

/// Where a span found in a stitched pair actually sits: which line, and which
/// characters of it.
class LineSpan {
  final int lineIndex;
  final int start;
  final int end;

  const LineSpan({
    required this.lineIndex,
    required this.start,
    required this.end,
  });

  bool overlaps(int otherStart, int otherEnd) =>
      start < otherEnd && otherStart < end;

  @override
  String toString() => 'LineSpan($lineIndex, $start..$end)';
}

/// Two adjacent lines joined into one string, and the way back.
class StitchedPair {
  final int upperIndex;
  final int lowerIndex;

  /// The two lines with a single space between them.
  ///
  /// A space and not a newline, and that is the entire mechanism: every label
  /// pattern in `sensitive_data.dart` separates a label from its value with
  /// horizontal space only, precisely so that a label at the end of one line
  /// cannot reach across into the next. Here that reach is the point, so the
  /// separator is one the patterns accept — and it stays scoped to two lines
  /// the geometry has already vouched for.
  final String text;

  /// Where the lower line's text begins in [text].
  final int boundary;

  const StitchedPair({
    required this.upperIndex,
    required this.lowerIndex,
    required this.text,
    required this.boundary,
  });

  /// The span `[start, end)` broken into the pieces each line really owns.
  ///
  /// One piece when the value sits inside a single line — the ordinary case,
  /// where only the *label* was on the other line. Two when the value itself
  /// wrapped, which happens to long card numbers and is the case where getting
  /// the mapping wrong would cover half a number and leave the rest showing.
  ///
  /// The joining space belongs to neither line and is never returned.
  List<LineSpan> piecesFor(int start, int end) {
    final int from = math.max(0, start);
    final int to = math.min(text.length, end);
    if (from >= to) return const <LineSpan>[];

    final int upperLength = boundary - 1;
    final List<LineSpan> pieces = <LineSpan>[];

    if (from < upperLength) {
      pieces.add(
        LineSpan(
          lineIndex: upperIndex,
          start: from,
          end: math.min(to, upperLength),
        ),
      );
    }
    if (to > boundary) {
      pieces.add(
        LineSpan(
          lineIndex: lowerIndex,
          start: math.max(from, boundary) - boundary,
          end: to - boundary,
        ),
      );
    }

    return pieces;
  }
}

abstract class LineStitcher {
  LineStitcher._();

  /// Every adjacent pair of [lines] worth reading as one sentence.
  ///
  /// Pairs only, never three at a time. A label and its value are one line
  /// apart; anything further is a paragraph, and running a detector over a
  /// paragraph is how an address pattern swallows half a screen.
  static List<StitchedPair> pairsIn(List<StitchLine> lines) {
    final List<StitchedPair> pairs = <StitchedPair>[];

    for (int i = 0; i + 1 < lines.length; i++) {
      final StitchLine upper = lines[i];
      final StitchLine lower = lines[i + 1];
      if (!_belongTogether(upper, lower)) continue;

      pairs.add(
        StitchedPair(
          upperIndex: i,
          lowerIndex: i + 1,
          text: '${upper.text} ${lower.text}',
          boundary: upper.text.length + 1,
        ),
      );
    }

    return pairs;
  }

  static bool _belongTogether(StitchLine upper, StitchLine lower) {
    if (upper.blockId != lower.blockId) return false;
    if (upper.text.trim().isEmpty || lower.text.trim().isEmpty) return false;

    final double height = math.max(
      upper.bounds.height,
      lower.bounds.height,
    );
    if (height <= 0) return false;

    // Stacked, not side by side: the lower line has to start below the upper
    // one's middle. Two halves of a two-column layout are adjacent in the list
    // and share a block, and joining them reads a label against the wrong
    // value.
    if (lower.bounds.top < upper.bounds.center.dy) return false;

    // And close enough that a wrapped field is the likelier explanation. One
    // line's height of blank space is about where a form field ends and the
    // next section begins.
    final double gap = lower.bounds.top - upper.bounds.bottom;
    if (gap > height) return false;

    // Sharing a column. A caption under a picture on the far side of the
    // screen is neither this line's continuation nor its value.
    final double overlap =
        math.min(upper.bounds.right, lower.bounds.right) -
        math.max(upper.bounds.left, lower.bounds.left);
    return overlap > 0;
  }
}
