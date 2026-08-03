// Generates every raster the SHOTO mark needs, from the one painter that
// defines it.
//
//     flutter test tool/generate_brand_assets.dart
//
// Run it after touching `shoto_brand_mark.dart` or `app_brand.dart`, and
// commit whatever it changes.
//
// ---
//
// **Why this exists rather than a folder of exported PNGs.**
//
// The mark has to appear at twenty-eight different pixel sizes across two
// platforms: five launcher densities on Android, five more for each of the
// three adaptive-icon layers, five for the native launch window, sixteen for
// iOS. Hand-exporting those is not the problem — keeping them in agreement
// for the rest of the project's life is. One tweak to the tray, and the icon
// on the home screen is a version behind the one on the splash, and nothing
// in the build will ever say so.
//
// Here the geometry lives in `lib/`, in Dart, next to the widget the app
// actually draws, and these files are output. They cannot disagree.
//
// It runs as a test rather than as a `dart run` script because rendering
// needs a live `dart:ui` — real gradients, real antialiasing, the same
// rasteriser that will draw the mark on the device. A CPU-side redraw in
// Python or an SVG export would be a *second* implementation of the mark, and
// a second implementation is the exact thing this file exists to avoid.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/widgets/shoto_brand_mark.dart';

/// Density buckets, as multipliers on a density-independent pixel.
const Map<String, double> _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

const String _android = 'android/app/src/main/res';
const String _iosIcons = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const String _iosLaunch = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';

/// The size, in dp, of an Android adaptive icon's canvas. Fixed by the
/// platform: the launcher is free to mask, scale and parallax anywhere inside
/// it, and only the central 66dp is guaranteed to survive.
const double _adaptiveCanvas = 108;

/// How much of that canvas the mark's box takes up.
///
/// The box is ~85% covered by drawn content, so this puts the mark at about
/// 64dp — just inside the 66dp the platform guarantees, and no smaller,
/// because a foreground that hides well inside the safe zone reads as a small
/// icon rather than as a safe one.
const double _adaptiveMark = 0.70;

/// The mark's size in the native launch window, in dp. The native window
/// stays up until the first real screen is ready, so unlike the icon sizes
/// above this one has no Flutter-side counterpart to stay in sync with.
const double _splashMark = 96;

void main() {
  test('generate brand assets', () async {
    // ------------------------------------------------- Android, legacy icon
    //
    // Only API 24 and 25 ever see this; everything newer takes the adaptive
    // pair below. It keeps its own rounded corners because nothing on those
    // versions is going to add them.
    for (final MapEntry<String, double> d in _densities.entries) {
      await _png(
        '$_android/mipmap-${d.key}/ic_launcher.png',
        (48 * d.value).round(),
        (px) => ShotoBrandMarkPainter(markExtent: px),
      );
    }

    // ---------------------------------------------- Android, adaptive icon
    //
    // Three layers, all cut from the same painter. The background is
    // full-bleed and square-cornered — the launcher applies the device's own
    // mask, and a slab that arrives pre-rounded gets rounded twice.
    for (final MapEntry<String, double> d in _densities.entries) {
      final int px = (_adaptiveCanvas * d.value).round();

      await _png(
        '$_android/mipmap-${d.key}/ic_launcher_background.png',
        px,
        (px) => ShotoBrandMarkPainter(
          markExtent: px,
          mark: false,
          backdropCornerRadius: 0,
        ),
      );

      await _png(
        '$_android/mipmap-${d.key}/ic_launcher_foreground.png',
        px,
        (px) => ShotoBrandMarkPainter(
          markExtent: px * _adaptiveMark,
          backdrop: false,
        ),
      );

      // Themed icons, Android 13+. The painter has a mode for this rather than
      // the drawing simply being tinted flat here, because a flat tint is what
      // this used to be and it produced a featureless blob — every boundary in
      // the mark is a change of colour, and a themed icon has no colour. The
      // mode turns those boundaries into gaps instead.
      await _png(
        '$_android/mipmap-${d.key}/ic_launcher_monochrome.png',
        px,
        (px) => ShotoBrandMarkPainter(
          markExtent: px * _adaptiveMark,
          backdrop: false,
          monochrome: true,
        ),
      );
    }

    // ------------------------------------------- Android, the launch window
    //
    // An empty tray, and the emptiness is the point: this is drawn by the OS
    // before Flutter exists, so it cannot move — and the first Flutter frame
    // draws exactly this, at exactly this size, in exactly this place, and
    // then files the cards into it.
    for (final MapEntry<String, double> d in _densities.entries) {
      await _png(
        '$_android/drawable-${d.key}/splash_logo.png',
        (_splashMark * d.value).round(),
        (px) => ShotoBrandMarkPainter(markExtent: px, cards: false),
      );
    }

    // ---------------------------------------------------------------- iOS
    //
    // Square-cornered and opaque. iOS masks every icon to its own
    // superellipse, and the App Store rejects an icon with an alpha channel
    // outright.
    const Map<String, int> iosIcons = {
      'Icon-App-20x20@1x': 20,
      'Icon-App-20x20@2x': 40,
      'Icon-App-20x20@3x': 60,
      'Icon-App-29x29@1x': 29,
      'Icon-App-29x29@2x': 58,
      'Icon-App-29x29@3x': 87,
      'Icon-App-40x40@1x': 40,
      'Icon-App-40x40@2x': 80,
      'Icon-App-40x40@3x': 120,
      'Icon-App-60x60@2x': 120,
      'Icon-App-60x60@3x': 180,
      'Icon-App-76x76@1x': 76,
      'Icon-App-76x76@2x': 152,
      'Icon-App-83.5x83.5@2x': 167,
      'Icon-App-1024x1024@1x': 1024,
    };

    for (final MapEntry<String, int> icon in iosIcons.entries) {
      await _png(
        '$_iosIcons/${icon.key}.png',
        icon.value,
        (px) => ShotoBrandMarkPainter(markExtent: px, backdropCornerRadius: 0),
        opaque: true,
      );
    }

    // The iOS launch image, matching Android's: the same empty tray, at the
    // same 96dp, for the same reason.
    for (int scale = 1; scale <= 3; scale++) {
      await _png(
        '$_iosLaunch/LaunchImage${scale == 1 ? '' : '@${scale}x'}.png',
        (_splashMark * scale).round(),
        (px) => ShotoBrandMarkPainter(markExtent: px, cards: false),
      );
    }

    // A single large reference, for the store listing and for looking at.
    //
    // Deliberately not under `assets/`. Nothing here is bundled into the app —
    // the mark is drawn, not loaded — and a stray 200KB PNG sitting in the
    // assets folder is exactly the kind of thing that gets swept into
    // pubspec's asset list by someone adding `assets/` wholesale, and shipped
    // to every user for no reason.
    await _png(
      'branding/shoto_icon.png',
      1024,
      (px) => ShotoBrandMarkPainter(markExtent: px),
    );
  });
}

