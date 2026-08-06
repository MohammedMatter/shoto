import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_colors.dart';

/// How strongly each kind of surface frosts what is behind it.
///
/// These live together because a backdrop blur is **the most expensive thing
/// this app draws**, and the cost is not paid once — a `BackdropFilter` has to
/// re-blur its region on every frame in which the pixels behind it change. A
/// blur over a scrolling list is therefore a per-frame cost for as long as the
/// finger is moving.
///
/// Which is why the numbers are graded by *how much of the time the surface is
/// on screen*, not by how pretty a given value looks in isolation:
///
/// * [bar] is on screen in every tab, all the time, over whatever is
///   scrolling. It gets the smallest sigma in the app.
/// * [panel] is a sheet or toolbar the user opened and is looking at.
/// * [dialog] blurs the whole screen, but only while a dialog is up and
///   nothing behind it is moving.
///
/// The nav bar used to sit at **30**, well past the ceiling the dialog code
/// had already written down for itself, and it was the single always-on
/// blur in the app. Dropping it and lifting the fill opacity to compensate
/// looks near-identical and stops charging every scroll in the app for it.
abstract class AppBlur {
  AppBlur._();

  /// Past roughly this, the visual difference is small and the cost is not.
  static const double max = 18;

  static const double bar = 14;
  static const double panel = 16;
  static const double dialog = 12;

  /// For sheets that cover most of the screen.
  ///
  /// Blur cost scales with area, and a near-full-screen panel re-blurs that
  /// area on every frame of its entrance — so the surfaces that can least
  /// afford [panel] are exactly the ones large enough to make it visible.
  /// Frosting reads by *proportion* to the surface it sits on, and at this
  /// size a lighter sigma is indistinguishable in a still while being
  /// distinctly cheaper in motion.
  static const double tallSheet = 10;
}

/// A frosted region: the clip and the blur, and nothing else.
///
/// Deliberately does **not** take a colour, gradient or border. Every glass
/// surface in this app decorates itself differently — a pill, a circle, a
/// sheet with a sheen — and folding all of that in would produce one widget
/// with eight optional parameters. What is worth centralising is the
/// expensive half: one place that decides what a blur costs, so tuning it is
/// a single edit rather than a hunt through eight files.
class GlassLayer extends StatelessWidget {
  final Widget child;

  /// Must match whatever the child draws, or the blur will show outside it.
  /// A radius of 999 on a square box gives a circle.
  final double? radius;

  /// For the surfaces whose corners are not all the same — a bottom sheet
  /// rounds its top two and runs off the bottom of the screen, so it cannot
  /// state its clip as one number. Give exactly one of this and [radius].
  final BorderRadius? borderRadius;

  final double sigma;

  const GlassLayer({
    super.key,
    required this.child,
    this.radius,
    this.borderRadius,
    this.sigma = AppBlur.panel,
  }) : assert(
         (radius == null) != (borderRadius == null),
         'GlassLayer takes either radius or borderRadius, not both or neither.',
       );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(radius!),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: sigma.clamp(0, AppBlur.max),
          sigmaY: sigma.clamp(0, AppBlur.max),
        ),
        child: child,
      ),
    );
  }
}

/// The lit edge of a glass surface: one hairline, brightest along the top.
///
/// This is the smallest thing in the file and the one that decides whether a
/// translucent panel reads as *glass* or as a slightly see-through rectangle.
/// A blurred fill on its own has no edge — it ends wherever the clip says it
/// ends, which is the look of a mask rather than of an object. A single bright
/// hairline gives the surface a thickness for light to catch on, and that is
/// the entire difference.
///
/// Painted rather than declared as a [Border], for two reasons that both come
/// from the same place: [BoxDecoration] refuses to paint a border on one side
/// only once a `borderRadius` is involved, and a rim of even brightness all
/// the way round reads as an outline. Light comes from above in every
/// interface Apple has ever shipped, so the stroke is shaded with a gradient
/// that dies out [falloff] pixels down and the bottom of the surface simply
/// has no edge — which is also what stops the tab bar from drawing a bright
/// line across the home indicator.
///
/// Costs nothing on layout: [CustomPaint] hands its constraints straight to
/// the child, so this can be dropped around existing content without moving a
/// pixel of it.
class GlassRim extends StatelessWidget {
  final Widget child;

  /// Must match the clip of the [GlassLayer] this sits inside, or the hairline
  /// will trace a shape the surface doesn't have.
  final BorderRadius borderRadius;

  /// How far down the surface the light survives, in logical pixels. Roughly
  /// half the height of the surface: a tab-bar pill wants a shorter falloff
  /// than a sheet, or the rim runs down the whole of it.
  final double falloff;

  /// Defaults to white at the alpha that reads as *edge* rather than as
  /// *outline* in each mode. Dark mode needs far less: over near-black, white
  /// at a tenth is already a clearly visible line, while the same value on
  /// paper disappears entirely.
  final Color? color;

  const GlassRim({
    super.key,
    required this.child,
    required this.borderRadius,
    this.falloff = 44,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _GlassRimPainter(
        borderRadius: borderRadius,
        color:
            color ??
            Colors.white.withValues(alpha: context.colors.isDark ? 0.11 : 0.6),
        falloff: falloff,
      ),
      child: child,
    );
  }
}

class _GlassRimPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color color;
  final double falloff;

  const _GlassRimPainter({
    required this.borderRadius,
    required this.color,
    required this.falloff,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final Rect rect = Offset.zero & size;

    // Inset by half a stroke: a 1px line centred on the clip's own edge is
    // half outside it, and the clip would eat the visible half.
    final RRect outline = borderRadius.toRRect(rect).deflate(0.5);

    final double end = (falloff / size.height).clamp(0.02, 1);

    canvas.drawRRect(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0)],
          stops: [0, end],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassRimPainter old) =>
      old.borderRadius != borderRadius ||
      old.color != color ||
      old.falloff != falloff;
}
