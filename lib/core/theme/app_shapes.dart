import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Corner radii, as a scale rather than a habit.
///
/// The app had **fourteen** different radius values in it — 13, 14, 15, 16,
/// 17, 18, 20, 22, 24, 25, 26, 28, 34 — each one chosen in the moment and
/// none of them related to the others. Nobody notices any single value; what
/// people notice is that nothing lines up, and a system with fourteen
/// arbitrary values is not a system.
///
/// Four steps and a pill. If a new surface does not fit one of them, the
/// surface is wrong, not the scale.
abstract class AppRadius {
  AppRadius._();

  /// Chips, small inputs, the drag handle.
  static double get xs => 8.r;

  /// Buttons, list rows, condition chips.
  static double get sm => 12.r;

  /// Cards, tiles, thumbnails — the default.
  static double get md => 18.r;

  /// Sheets and the largest hero surfaces.
  static double get lg => 26.r;

  /// Fully round.
  static const double pill = 999;
}

/// **The signature: a clipped corner.**
///
/// One shape, used for exactly one meaning: *Shoto is holding this.*
///
/// The corner it clips is the top-**trailing** one — the corner a filing
/// clerk clips off an index card so a misfiled card stands proud of the row
/// and can be found by running a thumb down the stack. That is not decoration
/// borrowed from somewhere; it is the oldest possible answer to the exact
/// problem this app exists to solve, which is that things you kept become
/// impossible to find again.
///
/// The rule that gives it meaning is what it is **not** applied to. Buttons,
/// chips, sheets and the nav bar are plain rounded rectangles, because none
/// of them is a thing you kept. Clipped = in your library. Somebody who never
/// consciously notices the shape will still learn it, because it only ever
/// appears on one kind of object.
///
/// Direction-aware: in Arabic and Urdu the clip moves to the top-left, since
/// "the corner you see first" is the whole point of clipping it.
class ClippedCorner extends StatelessWidget {
  final Widget child;

  /// How far along each edge the cut runs. Scaled with the corner radius so a
  /// thumbnail and a hero card read as the same gesture at different sizes.
  final double cut;

  final double radius;

  const ClippedCorner({
    super.key,
    required this.child,
    double? cut,
    double? radius,
  }) : cut = cut ?? 0,
       radius = radius ?? 0;

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return ClipPath(
      clipper: _ClippedCornerClipper(
        cut: cut == 0 ? 18.r : cut,
        radius: radius == 0 ? AppRadius.md : radius,
        fromLeft: rtl,
      ),
      child: child,
    );
  }
}

class _ClippedCornerClipper extends CustomClipper<Path> {
  final double cut;
  final double radius;

  /// Which top corner loses its point.
  final bool fromLeft;

  const _ClippedCornerClipper({
    required this.cut,
    required this.radius,
    required this.fromLeft,
  });

  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double c = cut.clamp(0, (w < h ? w : h) / 2);
    final double r = radius.clamp(0, (w < h ? w : h) / 2);
    final Path path = Path();

    if (fromLeft) {
      path
        ..moveTo(c, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
        ..lineTo(w, h - r)
        ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
        ..lineTo(r, h)
        ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
        ..lineTo(0, c)
        ..close();
    } else {
      path
        ..moveTo(r, 0)
        ..lineTo(w - c, 0)
        ..lineTo(w, c)
        ..lineTo(w, h - r)
        ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
        ..lineTo(r, h)
        ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
        ..lineTo(0, r)
        ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
        ..close();
    }
    return path;
  }

  @override
  bool shouldReclip(_ClippedCornerClipper old) =>
      old.cut != cut || old.radius != radius || old.fromLeft != fromLeft;
}
