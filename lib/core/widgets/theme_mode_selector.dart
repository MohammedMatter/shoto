import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

class ThemeModeSelector extends StatelessWidget {
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
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
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: _options(context).map((option) {
          final (mode, icon, label) = option;
          final bool isSelected = mode == value;
          return Expanded(
            child: PressableScale(
              scale: 0.95,
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                // Same fix as GridDensitySelector: an explicit curve, because
                // AnimatedContainer defaults to linear.
                duration: AppMotion.duration(context, AppMotion.normal),
                curve: AppMotion.standard,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18.sp,
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.textSecondary,
                    ),
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
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
