import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/text_appearance.dart';
import 'package:shoto/core/utils/text_line_geometry.dart';

void main() {
  group('reading colours off a screenshot', () {
    test('dark text on a flat light panel', () {
      // The ordinary case: a chat bubble, a bank statement, a receipt.
      final _Canvas canvas = _Canvas(
        120,
        40,
        const Color(0xFFF2F2F2),
      )..writeInk(const Rect.fromLTWH(20, 14, 60, 12), const Color(0xFF202020));

      final TextAppearance look = canvas.sample(
        const Rect.fromLTWH(18, 12, 64, 16),
      );

      expect(look.background, _near(const Color(0xFFF2F2F2)));
      expect(look.ink, _near(const Color(0xFF202020)));
      expect(look.isDarkOnLight, isTrue);
      expect(look.canBeRepainted, isTrue);
    });

    test('light text on a flat dark panel', () {
      final _Canvas canvas = _Canvas(
        120,
        40,
        const Color(0xFF17181C),
      )..writeInk(const Rect.fromLTWH(20, 14, 60, 12), const Color(0xFFEDEDED));

      final TextAppearance look = canvas.sample(
        const Rect.fromLTWH(18, 12, 64, 16),
      );

      expect(look.background, _near(const Color(0xFF17181C)));
      expect(look.ink, _near(const Color(0xFFEDEDED)));
      expect(look.isDarkOnLight, isFalse);
      expect(look.canBeRepainted, isTrue);
    });

    test('a photo background refuses to be repainted', () {
      // This is the check that stops a substitution being drawn onto a
      // gradient, where a single flat fill can only ever look like a patch.
      final _Canvas canvas = _Canvas.noise(120, 40);

      final TextAppearance look = canvas.sample(
        const Rect.fromLTWH(18, 12, 64, 16),
      );

      expect(look.canBeRepainted, isFalse);
      expect(look.uniformity, lessThan(0.55));
    });

    test('a gentle gradient is still too textured to fake', () {
      final _Canvas canvas = _Canvas.gradient(120, 40);

      final TextAppearance look = canvas.sample(
        const Rect.fromLTWH(18, 12, 64, 16),
      );

      expect(look.canBeRepainted, isFalse);
    });

    test('anti-aliased edges do not become the ink colour', () {
      // A handful of mid-grey pixels around every glyph must not outvote the
      // glyph itself, or the substitution comes out washed out.
      final _Canvas canvas = _Canvas(120, 40, const Color(0xFFFFFFFF))
        ..writeInk(const Rect.fromLTWH(20, 15, 60, 10), const Color(0xFF000000))
        ..writeInk(const Rect.fromLTWH(20, 14, 60, 1), const Color(0xFF9A9A9A))
        ..writeInk(const Rect.fromLTWH(20, 25, 60, 1), const Color(0xFF9A9A9A));

      final TextAppearance look = canvas.sample(
        const Rect.fromLTWH(18, 12, 64, 16),
      );

      expect(look.ink, _near(const Color(0xFF000000)));
    });

    test('an empty patch still yields a legible pair', () {
      // Nothing to read: the recogniser saw a line, the pixels are blank.
      // Whatever gets drawn still has to be visible.
      final _Canvas canvas = _Canvas(120, 40, const Color(0xFFFFFFFF));
      final TextAppearance look = canvas.sample(
        const Rect.fromLTWH(18, 12, 64, 16),
      );

      expect(look.background, _near(const Color(0xFFFFFFFF)));
      expect(look.isDarkOnLight, isTrue);
    });

    test('a rectangle reaching past the edge of the image is clamped', () {
      final _Canvas canvas = _Canvas(40, 20, const Color(0xFFCCCCCC));
      // Would read out of bounds if the sampler trusted the rectangle.
      final TextAppearance look = canvas.sample(
        const Rect.fromLTWH(-30, -30, 200, 200),
      );
      expect(look.background, _near(const Color(0xFFCCCCCC)));
    });
  });

  group('turning a character range into a rectangle', () {
    // "Card number: 4111 1111 1111 1111" laid out as eight words.
    const String line = 'Card number: 4111 1111 1111 1111';
    final List<PositionedWord> words = <PositionedWord>[
      const PositionedWord(text: 'Card', bounds: Rect.fromLTWH(10, 4, 40, 14)),
      const PositionedWord(
        text: 'number:',
        bounds: Rect.fromLTWH(54, 4, 66, 14),
      ),
      const PositionedWord(text: '4111', bounds: Rect.fromLTWH(124, 4, 38, 14)),
      const PositionedWord(text: '1111', bounds: Rect.fromLTWH(166, 4, 38, 14)),
      const PositionedWord(text: '1111', bounds: Rect.fromLTWH(208, 4, 38, 14)),
      const PositionedWord(text: '1111', bounds: Rect.fromLTWH(250, 4, 38, 14)),
    ];
    const Rect lineBounds = Rect.fromLTWH(10, 4, 278, 14);

    test('the label is left alone', () {
      final int start = line.indexOf('4111');
      final TextRun run = TextLineGeometry.runFor(
        line,
        words,
        lineBounds,
        start,
        line.length,
      )!;

      expect(run.start, start);
      expect(run.end, line.length);
      expect(run.bounds.left, 124);
      expect(run.bounds.right, 288);
    });

    test('repeated words are located in order, not all at the first', () {
      // Three identical "1111" words; searching from zero each time would
      // stack them all on the first one's rectangle.
      final List<int> lefts = <int>[];
      for (int i = 0; i < line.length; i++) {
        if (!line.startsWith('1111', i)) continue;
        final TextRun run = TextLineGeometry.runFor(
          line,
          words,
          lineBounds,
          i,
          i + 4,
        )!;
        lefts.add(run.bounds.left.round());
      }
      expect(lefts, <int>[166, 208, 250]);
    });

    test('a range inside a word grows to the whole word', () {
      // Half a word cannot be painted over, because nothing measured where
      // its characters begin — so the run widens and the caller redraws the
      // word with only the private part swapped.
      final int start = line.indexOf('4111') + 2;
      final TextRun run = TextLineGeometry.runFor(
        line,
        words,
        lineBounds,
        start,
        start + 2,
      )!;

      expect(run.start, line.indexOf('4111'));
      expect(run.end, line.indexOf('4111') + 4);
      expect(run.bounds, const Rect.fromLTWH(124, 4, 38, 14));
    });

    test('with no words reported, the whole line is redrawn', () {
      final TextRun run = TextLineGeometry.runFor(
        line,
        const <PositionedWord>[],
        lineBounds,
        13,
        line.length,
      )!;

      expect(run.start, 0);
      expect(run.end, line.length);
      expect(run.bounds, lineBounds);
    });

    test('a word the recogniser spelled differently widens to the line', () {
      // The failure users report as "it covered everything except one". ML Kit
      // reported the last group as "l111" — one character off from what it put
      // in the line — so it cannot be located, and the union it is missing
      // from stops four digits short of the end of the card number. Covering
      // the whole line is the only honest answer left.
      final List<PositionedWord> damaged = <PositionedWord>[
        ...words.take(5),
        const PositionedWord(text: 'l111', bounds: Rect.fromLTWH(250, 4, 38, 14)),
      ];
      final int start = line.indexOf('4111');
      final TextRun run = TextLineGeometry.runFor(
        line,
        damaged,
        lineBounds,
        start,
        line.length,
      )!;

      expect(run.bounds, lineBounds);
      expect(run.bounds.right, 288);
    });

    test('a trailing space in the range does not widen it to the line', () {
      // The range's visible part still ends inside a located word, so the
      // narrow cover is kept and the label survives.
      final int start = line.indexOf('4111');
      final TextRun run = TextLineGeometry.runFor(
        line,
        words,
        lineBounds,
        start,
        line.indexOf('1111') + 5,
      )!;

      expect(run.bounds.left, 124);
      expect(run.start, start);
    });

    test('a range that is only whitespace covers nothing', () {
      final int space = line.indexOf(' ');
      expect(
        TextLineGeometry.runFor(line, words, lineBounds, space, space + 1),
        isNull,
      );
    });

    test('an out-of-range request is refused rather than clamped', () {
      expect(TextLineGeometry.runFor(line, words, lineBounds, 5, 5), isNull);
      expect(
        TextLineGeometry.runFor(line, words, lineBounds, 0, line.length + 5),
        isNull,
      );
    });

    test('a word the recogniser mangled costs only that word', () {
      // "number:" comes back as something not present in the line text. The
      // words after it must still land correctly, or every rectangle on the
      // line shifts.
      final List<PositionedWord> damaged = <PositionedWord>[
        words[0],
        const PositionedWord(
          text: 'nurnber;',
          bounds: Rect.fromLTWH(54, 4, 66, 14),
        ),
        ...words.skip(2),
      ];

      final int start = line.indexOf('4111');
      final TextRun run = TextLineGeometry.runFor(
        line,
        damaged,
        lineBounds,
        start,
        start + 4,
      )!;
      expect(run.bounds, const Rect.fromLTWH(124, 4, 38, 14));
    });
  });
}

