import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

class SubscriptionPackageCard extends StatelessWidget {
  final String title;
  final String priceString;
  final String periodLabel;
  final String? badgeLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const SubscriptionPackageCard({
    super.key,
    required this.title,
    required this.priceString,
    required this.periodLabel,
    this.badgeLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The paywall is a decision screen: choosing a plan should feel like the
    // selection *moved* between two cards, not like both cards were redrawn.
    return PressableScale(
      scale: 0.98,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.press),
        curve: AppMotion.standard,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.press),
              curve: AppMotion.standard,
              width: 22.w,
              height: 22.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: AnimatedScale(
                scale: isSelected ? 1 : 0.4,
                duration: AppMotion.duration(context, AppMotion.press),
                curve: AppMotion.standard,
                child: AnimatedOpacity(
                  opacity: isSelected ? 1 : 0,
                  duration: AppMotion.duration(context, AppMotion.press),
                  curve: AppMotion.standard,
                  // No longer const: onMarker now flips with the theme, so
                  // it cannot be baked in at compile time.
                  child: Icon(Icons.check, color: AppColors.onMarker, size: 14),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: AppTextStyles.titleLarge),
                      if (badgeLabel != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            badgeLabel!,
                            style: AppTextStyles.caption.asSemiBold.copyWith(
                              color: AppColors.onMarker,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: priceString, style: AppTextStyles.titleLarge),
                  TextSpan(text: periodLabel, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
