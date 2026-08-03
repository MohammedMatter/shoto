import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/utils/line_stitching.dart';
import 'package:shoto/core/utils/sensitive_data.dart';
import 'package:shoto/core/utils/text_line_geometry.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/safe_share/domain/entities/sensitive_region.dart';
import 'package:shoto/features/screenshots/data/data_sources/text_recognition_data_source.dart';

/// Finds private details in a screenshot and produces a copy with a solid
/// block painted over each one.
///
/// An earlier version of this class did something cleverer: it read the
/// colours behind the text, erased the area in the screenshot's own
/// background colour and redrew a believable stand-in — a different card
/// number, another ordinary name — so the shared copy did not look edited at
/// all. It was removed on purpose. A block says one thing and the user can
/// check it in the preview in a second; a substitution asks them to believe
/// the app put the right invented value in the right place, which is a much
/// larger thing to ask on the one screen whose whole job is to be trusted.
///
/// Two consequences worth stating plainly:
///
/// * **Only the private part is covered.** "Card number: 4111 1111 1111 1111"
///   keeps its label; the digits go under the block. Covering the whole line
///   would delete context the reader needs.
/// * **The export is a fresh PNG encoded from pixels.** There is no layer to
///   peel back and no metadata carrying the original through — the covered
///   copy is the only version of that image which exists.
class RedactionService {
  final TextRecognitionDataSource _textRecognition;
  final AuthRepository _auth;

  RedactionService(this._textRecognition, this._auth);

  /// Scans [imageFile] and reports what it found and where.
  Future<RedactionPlan> scan(File imageFile) async {
    final List<RecognizedLine> lines = await _textRecognition.recognizeLines(
      imageFile,
    );

    final ui.Image image = await _decode(await imageFile.readAsBytes());

    // Read the size out *before* letting the image go. `Image.width` asserts
    // the image has not been disposed, so reaching for it later throws rather
    // than returning a stale number — and it would throw inside the scan
    // loop, turning every screenshot that actually contains something private
    // into "could not read this screenshot".
    final ui.Size size = ui.Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    image.dispose();

    // The signed-in user's own name is the one piece of context that lets an
    // unlabelled name be recognised without guessing. See [SensitiveData].
    final Set<String> ownerNames = SensitiveData.namesFrom(
      _auth.currentUser?.name,
    );

    final List<SensitiveRegion> regions = regionsIn(
      lines,
      ownerNames: ownerNames,
    );

    // Most damaging first: the review list is read top down, and the card
    // number is what the user actually needs to see is handled.
    regions.sort(
      (SensitiveRegion a, SensitiveRegion b) =>
          a.kind.index.compareTo(b.kind.index),
    );

    return RedactionPlan(regions: regions, imageSize: size);
  }

  /// Everything private in a page of recognised text, as regions on the image.
  ///
  /// Public and static so both passes below can be tested with a handful of
  /// hand-written lines — no image, no recogniser, no device. This is where a
  /// missed finding becomes a leak, so it is checked directly rather than
  /// through a screenshot.
  static List<SensitiveRegion> regionsIn(
    List<RecognizedLine> lines, {
    Set<String> ownerNames = const {},
  }) {
    final List<SensitiveRegion> regions = [];

    // What each line has already given up, so the second pass can tell a new
    // finding from the same one seen again.
    final Map<int, List<_Claim>> claimed = <int, List<_Claim>>{};

    // Pass one: each line on its own. This is where nearly everything is
    // found, because nearly every label sits on the same line as its value.
    for (int index = 0; index < lines.length; index++) {
      for (final SensitiveMatch match in SensitiveData.findIn(
        lines[index].text,
        ownerNames: ownerNames,
      )) {
        _claim(
          regions,
          claimed,
          lines,
          index,
          match.kind,
          match.start,
          match.end,
        );
      }
    }

    // Pass two: adjacent lines read as one sentence.
    //
    // A form field wrapped across two lines is invisible to pass one, and it
    // is invisible in the way that matters: "ID number" on its own carries no
    // digits, and the ten digits underneath carry no label, so the detector
    // that needs a caption correctly declines both halves. Neither line is
    // wrong on its own. The unit was.
    //
    // Only kinds that had to *prove* themselves are accepted from here — a
    // checksum, a label, an `@`. [SensitiveKind.number] is excluded on
    // purpose: it recognises a shape and nothing else, so across a join it
    // would happily read the end of one line's price and the start of the
    // next line's quantity as a single long number and black out both.
    for (final StitchedPair pair in LineStitcher.pairsIn(<StitchLine>[
      for (final RecognizedLine line in lines)
        StitchLine(
          text: line.text,
          bounds: line.bounds,
          blockId: line.blockId,
        ),
    ])) {
      for (final SensitiveMatch match in SensitiveData.findIn(
        pair.text,
        ownerNames: ownerNames,
      )) {
        if (match.kind == SensitiveKind.number) continue;
        for (final LineSpan piece in pair.piecesFor(match.start, match.end)) {
          _claim(
            regions,
            claimed,
            lines,
            piece.lineIndex,
            match.kind,
            piece.start,
            piece.end,
          );
        }
      }
    }

    return regions;
  }

