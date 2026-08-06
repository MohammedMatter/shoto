import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';

/// The only way this app draws a gallery thumbnail.
///
/// It is shared rather than repeated because the alternative shipped a real
/// bug twice. Written the obvious way —
///
/// ```dart
/// FutureBuilder(future: asset.thumbnailDataWithSize(...), ...)
/// ```
///
/// — the future is **rebuilt on every `build()`**, so switching tabs,
/// toggling a favourite or entering selection mode starts a fresh fetch and
/// paints an empty box until it returns. The picture visibly twitches for
/// reasons that have nothing to do with the picture. It is also why
/// scrolling stuttered: `Image.memory` never touches Flutter's `ImageCache`,
/// so every recycled tile paid for a whole decode again.
///
/// An [ImageProvider] is keyed by asset and size, so the second request for
/// the same thumbnail is a cache hit — no channel call, no decode, no gap.
/// The grid was fixed first and the Home strip was missed, which is exactly
/// how the twitch survived being "fixed".
class AssetThumbnailImage extends StatelessWidget {
  final AssetEntity asset;

  /// One size for the whole app, on purpose.
  ///
  /// Size is part of the cache key. Home asking for 240 while the grid asked
  /// for 300 meant every screenshot was fetched and decoded **twice** and
  /// neither screen could reuse the other's work. 300 covers the largest
  /// tile with room to spare.
  static const ThumbnailSize size = ThumbnailSize.square(300);

  /// What shows through before the first frame decodes.
  ///
  /// The grid wants the app's placeholder tint. The full-screen viewer wants
  /// nothing at all — a pale rectangle flashing on a black page, for the one
  /// frame before a cached thumbnail paints, is more noticeable than the gap
  /// it was meant to cover.
  final Color? background;

  /// How the thumbnail fills its box.
  ///
  /// Cover everywhere a screenshot appears *among others* — a grid of tiles
  /// that are not the same shape is not a grid. [BoxFit.contain] is for the
  /// one screen that shows a single capture and asks the user to judge it:
  /// cropping a tall screenshot to a square there throws away most of what
  /// the judgement depends on.
  ///
  /// It is not part of the cache key, so both fits share one decode.
  final BoxFit fit;

  const AssetThumbnailImage({
    super.key,
    required this.asset,
    this.background,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background ?? context.colors.surfaceVariant,
      child: Image(
        image: AssetEntityImageProvider(
          asset,
          isOriginal: false,
          thumbnailSize: size,
        ),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        // Holds the pixels already on screen while a new decode is in flight
        // rather than blanking back to the placeholder.
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          // curve was absent — Flutter defaults to Curves.linear. A decoded
          // frame arriving is an entrance, and entrances ease out.
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: AppMotion.duration(context, AppMotion.press),
            curve: AppMotion.standard,
            child: child,
          );
        },
      ),
    );
  }
}
