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

  /// Chrome floating over a full-screen photograph: **no blur.**
  ///
  /// The photo viewer is the one screen where the thing behind the glass is a
  /// full-resolution screenshot filling the display, and it carries three
  /// pieces of chrome at once. Measured on a real phone in a profile build,
  /// that screen cost 20–23ms of raster per frame *by itself*, before any
  /// sheet was opened on top of it — over a 16.6ms budget with nothing else
  /// happening. Sharing one backdrop between the three
  /// ([BackdropGroup]) cut the spikes and left that baseline where it was: one
  /// blur of a screen-sized picture is simply ~20ms on this class of GPU.
  ///
  /// So the chrome over a photograph stops blurring and leans on its fill
  /// instead, which is where its legibility came from in the first place —
  /// see `PhotoChromePalette`, whose alphas are set by the worst case rather
  /// than the pretty one. What is lost is the picture *softening* under the
  /// bars; what is bought is the entire screen back under budget. On a surface
  /// whose whole job is to show somebody a picture, that is not a close call.
  static const double overPhoto = 0;

  /// For sheets that cover most of the screen: **no backdrop blur at all.**
  ///
  /// This was 10, down from 16, on the argument that a lighter sigma over a
  /// large area is invisible in a still and cheaper in motion. Measured on a
  /// real phone, that argument finishes one step further along than it was
  /// taken: the surfaces this applies to are 82–90% opaque *and* cover four
  /// fifths of the screen, so the backdrop contributes a few percent of the
  /// pixels while costing ~60ms of GPU time a frame — four frames' worth of
  /// budget for something you cannot point to in a screenshot.
  ///
  /// A sheet that big is not a pane you see the room through, it is a page.
  /// So it stops pretending: no blur, and [SheetSurface] compensates by
  /// closing the fill to nearly opaque, which is what the eye reads as
  /// *material* anyway. The small sheets keep their frost, where it is both
  /// visible and affordable.
  static const double tallSheet = 0;
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
    final BorderRadius shape = borderRadius ?? BorderRadius.circular(radius!);
    final double resolved = sigma.clamp(0, AppBlur.max);

    // **No filter at all rather than a filter that blurs by nothing.**
    //
    // A [BackdropFilter] costs a `saveLayer` and a full filter pass over its
    // region whether or not the blur it applies amounts to anything, so a zero
    // sigma is not a cheap blur — it is the entire cost of one, for no visible
    // effect. Returning the clip on its own is what makes a sigma of zero
    // genuinely mean *do not do this*, which is what a travelling sheet needs
    // it to mean. See `SheetSurface`, which spends the whole of its entrance
    // here.
    if (resolved <= 0) return ClipRRect(borderRadius: shape, child: child);

    final ImageFilter blur = ImageFilter.blur(
      sigmaX: resolved,
      sigmaY: resolved,
    );

    // **Share one backdrop with the other glass in the same group, when there
    // is one.**
    //
    // Three separate `BackdropFilter`s over one photograph — which is exactly
    // what the photo viewer is, with a top bar, an intent bar and an action
    // bar — each snapshot the screen behind them and blur it independently.
    // The three snapshots are of the *same* picture, so two of the three are
    // work done twice. A [BackdropGroup] makes them sample one shared layer
    // instead.
    //
    // Grouping is opt-in from above rather than assumed here, because it is
    // only correct when the surfaces genuinely share a backdrop: a grouped
    // filter reads what was painted *before the group*, so a piece of glass
    // that is supposed to blur a sibling drawn beside it would come out blank.
    // Asking whether an ancestor has declared a group is what keeps that
    // decision where the layout is known.
    final bool shared = BackdropGroup.of(context) != null;

    return ClipRRect(
      borderRadius: shape,
      child: shared
          ? BackdropFilter.grouped(filter: blur, child: child)
          : BackdropFilter(filter: blur, child: child),
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
