import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';

/// "All" / "Unsorted" / "Favorites" count pills sitting above the screenshots
/// grid — a live count readout and the filter control in one strip.
///
/// **Unsorted sits in the middle, and it is the reason this row grew.** It is
/// the same number Home puts at 58px, so arriving here from Home's hero lands
/// on a pill that is already lit and already agrees with the figure that was
/// tapped. Without it the count on Home was a claim the Library could not
/// back up.
class ScreenshotsFilterRow extends StatelessWidget {
  final int totalCount;
  final int unsortedCount;
  final int favoritesCount;
  final LibraryFilter filter;
  final ValueChanged<LibraryFilter> onSelect;

  const ScreenshotsFilterRow({
    super.key,
    required this.totalCount,
    required this.unsortedCount,
    required this.favoritesCount,
    required this.filter,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Scrollable, unlike the two-pill Row this replaces. Three pills carrying
    // a word and a figure each already reach the edge of a narrow phone in
    // English, and "غير مصنّفة" / "Non classées" are longer still — a plain
    // Row would overflow rather than let the last pill be reached.
    return SizedBox(
      height: 50.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.fromSTEB(20.w, 4.h, 20.w, 12.h),
        children: [
          _pill(
            context,
            LibraryFilter.all,
            Icons.grid_view_rounded,
            context.l10n.libraryFilterAll,
            totalCount,
          ),
          SizedBox(width: 8.w),
          _pill(
            context,
            LibraryFilter.unsorted,
            Icons.inbox_rounded,
            context.l10n.libraryFilterUnsorted,
            unsortedCount,
          ),
          SizedBox(width: 8.w),
          _pill(
            context,
            LibraryFilter.favorites,
            Icons.favorite_rounded,
            context.l10n.libraryFilterFavorites,
            favoritesCount,
          ),
        ],
      ),
    );
  }

  Widget _pill(
    BuildContext context,
    LibraryFilter value,
    IconData icon,
    String label,
    int count,
  ) {
    final bool isActive = filter == value;
    return _CountPill(
      icon: icon,
      label: label,
      count: count,
      isActive: isActive,
      // Inert while it is the one already showing, so the pill does not
      // ripple and buzz to report that nothing happened.
      onTap: isActive ? null : () => onSelect(value),
    );
  }
}

class _CountPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback? onTap;

  const _CountPill({
    required this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ThemeController>(),
      builder: (context, child) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap == null
              ? null
              : () {
                  Haptics.tap();
                  onTap!();
                },
          child: AnimatedContainer(
            // Was 200ms with no curve, which means AnimatedContainer's
            // default: linear. A fill and a border easing at a constant rate
            // is the one timing reserved for things that genuinely move at a
            // constant rate.
            duration: AppMotion.duration(context, AppMotion.normal),
            curve: AppMotion.standard,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isActive ? null : AppColors.surface,
              gradient: isActive ? AppColors.primaryGradient : null,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isActive ? Colors.transparent : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15.sp,
                  // Was hard-coded white. The active fill is the accent,
                  // which is *light* brass in dark mode — so white on white,
                  // and the selected pill's label vanished. onPrimary flips
                  // with the fill it sits on.
                  color: isActive
                      ? AppColors.onPrimary
                      : AppColors.textSecondary,
                ),
                SizedBox(width: 6.w),
                Text(
                  context.l10n.countChip(label, count),
                  style: AppTextStyles.bodySmall.asMedium.copyWith(
                    color: isActive
                        ? AppColors.onPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
