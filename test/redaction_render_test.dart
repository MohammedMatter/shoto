import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/sensitive_data.dart';
import 'package:shoto/features/safe_share/data/services/redaction_service.dart';
import 'package:shoto/features/safe_share/domain/entities/sensitive_region.dart';
import 'package:shoto/features/screenshots/data/data_sources/text_recognition_data_source.dart';

/// The renderer, run for real, checked in pixels.
///
/// Everything else about Safe Share can be tested as pure Dart, and the one
/// piece that cannot is the piece that actually changes somebody's image:
/// decode, erase, draw, re-encode. `flutter analyze` and a green suite say
/// nothing about whether a single pixel moved — this project has shipped two
/// launch-blocking bugs that were invisible to both.
///
/// `redact` needs no recogniser and no image labelling, only a file and a
/// plan, so it can be driven end to end here. The assertions avoid anything
/// font-dependent (the test engine draws glyphs as boxes) and check the
/// property that actually matters: **the original pixels are gone, and
/// nothing outside the region was touched.**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workspace;
  late RedactionService service;

  setUpAll(() {
    workspace = Directory.systemTemp.createTempSync('shoto_redaction');
    // Constructing the recogniser allocates an id and nothing else — no
    // channel call happens until processImage, which redact never makes.
    service = RedactionService(TextRecognitionDataSource());
  });

  tearDownAll(() => workspace.deleteSync(recursive: true));

  /// A white image with a red block where the "private text" is, so anything
  /// left of the original is unmistakable in the output.
  Future<File> makeSource({
    required int width,
    required int height,
    required ui.Rect secret,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    canvas.drawRect(secret, ui.Paint()..color = const ui.Color(0xFFFF0000));

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width, height);
    final ByteData png = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!;
    picture.dispose();
    image.dispose();

    final File file = File(
      '${workspace.path}/src_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(png.buffer.asUint8List());
    return file;
  }

  Future<_Pixels> decode(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ByteData raw = (await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    final _Pixels pixels = _Pixels(
      raw.buffer.asUint8List(),
      frame.image.width,
      frame.image.height,
    );
    frame.image.dispose();
    codec.dispose();
    return pixels;
  }

  SensitiveRegion regionAt(
    ui.Rect bounds, {
    RegionTreatment treatment = RegionTreatment.cover,
    String runText = '4111 1111 1111 1111',
    bool isRtl = false,
  }) => SensitiveRegion(
    kind: SensitiveKind.card,
    bounds: bounds,
    runId: 'run-0',
    runText: runText,
    localStart: 0,
    localEnd: runText.length,
    original: runText,
    isRtl: isRtl,
    treatment: treatment,
  );

  group('covering', () {
    test('the region becomes a solid block', () async {
      const ui.Rect secret = ui.Rect.fromLTWH(40, 40, 200, 24);
      final File source = await makeSource(
        width: 400,
        height: 120,
        secret: secret,
      );

      final Uint8List out = await service.redact(
        source,
        RedactionPlan(
          regions: <SensitiveRegion>[regionAt(secret)],
          imageSize: const ui.Size(400, 120),
        ),
      );

      final _Pixels pixels = await decode(out);
      expect(pixels.width, 400);
      expect(pixels.height, 120);
      expect(
        pixels.countRedIn(secret),
        0,
        reason: 'the real value was still visible in the exported image',
      );
      expect(pixels.at(140, 52), const ui.Color(0xFF121212));
    });

    test('nothing outside the region is touched', () async {
      const ui.Rect secret = ui.Rect.fromLTWH(40, 40, 200, 24);
      const ui.Rect bystander = ui.Rect.fromLTWH(300, 40, 60, 24);

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 400, 120),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF),
      );
      canvas.drawRect(secret, ui.Paint()..color = const ui.Color(0xFFFF0000));
      canvas.drawRect(
        bystander,
        ui.Paint()..color = const ui.Color(0xFFFF0000),
      );
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(400, 120);
      final ByteData png = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!;
      picture.dispose();
      image.dispose();

      final File source = File('${workspace.path}/two_blocks.png');
      await source.writeAsBytes(png.buffer.asUint8List());

      final Uint8List out = await service.redact(
        source,
        RedactionPlan(
          regions: <SensitiveRegion>[regionAt(secret)],
          imageSize: const ui.Size(400, 120),
        ),
      );

      final _Pixels pixels = await decode(out);
      expect(pixels.countRedIn(secret), 0);
      expect(
        pixels.countRedIn(bystander),
        bystander.width.toInt() * bystander.height.toInt(),
        reason: 'the block reached past its own rectangle',
      );
    });

    test('the block reaches past the glyphs', () async {
      // OCR rectangles hug the letters, so a block flush to the box leaves
      // readable fringes above and below. The source here is painted red a
      // few pixels *wider* than the region, and those pixels must come back
      // covered rather than red.
      const ui.Rect region = ui.Rect.fromLTWH(40, 40, 200, 24);
      final File source = await makeSource(
        width: 400,
        height: 120,
        secret: const ui.Rect.fromLTWH(38, 38, 204, 28),
      );

      final Uint8List out = await service.redact(
        source,
        RedactionPlan(
          regions: <SensitiveRegion>[regionAt(region)],
          imageSize: const ui.Size(400, 120),
        ),
      );

      final _Pixels pixels = await decode(out);
      expect(pixels.at(140, 38), const ui.Color(0xFF121212));
      expect(pixels.at(140, 65), const ui.Color(0xFF121212));
      expect(pixels.countRedIn(region), 0);
    });

    test('a right-to-left run is covered like any other', () async {
      const ui.Rect secret = ui.Rect.fromLTWH(20, 20, 260, 26);
      final File source = await makeSource(
        width: 320,
        height: 80,
        secret: secret,
      );

      final Uint8List out = await service.redact(
        source,
        RedactionPlan(
          regions: <SensitiveRegion>[
            regionAt(secret, runText: 'محمد أبو مطر', isRtl: true),
          ],
          imageSize: const ui.Size(320, 80),
        ),
      );

      expect((await decode(out)).countRedIn(secret), 0);
    });

    test('a zero-height region is skipped rather than crashing', () async {
      const ui.Rect degenerate = ui.Rect.fromLTWH(40, 40, 200, 0);
      final File source = await makeSource(
        width: 400,
        height: 120,
        secret: const ui.Rect.fromLTWH(40, 40, 200, 24),
      );

      final Uint8List out = await service.redact(
        source,
        RedactionPlan(
          regions: <SensitiveRegion>[regionAt(degenerate)],
          imageSize: const ui.Size(400, 120),
        ),
      );

      expect((await decode(out)).width, 400);
    });
  });

  group('keeping', () {
    test('a kept region leaves the image exactly as it was', () async {
      const ui.Rect secret = ui.Rect.fromLTWH(40, 40, 200, 24);
      final File source = await makeSource(
        width: 400,
        height: 120,
        secret: secret,
      );

      final Uint8List out = await service.redact(
        source,
        RedactionPlan(
          regions: <SensitiveRegion>[
            regionAt(secret, treatment: RegionTreatment.keep),
          ],
          imageSize: const ui.Size(400, 120),
        ),
      );

      final _Pixels pixels = await decode(out);
      expect(
        pixels.countRedIn(secret),
        secret.width.toInt() * secret.height.toInt(),
      );
    });
  });
}

class _Pixels {
  final Uint8List rgba;
  final int width;
  final int height;

  const _Pixels(this.rgba, this.width, this.height);

  ui.Color at(int x, int y) {
    final int i = (y * width + x) * 4;
    return ui.Color.fromARGB(rgba[i + 3], rgba[i], rgba[i + 1], rgba[i + 2]);
  }

  /// How many pixels of the original red block survive inside [area].
  int countRedIn(ui.Rect area) {
    int found = 0;
    for (int y = area.top.toInt(); y < area.bottom.toInt(); y++) {
      for (int x = area.left.toInt(); x < area.right.toInt(); x++) {
        if (x < 0 || y < 0 || x >= width || y >= height) continue;
        final int i = (y * width + x) * 4;
        if (rgba[i] > 200 && rgba[i + 1] < 80 && rgba[i + 2] < 80) found++;
      }
    }
    return found;
  }
}
