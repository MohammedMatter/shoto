import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

class ThemeModeSelector extends StatelessWidget {
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  /// Whether the dark option is locked behind Pro.
  ///
  /// **Only [ThemeMode.dark] is ever gated, never [ThemeMode.system].** That
  /// distinction is the whole reason this is a per-option flag rather than a
  /// flag on the control: a phone in system dark mode has to keep rendering
  /// the app dark, or a free user's app would fight their device every evening
  /// and look broken rather than look locked. What is paid for is *choosing*
  /// dark regardless of the phone — the preference, not the appearance.
  ///
  /// Drawn rather than hidden. A control that silently loses an option teaches
  /// nothing; one that shows a lock says both that the option exists and how
  /// to get it, which is the only version of a gate that ever sells anything.
  final bool lockDark;

  /// Icons only, sized to its own content instead of filling the row.
  ///
  /// The same option [GridDensitySelector] already carries, and it arrived here
  /// for the same reason turned up one level: given a row of its own, this
  /// control and the density one together took about a third of the screen —
  /// so the first thing anybody saw in Settings was two large blocks, and every
  /// other setting in the app was two scrolls below them. Two segmented slabs
  /// for two preferences is a lot of page for something most people set once.
  ///
  /// The words come off because these three glyphs need them least in the whole
  /// app: a sun, a moon and an **A** are the same three marks every phone uses
  /// on its own brightness controls. The label survives as the tooltip and in
  /// the semantics, so nothing is lost to anyone who cannot see the glyph.
  final bool compact;

  const ThemeModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
    this.lockDark = false,
  });

  /// Built from a context rather than held as a const list — the labels are
  /// translated, so they cannot be known at compile time.
  static List<(ThemeMode, IconData, String)> _options(BuildContext context) => [
    (
      ThemeMode.system,
      Icons.brightness_auto_rounded,
      context.l10n.settingsThemeSystem,
    ),
    (
      ThemeMode.light,
      Icons.light_mode_rounded,
      context.l10n.settingsThemeLight,
    ),
    (ThemeMode.dark, Icons.dark_mode_rounded, context.l10n.settingsThemeDark),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 3.w : 4.w),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(compact ? 14.r : 16.r),
      ),
      child: Row(
        // Sized by its contents in compact mode, so it sits at the end of a
        // row instead of pushing the label off the other side.
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: _options(context).map((option) {
          final (mode, icon, label) = option;
          final bool isSelected = mode == value;
          final bool locked = lockDark && mode == ThemeMode.dark;

          final Widget segment = PressableScale(
            scale: 0.95,
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              // Same fix as GridDensitySelector: an explicit curve, because
              // AnimatedContainer defaults to linear.
              duration: AppMotion.duration(context, AppMotion.normal),
              curve: AppMotion.standard,
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              // Wider than it is tall in compact mode: the glyph would
              // otherwise sit in an 18px target once the text under it is
              // gone, and 44px is the floor for anything a thumb has to hit.
              padding: compact
                  ? EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h)
                  : EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected ? context.colors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(compact ? 11.r : 12.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // **The moon stays, and the lock rides its corner.**
                  //
                  // The padlock replaced the glyph for one build, on the logic
                  // that two symbols cannot share an 18px target. That solved
                  // the crowding and lost the message: a row of sun, auto and
                  // *padlock* says "something here is locked" without ever
                  // saying **what** — and somebody who has never seen the
                  // control cannot want a feature they cannot identify. The
                  // whole point of drawing a gate instead of hiding the option
                  // is to advertise the option.
                  //
                  // So the option keeps its own face, dimmed to say it is out
                  // of reach, and a small accent lock sits on the corner to say
                  // why. A badge over a glyph is exactly how both platforms
                  // mark a locked app icon, which is why it needs no legend.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // **Not dimmed.** A locked option was drawn at
                      // `textDisabled` for one build, which is the colour this
                      // app uses for controls that do nothing — and it made the
                      // moon the faintest thing in the row, so the option being
                      // *sold* was the one hardest to see. The badge already
                      // says it is not yours; the glyph's job is to make you
                      // want it, and it cannot do that whispering.
                      Icon(
                        icon,
                        size: 18.sp,
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.textSecondary,
                      ),
                      if (locked)
                        PositionedDirectional(
                          end: -5.w,
                          bottom: -4.h,
                          child: Container(
                            width: 12.w,
                            height: 12.w,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.colors.primary,
                              // A ring in the track's own colour, so the badge
                              // reads as sitting *on* the moon rather than
                              // merging into it where the two overlap.
                              border: Border.all(
                                color: isSelected
                                    ? context.colors.surface
                                    : context.colors.surfaceVariant,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 7.5.sp,
                              color: context.colors.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!compact) ...[
                    SizedBox(height: 4.h),
                    Text(
                      label,
                      style: context.text.caption
                          .weight(
                            isSelected
                                ? AppTypography.semiBold
                                : AppTypography.regular,
                          )
                          .copyWith(
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          );

          // The label still exists for anyone who cannot see the glyph, and as
          // the long-press tooltip — dropping the text from the screen is not a
          // reason to drop it from the semantics.
          return compact
              ? Tooltip(message: label, child: segment)
              : Expanded(child: segment);
        }).toList(),
      ),
    );
  }
}
