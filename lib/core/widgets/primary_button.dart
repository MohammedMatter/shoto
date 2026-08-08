import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// The app's one filled button.
///
/// It used to be an [InkWell], which is the wrong feedback twice over: the
/// ripple is invisible on a saturated gradient, and it starts on *release*,
/// so the button gave no answer at all during the part of the tap the user is
/// actually watching. Every other pressable surface in Shoto shrinks on press
/// down; the most prominent control in the app was the one that didn't.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      // Shallower than a card's 0.97. This button is full-width, so the same
      // ratio moves far more pixels and starts to read as the whole bar
      // flexing rather than as a button acknowledging a press.
      scale: 0.985,
      onTap: isLoading ? null : onPressed,
      child: SizedBox(
        width: double.infinity,
        height: 35.h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: context.colors.primaryGradient,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            // Label to spinner is a state change on a control the user is
            // waiting on, so it gets a bridge rather than a cut. Swapping
            // them instantly makes the button look like it was replaced by a
            // different button.
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
                        color: context.colors.onPrimary,
                      ),
                    )
                  : Row(
                      key: const ValueKey<bool>(false),
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // **Flexible, because a button narrower than its own
                        // label is a crash stripe, not a truncation.**
                        //
                        // `mainAxisSize.min` says this row wants to be as wide
                        // as its contents; nothing said what to do when it is
                        // not allowed to be. Merge's "Save to gallery" beside
                        // "Discard" overflowed by 38px on a 360pt phone — and
                        // that is the *English*. German sets the same button
                        // to "In Galerie sichern".
                        //
                        // Ellipsis rather than a smaller font: a button that
                        // resizes its own text makes two buttons side by side
                        // disagree about their type scale, which reads as a
                        // rendering fault even when both fit.
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: context.text.button.copyWith(
                              color: context.colors.onPrimary,
                            ),
                          ),
                        ),
                        if (icon != null) ...[
                          SizedBox(width: 8.w),
                          Icon(
                            icon,
                            color: context.colors.onPrimary,
                            size: 18.sp,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
