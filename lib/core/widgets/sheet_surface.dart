import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/widgets/glass_layer.dart';

/// The panel a bottom sheet is drawn on: frosted, not filled.
///
/// Every sheet in the app used to paint itself an opaque [AppColors.surface]
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

  const SheetSurface({super.key, required this.child});

  /// Only the top two corners are cut, and by more than a card is: a sheet is
  /// the largest surface the app raises, and a radius that reads as generous at
  /// the width of a chip reads as barely rounded across a whole screen.
  static const double cornerRadius = 28;

  @override
  Widget build(BuildContext context) {
    final BorderRadius shape = BorderRadius.vertical(
      top: Radius.circular(cornerRadius.r),
    );

    return GlassLayer(
      borderRadius: shape,
      child: GlassRim(
        borderRadius: shape,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.isDark
                  ? [
                      const Color(0xFF303030).withValues(alpha: 0.78),
                      const Color(0xFF212121).withValues(alpha: 0.86),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.82),
                      const Color(0xFFF4F4F4).withValues(alpha: 0.9),
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
      ),
    );
  }
}
