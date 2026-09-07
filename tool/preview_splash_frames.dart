// Renders the mark's filing animation as a strip of stills, for looking at.
//
//     flutter test tool/preview_splash_frames.dart
//
// Writes build/splash_frames_{light,dark}.png. Scaffolding, not a test — it
// exists so the choreography can be checked without installing a debug build
// over whatever the phone is already carrying.
//
// **The launch screen no longer plays this**, despite the file's name. The
// cards flying in is what the sign-in screen and the Pro welcome do; the
// launch screen takes the mark whole from the platform's own splash and settles
// it. See `lib/core/widgets/splash_curtain.dart`. The name is kept because the
// output path is, and because this is still the only place the filing
// choreography can be seen frame by frame.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/widgets/shoto_brand_mark.dart';

void main() {
  test('splash frames', () async {
    // Sampled at the moments that matter rather than evenly: the curve is a
    // strong ease-out, so almost everything happens in the first third.
    const List<double> steps = [0, 0.12, 0.25, 0.4, 0.6, 1.0];
    const double w = 260;
    const double h = 420;
    const double gap = 8;

    for (final MapEntry<String, Color> mode in {
      'light': const Color(0xFFFAFAFA),
      'dark': const Color(0xFF1A1A1A),
    }.entries) {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Rect bounds = Rect.fromLTWH(
        0,
        0,
        steps.length * (w + gap) + gap,
        h + gap * 2,
      );
      final Canvas canvas = Canvas(recorder, bounds);
      canvas.drawRect(bounds, Paint()..color = const Color(0xFF9AA0AA));

      for (int i = 0; i < steps.length; i++) {
        canvas.save();
        canvas.translate(gap + i * (w + gap), gap);
        canvas.clipRect(const Rect.fromLTWH(0, 0, w, h));
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, w, h),
          Paint()..color = mode.value,
        );
        ShotoBrandMarkPainter(
          markExtent: 96,
          progress: steps[i],
        ).paint(canvas, const Size(w, h));
        canvas.restore();
      }

      final ui.Image image = await recorder.endRecording().toImage(
        bounds.width.round(),
        bounds.height.round(),
      );
      final ByteData data = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!;
      File('build/splash_frames_${mode.key}.png')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(data.buffer.asUint8List());
    }
  });
}
