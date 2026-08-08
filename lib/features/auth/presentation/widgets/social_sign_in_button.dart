import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

class SocialSignInButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const SocialSignInButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // This is the very first thing anyone touches in Shoto, and it was the
    // one control with no press response at all — an ink ripple on a plain
    // surface card, starting only once the finger came off. First impressions
    // of "does this app feel solid" are decided here.
    return PressableScale(
      scale: 0.985,
      onTap: isLoading ? null : onPressed,
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: context.colors.border),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.press),
              switchInCurve: AppMotion.standard,
              switchOutCurve: AppMotion.standard,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      key: const ValueKey<bool>(true),
                      width: 22.w,
                      height: 22.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: context.colors.textPrimary,
                      ),
                    )
                  : Row(
                      key: const ValueKey<bool>(false),
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 22.w, height: 22.w, child: icon),
                        SizedBox(width: 12.w),
                        Text(label, style: context.text.button),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
