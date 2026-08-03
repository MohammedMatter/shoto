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
        StageProp.premium => _PremiumProp(key: const ValueKey('premium')),
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

/// The Pro stage reads from [PremiumFeature.all] rather than from a list
/// written here.
///
/// That list is already the single source of truth for what paying gets you —
/// the paywall and the settings card both render from it. An onboarding with
/// its own copy of it is an onboarding that will be wrong the first time a
/// feature is added, and being wrong in the introduction is worse than being
/// brief.
class _PremiumProp extends StatelessWidget {
  const _PremiumProp({super.key});

  @override
  Widget build(BuildContext context) {
    final List<PremiumFeature> shown = PremiumFeature.all.take(4).toList();
    final int rest = PremiumFeature.all.length - shown.length;

    return Align(
      alignment: const Alignment(0, 1),
      child: Container(
        width: 292.w,
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final PremiumFeature feature in shown) ...[
              Row(
                children: [
                  Icon(feature.icon, size: 16.sp, color: AppColors.textPrimary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      feature.title(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.asMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 9.h),
            ],
            if (rest > 0)
              Padding(
                padding: EdgeInsetsDirectional.only(start: 26.w),
                child: Text(
                  context.l10n.onbProMore(rest),
                  style: AppTextStyles.caption,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
