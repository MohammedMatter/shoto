/// The placeholder vocabulary, for the one moment the app has nothing to say
/// yet.
///
/// **A skeleton is a promise about layout, not a spinner.** Home's first frame
/// used to draw literally nothing where its main block goes — `SizedBox.shrink`
/// — so a cold start opened on a page in "empty library" shape and then
/// rearranged itself the instant the gallery read landed. What the user saw was
/// not a load, it was the page changing its mind.
///
/// So everything here is about *reserving the right space*. A placeholder that
/// is a different height from the thing it stands in for has not solved the
/// problem, it has moved it: the jump still happens, just from a different
/// starting position. Every box below is sized from the same constants the real
/// widget uses, which is why they are `static const` on those widgets rather
/// than typed in twice.
///
/// There is no shimmer. A sweeping highlight is a second animation running
/// under a page that is already doing an entrance, and it draws the eye to the
/// part of the screen with the least information on it.
library;

import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';

/// One grey block standing in for content that has not arrived.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double? radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius ?? 6),
      ),
    );
  }
}

/// A slow breath over everything under it, so a placeholder reads as *pending*
/// rather than as content that failed to render.
///
/// One controller for the whole block rather than one per box: the boxes have
/// to pulse **together** — a dozen independently animated greys is a page
/// twinkling at the user — and a single [FadeTransition] over the subtree is
/// also one opacity layer instead of a dozen.
///
/// Nothing at all under reduced motion, which is the whole point of that
/// setting: a loading state is exactly the kind of ambient, non-explanatory
/// movement it exists to remove. The boxes are still there, just still.
class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  /// Slower than anything else in the app, and deliberately outside
  /// [AppMotion]'s tiers.
  ///
  /// Those durations are all under 300ms because they are attached to
  /// something the user did and is waiting on the end of. This is attached to
  /// nothing and ends when the data does, so the same reasoning inverts: a fast
  /// pulse on a block nobody triggered reads as an alarm.
  static const Duration _period = Duration(milliseconds: 1100);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  )..repeat(reverse: true);

  /// Never down to zero. A placeholder that fully disappears is a hole in the
  /// layout twice a second, which is worse than the blank frame this replaces.
  late final Animation<double> _opacity = Tween<double>(
    begin: 1,
    end: 0.45,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
