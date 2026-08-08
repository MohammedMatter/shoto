import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/line_stitching.dart';
import 'package:shoto/core/utils/sensitive_data.dart';
import 'package:shoto/features/safe_share/data/services/redaction_service.dart';
import 'package:shoto/features/safe_share/domain/entities/sensitive_region.dart';
import 'package:shoto/features/screenshots/data/data_sources/text_recognition_data_source.dart';

/// A line of a form: full width, twenty tall, stacked at [row].
StitchLine _stacked(String text, int row, {int blockId = 0}) => StitchLine(
  text: text,
  bounds: Rect.fromLTWH(20, 40.0 + row * 24, 260, 20),
  blockId: blockId,
);

/// The same, as something the scanner can read — one word box per word, laid
/// out left to right so the geometry has something real to work with.
RecognizedLine _line(String text, int row, {int blockId = 0}) {
  final List<RecognizedWord> words = <RecognizedWord>[];
  double x = 20;
  for (final String word in text.split(' ')) {
    final double width = word.length * 8;
    words.add(
      RecognizedWord(
        text: word,
        bounds: Rect.fromLTWH(x, 40.0 + row * 24, width, 20),
      ),
    );
    x += width + 6;
  }
  return RecognizedLine(
    text: text,
    bounds: Rect.fromLTWH(20, 40.0 + row * 24, 260, 20),
    blockId: blockId,
    words: words,
  );
}