  /// Turns one finding into a region on the image, unless that stretch of the
  /// line is already spoken for.
  ///
  /// The overlap check is what lets the two passes run over the same lines
  /// without listing anything twice: a value found on its own line in pass one
  /// is found again in pass two as part of a stitched pair, and it is the same
  /// value. Anything genuinely new — the ten digits that only became an ID
  /// number once the label above them was in the same string — overlaps
  /// nothing and is added.
  ///
  /// With one exception, and it is the exception the second pass exists for.
  /// [SensitiveKind.number] is what the scanner calls digits it cannot name,
  /// so pass one claims those ten digits as a plain number before pass two
  /// ever sees the label above them. Refusing the overlap would keep the
  /// covering and throw away the *only* thing that changed — the app now knows
  /// it is an ID number. So an unnamed claim steps aside for a named one.
  static void _claim(
    List<SensitiveRegion> regions,
    Map<int, List<_Claim>> claimed,
    List<RecognizedLine> lines,
    int lineIndex,
    SensitiveKind kind,
    int start,
    int end,
  ) {
    final RecognizedLine line = lines[lineIndex];
    if (start < 0 || end > line.text.length || start >= end) return;
    if (line.text.substring(start, end).trim().isEmpty) return;

    final List<_Claim> taken = claimed.putIfAbsent(lineIndex, () => <_Claim>[]);
    final List<_Claim> superseded = <_Claim>[];
    for (final _Claim held in taken) {
      if (!held.span.overlaps(start, end)) continue;
      final bool namesIt =
          held.region.kind == SensitiveKind.number &&
          kind != SensitiveKind.number;
      if (!namesIt) return;
      superseded.add(held);
    }
    for (final _Claim held in superseded) {
      taken.remove(held);
      regions.remove(held.region);
    }

    TextRun? run = TextLineGeometry.runFor(
      line.text,
      <PositionedWord>[
        for (final RecognizedWord word in line.words)
          PositionedWord(text: word.text, bounds: word.bounds),
      ],
      line.bounds,
      start,
      end,
    );

    // A finding that reaches this point has already been recognised as
    // private. Dropping it because its rectangle could not be worked out is
    // the one failure this feature must never have: the review list never
    // mentions it, the preview looks clean, and the value is still in the file
    // the user sends. Whatever the geometry could not resolve, the line it
    // came from is known — so the line is covered instead.
    run ??= TextRun(bounds: line.bounds, start: 0, end: line.text.length);

    final String runText = line.text.substring(run.start, run.end);
    final SensitiveRegion region = SensitiveRegion(
      kind: kind,
      bounds: run.bounds,
      runId: '$lineIndex:${run.start}-${run.end}',
      runText: runText,
      localStart: start - run.start,
      localEnd: end - run.start,
      original: line.text.substring(start, end),
      isRtl: _isRtl(runText),
      // Everything found is covered. The scanner used to choose per finding,
      // from how flat the pixels behind it were, which meant one screenshot
      // came back partly rewritten and partly blacked out — two different
      // decisions about one image, discovered by the user in the preview.
      treatment: RegionTreatment.cover,
    );

    taken.add(
      _Claim(
        span: LineSpan(lineIndex: lineIndex, start: start, end: end),
        region: region,
      ),
    );
    regions.add(region);
  }

