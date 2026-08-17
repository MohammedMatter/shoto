import 'dart:ui';

import 'package:shoto/core/utils/text_line_geometry.dart' show PositionedWord;

/// One recognised line, reduced to the two things selecting needs: where the
/// line sits, and where each of its words sits inside it.
///
/// Same split as [TextLineGeometry] and for the same reason — this file is
/// rectangles and string arithmetic, and keeping `google_mlkit_*` out of it is
/// what lets every case below be tested without a recogniser, an image, or a
/// device.
class SelectableLine {
  final String text;
  final Rect bounds;
  final List<PositionedWord> words;

  const SelectableLine({
    required this.text,
    required this.bounds,
    required this.words,
  });
}

/// One unit a finger can land on, in source-image pixels.
///
/// A **word**, not a character. OCR reports where words are and nothing about
/// where the characters inside them begin — the same measurement gap that
/// stops Safe Share from covering half a word. Selecting per character would
/// mean interpolating positions inside a word, which works in Latin, quietly
/// mirrors itself in Arabic, and would leave the highlight sitting a letter to
/// the left of the finger. Whole words are the finest unit the geometry can
/// actually prove, so they are the unit.
class SelectableWord {
  final String text;
  final Rect bounds;

  /// Which row of the picture this word was read on, after ordering.
  ///
  /// Carried on the word rather than looked up later because it answers both
  /// questions the rest of this file has: where a line break goes when the
  /// selection is turned back into text, and which words may be merged into a
  /// single highlight bar.
  final int line;

  const SelectableWord({
    required this.text,
    required this.bounds,
    required this.line,
  });
}

/// Turns recognised lines into something a finger can drag across.
///
/// Everything here is deliberately pure: given rectangles and strings it
/// returns rectangles and strings. The widget owns the gestures and the
/// painting; this owns what "the words between these two points" means, which
/// is the part with edge cases worth testing.
abstract class TextSelectionGeometry {
  TextSelectionGeometry._();

  /// Every word in the picture, in reading order.
  ///
  /// **Rows are built before anything is sorted, and that is not a detail.**
  /// The obvious implementation — sort every line by top, tie-break by left —
  /// needs a comparator that answers "are these two on the same row?", and
  /// that question is not transitive: three lines can each overlap the next
  /// while the first and last do not, which is an inconsistent comparator and
  /// an order that changes with the input's original arrangement. So lines are
  /// swept top-down into rows first, each row is sorted left-to-right on its
  /// own, and the rows are concatenated. Deterministic, and it costs nothing.
  ///
  /// A line the recogniser gave **no words** for becomes one word covering the
  /// whole line. Some recognisers report none, and a line of symbols can
  /// produce none; the honest fallback is a unit that is coarser than ideal
  /// rather than a line that cannot be selected at all.
  static List<SelectableWord> wordsIn(List<SelectableLine> lines) {
    final List<SelectableLine> usable = <SelectableLine>[
      for (final SelectableLine line in lines)
        if (!line.bounds.isEmpty) line,
    ];
    if (usable.isEmpty) return const <SelectableWord>[];

    usable.sort((SelectableLine a, SelectableLine b) {
      final int byTop = a.bounds.top.compareTo(b.bounds.top);
      return byTop != 0 ? byTop : a.bounds.left.compareTo(b.bounds.left);
    });

    final List<List<SelectableLine>> rows = <List<SelectableLine>>[];
    for (final SelectableLine line in usable) {
      final List<SelectableLine>? row = rows.isEmpty ? null : rows.last;
      if (row != null && _sharesRow(row.last.bounds, line.bounds)) {
        row.add(line);
      } else {
        rows.add(<SelectableLine>[line]);
      }
    }

    final List<SelectableWord> words = <SelectableWord>[];
    for (int row = 0; row < rows.length; row++) {
      rows[row].sort(
        (SelectableLine a, SelectableLine b) =>
            a.bounds.left.compareTo(b.bounds.left),
      );
      for (final SelectableLine line in rows[row]) {
        final List<PositionedWord> inLine = <PositionedWord>[
          for (final PositionedWord word in line.words)
            if (word.text.trim().isNotEmpty && !word.bounds.isEmpty) word,
        ];

        if (inLine.isEmpty) {
          words.add(
            SelectableWord(text: line.text, bounds: line.bounds, line: row),
          );
          continue;
        }

        for (final PositionedWord word in inLine) {
          words.add(
            SelectableWord(text: word.text, bounds: word.bounds, line: row),
          );
        }
      }
    }

    return words;
  }

  /// Whether [next] is on the same visual row as [previous].
  ///
  /// Measured as overlap against the **shorter** of the two, so a line of body
  /// text beside a heading twice its height still counts as beside it. Half is
  /// the threshold: two columns at the same height genuinely are one row for
  /// the purpose of dragging across them, while the next paragraph down is
  /// not.
  static bool _sharesRow(Rect previous, Rect next) {
    final double overlap =
        (previous.bottom < next.bottom ? previous.bottom : next.bottom) -
        (previous.top > next.top ? previous.top : next.top);
    if (overlap <= 0) return false;
    final double shorter = previous.height < next.height
        ? previous.height
        : next.height;
    return shorter > 0 && overlap >= shorter * 0.5;
  }

