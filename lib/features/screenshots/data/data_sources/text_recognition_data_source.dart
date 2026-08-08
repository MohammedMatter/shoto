import 'dart:io';
import 'dart:ui' show Rect;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR (no image ever leaves the phone) backing the premium
/// "search inside your screenshots" feature. One recognizer instance is
/// reused for the app's lifetime rather than created per call.
class TextRecognitionDataSource {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<String> recognizeText(File imageFile) async {
    final InputImage inputImage = InputImage.fromFilePath(imageFile.path);
    final RecognizedText result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  /// The recognised lines together with **where each one sits** in the image.
  ///
  /// ML Kit has always returned this geometry and the app used to throw all
  /// of it away, keeping only `result.text`. That made Shoto able to read a
  /// screenshot but blind to the position of anything it read — which is
  /// fine for search, and useless for covering a card number up.
  ///
  /// Lines rather than blocks or words: a block can span a whole paragraph
  /// (covering far more than the private bit), while a word splits
  /// "4111 1111 1111 1111" into four fragments that individually pass no
  /// checksum at all.
  ///
  /// The line's own **words** come along too. Detection has to happen on the
  /// whole line for the checksums to work, but a line is usually a label and
  /// a value — "Card number: 4111 1111 1111 1111" — and covering all of it
  /// deletes the label as well. The word boxes are what turn a character
  /// range found in `line.text` back into a rectangle on the image, so only
  /// the value itself is touched.
  Future<List<RecognizedLine>> recognizeLines(File imageFile) async {
    final InputImage inputImage = InputImage.fromFilePath(imageFile.path);
    final RecognizedText result = await _recognizer.processImage(inputImage);

    return [
      for (int block = 0; block < result.blocks.length; block++)
        for (final TextLine line in result.blocks[block].lines)
          RecognizedLine(
            text: line.text,
            bounds: line.boundingBox,
            blockId: block,
            words: [
              for (final TextElement element in line.elements)
                RecognizedWord(text: element.text, bounds: element.boundingBox),
            ],
          ),
    ];
  }

  void dispose() => _recognizer.close();
}

/// One line of recognised text and its rectangle, in source-image pixels.
class RecognizedLine {
  final String text;
  final Rect bounds;

  /// Which recognised block this line came from.
  ///
  /// The recogniser groups lines that read together and the flattened list
  /// above used to throw that grouping away. It is what tells the safe-share
  /// scan which two lines may be read as one sentence — a label and the value
  /// wrapped underneath it — without joining two unrelated columns. See
  /// `LineStitcher`.
  final int blockId;

  /// The line's words, in reading order, each with its own rectangle.
  /// Empty when the recogniser reported none — callers must cope, see
  /// `TextLineGeometry`.
  final List<RecognizedWord> words;

  const RecognizedLine({
    required this.text,
    required this.bounds,
    this.blockId = 0,
    this.words = const [],
  });
}

/// One word of recognised text and its rectangle, in source-image pixels.
class RecognizedWord {
  final String text;
  final Rect bounds;

  const RecognizedWord({required this.text, required this.bounds});
}
