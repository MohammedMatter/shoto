// Generates every raster the Shoto mark needs, from the one painter that
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
import 'package:shoto/core/theme/app_icon.dart';
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

// ------------------------------------------------------- the launch window
//
// **The splash is no longer the app icon printed large**, which is what it was
// and what every default Flutter project ships. An icon is a *tile* — it
// carries its own rounded background — so putting one in the middle of a
// screen paints a sticker onto a blank wall rather than designing a screen.
//
// What is drawn now is the mark with no slab under it, on a full-bleed field of
// the brand's own ground, with the wordmark beneath it. The colour moved from
// the logo to the screen, which is the whole change.
//
// **The field is the same in light and dark**, which is a deliberate break from
// what `colors.xml` used to guarantee — see the note there about matching
// `AppPalette.background` exactly so the handover does not flash. It flashes
// now, once, from teal to the app's own background at Flutter's first frame.
// That is the price of a launch screen that is the same brand moment for
// everybody rather than two different greys.

/// The launch mark's canvas and the safe area inside it, in dp.
///
/// Android's own numbers: a splash icon is authored on a 288dp square and
/// everything drawn has to stay inside the middle 192dp, because the platform
/// is free to mask, scale or animate the rest. The same pair drives the iOS
/// launch image, so one drawing serves both and there is nothing to keep in
/// agreement.
///
/// **Nothing native carries the wordmark any more, and that is the point of
/// this file getting shorter rather than longer.** For a long time the launch
/// window drew the mark with `SHOTO` set under it, in two rasters — one per
/// field — with a `FontLoader` in this script to set them, because a window
/// painted before the app's process exists cannot choose a colour or a font at
/// runtime. All of that was in service of a picture nobody could animate.
///
/// The wordmark is drawn by `SplashCurtain` now, in Flutter, where it can
/// arrive rather than merely be present. What the platform gets is the mark
/// alone — which is exactly what the platform's splash slot is specified to
/// hold — and the two agree because the curtain is handed the icon's measured
/// rectangle and draws into it. See `lib/core/widgets/splash_curtain.dart`.
///
/// **And the mark here has no slab.** The rounded tile was mandatory for as
/// long as the launch window was the *icon* printed large — an icon carries its
/// own tile, and dropping one in the middle of a screen decorates a screen
/// rather than designing one. What kept it after that was the light field: the
/// front card is `AppBrand.paper`, six levels off `#F4F4F4`, so bare on light
/// mode it all but disappears.
///
/// It is bare anyway, and the reason is that the front card was never what was
/// carrying the mark. The two teal cards behind it and the ribbon on it hold
/// the silhouette on a near-white field — the paper card reads as a very quiet
/// shape between them rather than as a missing one. Checked by rendering it on
/// `#F4F4F4`, `#FFFFFF`, `#111213` and `#000000` before committing to it, which
/// is the only way that judgement can honestly be made.
///
/// One drawing serves both fields, so there is no `drawable-night` twin of this
/// and nothing per-mode to keep in step.
const double _splashIconCanvas = 288;
const double _splashIconMark = 192;

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

    // ------------------------------------------ Android, alternate icons
    //
    // **Only the background layer is redrawn per variant**, which is what
    // makes six icons cost fifty files instead of two hundred. The adaptive
    // foreground is built with `backdrop: false` — it is the tray and the
    // cards on transparency, with no slab in it at all — so every variant
    // shares the one already written above, and so does the monochrome layer,
    // which has no colour by definition.
    //
    // The legacy raster is the exception and has to be drawn whole: API 24 and
    // 25 take a single flat PNG with no layers to compose, and this app's
    // minSdk is 24.
    for (final AppIcon icon in AppIcon.all) {
      if (icon == AppIcon.ink) continue; // Already written, unsuffixed.

      for (final MapEntry<String, double> d in _densities.entries) {
        await _png(
          '$_android/mipmap-${d.key}/ic_launcher_background_${icon.id}.png',
          (_adaptiveCanvas * d.value).round(),
          (px) => ShotoBrandMarkPainter(
            markExtent: px,
            mark: false,
            backdropCornerRadius: 0,
            slab: icon.slab,
          ),
        );

        await _png(
          '$_android/mipmap-${d.key}/ic_launcher_${icon.id}.png',
          (48 * d.value).round(),
          (px) => ShotoBrandMarkPainter(markExtent: px, slab: icon.slab),
        );
      }

      // The adaptive descriptor. Written from here rather than kept by hand in
      // `res/` because the whole point of this file is that nothing about the
      // mark exists in two places — a variant added to `AppIcon.all` should
      // need no XML written for it.
      File(
        '$_android/mipmap-anydpi-v26/ic_launcher_${icon.id}.xml',
      ).writeAsStringSync(_adaptiveXml(icon.id));
    }

    // ------------------------------------------- Android, the launch window
    //
    // One drawable, unqualified: the field is `AppBrand.ground` in both modes,
    // so there is nothing for a `drawable-night` twin to say differently. This
    // is what `windowSplashScreenAnimatedIcon` is pointed at on every API
    // level — `androidx.core:core-splashscreen` backports that attribute below
    // 31, so there is no longer a second launch drawable for old phones and no
    // `launch_background.xml` at all.
    for (final MapEntry<String, double> d in _densities.entries) {
      await _splashIconPng('$_android/drawable-${d.key}/splash_mark.png', d.value);
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

    // The iOS launch image — the same drawing on the same canvas as Android's,
    // because `LaunchBackground.colorset` is already `AppBrand.ground` and the
    // curtain that takes over is the same curtain. One artwork, three
    // rasterisations, no second set of proportions to keep in step.
    for (int scale = 1; scale <= 3; scale++) {
      await _splashIconPng(
        '$_iosLaunch/LaunchImage${scale == 1 ? '' : '@${scale}x'}.png',
        scale.toDouble(),
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

/// The adaptive-icon descriptor for one alternate variant.
///
/// Its foreground and monochrome layers are the *unsuffixed* ones — those are
/// the tray and cards with no slab in them, so every variant shares them and
/// only the background differs. See the loop that writes these.
String _adaptiveXml(String id) =>
    '''
<?xml version="1.0" encoding="utf-8"?>
<!--
    Generated by tool/generate_brand_assets.dart — do not edit by hand.

    An alternate launcher icon. Identical to ic_launcher.xml except for the
    background layer: the foreground (tray and cards) and the monochrome
    stencil carry no slab, so all six variants share the one drawing.
-->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background_$id" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
''';


/// The bare mark, centred on the canvas both platforms' launch slots expect.
///
/// **Centred on its own ink rather than on its box.** With a slab under it the
/// two are the same question — the slab is the box — and the mark's deliberate
/// weight to the left reads as composition inside a frame. Bare on a field
/// there is no frame, and the same offset reads as a centring mistake. See
/// [ShotoBrandMarkPainter.restBounds] for why the correction is computed here
/// instead of typed.
Future<void> _splashIconPng(String path, double density) async {
  final int px = (_splashIconCanvas * density).round();

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()),
  );
  canvas.scale(density);

  // Solved from the safe area's width, which is the binding dimension: the ink
  // is 75.5 wide against 69.7 tall, so a mark fitted by height would overflow
  // the 192dp square it has to stay inside.
  final double extent = ShotoBrandMarkPainter.extentForInkWidth(
    _splashIconMark,
  );

  ShotoBrandMarkPainter(
    markExtent: extent,
    backdrop: false,
    centre: ShotoBrandMarkPainter.centreForInk(
      const Offset(_splashIconCanvas / 2, _splashIconCanvas / 2),
      extent,
    ),
  ).paint(canvas, const Size(_splashIconCanvas, _splashIconCanvas));

  final ui.Image image = await recorder.endRecording().toImage(px, px);
  final Uint8List bytes = (await image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
  image.dispose();

  final File file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);

  // ignore: avoid_print
  print('  ${px}px  $path');
}
