import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/utils/perceptual_hash.dart';

/// Turns a gallery asset into a [PerceptualHash] fingerprint.
///
/// Deliberately works off a small thumbnail rather than the full-resolution
/// file: the hash squashes everything to 9x8 anyway, so decoding a multi-
/// megabyte PNG would be pure waste on a scan that touches every screenshot
/// in the library.
class PerceptualHashDataSource {
  /// Intermediate thumbnail size requested from the gallery. Larger than the
  /// final 9x8 grid so the OS-provided thumbnail still carries enough detail
  /// for the downscale to average meaningfully, but small enough to stay
  /// cheap.
  static const ThumbnailSize _thumbnailSize = ThumbnailSize.square(64);

  Future<String?> computeHash(AssetEntity asset) async {
    ui.Image? image;
    try {
      final Uint8List? thumbnail = await asset.thumbnailDataWithSize(
        _thumbnailSize,
      );
      if (thumbnail == null) return null;

      // targetWidth/targetHeight make the engine do the downscale for us,
      // so we never materialize the full-size bitmap.
      final ui.Codec codec = await ui.instantiateImageCodec(
        thumbnail,
        targetWidth: PerceptualHash.sampleWidth,
        targetHeight: PerceptualHash.sampleHeight,
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      image = frame.image;
      codec.dispose();

      final ByteData? rgba = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (rgba == null) return null;

      return PerceptualHash.fromRgba(rgba.buffer.asUint8List());
    } catch (_) {
      // A single unreadable/corrupt asset must not abort a whole-library
      // scan — it just doesn't participate in duplicate matching.
      return null;
    } finally {
      image?.dispose();
    }
  }
}