Matcher _near(Color expected, {int tolerance = 6}) => predicate<Color>(
  (Color actual) =>
      ((actual.r - expected.r) * 255).abs() <= tolerance &&
      ((actual.g - expected.g) * 255).abs() <= tolerance &&
      ((actual.b - expected.b) * 255).abs() <= tolerance,
  'a colour within $tolerance of $expected',
);

/// A hand-drawn RGBA buffer, so the sampler can be tested without an image.
class _Canvas {
  final int width;
  final int height;
  final Uint8List pixels;

  _Canvas(this.width, this.height, Color fill)
    : pixels = Uint8List(width * height * 4) {
    writeInk(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), fill);
  }

  factory _Canvas.noise(int width, int height) {
    final _Canvas canvas = _Canvas(width, height, const Color(0xFF808080));
    final math.Random random = math.Random(7);
    for (int i = 0; i < width * height; i++) {
      canvas.pixels[i * 4] = random.nextInt(256);
      canvas.pixels[i * 4 + 1] = random.nextInt(256);
      canvas.pixels[i * 4 + 2] = random.nextInt(256);
      canvas.pixels[i * 4 + 3] = 255;
    }
    return canvas;
  }

  factory _Canvas.gradient(int width, int height) {
    final _Canvas canvas = _Canvas(width, height, const Color(0xFF000000));
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int i = (y * width + x) * 4;
        final int value = (40 + (x / width) * 180).round();
        canvas.pixels[i] = value;
        canvas.pixels[i + 1] = value;
        canvas.pixels[i + 2] = value;
        canvas.pixels[i + 3] = 255;
      }
    }
    return canvas;
  }

  void writeInk(Rect area, Color colour) {
    final int left = area.left.floor().clamp(0, width);
    final int top = area.top.floor().clamp(0, height);
    final int right = area.right.ceil().clamp(0, width);
    final int bottom = area.bottom.ceil().clamp(0, height);

    for (int y = top; y < bottom; y++) {
      for (int x = left; x < right; x++) {
        final int i = (y * width + x) * 4;
        pixels[i] = (colour.r * 255).round();
        pixels[i + 1] = (colour.g * 255).round();
        pixels[i + 2] = (colour.b * 255).round();
        pixels[i + 3] = 255;
      }
    }
  }

  TextAppearance sample(Rect bounds) => TextAppearanceProbe.sample(
    rgba: pixels,
    imageWidth: width,
    imageHeight: height,
    bounds: bounds,
  );
}
