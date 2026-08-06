import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// Segmented pill selector for the screenshots grid column count — mirrors
/// [ThemeModeSelector]'s layout so Settings stays visually consistent.
class GridDensitySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  /// Icons only, sized to its own content instead of filling the row.
  ///
  /// Settings gives this control a row to itself, where the words under the
  /// glyphs are what make "comfortable" and "compact" mean something the
  /// first time somebody meets them. The library's view sheet is the opposite
  /// case: the control sits beside a heading that already names it, and the
  /// three glyphs *are* the answer — two columns, three, four — drawn at the
  /// size they describe.
  ///
  /// So the labels come off and the pill stops stretching. A segmented
  /// control that spans the sheet for three options reads as the most
  /// important thing on it, which density is not.
  final bool compact;

  const GridDensitySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 3.w : 4.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(compact ? 14.r : 16.r),
      ),
      child: Row(
        // Sized by its contents in compact mode, so it sits at the end of a
        // row instead of pushing the heading off the other side.
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: GridDensityController.options.map((columns) {
          // Icon and name come from the controller so this picker and the
          // Library header button can never disagree about what a density
          // looks like or is called.
          final IconData icon = GridDensityController.iconFor(columns);
          final String label = GridDensityController.labelFor(context, columns);
          final bool isSelected = columns == value;

          final Widget segment = PressableScale(
              scale: 0.95,
              onTap: () => onChanged(columns),
              child: AnimatedContainer(
                // The duration was hardcoded and the curve was left at
                // AnimatedContainer's default, which is **linear** — so the
                // pill's fill crossfaded at a constant rate, the
                // one timing reserved for things that genuinely move at a
                // constant rate. A colour change should arrive quickly and
                // settle, like everything else here.
                duration: AppMotion.duration(context, AppMotion.normal),
                curve: AppMotion.standard,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                // Square-ish and generous in compact mode. The glyph shrinks
                // to a 18px target if the padding follows the text that is no
                // longer there, and a 44px touch target is the floor for
                // anything a thumb has to hit.
                padding: compact
                    ? EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h)
                    : EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(compact ? 11.r : 12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18.sp,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    if (!compact) ...[
                      SizedBox(height: 4.h),
                      Text(
                        label,
                        style: AppTextStyles.caption
                            .weight(
                              isSelected
                                  ? AppTextStyles.semiBold
                                  : AppTextStyles.regular,
                            )
                            .copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            );

          // The label still exists for anyone who cannot see the glyph, and
          // as the long-press tooltip — dropping the text from the screen is
          // not a reason to drop it from the semantics.
          return compact
              ? Tooltip(message: label, child: segment)
              : Expanded(child: segment);
        }).toList(),
      ),
    );
  }
}
