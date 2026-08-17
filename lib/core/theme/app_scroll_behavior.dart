import 'package:flutter/material.dart';

/// How every scrollable in the app behaves when it reaches its end.
///
/// **Rubber, not a wall.** Flutter hands Android `ClampingScrollPhysics`: the
/// list stops dead at the top and a blue arc smears across the edge to say so.
/// That is the platform's answer and it is the wrong one for this app, for a
/// reason the animation standards in this repo state directly — *friction over
/// hard stops; allow over-drag with rising resistance rather than an invisible
/// wall.* A list that stops instantly has no mass. Everything a person flicks
/// has some, and a page that pretends otherwise is the specific thing people
/// mean when they say an app "feels cheap" and cannot point at why.
///
/// [BouncingScrollPhysics] is that mass: the further you pull past the end the
/// harder it pulls back, and it settles on a spring rather than a stop. It is
/// also what the app was already doing in one place by hand — the intent strip
/// on Home asked for it explicitly — which is exactly the kind of local fix
/// that should have been a global decision.
///
/// **The glow goes with it.** An overscroll indicator exists to report the wall;
/// with the rubber band there is no wall to report, and drawing both means the
/// page stretches *and* smears. Returning the child unwrapped is how a
/// [ScrollBehavior] declines to draw one.
///
/// The scrollbar stays: it says *where you are in a long list*, which is a
/// different question and one this app's libraries are long enough to raise.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  /// `RangeMaintainingScrollPhysics` as the parent, which is what iOS gets by
  /// default and is not decoration: it is what stops a list jumping when
  /// something above the viewport changes size — a thumbnail resolving, a row
  /// animating out. Dropping it to compose the bounce by hand would trade a
  /// wall for a jump.
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: RangeMaintainingScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
