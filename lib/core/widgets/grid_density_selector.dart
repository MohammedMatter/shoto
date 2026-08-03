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

  const GridDensitySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: GridDensityController.options.map((columns) {
          // Icon and name come from the controller so this picker and the
          // Library header button can never disagree about what a density
          // looks like or is called.
          final IconData icon = GridDensityController.iconFor(columns);
          final String label = GridDensityController.labelFor(context, columns);
          final bool isSelected = columns == value;
          return Expanded(
            child: PressableScale(
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
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
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
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
