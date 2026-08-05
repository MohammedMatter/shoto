import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/onboarding/presentation/widgets/onboarding_stages.dart';
import 'package:shoto/features/onboarding/presentation/widgets/shot_card.dart';
import 'package:shoto/features/subscription/domain/entities/premium_feature.dart';

/// The nine cards, and whatever the current stage puts beside them.
///
/// One `Stack`, nine children, and an animation that moves them from where
/// they were to where the new stage says they should be. There is no page
/// view here and no cross-fade between screens: **the same nine widgets are
/// alive from the first stage to the last**, which is the entire idea. You
/// are not being shown four pictures of a product; you are watching your own
/// pile of screenshots be dealt with.
class StageCanvas extends StatelessWidget {
  final List<CardPose> from;
  final List<CardPose> to;
  final StageProp prop;

  /// 0 while the cards are still in their old arrangement, 1 once they have
  /// arrived in the new one.
  final Animation<double> progress;

  const StageCanvas({
    super.key,
    required this.from,
    required this.to,
    required this.prop,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        // Resolved once and shared: the wash is derived from exactly the
        // poses the cards are drawn at, so the light cannot drift out of step
        // with them mid-flight.
        final List<CardPose> poses = [
          for (int i = 0; i < OnboardingStage.cardCount; i++)
            CardPose.lerp(from[i], to[i], _t(i)),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            // The wash is drawn into a box taller than the stage and allowed
            // to paint outside it.
            //
            // Confined to the stage it produced a hard horizontal edge across
            // the screen at the top and bottom of the canvas: the gradient is
            // wider than the box, so it was still at roughly a fifth of its
            // strength when the box simply stopped. Bleeding it past the
            // stage puts the whole of the falloff outside the area anything
            // else occupies, which is the only way the light ends without a
            // line.
            final double bleed = constraints.maxHeight * _bleed;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -bleed,
                  bottom: -bleed,
                  left: 0,
                  right: 0,
                  // Poses are fractions of the *stage*, so a card's y has to
                  // be compressed into the taller box the wash lives in or
                  // the light would sit lower than the cards it belongs to.
                  child: _Wash(poses: poses, yScale: 1 / (1 + 2 * _bleed)),
                ),
                // Behind the cards: whatever this stage is about.
                Positioned.fill(child: _Prop(prop: prop)),
                for (int i = 0; i < OnboardingStage.cardCount; i++)
                  _PosedCard(index: i, pose: poses[i]),
              ],
            );
          },
        );
      },
    );
  }

  /// How far past the stage, top and bottom, the wash is allowed to reach —
  /// as a fraction of the stage's own height.
  static const double _bleed = 0.35;

  /// Each card's own progress through the move.
  ///
  /// Cards do not all leave at once — the one nearest the front goes first
  /// and the rest follow a frame or two behind, which is what makes a group
  /// of objects read as a group rather than as a single sliding sheet. The
  /// stagger is deliberately small and the *whole* rearrangement, tail
  /// included, still finishes inside the app's longest allowed duration.
  double _t(int index) {
    const double step = 0.05;
    final double start = index * step;
    final double span = 1 - step * (OnboardingStage.cardCount - 1);
    return ((progress.value - start) / span).clamp(0.0, 1.0);
  }
}

/// The light behind the cards.
///
/// The screen is achromatic on purpose everywhere else, and the reason is
/// written down in [AppColors]: the app frames *other people's screenshots*,
/// so the frame must not have a temperature the pictures inside it do not
/// share. On this screen there are no photographs — every card is drawn — so
/// that constraint is not the one operating here, and the sequence was paying
/// its price for nothing.
///
/// What it must still protect is the **search hit**. A line of a card turning
/// [AppColors.secondary] is the one moment colour is allowed to mean
/// something, and it only reads because nothing else on the screen competes.
///
/// Three things keep that true, and they are the constraints to check against
/// before changing anything here:
///
/// 1. **The same hue, never a second one.** A wash in any other colour would
///    make the lit line one of two colours on screen instead of the only one.
/// 2. **It never touches a card.** The rule in [ShotCard] is about a card's
///    surface; this is behind them, on the background.
/// 3. **It stays diffuse.** Measured on device: the wash peaks around 20/255
///    from the background where the lit line sits at 81 — four times apart,
///    and a soft field against a hard saturated edge, which the eye separates
///    as two different kinds of thing rather than as competition.
///
/// In practice it does the opposite of competing. Because the light closes in
/// as the cards gather, by the *found* stage it has become a pool around the
/// one card that matters — it points at the lit line rather than dividing
/// attention with it.
///
/// **It is derived from the cards rather than declared per stage.** The centre
/// is their centroid and the radius follows how far apart they are, so the
/// light spreads out over the pile and closes in as they are filed — the
/// sequence's own argument, from chaos to focus, told a second time by the
/// lighting. Nothing has to be authored for it, and a stage added or
/// re-posed later gets a correct wash without anyone remembering to update
/// one.
class _Wash extends StatelessWidget {
  final List<CardPose> poses;

