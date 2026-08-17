import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/onboarding/presentation/widgets/onboarding_stages.dart';

/// The three fragments under a stage's sentence, arriving one after another.
///
/// ## Why they are staggered
///
/// Three chips that appear together are a row of tags and the eye takes them
/// as one shape. Dealt at 70ms apart they are read — left to right, in the
/// order they were written, which is the order the claims build in. It costs
/// a fifth of a second and it is the difference between three words being
/// *seen* and three words being *read*.
///
/// The stagger runs on the same controller as the rest of the stage rather
/// than a private one, so the chips can never finish arriving before the
/// headline above them has.
///
/// ## Why they wrap
///
/// German. "Automatisch importieren" is twice the width of "Auto-import", and
/// a fixed two-column grid either clips it or drives the type down to a size
/// nothing else on the screen uses. A [Wrap] takes whatever the translation
/// turns out to be and puts the overflow on its own line, which is also what
/// the reference design does at three chips.
class OnboardingChips extends StatelessWidget {
  final List<StageChip> chips;

  /// 0 before any chip has arrived, 1 once the last one has. Sub-intervals of
  /// this are handed out per chip.
  final double progress;

  const OnboardingChips({
    super.key,
    required this.chips,
    required this.progress,
  });

  /// Each chip's share of [progress]. Wide overlaps: chips that queue read as
  /// a list being built, chips that overlap read as one row arriving.
  static const double _step = 0.16;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: <Widget>[
        for (int i = 0; i < chips.length; i++)
          _Chip(chip: chips[i], t: _t(i)),
      ],
    );
  }

  double _t(int index) {
    final double start = index * _step;
    final double span = 1 - _step * (chips.length - 1);
    return AppMotion.standard.transform(
      ((progress - start) / span).clamp(0.0, 1.0),
    );
  }
}

class _Chip extends StatelessWidget {
  final StageChip chip;
  final double t;

  const _Chip({required this.chip, required this.t});

  @override
  Widget build(BuildContext context) {
    if (t <= 0) return const SizedBox.shrink();

    return Opacity(
      opacity: t,
      child: Transform.translate(
        // Sideways rather than up. The headline and the sentence above already
        // rise; a third block doing the same thing turns the whole screen into
        // one lift. Coming in from the leading edge also puts the motion in
        // reading order, and flips with the layout because the offset is
        // resolved against the text direction below.
        offset: Offset(
          (1 - t) * 14 * (Directionality.of(context) == TextDirection.rtl ? -1 : 1),
          0,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(12.w, 8.h, 14.w, 8.h),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(chip.icon, size: 16.sp, color: context.colors.primary),
              SizedBox(width: 7.w),
              Text(
                chip.label(context),
                style: context.text.bodySmall.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
