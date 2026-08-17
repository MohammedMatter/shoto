import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/safe_share/domain/entities/sensitive_region.dart';

/// The screenshot being worked on, at whatever size it fits.
///
/// It has two jobs across the two halves of this screen, and they are
/// deliberately different pictures:
///
/// * Before unlocking, it shows the **original, untouched**, with a ring drawn
///   around each finding. That answers "where is it?" — which is the whole of
///   what the free scan promises — and nothing else.
///
///   Deliberately a ring and not a blur. A blur *is* the product: frost the
///   findings on screen and anyone can screenshot the result and walk away
///   with a redacted picture without ever passing the paywall. An outline on
///   the user's own screenshot, on the user's own phone, is worth nothing to
///   screenshot — every private detail in it is still perfectly readable,
///   which is exactly the point being made.
/// * After unlocking, it shows the exported bytes themselves. Not an
///   approximation drawn with widgets: the actual PNG that will be shared, so
///   what the user checks is what the recipient gets.
class ScreenshotPreview extends StatelessWidget {
  final File file;
  final Size imageSize;

  /// The findings to ring. Empty once [result] is showing.
  final List<SensitiveRegion> markers;

  /// The rendered copy. When present it replaces the original entirely.
  final Uint8List? result;

  /// Whether a fresh render is in flight. The previous result stays on screen
  /// underneath — a preview that blanked out on every change would make the
  /// treatment buttons feel broken.
  final bool busy;

  const ScreenshotPreview({
    super.key,
    required this.file,
    required this.imageSize,
    this.markers = const [],
    this.result,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = result;

    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ColoredBox(
          color: context.colors.surfaceVariant,
          child: AspectRatio(
            aspectRatio: imageSize.width / imageSize.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bytes != null)
                  // gaplessPlayback: re-rendering after a treatment changes
                  // swaps these bytes for new ones, and without it the
                  // preview blinks to empty on every tap.
                  Image.memory(bytes, fit: BoxFit.fill, gaplessPlayback: true)
                else
                  _WithMarkers(
                    file: file,
                    imageSize: imageSize,
                    markers: markers,
                  ),
                if (busy)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: const _BusyPill(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    // Substitutions are small and deliberately unremarkable, which makes them
    // hard to check at a third of actual size. Anyone about to send a
    // screenshot they were worried about should be able to look properly.
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (_, _, _) => _FullScreenPreview(
          file: file,
          imageSize: imageSize,
          markers: markers,
          result: result,
        ),
      ),
    );
  }
}

/// "Building your clean copy", floating over whatever is already showing.
///
/// Sits on the picture rather than replacing it: the point of the debounce is
/// that the previous result stays readable while the next one is drawn.
class _BusyPill extends StatelessWidget {
  const _BusyPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: context.colors.background.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 11.w,
            height: 11.w,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: context.colors.primary,
            ),
          ),
          SizedBox(width: 7.w),
          Text(
            context.l10n.safeShareBuilding,
            style: context.text.caption.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WithMarkers extends StatelessWidget {
  final File file;
  final Size imageSize;
  final List<SensitiveRegion> markers;

  const _WithMarkers({
    required this.file,
    required this.imageSize,
    required this.markers,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double scaleX = constraints.maxWidth / imageSize.width;
        final double scaleY = constraints.maxHeight / imageSize.height;

        final List<Rect> rects = [
          for (final SensitiveRegion region in markers)
            Rect.fromLTWH(
              region.bounds.left * scaleX,
              region.bounds.top * scaleY,
              region.bounds.width * scaleX,
              region.bounds.height * scaleY,
            ).inflate(2),
        ];

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.fill),
            // The colour is read here, in a build that reruns on a theme
            // change, and handed to the painter. A [CustomPainter] has no
            // `BuildContext` and so cannot read the palette itself: it would
            // have to be given one from somewhere, and `shouldRepaint` has no
            // way to notice that something it closed over has changed.
            //
            // The wash is 8% so the eye finds the region at a glance; any
            // heavier and it starts doing the job the subscription is for.
            if (rects.isNotEmpty)
              CustomPaint(
                painter: _RegionsOutline(rects, context.colors.marker),
              ),
          ],
        );
      },
    );
  }
}

/// Rings each finding on the original. Nothing here hides anything — see the
/// note on [ScreenshotPreview] for why that is the whole design.
class _RegionsOutline extends CustomPainter {
  final List<Rect> rects;
  final Color colour;

  const _RegionsOutline(this.rects, this.colour);

  @override
  void paint(Canvas canvas, Size size) {
    // **Two rings, and the second one is not decoration.**
    //
    // This drew a single stroke in the accent, which is the one place in the
    // app where a palette colour cannot be trusted to be visible: it is
    // painted *on a screenshot*, and the screenshot's colours are the whole
    // set of colours Shoto does not choose. Caught on the real thing — a blue
    // spreadsheet full of IBANs, where a blue ring around each finding was
    // indistinguishable from the cell borders already in the picture. The
    // feature's entire claim is "here is what I found"; a marker that blends
    // into the content is the one failure it cannot afford.
    //
    // There is no hue that contrasts with an unknown image, so the answer is
    // not a better hue — it is a pair with opposite luminance. A near-black
    // halo under a near-white ring means one of the two always separates from
    // whatever is behind it, which is why every crop and selection tool ever
    // built draws its marquee this way. Both are fixed rather than mode-aware,
    // for the same reason the viewer's chrome is: the surface underneath is a
    // photograph, not the app's own material.
    //
    // The accent survives as the 8% wash, which is what still makes the marker
    // *Shoto's*. The wash is deliberately too faint to hide anything — any
    // heavier and it starts doing the job the subscription is for.
    final Paint wash = Paint()..color = colour.withValues(alpha: 0.08);
    final Paint halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppPalette.overlay.withValues(alpha: 0.45);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppPalette.paper.withValues(alpha: 0.95);

    for (final Rect rect in rects) {
      final RRect rounded = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(3),
      );
      canvas.drawRRect(rounded, wash);
      canvas.drawRRect(rounded, halo);
      canvas.drawRRect(rounded, stroke);
    }
  }

  @override
  bool shouldRepaint(_RegionsOutline oldDelegate) =>
      oldDelegate.rects != rects || oldDelegate.colour != colour;
}

class _FullScreenPreview extends StatelessWidget {
  final File file;
  final Size imageSize;
  final List<SensitiveRegion> markers;
  final Uint8List? result;

  const _FullScreenPreview({
    required this.file,
    required this.imageSize,
    required this.markers,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = result;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 6,
              child: Center(
                child: AspectRatio(
                  aspectRatio: imageSize.width / imageSize.height,
                  child: bytes != null
                      ? Image.memory(bytes, fit: BoxFit.contain)
                      : _WithMarkers(
                          file: file,
                          imageSize: imageSize,
                          markers: markers,
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8.h,
            right: 12.w,
            child: IconButton(
              tooltip: context.l10n.commonClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
