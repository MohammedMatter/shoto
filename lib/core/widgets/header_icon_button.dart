import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';

/// The circular action button that sits beside a page title.
///
/// **One implementation, because there used to be two.** Library and Folders
/// both put an action in the same corner of the same header doing the same
/// class of thing — add screenshots, add a folder — and they looked nothing
/// alike: Library's was a 42px circle in `surface` with a hairline, Folders'
/// was a filled slab of [AppColors.primaryGradient]. The accent is bone
/// (`#EBEBEB`) in dark mode, so on a device that slab was a **solid white
/// square, larger and louder than the page title beside it and louder than the
/// folders it sat above** — the add button was the brightest object on a screen
/// whose entire job is to show you your folders.
///
/// Neither was wrong on its own. Having both is what was wrong: a header
/// action is a vocabulary, and an app that speaks it two ways has to be read
/// twice.
///
/// The circle won because it is the quieter of the two and this position does
/// not need volume — it is the top corner of a page the user opened
/// deliberately, not something that has to win attention against content.
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  /// Names the button for anyone who cannot read the glyph, and for the icons
  /// that genuinely need it — three grid-density glyphs are not tellable apart
  /// at a glance the first time.
  final String? tooltip;

  /// Whether this button is currently *doing* something to the screen behind
  /// it — a dot on the rim, nothing more.
  ///
  /// It exists for the library's view button, which now holds the content
  /// filters that used to be a row of chips above the grid. A lit chip said
  /// "something is narrowing what you are looking at" just by being there;
  /// once that moved into a sheet, the button had to say it instead. A
  /// control that hides an active filter and looks identical either way is
  /// worse than the row it replaced.
  final bool isMarked;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.isMarked = false,
  });

  static double get size => 42.w;

  @override
  Widget build(BuildContext context) {
    final Widget button = PressableScale(
      scale: 0.9,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            // The rim carries it as well as the dot. A 7px dot alone is easy
            // to miss on a 42px circle at the top of a busy screen, and the
            // two together read as one state rather than as decoration.
            color: isMarked ? AppColors.primary : AppColors.border,
          ),
        ),
        // Swapped rather than replaced. Where the icon changes to reflect a
        // state the grid behind it also changed, an icon that switched
        // instantly read as a glitch — a quick spin-and-scale makes the two
        // feel like one action rather than two unrelated things happening.
        //
        // Keyed by the icon, so a button whose icon never changes simply never
        // animates.
        child: AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotion.press),
          switchInCurve: AppMotion.standard,
          switchOutCurve: AppMotion.exit,
          transitionBuilder: (child, animation) => RotationTransition(
            turns: Tween<double>(begin: 0.6, end: 1).animate(animation),
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: Icon(
            icon,
            key: ValueKey<IconData>(icon),
            color: AppColors.textPrimary,
            size: 19.sp,
          ),
        ),
      ),
    );

    final Widget marked = isMarked
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              button,
              // Outside the circle rather than inside it: within the rim it
              // sits next to the glyph and reads as part of the icon.
              PositionedDirectional(
                top: -1,
                end: -1,
                child: Container(
                  width: 9.w,
                  height: 9.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    // Punched out of the page rather than laid on top of it,
                    // so the dot keeps its shape wherever the button lands.
                    border: Border.all(color: AppColors.background, width: 1.5),
                  ),
                ),
              ),
            ],
          )
        : button;

    return tooltip == null ? marked : Tooltip(message: tooltip!, child: marked);
  }
}