void main() {
  group('which lines may be read as one', () {
    test('two stacked lines of the same block are joined', () {
      final List<StitchedPair> pairs = LineStitcher.pairsIn(<StitchLine>[
        _stacked('ID number', 0),
        _stacked('1234567890', 1),
      ]);

      expect(pairs, hasLength(1));
      expect(pairs.single.text, 'ID number 1234567890');
      expect(pairs.single.boundary, 'ID number'.length + 1);
    });

    test('lines from different blocks are never joined', () {
      // The recogniser already decided these do not read together.
      final List<StitchedPair> pairs = LineStitcher.pairsIn(<StitchLine>[
        _stacked('ID number', 0),
        _stacked('1234567890', 1, blockId: 1),
      ]);

      expect(pairs, isEmpty);
    });

    test('a line far below is a new section, not a continuation', () {
      final List<StitchedPair> pairs = LineStitcher.pairsIn(<StitchLine>[
        _stacked('ID number', 0),
        const StitchLine(
          text: '1234567890',
          bounds: Rect.fromLTWH(20, 200, 260, 20),
          blockId: 0,
        ),
      ]);

      expect(pairs, isEmpty);
    });

    test('two columns side by side are not a label and its value', () {
      // Adjacent in the list, same block, same height — and reading them as
      // one line pairs a label with the wrong column's value.
      final List<StitchedPair> pairs = LineStitcher.pairsIn(<StitchLine>[
        const StitchLine(
          text: 'ID number',
          bounds: Rect.fromLTWH(20, 40, 120, 20),
          blockId: 0,
        ),
        const StitchLine(
          text: '1234567890',
          bounds: Rect.fromLTWH(160, 40, 120, 20),
          blockId: 0,
        ),
      ]);

      expect(pairs, isEmpty);
    });

    test('lines in different columns do not join', () {
      final List<StitchedPair> pairs = LineStitcher.pairsIn(<StitchLine>[
        const StitchLine(
          text: 'ID number',
          bounds: Rect.fromLTWH(20, 40, 100, 20),
          blockId: 0,
        ),
        const StitchLine(
          text: '1234567890',
          bounds: Rect.fromLTWH(200, 64, 100, 20),
          blockId: 0,
        ),
      ]);

      expect(pairs, isEmpty);
    });

    test('only pairs, never three at a time', () {
      final List<StitchedPair> pairs = LineStitcher.pairsIn(<StitchLine>[
        _stacked('one', 0),
        _stacked('two', 1),
        _stacked('three', 2),
      ]);

      expect(pairs, hasLength(2));
      expect(pairs.map((StitchedPair p) => p.text), <String>[
        'one two',
        'two three',
      ]);
    });
  });

  group('finding the way back to a line', () {
    final StitchedPair pair = LineStitcher.pairsIn(<StitchLine>[
      _stacked('ID number', 0),
      _stacked('1234567890', 1),
    ]).single;

    test('a value inside the lower line maps to that line alone', () {
      final int at = pair.text.indexOf('1234567890');
      final List<LineSpan> pieces = pair.piecesFor(at, at + 10);

      expect(pieces, hasLength(1));
      expect(pieces.single.lineIndex, 1);
      expect(pieces.single.start, 0);
      expect(pieces.single.end, 10);
    });

    test('a value that wrapped maps to both lines, without the join', () {
      // The case that would leave half a card number showing if the offsets
      // were off by the joining space.
      final List<LineSpan> pieces = pair.piecesFor(3, pair.text.length);

      expect(pieces, hasLength(2));
      expect(pieces.first.lineIndex, 0);
      expect(pieces.first.start, 3);
      expect(pieces.first.end, 'ID number'.length);
      expect(pieces.last.lineIndex, 1);
      expect(pieces.last.start, 0);
      expect(pieces.last.end, '1234567890'.length);
    });

    test('a span outside the pair yields nothing rather than a bad offset', () {
      expect(pair.piecesFor(5, 5), isEmpty);
      expect(pair.piecesFor(-4, -1), isEmpty);
    });
  });

  group('scanning a page of lines', () {
    Set<SensitiveKind> kindsOf(List<RecognizedLine> lines) =>
        RedactionService.regionsIn(
          lines,
        ).map((SensitiveRegion r) => r.kind).toSet();

    test('a label on one line finds the value on the next', () {
      // The whole point of the second pass. Neither line says anything on its
      // own: "ID number" carries no digits, and ten digits carry no label.
      expect(
        kindsOf(<RecognizedLine>[
          _line('National ID', 0),
          _line('1234567890', 1),
        ]),
        contains(SensitiveKind.nationalId),
      );
    });

    test('the same in another shipped language', () {
      // The stitching is language-agnostic — it joins a label line to the line
      // under it and re-runs the ordinary patterns — but that only holds if
      // the label is one the patterns know. This used to be checked in Arabic,
      // which the recogniser cannot read; German is a label it can return.
      expect(
        kindsOf(<RecognizedLine>[
          _line('Steuer-ID', 0),
          _line('98765432109', 1),
        ]),
        contains(SensitiveKind.nationalId),
      );
    });

    test('the region lands on the value, not on the label', () {
      final List<SensitiveRegion> regions = RedactionService.regionsIn(
        <RecognizedLine>[_line('National ID', 0), _line('1234567890', 1)],
      );
      final SensitiveRegion id = regions.firstWhere(
        (SensitiveRegion r) => r.kind == SensitiveKind.nationalId,
      );

      expect(id.original, '1234567890');
      // Second row, not the first.
      expect(id.bounds.top, 64);
    });

    test('a value found on its own line is not listed twice', () {
      final List<SensitiveRegion> regions = RedactionService.regionsIn(
        <RecognizedLine>[
          _line('Card number: 4111 1111 1111 1111', 0),
          _line('Expires 05/28', 1),
        ],
      );

      expect(
        regions.where((SensitiveRegion r) => r.kind == SensitiveKind.card),
        hasLength(1),
      );
    });

    test('two ordinary numbers on stacked lines are not merged', () {
      // The reason [SensitiveKind.number] is refused across a join: neither of
      // these is long enough to hide on its own, and joined they read as one
      // eleven-digit run.
      final List<SensitiveRegion> regions = RedactionService.regionsIn(
        <RecognizedLine>[_line('Total 45900', 0), _line('12 items', 1)],
      );

      expect(regions, isEmpty);
    });

    test('nothing private on the page yields nothing', () {
      expect(
        RedactionService.regionsIn(<RecognizedLine>[
          _line('Settings', 0),
          _line('Notifications', 1),
          _line('About this app', 2),
        ]),
        isEmpty,
      );
    });
  });
}
