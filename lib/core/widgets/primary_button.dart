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
///
/// ---
///
/// **A null [onPressed] now looks like a null [onPressed].**
///
/// It did not. The parameter has always been nullable and the button has
/// always stopped answering taps when it was null — and it went on painting
/// itself in full accent while it did, so the only way to find out the control
/// was dead was to press it and watch nothing happen. That is the failure this
/// app's own rule names elsewhere: a control that hides its state and looks
/// identical either way is worse than no control.
///
/// Three call sites were already living with it. The folder editor refused an
/// empty name by silently returning from its save handler, and Backup's two
/// buttons pass `_busy ? null : …` — so both of them sat lit and unresponsive
/// for the whole length of an archive being written.
///
/// Off is [AppPalette.surfaceVariant] under [AppPalette.textDisabled]: the
/// same pair the disabled state of every input in the app already uses, so
/// "not yet" reads the same wherever it happens. The change is animated, and
/// that is most of the point — the button *lights up* on the keystroke that
/// makes it usable, which tells the user what the field was for.
///
/// [isLoading] deliberately does not count as off. A button mid-task refuses
/// taps too, but it is working rather than waiting on the user, and dimming it
/// would say the opposite.
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
    final bool isOff = onPressed == null && !isLoading;

    return PressableScale(
      // Shallower than a card's 0.97. This button is full-width, so the same
      // ratio moves far more pixels and starts to read as the whole bar
      // flexing rather than as a button acknowledging a press.
      scale: 0.985,
      onTap: isLoading ? null : onPressed,
      child: SizedBox(
        width: double.infinity,
        height: 35.h,
        // One driver for the fill and the label together, rather than an
        // `AnimatedContainer` around an `AnimatedDefaultTextStyle`: they are
        // one state change and they have to travel at exactly one speed, or
        // the label arrives on a slab that has not finished lighting.
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: isOff ? 1 : 0),
          duration: AppMotion.duration(context, AppMotion.press),
          curve: AppMotion.standard,
          builder: (BuildContext context, double t, Widget? _) {
            final Color foreground = Color.lerp(
              context.colors.onPrimary,
              context.colors.textDisabled,
              t,
            )!;

            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient.lerp(
                  context.colors.primaryGradient,
                  LinearGradient(
                    colors: <Color>[
                      context.colors.surfaceVariant,
                      context.colors.surfaceVariant,
                    ],
                  ),
                  t,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: _content(context, foreground),
            );
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Color foreground) {
    return Center(
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
                      style: context.text.button.copyWith(color: foreground),
                    ),
                  ),
                  if (icon != null) ...[
                    SizedBox(width: 8.w),
                    Icon(icon, color: foreground, size: 18.sp),
                  ],
                ],
              ),
      ),
    );
  }
}
