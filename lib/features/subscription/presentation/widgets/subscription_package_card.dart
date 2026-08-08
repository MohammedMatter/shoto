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
              ? context.colors.primary.withValues(alpha: 0.12)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected ? context.colors.primary : context.colors.border,
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
                color: isSelected ? context.colors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.border,
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
                  child: Icon(
                    Icons.check,
                    color: context.colors.onMarker,
                    size: 14,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // **Wrap, not Row.** The price beside this column is laid
                  // out at its intrinsic width — it is the one thing on a
                  // paywall that may never be shortened — so the title and
                  // its badge get whatever is left, which at 360pt is not
                  // enough for both. As a `Row` they overflowed by 127px in
                  // English, and by 31px more once the title was allowed to
                  // ellipsise, because the badge is a fixed size and could
                  // not give anything back.
                  //
                  // Wrapping puts "Save 73%" on its own line instead, which
                  // costs a few pixels of height on narrow phones and never
                  // truncates a discount — the number the whole card exists
                  // to advertise.
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(title, style: context.text.titleLarge),
                      if (badgeLabel != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: context.colors.primaryGradient,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            badgeLabel!,
                            style: context.text.caption.asSemiBold.copyWith(
                              color: context.colors.onMarker,
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
                  TextSpan(text: priceString, style: context.text.titleLarge),
                  TextSpan(text: periodLabel, style: context.text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