  /// The word under [point], or null when the finger is not on one.
  ///
  /// [slop] grows every word's box before the test, and it is measured in the
  /// same units as the boxes — image pixels — so the caller converts from
  /// finger-sized screen distance once, at the scale the picture is actually
  /// drawn at. A word box is drawn tight around its glyphs, and a fingertip
  /// covers several of them; without the slop, a press aimed at the middle of
  /// a short word lands in the gap above it as often as not.
  ///
  /// When boxes overlap after growing, the **smallest** wins. The alternative
  /// — first match in reading order — makes a long line swallow the short word
  /// sitting inside its bounds, which is exactly the word somebody aiming
  /// carefully was aiming at.
  static int? wordAt(
    List<SelectableWord> words,
    Offset point, {
    double slop = 0,
  }) {
    int? best;
    double bestArea = double.infinity;

    for (int index = 0; index < words.length; index++) {
      final Rect box = words[index].bounds.inflate(slop);
      if (!box.contains(point)) continue;
      final double area = box.width * box.height;
      if (area < bestArea) {
        best = index;
        bestArea = area;
      }
    }

    return best;
  }

  /// The word closest to [point], whatever the distance.
  ///
  /// This is what a **drag** asks, and it asks a different question from
  /// [wordAt] on purpose. Once a selection has started, the finger has to keep
  /// meaning something while it travels over a picture — through the margin, a
  /// blank strip between paragraphs, the gap at the end of a short line. A
  /// null there would make the highlight let go mid-drag and snap back, which
  /// reads as the app losing the gesture rather than the user leaving the
  /// text.
  ///
  /// **A word the finger is level with always beats one it is merely close
  /// to.** Straight-line distance sounds like the right measure and is not:
  /// dragging off the end of a short line puts the finger in empty space where
  /// the *previous* line's last word can easily be the nearer of the two, so
  /// the selection jumps up a line and shortens while the finger is still
  /// moving forwards. Anything the finger is vertically inside is judged by
  /// horizontal distance alone, and only when it is between lines entirely
  /// does the plain distance decide.
  ///
  /// Returns -1 only for an empty list.
  static int nearestWord(List<SelectableWord> words, Offset point) {
    int best = -1;
    double bestScore = double.infinity;
    bool bestLevel = false;

    for (int index = 0; index < words.length; index++) {
      final Rect box = words[index].bounds;
      final bool level = point.dy >= box.top && point.dy <= box.bottom;

      final double score = level
          ? (point.dx < box.left
                ? box.left - point.dx
                : (point.dx > box.right ? point.dx - box.right : 0))
          : _distanceTo(box, point);

      // A level word displaces a merely-near one outright, whatever the
      // numbers say — the two scores are not even in the same units.
      if (level && !bestLevel) {
        best = index;
        bestScore = score;
        bestLevel = true;
      } else if (level == bestLevel && score < bestScore) {
        best = index;
        bestScore = score;
      }

      if (bestLevel && bestScore == 0) break;
    }

    return best;
  }

  /// Squared distance from [point] to the nearest edge of [box], zero inside.
  ///
  /// Squared rather than real: only the comparison matters, and a square root
  /// per word per drag frame is work nobody can see the result of.
  static double _distanceTo(Rect box, Offset point) {
    final double dx = point.dx < box.left
        ? box.left - point.dx
        : (point.dx > box.right ? point.dx - box.right : 0);
    final double dy = point.dy < box.top
        ? box.top - point.dy
        : (point.dy > box.bottom ? point.dy - box.bottom : 0);
    return dx * dx + dy * dy;
  }

  /// The selected words as text, ready for the clipboard.
  ///
  /// Words on one row are joined with a space and rows with a newline, which
  /// is the whole reason this feature builds its own string instead of
  /// concatenating what the recogniser reported. A copied address that arrives
  /// as one run-on line, or a copied paragraph whose every word is on its own
  /// line, is a copy the user has to repair by hand — and repairing it by hand
  /// is the thing they opened this to avoid.
  ///
  /// [start] is inclusive, [end] exclusive; both are clamped, so a caller that
  /// has lost track of the list's length gets a short string rather than a
  /// crash.
  static String textIn(List<SelectableWord> words, int start, int end) {
    final int from = start.clamp(0, words.length);
    final int to = end.clamp(from, words.length);
    if (from == to) return '';

    final StringBuffer out = StringBuffer();
    for (int index = from; index < to; index++) {
      if (index > from) {
        out.write(words[index].line == words[index - 1].line ? ' ' : '\n');
      }
      out.write(words[index].text);
    }

    return out.toString();
  }

  /// One rectangle per run of selected words, for painting the highlight.
  ///
  /// Consecutive words on the same row are merged into a single bar. Drawn per
  /// word instead, a selected sentence is a row of separate chips with gaps
  /// where the spaces are — which looks like eight things being selected
  /// rather than one phrase, and reads as a bug on the first glance.
  static List<Rect> highlightRects(
    List<SelectableWord> words,
    int start,
    int end,
  ) {
    final int from = start.clamp(0, words.length);
    final int to = end.clamp(from, words.length);
    if (from == to) return const <Rect>[];

    final List<Rect> bars = <Rect>[];
    Rect run = words[from].bounds;
    int line = words[from].line;

    for (int index = from + 1; index < to; index++) {
      final SelectableWord word = words[index];
      if (word.line == line) {
        run = run.expandToInclude(word.bounds);
      } else {
        bars.add(run);
        run = word.bounds;
        line = word.line;
      }
    }
    bars.add(run);

    return bars;
  }
}