  /// Burns the plan into the image and returns PNG bytes.
  Future<Uint8List> redact(File imageFile, RedactionPlan plan) async {
    final ui.Image source = await _decode(await imageFile.readAsBytes());
    ui.Picture? picture;
    ui.Image? output;

    try {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      canvas.drawImage(source, ui.Offset.zero, ui.Paint());

      for (final ui.Rect bounds in coveredAreas(plan.regions)) {
        _paintCover(canvas, bounds);
      }

      picture = recorder.endRecording();
      output = await picture.toImage(source.width, source.height);

      final ByteData? png = await output.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (png == null) {
        throw const RedactionException(AppMessage.redactionSave);
      }
      // A fresh PNG, encoded from pixels. Nothing of the original survives
      // underneath the blocks.
      return png.buffer.asUint8List();
    } finally {
      picture?.dispose();
      output?.dispose();
      source.dispose();
    }
  }

  /// The rectangles that will actually be painted: everything not set to
  /// [RegionTreatment.keep], with the regions sharing a run of text collapsed
  /// into one.
  ///
  /// Public so it can be tested without a canvas. This is the only place a
  /// bug leaves a real value visible in an image the review list swore was
  /// handled, so it is checked directly rather than through the renderer.
  static Iterable<ui.Rect> coveredAreas(List<SensitiveRegion> regions) {
    final Map<String, ui.Rect> byRun = <String, ui.Rect>{};
    for (final SensitiveRegion region in regions) {
      if (region.treatment == RegionTreatment.keep) continue;
      final ui.Rect? existing = byRun[region.runId];
      byRun[region.runId] = existing == null
          ? region.bounds
          : existing.expandToInclude(region.bounds);
    }
    return byRun.values;
  }

  /// A solid block, not a blur.
  ///
  /// A blurred region can sometimes be recovered, and even when it cannot it
  /// *looks* recoverable — the wrong feeling for a treatment whose entire job
  /// is to be final.
  static void _paintCover(ui.Canvas canvas, ui.Rect bounds) {
    // OCR rectangles hug the glyphs, so a cover flush to the ink leaves
    // readable fringes above and below.
    final ui.Rect padded = bounds.inflate(3);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(padded, const ui.Radius.circular(4)),
      ui.Paint()..color = const ui.Color(0xFF121212),
    );
  }

  /// Whether a run reads right to left.
  ///
  /// Decided by which script the letters are in rather than by the app's
  /// language: SHOTO's interface being in English says nothing about the
  /// screenshot, which may well be an Arabic banking app. Digits are ignored
  /// because they are written left to right in both.
  static bool _isRtl(String text) {
    for (final int unit in text.codeUnits) {
      // Arabic, Hebrew, and the Arabic presentation forms.
      if (unit >= 0x0590 && unit <= 0x08FF) return true;
      if (unit >= 0xFB1D && unit <= 0xFEFC) return true;
    }
    return false;
  }

  Future<ui.Image> _decode(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    try {
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }
}

/// A stretch of one line that has already been accounted for, and the region
/// standing for it.
///
/// The region is kept alongside the span so a later, better-informed finding
/// can take its place instead of merely being refused. See [RedactionService].
class _Claim {
  final LineSpan span;
  final SensitiveRegion region;

  const _Claim({required this.span, required this.region});
}

class RedactionException implements Exception {
  final AppMessage message;
  const RedactionException(this.message);

  @override
  String toString() => 'RedactionException($message)';
}