/// Rasterises [painter] into a square PNG of [px] pixels and writes it.
///
/// [painter] is a callback rather than a value because every size needs its
/// own `markExtent` — the painter measures the mark in the same units as the
/// canvas, which is what lets one description serve a 20px icon and a 1024px
/// one without a scale factor anywhere in the geometry.
Future<void> _png(
  String path,
  int px,
  ShotoBrandMarkPainter Function(double px) painter, {
  bool opaque = false,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Rect bounds = Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble());
  final Canvas canvas = Canvas(recorder, bounds);

  painter(px.toDouble()).paint(canvas, bounds.size);

  final ui.Image image = await recorder.endRecording().toImage(px, px);

  final Uint8List bytes;
  if (opaque) {
    final ByteData raw = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    bytes = _encodeOpaquePng(raw.buffer.asUint8List(), px);
  } else {
    bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }
  image.dispose();

  final File file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);

  // ignore: avoid_print
  print('  ${px}px  $path${opaque ? '  (no alpha)' : ''}');
}

// ---------------------------------------------------------------------------
// A 24-bit PNG writer, forty lines of it, for one reason:
//
//   **App Store Connect rejects an app icon that has an alpha channel**, and
//   `ui.Image.toByteData(format: png)` can only produce RGBA. Not "rejects an
//   icon with transparent pixels" — rejects one with the *channel present*,
//   which every icon this file would otherwise emit has, every one of them
//   fully opaque. The upload fails at validation, long after the build looks
//   like it worked.
//
// The alternative was a post-processing step in another language, which is a
// second tool to install and a second thing to remember to run; or the
// `image` package, which is a runtime dependency the app itself would then
// ship for the sake of a build script. Re-encoding pixels that are already in
// hand is smaller than either.
// ---------------------------------------------------------------------------

/// Re-encodes [rgba] — tightly packed, four bytes per pixel — as a colour-type
/// 2 (truecolour, no alpha) PNG.
Uint8List _encodeOpaquePng(Uint8List rgba, int size) {
  // Each scanline is prefixed with its filter type. Zero is "none": the rows
  // are stored raw and zlib does all the compressing. Filtering would shrink
  // the file, and these files are written once and never fetched over a
  // network, so it would buy nothing worth the code.
  final Uint8List rows = Uint8List(size * (1 + size * 3));
  int w = 0;
  for (int y = 0; y < size; y++) {
    rows[w++] = 0;
    for (int x = 0; x < size; x++) {
      final int r = (y * size + x) * 4;
      rows[w++] = rgba[r];
      rows[w++] = rgba[r + 1];
      rows[w++] = rgba[r + 2];
    }
  }

  final BytesBuilder out = BytesBuilder();
  out.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  final Uint8List ihdr = Uint8List(13);
  final ByteData header = ihdr.buffer.asByteData();
  header.setUint32(0, size);
  header.setUint32(4, size);
  ihdr[8] = 8; // bits per channel
  ihdr[9] = 2; // colour type 2 — RGB, and nothing else
  // 10..12 stay zero: deflate, adaptive filtering, no interlacing.

  _chunk(out, 'IHDR', ihdr);
  _chunk(out, 'IDAT', Uint8List.fromList(ZLibEncoder().convert(rows)));
  _chunk(out, 'IEND', Uint8List(0));

  return out.takeBytes();
}

void _chunk(BytesBuilder out, String type, Uint8List data) {
  final Uint8List name = Uint8List.fromList(type.codeUnits);

  final Uint8List length = Uint8List(4);
  length.buffer.asByteData().setUint32(0, data.length);
  out.add(length);
  out.add(name);
  out.add(data);

  final Uint8List crc = Uint8List(4);
  crc.buffer.asByteData().setUint32(0, _crc32([...name, ...data]));
  out.add(crc);
}

/// The CRC-32 every PNG chunk ends with. Standard polynomial, table built once.
final List<int> _crcTable = List<int>.generate(256, (int n) {
  int c = n;
  for (int k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  int c = 0xFFFFFFFF;
  for (final int b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
