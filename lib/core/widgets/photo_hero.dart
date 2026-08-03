import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// A [Hero] for a picture, which also carries the corner radius that picture
/// has **on this side of the flight**.
///
/// A plain `Hero` lifts its child into the navigator's overlay for the duration
/// of the flight, and the overlay is not inside whatever `ClipRRect` the child
/// normally lives in. So a rounded grid tile squares off its corners on the
/// first frame of the flight and rounds them again on the last frame of the way
/// back — a hard edge appearing and disappearing at the two exact moments the
/// eye is following that shape across the screen. It is small, it is only two
/// frames, and it is the difference between one object moving and two objects
/// being swapped.
///
/// Telling both ends what radius they draw with lets the flight interpolate
/// between them, so the corner opens out as the picture grows and closes back
/// as it returns. Nothing else about the picture changes.
class PhotoHero extends StatelessWidget {
  final Object tag;

  /// The corner radius this picture is drawn with when it is *not* flying.
  /// Zero for the full-screen viewer, the tile radius in a grid.
  final double radius;

  final Widget child;

  const PhotoHero({
    super.key,
    required this.tag,
    required this.child,
    this.radius = 0,
  });

  /// The radius declared by the [PhotoHero] that built a given hero, or a
  /// square corner if the other end of the flight is an ordinary `Hero`.
  static double _radiusOf(BuildContext heroContext) =>
      heroContext.findAncestorWidgetOfExactType<PhotoHero>()?.radius ?? 0;

  static Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final double from = _radiusOf(fromHeroContext);
    final double to = _radiusOf(toHeroContext);

    // `animation` always runs 0 → 1 in the direction of the flight, so this
    // reads the same for a push and for a pop; the two contexts have already
    // swapped roles.
    return AnimatedBuilder(
      animation: animation,
      // Matches Flutter's own default shuttle, which flies the *destination*
      // hero's child in both directions.
      child: (toHeroContext.widget as Hero).child,
      builder: (context, child) => ClipRRect(
        borderRadius: BorderRadius.circular(
          lerpDouble(from, to, animation.value)!,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The child is deliberately *not* clipped here: every call site already
    // sits inside the clip its own layout needs, and adding a second one would
    // mean the flight's animated corner is intersected by a fixed one.
    return Hero(tag: tag, flightShuttleBuilder: _shuttle, child: child);
  }
}
