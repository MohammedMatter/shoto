import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/widgets/content_trait_visuals.dart';

/// The library's filter strip: **two independent axes, one per row.**
///
/// Status ("have I dealt with this") is the top row — All / Unsorted /
/// Favorites, mutually exclusive. Content ("what is in it") is the row beneath
/// — Sensitive / Links / Contacts / Codes / Dates, at most one at a time but
/// freely combinable with any status.
///
/// **They are two rows because one row did not work.** The three status pills
/// already fill a 360dp phone edge to edge in English, so every content chip
/// landed off-screen behind a horizontal scroll with nothing on screen hinting
/// they existed — a feature nobody would ever find. Stacking them costs
/// roughly 40dp above the grid and buys the whole second axis being visible.
///
/// The rows are also drawn differently, because they answer different
/// questions and a user reading them as one set of eight equal buttons would
/// expect tapping one to release another. Status keeps the primary *gradient*
/// and full-size pills; content takes flat accent fills at a smaller scale,
/// which reads as subordinate without being hidden.
///
/// The content row is absent entirely until the trait pass has produced at
/// least one non-empty count, so a library nobody has ever searched shows the
/// same single row it always did rather than a strip of dead zeroes.
///
/// **Unsorted sits in the middle of the status row, and it is the reason this
/// widget exists at all.** It is the same number Home puts at 58px, so
/// arriving from Home's hero lands on a pill already lit and already agreeing
/// with the figure that was tapped.
class ScreenshotsFilterRow extends StatelessWidget {
  final int totalCount;
  final int unsortedCount;
  final int favoritesCount;
  final LibraryFilter filter;
  final ValueChanged<LibraryFilter> onSelect;

  /// The lens currently narrowing the grid, if any.
  final ContentTrait? lens;

  /// Called with the tapped trait, or null when the active one is tapped again.
  final ValueChanged<ContentTrait?> onSelectLens;

  /// How many screenshots each trait would show, already scoped to [filter].
  final Map<ContentTrait, int> traitCounts;

  /// False until the background trait pass has finished — see
  /// `ScreenshotsLoadedState.traitsReady`.
  final bool traitsReady;

  const ScreenshotsFilterRow({
    super.key,
    required this.totalCount,
    required this.unsortedCount,
    required this.favoritesCount,
    required this.filter,
    required this.onSelect,
    required this.lens,
    required this.onSelectLens,
    required this.traitCounts,
    required this.traitsReady,
  });

  /// Traits worth offering: the active one always, plus any that would land on
  /// something.
  ///
  /// **A chip whose count is zero is a button whose only outcome is an empty
  /// grid**, and five of them permanently greyed out would say the feature is
  /// broken rather than that this library has no card numbers in it. The
  /// active lens survives the test even at zero, so the chip you just pressed
  /// never disappears under your finger — leaving no way back to the full
  /// library except guessing.
  List<ContentTrait> get _offered => <ContentTrait>[
    for (final ContentTrait trait in ContentTrait.values)
      if (trait == lens || (traitCounts[trait] ?? 0) > 0) trait,
  ];

  @override
  Widget build(BuildContext context) {
    final List<ContentTrait> offered = traitsReady
        ? _offered
        : const <ContentTrait>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Scrollable, unlike the two-pill Row this replaces. Three pills
        // carrying a word and a figure each already reach the edge of a narrow
        // phone in English, and "غير مصنّفة" / "Non classées" are longer still
        // — a plain Row would overflow rather than let the last pill be
        // reached.
        SizedBox(
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
        ),

        // Grows in once the counts are real, rather than appearing as a
        // finished row of zeroes and then correcting itself. Height as well as
        // opacity, or the grid below would jump the moment the pass lands.
        AnimatedSize(
          duration: AppMotion.duration(context, AppMotion.normal),
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: offered.isEmpty
              ? const SizedBox(width: double.infinity)
              : SizedBox(
                  height: 40.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsetsDirectional.fromSTEB(
                      20.w,
                      0,
                      20.w,
                      10.h,
                    ),
                    children: [
                      for (final ContentTrait trait in offered) ...[
                        _TraitChip(
                          trait: trait,
                          count: traitCounts[trait] ?? 0,
                          isActive: lens == trait,
                          // Tapping the active chip clears the lens. A filter
                          // you can only leave by finding some other control
                          // is a trap, and the chip that put you here is the
                          // first place anyone looks.
                          onTap: () =>
                              onSelectLens(lens == trait ? null : trait),
                        ),
                        SizedBox(width: 8.w),
                      ],
                    ],
                  ),
                ),
        ),
      ],
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

/// A content-lens chip.
///
/// Flat accent fill when on, against the status pills' gradient, and a step
/// smaller in every dimension. That is the whole visual grammar of the strip:
/// *the gradient row picks which slice of your library, the smaller flat row
/// picks what is inside it.* The icon also keeps its accent colour while
/// inactive, which is what makes the row scannable as a group before any of it
/// is read.
class _TraitChip extends StatelessWidget {
  final ContentTrait trait;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _TraitChip({
    required this.trait,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = trait.accent;

    return ListenableBuilder(
      listenable: sl<ThemeController>(),
      builder: (context, child) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () {
            Haptics.tap();
            onTap();
          },
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.normal),
            curve: AppMotion.standard,
            padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isActive ? accent : AppColors.surface,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                // A wash of the accent while off, so the chip belongs to its
                // trait before it is switched on — but only a wash, or five
                // idle chips would compete with whichever status pill is lit.
                color: isActive
                    ? Colors.transparent
                    : accent.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  trait.icon,
                  size: 13.sp,
                  // Both fills are dark in light mode and light in dark mode,
                  // so the label rides onPrimary exactly like the status
                  // pills rather than being hard-coded white.
                  color: isActive ? AppColors.onPrimary : accent,
                ),
                SizedBox(width: 5.w),
                Text(
                  context.l10n.countChip(trait.label(context), count),
                  style: AppTextStyles.caption.asMedium.copyWith(
                    color: isActive
                        ? AppColors.onPrimary
                        : AppColors.textPrimary,
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
