import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_visuals.dart';

/// The one part of Home that can get smaller.
///
/// Everything above it counts what has accumulated — screenshots, folders,
/// things not filed yet. This counts what the user said they would do and has
/// not done, and it is the only figure in SHOTO that a person can make fall.
///
/// **It is absent when there is nothing waiting**, rather than showing zeroes.
/// A permanent row of "0 to buy · 0 to read" would be five reminders that a
/// feature exists, which is advertising, not a list. Empty means finished, and
/// finished should look like nothing at all.
class WaitingOnYou extends StatelessWidget {
  /// How many are waiting under each intent. Intents with none are absent.
  final Map<ScreenshotIntent, int> waiting;

  final void Function(ScreenshotIntent intent) onOpen;

  const WaitingOnYou({super.key, required this.waiting, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (waiting.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.intentWaitingTitle,
              style: AppTextStyles.sectionLabel.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // A wrap rather than a scrolling strip: at most five short cards, and
        // anything the user might act on today should not be reachable only by
        // swiping past what they have already dealt with.
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: [
            for (final MapEntry<ScreenshotIntent, int> entry in waiting.entries)
              _WaitingCard(
                intent: entry.key,
                count: entry.value,
                onTap: () => onOpen(entry.key),
              ),
          ],
        ),
      ],
    );
  }
}

class _WaitingCard extends StatelessWidget {
  final ScreenshotIntent intent;
  final int count;
  final VoidCallback onTap;

  const _WaitingCard({
    required this.intent,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.96,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(intent.icon, size: 16.sp, color: AppColors.textSecondary),
            SizedBox(width: 9.w),
            // The number first and heavier than the verb. "3 to buy" is a
            // quantity of work; "To buy 3" is a label with a footnote.
            Text(
              '$count',
              style: AppTextStyles.bodyLarge.asMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              intent.waitingTitle(context).toLowerCase(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
