import 'package:shoto/core/localization/app_message.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/utils/scroll_stitcher.dart';
import 'package:shoto/features/stitch/domain/entities/stitch_outcome.dart';

/// Turns a run of scrolling screenshots into one tall image.
///
/// Everything here is I/O and pixel plumbing — the actual "where do these
/// overlap" reasoning lives in [ScrollStitcher], deliberately kept free of
/// Flutter so it can be tested exhaustively without a device.
///
/// Images are decoded twice, on purpose. The first pass asks the engine for
/// a [ScrollStitcher.profileWidth]-wide version, which is a few hundred
/// kilobytes instead of tens of megabytes and is all the seam search needs;
/// full-resolution frames are only materialised for the final composite, and
/// only then are they all alive at once.
class ImageStitchService {
  /// Upper bound on captures per stitch. Every source frame has to be held
  /// in memory simultaneously while the composite is rasterised, so this is
  /// a memory ceiling, not a UX preference.
  static const int maxSources = 5;

  /// Refuse to build anything taller than this. Very large surfaces fail at
  /// the graphics layer on some devices, and failing early with a clear
  /// message beats an opaque crash deep in the rasteriser.
  static const int maxOutputHeight = 16000;

  Future<StitchOutcome> stitch(
    List<AssetEntity> assets, {
    void Function(int step, int total)? onProgress,
  }) async {
    if (assets.length < 2) {
      throw const StitchException(AppMessage.stitchTooFew);
    }
    if (assets.length > maxSources) {
      throw StitchException(AppMessage.stitchTooMany(maxSources));
    }

    final List<Uint8List> encoded = [];
    for (int i = 0; i < assets.length; i++) {
      final Uint8List? bytes = await assets[i].originBytes;
      if (bytes == null) {
        throw const StitchException(AppMessage.stitchUnreadable);
      }
      encoded.add(bytes);
      onProgress?.call(i + 1, assets.length + 2);
    }

    // ---- Pass 1: cheap profiles, just enough to find the seams ----------
    final List<RowProfile> profiles = [];
    final List<int> heights = [];
    int? width;

    for (final Uint8List bytes in encoded) {
      final _Profiled profiled = await _profile(bytes);
      if (width == null) {
        width = profiled.sourceWidth;
      } else if (width != profiled.sourceWidth) {
        throw const StitchException(AppMessage.stitchWidths);
      }
      profiles.add(profiled.profile);
      heights.add(profiled.sourceHeight);
    }
    onProgress?.call(assets.length + 1, assets.length + 2);

    // Screenshots arrive newest-first from the gallery, but a scroll reads
    // top-to-bottom, so oldest must come first. If that ordering yields no
    // valid chain the user may have scrolled upwards while capturing, so the
    // reverse is tried before giving up.
    List<ScrollSeam>? seams = _chainSeams(profiles);
    List<int> orderedHeights = heights;
    List<Uint8List> orderedBytes = encoded;

    if (seams == null) {
      orderedHeights = heights.reversed.toList();
      orderedBytes = encoded.reversed.toList();
      seams = _chainSeams(profiles.reversed.toList());
    }

    if (seams == null) {
      throw const StitchException(AppMessage.stitchNoOverlap);
    }

    final List<StitchSlice>? slices = ScrollStitcher.buildSlices(
      orderedHeights,
      seams,
    );
    if (slices == null) {
      throw const StitchException(AppMessage.stitchOverlap);
    }

    final int outputHeight = ScrollStitcher.outputHeight(slices);
    if (outputHeight > maxOutputHeight) {
      throw const StitchException(AppMessage.stitchTooTall);
    }

    // ---- Pass 2: full-resolution composite ------------------------------
    final Uint8List png = await _compose(
      orderedBytes,
      slices,
      width!,
      outputHeight,
    );
    onProgress?.call(assets.length + 2, assets.length + 2);

    int totalSource = 0;
    for (final int height in orderedHeights) {
      totalSource += height;
    }

    return StitchOutcome(
      pngBytes: png,
      width: width,
      height: outputHeight,
      sourceCount: assets.length,
      trimmedRows: totalSource - outputHeight,
    );
  }

