import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_brand.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';

/// **The app, as a small object.**
///
/// Three cards in a fanned stack: two loose screenshots, and one in front with
/// a bookmark on it. It is the whole product in one shape — *these are yours,
/// this one you asked for again* — and it is now the same object
/// `ShotoBrandMarkPainter` draws on the launcher, leaning the same way, in the
/// same proportion, wearing the same ribbon.
///
/// **It used to be the same object wearing a clipped corner instead**, and the
/// two files drifted the day the brand mark stopped using one. See
/// `app_brand.dart` for why the chamfer went: at launcher sizes a triangle of
/// dark behind a light card reads as a folded page, which is the icon of every
/// document app there has ever been, and the whole point of Shoto is that
/// screenshots are pictures.
///
/// **What is deliberately *not* shared is the colour.** The brand mark is
/// fixed teal on fixed paper, because it has to be identical on a store
/// listing and a home screen. This one paints its cards from
/// [AppPalette] — `surface`, `border`, `textSecondary` — so an empty state does
/// not have a foreign swatch sitting in the middle of it. The ribbon is the
/// single exception, and it is fixed: it is the one element a person
/// recognises, and a bookmark that changed colour with the theme would be a
/// different mark in each one.
///
/// It is deliberately **not a creature**. A character with a face would be the
/// one thing on screen that could not be defended from the app's own design
/// notes: the palette is achromatic because Shoto frames other people's
/// pictures, the onboarding refuses to illustrate anything, and the promise the
/// whole product rests on is that it is discreet. A mascot with eyes
/// contradicts all three, and it would read as borrowed — every app has one.
///
/// The personality is in the **posture and the motion**, which is the same
/// place a good logo keeps it. At rest the stack sits fanned, like a file left
/// open on a desk. On arrival it fans out of a closed stack — once, never on a
/// loop. A mark that breathes forever would be decoration on a screen whose
/// whole job is to be quiet, and it would animate on a screen the user is not
/// looking at.
class ShotoMark extends StatelessWidget {
  /// What this particular empty screen is about. The stack is the constant;
  /// the thing it is holding changes with the context, which is what lets one
  /// mark serve every empty state without any of them losing their meaning.
  final IconData icon;

  /// Drives the fan. `null` renders the resting pose immediately — which is
  /// what reduced motion should get, since the mark is legible without ever
  /// moving.
  final Animation<double>? open;

  /// Width of the front card. Everything else is derived from it.
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

/// The three cards, in the brand mark's own geometry.
///
/// Every number below is read off `shoto_brand_mark.dart` and divided by the
/// front card's width, so the two marks are one description at two scales. The
/// stack **leans left** rather than fanning both ways, which is the visible
/// half of that: the ground opens on the left and the ribbon is left as the
/// only thing standing on the right.
class _Fan extends StatelessWidget {
  final IconData icon;
  final double card;

  /// 0 is a closed stack, 1 is the resting fan.
  final double t;

  const _Fan({required this.icon, required this.card, required this.t});

  /// How far each card sits left of the front one at rest, as a fraction of
  /// the front card's width, and how far it is turned there.
  static const List<double> _dx = [-0.38, -0.22, 0];
  static const List<double> _dy = [0.08, 0.03, 0];
  static const List<double> _turn = [-0.262, -0.131, 0]; // -15°, -7.5°, 0
  static const List<double> _scale = [0.80, 0.84, 1.0];

  /// The whole drawing sits left of the front card, so the front card sits
  /// right of centre to put it back. Solved rather than eyeballed: the content
  /// spans from `-0.78` to `+0.5` of a card width, whose midpoint is `-0.14`.
  static const double _recentre = 0.14;

