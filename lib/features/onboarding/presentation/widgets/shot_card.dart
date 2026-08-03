import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// What, if anything, this card is demonstrating.
enum ShotMark {
  /// An ordinary screenshot in the pile.
  none,

  /// A line of its text lit up, as a search hit.
  found,

  /// A number covered, as Safe Share does before you send it.
  covered,

  /// Held by SHOTO — draws the clipped corner.
  filed,
}

/// A screenshot, drawn rather than photographed.
///
/// The old onboarding scrolled five stock photographs behind a frosted panel.
/// Three things were wrong with that and only one of them was performance.
///
/// A photograph of *somebody else's* phone is a stock image, and it reads as
/// one: it says "this is a marketing screen" before a word is read. Drawing
/// the card instead means it can be **the user's own screenshot in outline**
/// — the same anonymous shape their library is full of — and it can then do
/// things a photograph cannot: light up the line a search matched, black out
/// the digits Safe Share would cover, take the clipped corner the moment it
/// belongs to SHOTO. The onboarding demonstrates the app on the thing it is
/// talking about.
///
/// It also costs nothing: a handful of boxes, no decode, no image cache, no
/// blur — on the one screen where a first impression is being formed and the
/// engine is still warming up.
class ShotCard extends StatelessWidget {
  /// Varies the drawn contents so nine cards do not look like nine copies.
  /// Deterministic: the same seed is the same "screenshot" every time.
  final int seed;

  final ShotMark mark;

  const ShotCard({super.key, required this.seed, this.mark = ShotMark.none});

  /// The card's own size. Poses scale it; nothing else measures it.
  static Size get size => Size(78.w, 128.w);

  @override
  Widget build(BuildContext context) {
    final Widget body = Container(
      width: size.width,
      height: size.height,
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: mark == ShotMark.filed
            ? null
            : BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: _Contents(seed: seed, mark: mark),
    );

    // The clipped corner is the app's one signature shape and means exactly
    // one thing: SHOTO is holding this. So it appears at the moment the card
    // is filed, and never before.
    return mark == ShotMark.filed
        ? ClippedCorner(cut: 14.w, radius: AppRadius.sm, child: body)
        : body;
  }
}

class _Contents extends StatelessWidget {
  final int seed;
  final ShotMark mark;

  const _Contents({required this.seed, required this.mark});

  @override
  Widget build(BuildContext context) {
    // Deterministic pseudo-variation. A real Random would reshuffle every
    // rebuild and the pile would flicker as it moved.
    final int a = seed * 7 % 5;
    final int b = seed * 13 % 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Block(width: 12.w, height: 12.w, radius: 999),
            SizedBox(width: 4.w),
            _Block(width: (18 + a * 4).w, height: 4.w),
          ],
        ),
        SizedBox(height: 7.w),
        if (b == 0) ...[
          // A card that is mostly a picture rather than mostly text.
          _Block(width: double.infinity, height: 34.w, radius: 4),
          SizedBox(height: 6.w),
        ],
        for (int line = 0; line < 3 + a % 2; line++) ...[
          _Line(
            width: (34 + ((seed + line) * 11 % 26)).w,
            lit: mark == ShotMark.found && line == 1,
          ),
          SizedBox(height: 5.w),
        ],
        const Spacer(),
        if (mark == ShotMark.covered)
          // The covered number: a solid bar, never a blur. A blur can
          // sometimes be undone and always *looks* like it could be, which is
          // the wrong thing to promise on a screen about safety.
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '•••• •••• ••••',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.background,
                    fontSize: 5.sp,
                    height: 1,
                  ),
                ),
              ),
            ],
          )
        else
          _Block(width: (26 + b * 6).w, height: 4.w),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final double width;
  final bool lit;

  const _Line({required this.width, required this.lit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 4.w,
      decoration: BoxDecoration(
        // The one place colour appears on a card: a search hit. It is the
        // only thing on the card the user is being asked to notice.
        color: lit ? AppColors.secondary : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Block({required this.width, required this.height, this.radius = 2});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