  /// Converts a stage-space `y` into this box's taller coordinate space.
  final double yScale;

  const _Wash({required this.poses, required this.yScale});

  /// Below this a card has effectively left and should not pull the light
  /// toward wherever it is drifting off to.
  static const double _present = 0.02;

  @override
  Widget build(BuildContext context) {
    double weight = 0;
    double cx = 0;
    double cy = 0;

    for (final CardPose pose in poses) {
      final double w = pose.opacity.clamp(0.0, 1.0);
      if (w <= _present) continue;
      weight += w;
      cx += pose.x * w;
      cy += pose.y * w;
    }

    if (weight <= 0) return const SizedBox.shrink();
    cx /= weight;
    cy /= weight;

    // Mean distance from the centroid: one number for "how scattered is
    // this", which is the only thing the light needs to know.
    double spread = 0;
    for (final CardPose pose in poses) {
      final double w = pose.opacity.clamp(0.0, 1.0);
      if (w <= _present) continue;
      final double dx = pose.x - cx;
      final double dy = pose.y - cy;
      spread += w * math.sqrt(dx * dx + dy * dy);
    }
    spread /= weight;

    // The two ends of the range the stages actually produce: the opening pile
    // sits near 0.75, the filed stack near 0.20. Measured rather than picked,
    // and clamped so a future stage outside the range degrades into the
    // nearest sensible light instead of an extreme one.
    final double t = ((spread - 0.20) / 0.55).clamp(0.0, 1.0);

    // Scattered → wide. Gathered → tight and stronger.
    //
    // Both numbers were raised after measuring the first attempt on a device
    // rather than judging it by eye. At `radius 0.62 / alpha 0.09` the
    // strongest tinted pixel anywhere on the screen was 7/255 above the
    // background and most of the stage was under 4 — invisible, for a real
    // cost in overdraw.
    //
    // The reason was not the alpha, it was the geometry: nine cards sit over
    // the middle of the canvas, which is exactly where a radial gradient is
    // brightest, so the only parts of the wash that were ever visible were
    // the gaps and the outer edge — the places the gradient had already
    // faded to nothing. The core has to be **wider than the pile** for any
    // of it to be seen at all.
    // `radius` is a fraction of the box's shortest side, which here is its
    // width — so the ceiling is set by how much vertical room the bleed
    // bought: past about 1.05 the falloff runs off the bottom of even the
    // taller box and the hard edge comes back.
    final double radius = 0.60 + t * 0.45;

    // The two modes cannot share an alpha, because the accent is not equally
    // far from the canvas in each. Teal sits at `#63B8B0` on near-black and
    // `#2A7A72` on paper — light-mode teal is much *darker* relative to its
    // background than dark-mode teal is lighter than its own. At a shared
    // 0.40 the same wash measured about 16–37/255 away from the background
    // on ink and about 83 on paper: atmosphere in one mode and a mint pool
    // in the other.
    //
    // So the number that is held constant is the *effect*, not the alpha —
    // which is the same reason the accent itself is two hand-picked values
    // rather than one lightened.
    final double peak = AppColors.isDark ? 0.40 : 0.17;
    final double alpha = peak - t * (peak * 0.35);

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(cx, cy * yScale),
            radius: radius,
            colors: [
              AppColors.secondary.withValues(alpha: alpha),
              AppColors.secondary.withValues(alpha: alpha * 0.34),
              AppColors.secondary.withValues(alpha: 0),
            ],
            stops: const [0, 0.46, 1],
          ),
        ),
      ),
    );
  }
}