  /// Seams for every consecutive pair, or null the moment one pair doesn't
  /// convincingly overlap — a chain is only as good as its weakest join, and
  /// a fabricated one would silently invent page content.
  List<ScrollSeam>? _chainSeams(List<RowProfile> profiles) {
    final List<ScrollSeam> seams = [];
    for (int i = 0; i < profiles.length - 1; i++) {
      final ScrollSeam? seam = ScrollStitcher.findSeam(
        profiles[i],
        profiles[i + 1],
      );
      if (seam == null) return null;
      seams.add(seam);
    }
    return seams;
  }

  /// Decodes [bytes] straight to a narrow, full-height frame and reduces it
  /// to luminance.
  ///
  /// Asking the codec for the target width means the engine performs the
  /// horizontal downscale natively and we never allocate the full bitmap in
  /// Dart. Height is kept at the original so the seam can be resolved to an
  /// exact pixel row — anything coarser shows up as a visible tear.
  Future<_Profiled> _profile(Uint8List bytes) async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      bytes,
    );
    final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(
      buffer,
    );
    final int sourceWidth = descriptor.width;
    final int sourceHeight = descriptor.height;

    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await descriptor.instantiateCodec(
        targetWidth: ScrollStitcher.profileWidth,
        targetHeight: sourceHeight,
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      image = frame.image;

      final ByteData? rgba = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (rgba == null) {
        throw const StitchException(AppMessage.stitchUnreadable);
      }

      return _Profiled(
        profile: RowProfile(
          width: ScrollStitcher.profileWidth,
          height: image.height,
          luma: _toLuma(rgba.buffer.asUint8List()),
        ),
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
      );
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor.dispose();
    }
  }

  /// Draws each slice into one surface and encodes the result.
  Future<Uint8List> _compose(
    List<Uint8List> encoded,
    List<StitchSlice> slices,
    int width,
    int height,
  ) async {
    final List<ui.Image> frames = [];
    ui.Picture? picture;
    ui.Image? output;

    try {
      for (final Uint8List bytes in encoded) {
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frame = await codec.getNextFrame();
        frames.add(frame.image);
        codec.dispose();
      }

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      // No filtering: every slice is drawn at 1:1, so resampling could only
      // soften the result.
      final ui.Paint paint = ui.Paint()
        ..filterQuality = ui.FilterQuality.none
        ..isAntiAlias = false;

      for (final StitchSlice slice in slices) {
        final ui.Image frame = frames[slice.imageIndex];
        canvas.drawImageRect(
          frame,
          ui.Rect.fromLTWH(
            0,
            slice.sourceTop.toDouble(),
            width.toDouble(),
            slice.height.toDouble(),
          ),
          ui.Rect.fromLTWH(
            0,
            slice.destTop.toDouble(),
            width.toDouble(),
            slice.height.toDouble(),
          ),
          paint,
        );
      }

      picture = recorder.endRecording();
      output = await picture.toImage(width, height);

      final ByteData? png = await output.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (png == null) {
        throw const StitchException(AppMessage.stitchEncode);
      }
      return png.buffer.asUint8List();
    } finally {
      picture?.dispose();
      output?.dispose();
      for (final ui.Image frame in frames) {
        frame.dispose();
      }
    }
  }

  static Uint8List _toLuma(Uint8List rgba) {
    final int pixels = rgba.length ~/ 4;
    final Uint8List luma = Uint8List(pixels);
    for (int i = 0; i < pixels; i++) {
      final int offset = i * 4;
      // Rec. 601 weights, matching the perceptual-hash util so both features
      // judge brightness the same way.
      luma[i] =
          (rgba[offset] * 299 +
              rgba[offset + 1] * 587 +
              rgba[offset + 2] * 114) ~/
          1000;
    }
    return luma;
  }
}

class _Profiled {
  final RowProfile profile;
  final int sourceWidth;
  final int sourceHeight;

  const _Profiled({
    required this.profile,
    required this.sourceWidth,
    required this.sourceHeight,
  });
}
