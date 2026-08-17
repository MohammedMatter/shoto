import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/widgets/shoto_brand_mark.dart';

/// The only decoration on the sign-in screen: the app's own mark, drawn
/// enormous and cropped by the corner of the phone.
///
/// **What this replaced, and why.** The background here used to be two soft
/// radial pools — accent top-left, teal bottom-right, both at low alpha — under
/// a comment describing them as "warmth rather than a gradient". They were
/// still a gradient, and they were the exact gradient every generated sign-in
/// screen on the internet opens with. `app_colors.dart` spent five revisions
/// draining colour washes out of this app and flattened all twenty-two of its
/// `LinearGradient`s to single fills; leaving one behind on the first screen
/// anybody sees was the loudest place to keep the habit.
///
/// So the decoration is not a colour any more, it is a **shape** — and the only
/// shape this product owns. [ShotoBrandMarkPainter] is asked for its cards at
/// one and a half times the width of the screen, anchored off the top trailing
/// corner, so what lands on the page is a fragment: one card edge, the clipped
/// corner, and the two rules cut out of the filed card. Blown up past the point
/// of being a logo, it reads as texture — and it is texture nobody else's app
/// can have, because it is generated from the same geometry as the icon on the
/// home screen.
///
/// **Drawn as a stencil rather than tinted afterwards.** `monochrome: true` is
/// the mode the Android themed icon uses: each card is cut out of the ones
/// behind it with a hairline of clearance, so the boundaries that are normally
/// carried by three different paper values survive being flattened to one
/// colour. Painting the mark normally and fading it would fuse the three cards
/// into a single lumpy blob at this alpha. The [ColorFiltered] then replaces
/// that stencil's colour while keeping its alpha, which is what lets the whole
/// thing be described by a single token — [AppPalette.textPrimary] — and be
/// correct in both modes without a second value.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;

    return RepaintBoundary(
      child: ColoredBox(
        color: colors.background,
        child: ColorFiltered(
          // Alpha low enough that on a screenshot of this screen it reads as a
          // change in the paper rather than as a picture. A hair more in dark
          // mode: the same alpha of a light shape on near-black is a smaller
          // step in value than a dark shape on paper.
          colorFilter: ColorFilter.mode(
            colors.textPrimary.withValues(alpha: colors.isDark ? 0.048 : 0.034),
            BlendMode.srcIn,
          ),
          child: CustomPaint(
            size: Size.infinite,
            isComplex: true,
            willChange: false,
            painter: _MarkWatermarkPainter(
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
  }
}

/// Places [ShotoBrandMarkPainter] rather than reimplementing any of it.
///
/// The mark knows how to draw itself at any extent, around any centre, with or
/// without its slab; all this decides is *how big* and *where* — which is the
/// whole of the composition and none of the geometry.
class _MarkWatermarkPainter extends CustomPainter {
  /// Mirrored for a right-to-left interface, so the mark is always cropped by
  /// the corner the reading eye leaves rather than the one it starts from.
  final bool rtl;

  const _MarkWatermarkPainter({required this.rtl});

  /// The mark's box, as a multiple of the screen's width.
  ///
  /// Past about 1.2 the fan stops being recognisable as three cards and starts
  /// being a set of curves, which is the point: this is not a logo placement,
  /// it is the mark used as paper stock.
  static const double _extent = 1.55;

  /// Where the centre of that box sits, as a fraction of the screen.
  ///
  /// Off the trailing edge and above the top one, so the fragment that lands on
  /// the page is the lower-leading quarter of the fan — the part with the
  /// clipped corner in it. Anchored high on purpose: the content column is
  /// start-aligned and its two action buttons are opaque, so anything drawn
  /// near the bottom of the screen would be sliced by a button edge and read as
  /// an accident rather than as a crop.
  static const Offset _centre = Offset(0.98, 0.06);

  @override
  void paint(Canvas canvas, Size size) {
    final double x = rtl ? 1 - _centre.dx : _centre.dx;

    ShotoBrandMarkPainter(
      markExtent: size.width * _extent,
      // Cards only. The slab is the mark's container, and a container this
      // large is a second background rather than a decoration on the first.
      backdrop: false,
      monochrome: true,
      centre: Offset(size.width * x, size.height * _centre.dy),
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_MarkWatermarkPainter old) => old.rtl != rtl;
}
