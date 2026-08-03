import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_motion.dart';

/// The route the full-screen screenshot viewer is opened with.
///
/// It exists as its own class rather than reusing `FadeSlidePageRoute` because
/// a page opened by a **shared-element flight** has a different job from every
/// other push in the app: the picture is already doing the moving, and the
/// page's only remaining task is to get out of its way.
///
/// Two decisions, both about not competing with the flight:
///
/// **No slide.** The generic route lifts the whole page by 4% of the screen on
/// its way in. The picture, meanwhile, travels its own path from the tile that
/// was tapped — the hero flies in the navigator's overlay, so it does not
/// share that movement. Two different translations happening at once over the
/// same 280ms is exactly the kind of thing that is impossible to point at and
/// still reads as "off". Here the page only fades.
///
/// **The fade finishes first.** It runs over the first ~55% of the transition
/// rather than all of it, so the background has already settled to solid black
/// while the picture is still arriving. One thing at a time: the surround
/// resolves, then the subject lands on it. Running both to the same finish line
/// meant the picture completed its flight over a half-transparent page that was
/// still dissolving the grid underneath it — a lot of simultaneous change for
/// an interaction whose entire content is "look at this one picture".
class PhotoViewerRoute<T> extends PageRouteBuilder<T> {
  PhotoViewerRoute({required WidgetBuilder builder})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: AppMotion.sheet,
        reverseTransitionDuration: AppMotion.normal,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0, 0.55, curve: AppMotion.standard),
              // Full range on the way out, and flipped so leaving is as
              // immediate as arriving — see AppMotion.standardReverse for why
              // passing the forward curve straight through behaves like an
              // ease-in.
              reverseCurve: AppMotion.standardReverse,
            ),
            child: child,
          );
        },
      );
}
