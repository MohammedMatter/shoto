import 'dart:ui';

/// One word of recognised text and where it sits, in source-image pixels.
///
/// Deliberately not the OCR package's own type: this file is pure geometry
/// and string arithmetic, and keeping it free of `google_mlkit_*` is what
/// lets every case below be tested without a recogniser, an image, or a
/// device. Same split as `perceptual_hash.dart` and `scroll_stitcher.dart`.
class PositionedWord {
  final String text;
  final Rect bounds;

  const PositionedWord({required this.text, required this.bounds});
}

/// A run of a line that will be redrawn, and the rectangle it occupies.
///
/// [start] and [end] are usually **wider** than the match that asked for
/// them. If a card number shares a word with something else — `ID:4111` — the
/// whole word has to be redrawn, because half a word cannot be painted over
/// without knowing where its characters begin, and that is exactly the
/// measurement OCR does not give. So the run grows to whole words and the
/// caller rebuilds the text of the run, substituting only the private part.
///
/// It is also why nothing here interpolates inside a word: guessing character
/// positions works in Latin and quietly mirrors itself in Arabic, and a
/// substitution one word to the left is worse than one that covers a word too
/// many.
class TextRun {
  final Rect bounds;
  final int start;
  final int end;

  const TextRun({required this.bounds, required this.start, required this.end});
}

/// Turns a character range inside a recognised line into a rectangle on the
/// image.
abstract class TextLineGeometry {
  TextLineGeometry._();

  /// The run of [lineText] that must be redrawn in order to hide
  /// `[start, end)`, and where it sits.
  ///
  /// Returns null when the range is empty or falls outside the line.
  ///
  /// When [words] is empty — some recognisers report none, and a line of
  /// symbols can produce none — the whole line is redrawn. That is the honest
  /// fallback: it is never wrong, only broader than necessary, and a broader
  /// cover still hides the number.
  static TextRun? runFor(
    String lineText,
    List<PositionedWord> words,
    Rect lineBounds,
    int start,
    int end,
  ) {
    if (start < 0 || end > lineText.length || start >= end) return null;

    final List<_Located> located = _locate(lineText, words);
    if (located.isEmpty) {
      return TextRun(bounds: lineBounds, start: 0, end: lineText.length);
    }

    Rect? union;
    int from = -1;
    int to = -1;

    for (final _Located word in located) {
      // Touching counts: a match that ends exactly where a word begins does
      // not involve that word.
      if (word.end <= start || word.start >= end) continue;
      union = union == null ? word.bounds : union.expandToInclude(word.bounds);
      if (from < 0 || word.start < from) from = word.start;
      if (word.end > to) to = word.end;
    }

    if (union == null) {
      // The range landed entirely on separators between words — nothing
      // visible to redraw.
      return null;
    }

    // **The union has to contain the whole value, or it is worse than
    // useless.** [_locate] skips any word it cannot find inside the line's own
    // text, and that happens more often than it sounds: a recogniser is free
    // to report a word with different spacing or a stray character from the
    // one it spelled into the line. When the skipped word is the one holding
    // the last four digits, everything above still succeeds and still returns
    // a rectangle — a rectangle that covers most of a card number.
    //
    // This is the exact shape of the failure users describe as "it covered
    // everything except one", so it is checked rather than assumed. If any
    // visible part of the range fell outside the located words, the whole line
    // is redrawn instead. Broader than necessary, and never wrong.
    final int visibleStart = _skipSpaceForward(lineText, start, end);
    final int visibleEnd = _skipSpaceBackward(lineText, start, end);
    if (visibleStart < visibleEnd && (from > visibleStart || to < visibleEnd)) {
      return TextRun(bounds: lineBounds, start: 0, end: lineText.length);
    }

    return TextRun(bounds: union, start: from, end: to);
  }

  static int _skipSpaceForward(String text, int start, int end) {
    int cursor = start;
    while (cursor < end && _isSpace(text.codeUnitAt(cursor))) {
      cursor++;
    }
    return cursor;
  }

  static int _skipSpaceBackward(String text, int start, int end) {
    int cursor = end;
    while (cursor > start && _isSpace(text.codeUnitAt(cursor - 1))) {
      cursor--;
    }
    return cursor;
  }

  static bool _isSpace(int unit) =>
      unit == 0x20 || unit == 0x09 || unit == 0x0A || unit == 0x0D ||
      unit == 0x00A0;

  /// Each word paired with where its text sits inside [lineText].
  ///
  /// The recogniser reports a line's text and its words separately and never
  /// says how one was joined into the other, so the offsets are recovered by
  /// searching. A forward-only cursor is what makes that safe: a line reading
  /// "1 1 1" has three identical words, and searching from the beginning each
  /// time would map all three onto the first.
  ///
  /// A word that cannot be found is skipped rather than guessed at, and the
  /// cursor does not move — so one unrecognisable fragment costs that word,
  /// not the alignment of every word after it.
  static List<_Located> _locate(String lineText, List<PositionedWord> words) {
    final List<_Located> out = <_Located>[];
    int cursor = 0;

    for (final PositionedWord word in words) {
      if (word.text.isEmpty) continue;
      final int at = lineText.indexOf(word.text, cursor);
      if (at < 0) continue;
      out.add(
        _Located(start: at, end: at + word.text.length, bounds: word.bounds),
      );
      cursor = at + word.text.length;
    }

    return out;
  }
}

class _Located {
  final int start;
  final int end;
  final Rect bounds;

  const _Located({
    required this.start,
    required this.end,
    required this.bounds,
  });
}