  @override
  Widget build(BuildContext context) {
    final double w = card.w;
    // 4:5, the brand mark's proportion. It was 1:1.34 here for as long as the
    // two files disagreed about everything else too.
    final double h = w * 1.25;

    return SizedBox(
      // Sized for the fanned pose, so the surrounding column does not reflow
      // as the mark opens. The content is 1.28 cards wide before rotation and
      // the back card's fifteen degrees add about a tenth more.
      width: w * 1.45,
      height: h * 1.24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 3; i++)
            _Card(
              w: w * _scale[i],
              h: h * _scale[i],
              radius: AppRadius.xs * _scale[i],
              dx: w * (_recentre + _dx[i] * t),
              dy: w * _dy[i] * t,
              angle: _turn[i] * t,
              opacity: i == 2 ? 1 : (0.45 + 0.15 * i) + 0.15 * t,
              child: i != 2
                  ? null
                  // The bookmark, and under it whatever this empty screen is
                  // about. The ribbon is short enough to sit entirely above a
                  // centred glyph — the first attempt used the launcher's full
                  // length and put the ribbon straight through the icon, and
                  // the fix of moving the glyph down and left read as two
                  // unrelated things sharing a card rather than as one card
                  // with a bookmark on it.
                  : Stack(
                      children: [
                        Align(
                          // Barely off centre — just far enough down to clear
                          // the ribbon's point. Moving it further, or out to
                          // the left, was tried and read as two unrelated
                          // things sharing a card rather than as one card with
                          // a bookmark on it.
                          alignment: const Alignment(0, 0.12),
                          child: Icon(
                            icon,
                            color: context.colors.textSecondary,
                            size: card.sp * 0.44,
                          ),
                        ),
                        const Positioned.fill(child: _Ribbon()),
                      ],
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
  final double radius;
  final double dx;
  final double dy;
  final double angle;
  final double opacity;
  final Widget? child;

  const _Card({
    required this.w,
    required this.h,
    required this.radius,
    required this.dx,
    required this.dy,
    required this.angle,
    required this.opacity,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: context.colors.surface,
              // Every card is the same shape now. The front one is no longer
              // the odd one out, which is what the chamfer used to make it.
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: context.colors.border),
            ),
            // Clipped so the ribbon follows the rounded top corner rather than
            // hanging over it — the same reason `_paintRibbon` clips to its
            // card. It is fixed *to* the card, not floating in front of it.
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The bookmark, in fractions of the card it is painted on.
///
/// The proportions come straight from `shoto_brand_mark.dart` — a ribbon that
/// starts flush with the top edge, because one that begins inside the card is
/// *printed on* it and one that runs off the edge is *attached to* it. Only
/// the length is shorter here, and only because this card is carrying a glyph
/// the launcher's is not.
class _Ribbon extends StatelessWidget {
  const _Ribbon();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _RibbonPainter());
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter();

  /// Left and right edges, as fractions of the card's width. The right margin
  /// matches the brand mark's — about a tenth of the card, which is what keeps
  /// the ribbon reading as sitting *on* the card rather than falling off it.
  /// **Narrower than the launcher's, and that is not a compromise.** There it
  /// is a third of a blank card and the only thing on it. Here the card is
  /// already carrying a glyph, and a ribbon at the brand proportion did not
  /// read as a bookmark on a screenshot — it read as a red flag with a small
  /// grey icon hiding under it.
  static const double _left = 0.640;
  static const double _right = 0.885;

  /// How far down it hangs, and how deep the V is taken out of the bottom.
  static const double _bottom = 0.34;
  static const double _notch = 0.10;

  @override
  void paint(Canvas canvas, Size size) {
    final double left = size.width * _left;
    final double right = size.width * _right;
    final double bottom = size.height * _bottom;
    final double notch = size.height * _notch;

    canvas.drawPath(
      Path()
        ..moveTo(left, 0)
        ..lineTo(right, 0)
        ..lineTo(right, bottom)
        ..lineTo((left + right) / 2, bottom - notch)
        ..lineTo(left, bottom)
        ..close(),
      Paint()..color = AppBrand.ribbon,
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter oldDelegate) => false;
}
