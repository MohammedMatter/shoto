import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';

/// **The app, as a small object.**
///
/// Three cards in a fanned stack: two loose screenshots, and one in front
/// that has been filed and so carries the clipped corner. It is the whole
/// product in one shape — *these are yours, this one SHOTO is holding* — and
/// every part of it is a rule the app already had.
///
/// It is deliberately **not a creature**. A character with a face would be
/// the one thing on screen that could not be defended from the app's own
/// design notes: the palette is achromatic because SHOTO frames other
/// people's pictures, the onboarding refuses to illustrate anything, and the
/// promise the whole product rests on is that it is discreet. A mascot with
/// eyes contradicts all three, and it would read as borrowed — every app has
/// one. A clipped card is borrowed from nowhere, because the shape means
/// something here and nowhere else.
///
/// The personality is in the **posture and the motion**, which is the same
/// place a good logo keeps it. At rest the stack sits slightly fanned, like
/// a file left open on a desk. On arrival it fans out of a closed stack —
/// once, never on a loop. A mark that breathes forever would be decoration on
/// a screen whose whole job is to be quiet, and it would animate on a screen
/// the user is not looking at.
class ShotoMark extends StatelessWidget {
  /// What this particular empty screen is about. The stack is the constant;
  /// the thing it is holding changes with the context, which is what lets one
  /// mark serve every empty state without any of them losing their meaning.
  final IconData icon;

  /// Drives the fan. `null` renders the resting pose immediately — which is
  /// what reduced motion should get, since the mark is legible without ever
  /// moving.
  final Animation<double>? open;

  /// Width of a single card. Everything else is derived from it.
  final double card;

  const ShotoMark({super.key, required this.icon, this.open, this.card = 44});

  @override
  Widget build(BuildContext context) {
    final Animation<double>? open = this.open;

    if (open == null) return _Fan(icon: icon, card: card, t: 1);

    return AnimatedBuilder(
      animation: open,
      builder: (context, _) =>
          _Fan(icon: icon, card: card, t: open.value.clamp(0.0, 1.0)),
    );
  }
}

class _Fan extends StatelessWidget {
  final IconData icon;
  final double card;

  /// 0 is a closed stack, 1 is the resting fan.
  final double t;

  const _Fan({required this.icon, required this.card, required this.t});

  @override
  Widget build(BuildContext context) {
    final double w = card.w;
    final double h = card.w * 1.34;

    // The box is sized for the fanned pose so the surrounding column does not
    // reflow as the mark opens.
    return SizedBox(
      width: w + 26.w,
      height: h + 10.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Card(
            w: w,
            h: h,
            dx: -13.w * t,
            dy: -3.w * t,
            angle: -0.11 * t,
            opacity: 0.45 + 0.15 * t,
          ),
          _Card(
            w: w,
            h: h,
            dx: 13.w * t,
            dy: -1.w * t,
            angle: 0.10 * t,
            opacity: 0.6 + 0.2 * t,
          ),
          // The filed one. Last in the stack, so it is the card in front, and
          // the only one wearing the corner.
          _Card(
            w: w,
            h: h,
            dx: 0,
            dy: 3.w * t,
            angle: 0,
            opacity: 1,
            filed: true,
            child: Icon(
              icon,
              color: context.colors.textSecondary,
              size: card.sp * 0.46,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final double w;
  final double h;
  final double dx;
  final double dy;
  final double angle;
  final double opacity;
  final bool filed;
  final Widget? child;

  const _Card({
    required this.w,
    required this.h,
    required this.dx,
    required this.dy,
    required this.angle,
    required this.opacity,
    this.filed = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final Widget body = Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surface,
        // A filed card is clipped instead of rounded, exactly as it is
        // everywhere else — the clip and the radius are the same gesture and
        // applying both would round off the cut.
        borderRadius: filed ? null : BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: filed
              ? ClippedCorner(cut: 12.w, radius: AppRadius.xs, child: body)
              : body,
        ),
      ),
    );
  }
}
