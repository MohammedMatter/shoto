import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/widgets/glass_layer.dart';

/// The panel a bottom sheet is drawn on: frosted, not filled.
///
/// Every sheet in the app used to paint itself an opaque [AppPalette.surface]
/// rectangle, which makes a fine card and a poor sheet. A sheet is a thing that
/// has *arrived over* the screen you were looking at, and an opaque fill throws
/// away the only cue that says so — once it stops moving there is nothing left
/// to distinguish it from a pushed page.
///
/// So the fill is translucent over a blur of whatever is behind it, the way
/// iOS's materials work: enough of the library shows through to keep the sheet
/// attached to the screen it came from, not nearly enough for a screenshot's
/// colours to reach the text sitting on top of it.
///
/// Three parts, all doing that same job:
///
/// * **The blur** — [AppBlur.panel], the app's middle sigma. A sheet is a
///   surface the user opened and is looking at, and nothing behind it is
///   moving while it is up, so it can afford more than the tab bar can.
/// * **The fill**, a two-stop gradient rather than a flat colour, brightest
///   where the light lands. The ramp is finished within the first third so a
///   full-height sheet doesn't read as a gradient.
/// * **The lit edge** — [GlassRim]. The one detail that makes the top of the
///   sheet read as the rim of a panel rather than as the line where one colour
///   stops and another starts.
///
/// Wrap a sheet's content in this **inside** any outer inset. The rule builder
/// holds itself sixty pixels off the top of the screen, and glass wrapped
/// around that padding would frost the gap as well as the sheet.
class SheetSurface extends StatelessWidget {
  final Widget child;

  /// Overrides the blur strength for the few sheets that are simply too big to
  /// pay [AppBlur.panel] for.
  ///
  /// A blur costs by area, and the area is the whole thing being animated: a
  /// sheet that covers four fifths of the screen re-blurs four fifths of the
  /// screen on every frame of its entrance, on the frames the user is watching
  /// most closely. The frosting is an identity worth keeping, so the answer is
  /// to spend less of it where it costs most rather than to drop it — at this
  /// size the difference between sigma 16 and sigma 10 is invisible in a
  /// still and the difference in frames is not.
  ///
  /// Left alone by every ordinary sheet. See [AppBlur.tallSheet].
  final double? sigma;

  const SheetSurface({super.key, required this.child, this.sigma});

  /// Only the top two corners are cut, and by more than a card is: a sheet is
  /// the largest surface the app raises, and a radius that reads as generous at
  /// the width of a chip reads as barely rounded across a whole screen.
  static const double cornerRadius = 28;

  @override
  Widget build(BuildContext context) {
    final BorderRadius shape = BorderRadius.vertical(
      top: Radius.circular(SheetSurface.cornerRadius.r),
    );
    final double target = sigma ?? AppBlur.panel;

    // **The frost waits until the sheet has stopped moving, and this is the
    // most expensive thing in the app made cheap.**
    //
    // Measured on a real phone in a profile build, opening the intent picker
    // over the photo viewer: Dart build time never passed 2ms while *raster*
    // ran 32–74ms a frame against a 16.6ms budget — up to four and a half
    // frames of GPU work per frame, none of it the widget tree's fault. A
    // `BackdropFilter` that is travelling re-samples and re-blurs a fresh
    // region every frame, over whatever it happens to be crossing; on that
    // screen, a full-resolution screenshot under three more pieces of glass.
    //
    // Nothing is lost by waiting. The fill below sits at 82–90% opacity, so
    // during a 220ms slide there is almost nothing of the backdrop to see
    // through it. The frost does its work once the panel is *still* and being
    // looked at, which is exactly when it can be afforded.
    //
    // **Read straight off the route's own animation rather than held in
    // state.** A [StatefulWidget] that flipped a flag when the entrance
    // finished was the obvious version and it was wrong in a way only the
    // tests caught: its `setState` schedules an *extra* frame, `pumpAndSettle`
    // then runs one frame longer, and every blinking text caret in a sheet
    // lands on a different phase — two golden failures forty-four pixels each,
    // in a sliver two pixels wide, having changed nothing anybody could see.
    // Listening to the animation that is already ticking adds no frame at all:
    // the last tick of the entrance and the arrival of the blur are the same
    // frame.
    final Animation<double>? travel = ModalRoute.of(context)?.animation;
    final bool frosted = target > 0 && (travel?.isCompleted ?? true);

    final Widget panel = _Panel(frosted: frosted, shape: shape, child: child);

    if (travel == null || target <= 0) {
      return GlassLayer(
        borderRadius: shape,
        sigma: frosted ? target : 0,
        child: panel,
      );
    }

    return ListenableBuilder(
      listenable: travel,
      builder: (BuildContext context, Widget? _) => GlassLayer(
        borderRadius: shape,
        sigma: travel.isCompleted ? target : 0,
        child: _Panel(frosted: travel.isCompleted, shape: shape, child: child),
      ),
    );
  }
}

/// The fill and the lit edge — everything about the sheet except the blur.
///
/// **The fill closes up whenever the blur is not there**, and the two are one
/// decision rather than two. A translucent fill only works because a blur is
/// smearing what is behind it into a wash; put the same fill over a sharp
/// backdrop and the sheet turns into a window with somebody's screenshot
/// legible through it, which is the one thing this surface must never be —
/// text on it stops being readable and the panel stops reading as a panel.
///
/// So: frosted and translucent, or sharp and nearly solid. Never translucent
/// and sharp.
class _Panel extends StatelessWidget {
  final bool frosted;
  final BorderRadius shape;
  final Widget child;

  const _Panel({
    required this.frosted,
    required this.shape,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = context.colors.isDark;

    // The same two stops in both states — a step toward the light at the top,
    // a step toward the canvas at the bottom — only their opacity changes.
    final Color top = dark
        ? context.colors.surfaceVariant
        : context.colors.surface;
    final Color bottom = dark
        ? context.colors.surface
        : context.colors.background;

    final double topAlpha = frosted ? (dark ? 0.78 : 0.82) : 0.985;
    final double bottomAlpha = frosted ? (dark ? 0.86 : 0.9) : 1;

    return GlassRim(
      borderRadius: shape,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Derived from the palette rather than written out, which is how
            // this pair had already drifted once: they were literals of a
            // *previous* neutral ramp, so a sheet stayed the old grey while
            // every card around it moved to the new one. A glass fill is
            // still a surface — it belongs to the surface system even though
            // it is translucent.
            colors: <Color>[
              top.withValues(alpha: topAlpha),
              bottom.withValues(alpha: bottomAlpha),
            ],
            // Past a third of the way down the panel is one flat colour.
            // Running the ramp to the bottom would make a tall sheet — the
            // rule builder is nearly full-screen — visibly a gradient.
            stops: const [0, 0.32],
          ),
          borderRadius: shape,
        ),
        child: child,
      ),
    );
  }
}
