import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/text_line_geometry.dart' show PositionedWord;
import 'package:shoto/core/utils/text_selection_geometry.dart';

/// Selecting text on a picture is rectangles and string arithmetic, and this
/// is where both are checked — without a recogniser, an image, or a device,
/// the same way `TextLineGeometry` is.
///
/// The cases worth having are the ones that produced a wrong *copy* rather
/// than a wrong drawing: a selection that reads two columns as one sentence, a
/// paragraph that arrives as one run-on line, a drag that lets go in the gap
/// between two lines.
void main() {
  /// A line of evenly spaced words, laid out left to right.
  SelectableLine lineOf(
    String text, {
    required double top,
    double left = 0,
    double height = 20,
    double wordWidth = 40,
    double gap = 10,
  }) {
    final List<String> parts = text.split(' ');
    final List<PositionedWord> words = <PositionedWord>[];
    double x = left;
    for (final String part in parts) {
      words.add(
        PositionedWord(
          text: part,
          bounds: Rect.fromLTWH(x, top, wordWidth, height),
        ),
      );
      x += wordWidth + gap;
    }
    return SelectableLine(
      text: text,
      bounds: Rect.fromLTWH(left, top, x - gap - left, height),
      words: words,
    );
  }

  group('reading order', () {
    test('lines are ordered top to bottom whatever order they arrive in', () {
      final List<SelectableWord> words =
          TextSelectionGeometry.wordsIn(<SelectableLine>[
            lineOf('third line', top: 200),
            lineOf('first line', top: 0),
            lineOf('second line', top: 100),
          ]);

      expect(
        words.map((SelectableWord w) => w.text).join(' '),
        'first line second line third line',
      );
    });

    test('two columns at the same height read left column first', () {
      final List<SelectableWord> words = TextSelectionGeometry.wordsIn(
        <SelectableLine>[
          lineOf('right', top: 0, left: 500),
          lineOf('left', top: 2, left: 0),
        ],
      );

      expect(words.map((SelectableWord w) => w.text).toList(), <String>[
        'left',
        'right',
      ]);
      // Same row, so a selection across both is one line of text rather than
      // two — which is what makes dragging over them behave.
      expect(words.first.line, words.last.line);
    });

    test('a line the recogniser gave no words for is still selectable', () {
      final List<SelectableWord> words =
          TextSelectionGeometry.wordsIn(const <SelectableLine>[
            SelectableLine(
              text: '••••1234',
              bounds: Rect.fromLTWH(0, 0, 120, 20),
              words: <PositionedWord>[],
            ),
          ]);

      expect(words.length, 1);
      expect(words.single.text, '••••1234');
      expect(words.single.bounds, const Rect.fromLTWH(0, 0, 120, 20));
    });
  });

  group('hit testing', () {
    final List<SelectableWord> words = TextSelectionGeometry.wordsIn(
      <SelectableLine>[
        lineOf('alpha beta gamma', top: 0),
        lineOf('delta epsilon', top: 100),
      ],
    );

    test('a press inside a word selects that word', () {
      final int? index = TextSelectionGeometry.wordAt(
        words,
        const Offset(60, 10),
      );
      expect(index, isNotNull);
      expect(words[index!].text, 'beta');
    });

    test('a press in the gap between words hits nothing without slop', () {
      expect(TextSelectionGeometry.wordAt(words, const Offset(45, 10)), isNull);
    });

    test('slop lets a fingertip miss slightly and still land', () {
      final int? index = TextSelectionGeometry.wordAt(
        words,
        const Offset(45, 10),
        slop: 8,
      );
      expect(index, isNotNull);
      expect(words[index!].text, anyOf('alpha', 'beta'));
    });

    test('dragging past the end of a line stays on that line', () {
      // Far off to the right of the second line. Measured as straight-line
      // distance, `gamma` on the line above is nearer — which is exactly the
      // jump this must not make.
      final int index = TextSelectionGeometry.nearestWord(
        words,
        const Offset(900, 105),
      );
      expect(words[index].text, 'epsilon');
    });

    test('between two lines, the genuinely closest word wins', () {
      // Nothing is level with the finger here, so there is no line to prefer.
      final int index = TextSelectionGeometry.nearestWord(
        words,
        const Offset(120, 60),
      );
      expect(words[index].text, 'gamma');
    });

    test('nearest reports -1 only when there is nothing to select', () {
      expect(
        TextSelectionGeometry.nearestWord(
          const <SelectableWord>[],
          Offset.zero,
        ),
        -1,
      );
    });
  });

  group('the copied string', () {
    final List<SelectableWord> words = TextSelectionGeometry.wordsIn(
      <SelectableLine>[
        lineOf('Flat 4 Hill Road', top: 0),
        lineOf('Manchester M1 2AB', top: 100),
      ],
    );

    test('words on one line are joined with spaces', () {
      expect(TextSelectionGeometry.textIn(words, 0, 4), 'Flat 4 Hill Road');
    });

    test('a new line in the picture is a new line in the clipboard', () {
      expect(
        TextSelectionGeometry.textIn(words, 0, words.length),
        'Flat 4 Hill Road\nManchester M1 2AB',
      );
    });

    test('a selection of one word is that word', () {
      expect(TextSelectionGeometry.textIn(words, 1, 2), '4');
    });

    test('out-of-range bounds are clamped rather than thrown', () {
      expect(TextSelectionGeometry.textIn(words, -5, 500), isNotEmpty);
      expect(TextSelectionGeometry.textIn(words, 3, 3), '');
      expect(TextSelectionGeometry.textIn(words, 9, 2), '');
    });
  });

  group('highlight bars', () {
    final List<SelectableWord> words = TextSelectionGeometry.wordsIn(
      <SelectableLine>[
        lineOf('one two three', top: 0),
        lineOf('four five', top: 100),
      ],
    );

    test('a run on one line is a single bar, gaps included', () {
      final List<Rect> bars = TextSelectionGeometry.highlightRects(words, 0, 3);
      expect(bars.length, 1);
      // Covers the spaces between the words rather than leaving them out,
      // which is what stops a selected phrase looking like separate chips.
      expect(bars.single.left, 0);
      expect(bars.single.right, 140);
    });

    test('a selection across lines is one bar per line', () {
      final List<Rect> bars = TextSelectionGeometry.highlightRects(
        words,
        1,
        words.length,
      );
      expect(bars.length, 2);
      expect(bars.first.top, 0);
      expect(bars.last.top, 100);
    });

    test('nothing selected paints nothing', () {
      expect(TextSelectionGeometry.highlightRects(words, 2, 2), isEmpty);
    });
  });
}