class _PosedCard extends StatelessWidget {
  final int index;
  final CardPose pose;

  const _PosedCard({required this.index, required this.pose});

  @override
  Widget build(BuildContext context) {
    if (pose.opacity <= 0.01) return const SizedBox.shrink();

    return Align(
      alignment: Alignment(pose.x, pose.y),
      child: Opacity(
        opacity: pose.opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: pose.turns * 2 * 3.1415926535,
          child: Transform.scale(
            scale: pose.scale,
            // Repaint boundary per card: nine transforms that all change
            // every frame, and without this each one dirties the whole
            // canvas including the prop behind it.
            child: RepaintBoundary(
              child: ShotCard(seed: index + 1, mark: pose.mark),
            ),
          ),
        ),
      ),
    );
  }
}

/// The stage's supporting cast — a folder, a search field, the Pro list.
///
/// Switched rather than rebuilt so it fades between stages instead of
/// snapping. Everything here is drawn with the app's own tokens, so what the
/// onboarding shows is literally what the app looks like.
class _Prop extends StatelessWidget {
  final StageProp prop;

  const _Prop({required this.prop});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.normal),
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      child: switch (prop) {
        StageProp.none => const SizedBox.shrink(key: ValueKey('none')),
        StageProp.folder => _FolderProp(key: const ValueKey('folder')),
        StageProp.search => _SearchProp(key: const ValueKey('search')),
        StageProp.safeShare => _SafeShareProp(key: const ValueKey('safeShare')),
      },
    );
  }
}

class _FolderProp extends StatelessWidget {
  const _FolderProp({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.82),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_rounded,
              size: 15.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 8.w),
            Text(
              context.l10n.onbFolderExample,
              style: AppTextStyles.bodySmall.asMedium,
            ),
            SizedBox(width: 8.w),
            Icon(Icons.check_rounded, size: 15.sp, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}

class _SearchProp extends StatelessWidget {
  const _SearchProp({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.82),
      child: Container(
        width: 200.w,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 16.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 9.w),
            Text(
              context.l10n.onbSearchExample,
              style: AppTextStyles.bodySmall.asMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            // The caret sits still. A blinking one is motion with nothing to
            // say, on a screen already carrying a moving pile of cards.
            Container(
              width: 1.5,
              height: 13.sp,
              margin: EdgeInsetsDirectional.only(start: 2.w),
              color: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// The last stage shows a card number being *substituted*, not a price list.
///
/// This used to render [PremiumFeature.all] — four paid features and "and 2
/// more" — which asked somebody to evaluate a subscription to a product they
/// had not used yet, as the final thing before the button that opens it. It
/// was also stale in a way nothing caught: its copy promised rules that file
/// screenshots for you, and filing rules were deleted in v13.
///
/// What replaced it is the one capability neither Google Photos nor Apple
/// Photos will ever ship. Both already read and index every screenshot for
/// free, so "find your screenshots" is a commodity the phone gives away —
/// but a platform owner cannot approve a feature that writes a different,
/// plausible card number into a user's photo, and that is exactly what this
/// does. Showing it beats describing it: two rows of mono digits, the second
/// one perfectly ordinary, is the whole product in one glance.
///
/// The number is fake in both rows, and the replacement passes the same Luhn
/// check the real one would — which is the actual claim being made.
class _SafeShareProp extends StatelessWidget {
  const _SafeShareProp({super.key});

  /// Neither of these belongs to anybody. `4539…` is a Visa test prefix and
  /// both lines are Luhn-valid, which is the point being demonstrated: the
  /// stand-in is not a row of Xs, it is a number that passes every check the
  /// original passed.
  static const String _before = '4539 1488 0343 6467';
  static const String _after = '4716 2093 5518 4021';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.9),
      child: Container(
        width: 268.w,
        padding: EdgeInsets.fromLTRB(16.w, 13.h, 16.w, 13.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Struck through rather than greyed out: grey reads as "disabled",
            // and this value is not disabled — it is gone.
            Text(
              _before,
              style: AppTextStyles.monoBody.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 7.h),
            Row(
              children: [
                Icon(
                  Icons.shield_moon_rounded,
                  size: 15.sp,
                  color: AppColors.secondary,
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: Text(
                    _after,
                    style: AppTextStyles.monoBody.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
