import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';

/// Where you are in the sequence, and a way back.
///
/// Segments rather than dots. Dots say "there are five of these"; segments
/// say that *and* how far along you are, because the filled one is wider than
/// the rest — which is the only reason to have an indicator at all. Each one
/// is tappable, so somebody who wants to re-read a stage can, without
/// swiping back through the ones after it.
class OnboardingProgress extends StatelessWidget {
  final int count;
  final int index;
  final ValueChanged<int> onTap;

  const OnboardingProgress({
    super.key,
    required this.count,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < count; i++)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 6.w),
            child: GestureDetector(
              // Keyed so a test can move the sequence without going through
              // the primary button, which fires haptics.
              key: ValueKey<String>('onboarding-step-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Padding(
                // The bar is 4px tall; the tap target is not.
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotion.normal),
                  curve: AppMotion.standard,
                  width: i == index ? 26.w : 12.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: i <= index
                        ? context.colors.primary
                        : context.colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
