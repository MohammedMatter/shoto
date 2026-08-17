import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/glass_layer.dart';

/// Chrome that floats over somebody else's picture.
///
/// Every control on the photo viewer sits on top of a screenshot Shoto did not
/// choose and cannot predict, and all of them used to be **white glass**: a
/// white fill at 14%, a white hairline, white glyphs. Over a dark screenshot
/// that is a beautiful pane of frosted glass. Over a white one — a receipt, a
/// document, an article, which is most of what anybody screenshots — it is
/// white on white, and the entire toolbar disappears. Not dimmed: gone.
///
/// The rule this replaces it with is the one every photo viewer converges on,
/// because there is only one answer: **chrome over unknown content is dark with
/// light glyphs.** A light material can only work over dark content, so it fails
/// half the time by construction. A dark one works over both — white glyphs keep
/// their contrast against a dark fill no matter what is behind it.
///
/// The alphas are set by the worst case rather than the pretty one, and they
/// went **up** when the blur went away — see [AppBlur.overPhoto].
///
/// A blur was never what made these legible; the fill was. What the blur did
/// was hide the *detail* behind them, and that is the job the extra opacity
/// has taken over: at the old values a bar over a page of small print showed
/// every line of it, sharp, through the glass, and a control you can read the
/// wallpaper through reads as a smudge rather than as a surface. Against pure
/// white, [barFill] now composites to roughly `#3C3C3C` and carries white 9pt
/// labels at better than 8:1; the lighter [circleFill] is for glyphs only,
/// where the threshold is lower and the shape does more of the work.
///
/// They are still translucent, deliberately — the picture is still visible
/// through them, which is what keeps them reading as something laid over the
/// photograph rather than as a black bar bolted on.
///
/// It lives in its own file because there are now two bars over the picture,
/// not one: the ordinary action bar, and the one that replaces it while text
/// is being selected. Two copies of the reasoning above would have drifted the
/// first time either was touched.
abstract class PhotoChromePalette {
  PhotoChromePalette._();

  /// The action bar: the piece carrying small text, so the most opaque.
  static LinearGradient get barFill => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppPalette.overlay.withValues(alpha: 0.82),
      AppPalette.overlay.withValues(alpha: 0.88),
    ],
  );

  /// The back button and the counter — icons and one short line.
  static Color get circleFill => AppPalette.overlay.withValues(alpha: 0.78);

  /// The lit edge. Unchanged from the old white glass, and it still earns its
  /// place: over a dark screenshot the fill alone has no boundary, and this is
  /// what gives the control an edge to be seen by.
  static Color get rim => Colors.white.withValues(alpha: 0.18);
}

/// One verb in a bar over the picture: a glyph with a small label under it.
class PhotoBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  /// A value whose change should make the icon pop once. Null for the
  /// stateless actions, which have nothing to report.
  final Object? pop;

  /// Dims the whole cell and swallows the tap. For a verb that exists but has
  /// nothing to work on yet — visible, so the bar does not reshuffle under the
  /// thumb the moment it becomes available.
  final bool enabled;

  const PhotoBarAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint = Colors.white,
    this.pop,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget glyph = Icon(icon, color: tint, size: 21.sp);

    final Widget cell = Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pop == null) glyph else ValuePop(value: pop, child: glyph),
          SizedBox(height: 4.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 9.5.sp,
              height: 1,
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return IgnorePointer(child: Opacity(opacity: 0.35, child: cell));
    }

    return PressableScale(scale: 0.88, onTap: onTap, child: cell);
  }
}

/// A round glass button over the picture — back, the counter's neighbours, the
/// tick on the intent bar.
class PhotoGlassCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  /// White everywhere except on the intent tick, which is the one control in
  /// this chrome with a state worth colouring — see `IntentVisuals.tint`.
  final Color? tint;

  /// Replaces the glass fill, for the same one exception.
  final Color? fill;

  const PhotoGlassCircle({
    super.key,
    required this.icon,
    required this.onTap,
    this.tint,
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.88,
      onTap: onTap,
      child: GlassLayer(
        radius: 999,
        sigma: AppBlur.overPhoto,
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.normal),
          curve: AppMotion.standard,
          width: 40.w,
          height: 40.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill ?? PhotoChromePalette.circleFill,
            border: Border.all(
              color: fill == null ? PhotoChromePalette.rim : Colors.transparent,
            ),
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.normal),
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.standard,
            transitionBuilder: (Widget child, Animation<double> animation) =>
                FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
                    child: child,
                  ),
                ),
            child: Icon(
              icon,
              key: ValueKey<IconData>(icon),
              color: tint ?? Colors.white,
              size: 16.sp,
            ),
          ),
        ),
      ),
    );
  }
}
