import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/widgets/grid_density_selector.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_sort.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/widgets/content_trait_visuals.dart';

/// Everything about *how the library is being looked at*, in one sheet:
/// what order, and which slice of its contents.
///
/// **This is where the second row of chips went.**
///
/// The library used to carry two independent scrolling chip axes stacked above
/// the grid — status on top, content traits beneath — and both overflowed the
/// screen edge. Together with the title, the count and four header buttons
/// that was roughly a third of a phone screen spent before the first thumbnail
/// in an app whose entire job is showing thumbnails. It was also, for a
/// first-run user, two rows of controls for a library they had not filled yet.
///
/// The status row survives above the grid, because it is the primary axis and
/// because Home's hero navigates straight into "Unsorted" — that pill has to
/// be visible and already lit when you arrive. The content traits move here.
///
/// **Sort and traits share one sheet on purpose.** They are the same question
/// asked twice — neither changes what is *in* the library, only what you are
/// currently looking at — and they were previously two separate controls, one
/// of them a row of chips and the other a header glyph. One sheet, one button,
/// one place to look.
///
/// The old two-row layout's own argument was that hiding traits behind a
/// scroll made them "a feature nobody would ever find". That is answered
/// differently rather than ignored: a labelled control that is always in the
/// same place is more findable than a chip that has scrolled off the edge, and
/// the button carries a dot whenever a trait is narrowing the grid.
/// **The sheet watches the bloc; it is not handed a snapshot.**
///
/// It used to take its numbers as plain arguments, read once at the moment it
/// opened, and a sheet built from a frozen copy of a changing thing has one
/// specific failure: tapping "read them" started a scan the sheet could never
/// hear the end of. The spinner ran forever — through the whole scan, and then
/// after it finished — because nothing was ever going to rebuild the widget.
/// The work was fine. The only broken thing was the screen reporting on it.
///
/// Reading the bloc directly also turns the wait into something legible: the
/// count beside the button falls as each screenshot is recognised, the trait
/// rows appear as their counts stop being zero, and the button takes itself
/// away when there is nothing left to read. Recognition still costs what it
/// costs — several hundred milliseconds an image, and that is ML Kit's floor,
/// not ours — but a number that moves is a wait, and a spinner that does not
/// is a hang.
Future<void> showLibraryViewSheet(
  BuildContext context, {
  required ScreenshotsBloc bloc,
  required ValueChanged<LibrarySort> onSort,
  required ValueChanged<ContentTrait?> onSelectLens,
  required VoidCallback onScan,
}) {
  return showAppSheet<void>(
    context: context,
    // `.value`, not `create`: this is the Library's own bloc, and the sheet
    // must not own or close it.
    builder: (_) => BlocProvider<ScreenshotsBloc>.value(
      value: bloc,
      child: BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
        bloc: bloc,
        builder: (BuildContext context, ScreenshotsState state) {
          if (state is! ScreenshotsLoadedState) {
            return const SheetSurface(child: SizedBox.shrink());
          }

          return SheetSurface(
            child: _LibraryViewSheet(
              sort: state.sort,
              onSort: onSort,
              lens: state.lens,
              onSelectLens: onSelectLens,
              traitCounts: <ContentTrait, int>{
                for (final ContentTrait trait in ContentTrait.values)
                  trait: state.traitCount(trait),
              },
              traitsReady: state.traitsReady,
              unreadCount: state.unreadCount,
              isScanning: state.isScanning,
              onScan: onScan,
            ),
          );
        },
      ),
    ),
  );
}

/// The sheet's body, built from plain values instead of from a bloc.
///
/// For the goldens, which exist to photograph this layout in six languages and
/// two themes. Reproducing each arrangement through a real state would mean
/// synthesising screenshots and trait maps until the derived counts happened
/// to come out right — a lot of scaffolding to photograph a column of rows,
/// and a test that would then be measuring the derivation rather than the
/// picture.
@visibleForTesting
Widget debugLibraryViewSheet({
  required LibrarySort sort,
  required ContentTrait? lens,
  required Map<ContentTrait, int> traitCounts,
  required bool traitsReady,
  required int unreadCount,
  required bool isScanning,
}) {
  return SheetSurface(
    child: _LibraryViewSheet(
      sort: sort,
      onSort: (_) {},
      lens: lens,
      onSelectLens: (_) {},
      traitCounts: traitCounts,
      traitsReady: traitsReady,
      unreadCount: unreadCount,
      isScanning: isScanning,
      onScan: () {},
    ),
  );
}

class _LibraryViewSheet extends StatelessWidget {
  final LibrarySort sort;
  final ValueChanged<LibrarySort> onSort;
  final ContentTrait? lens;
  final ValueChanged<ContentTrait?> onSelectLens;
  final Map<ContentTrait, int> traitCounts;
  final bool traitsReady;
  final int unreadCount;
  final bool isScanning;
  final VoidCallback onScan;

  const _LibraryViewSheet({
    required this.sort,
    required this.onSort,
    required this.lens,
    required this.onSelectLens,
    required this.traitCounts,
    required this.traitsReady,
    required this.unreadCount,
    required this.isScanning,
    required this.onScan,
  });

  /// Traits worth offering: the active one always, plus any that would land on
  /// something.
  ///
  /// A trait whose count is zero is a row whose only outcome is an empty grid,
  /// and five permanently dead rows say the feature is broken rather than that
  /// this library holds no card numbers. The active lens survives the test
  /// even at zero, so the row you just chose never vanishes out from under
  /// you, leaving no way back.
  List<ContentTrait> get _offered => <ContentTrait>[
    for (final ContentTrait trait in ContentTrait.values)
      if (trait == lens || (traitCounts[trait] ?? 0) > 0) trait,
  ];

  @override
  Widget build(BuildContext context) {
    final List<ContentTrait> offered = traitsReady
        ? _offered
        : const <ContentTrait>[];
    final bool showScan = traitsReady && unreadCount > 0;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // **Density lives here now, not in the header.**
              //
              // It was a permanent button on the busiest screen in the app,
              // for a preference somebody sets once and then never touches —
              // and it was the fourth control in a row of four, in front of a
              // grid whose entire job is to show pictures. The header's own
              // note already said density and sort both answer "how do I want
              // to look at this"; they are now in the same place, which is
              // what that sentence was describing all along.
              //
              // Not moved to Settings, where it also exists: a display choice
              // you make *while looking at the thing* should not require
              // leaving it.
              ListenableBuilder(
                listenable: sl<GridDensityController>(),
                builder: (context, _) => Row(
                  children: <Widget>[
                    // The same heading style the two sections below use, so
                    // the sheet reads as three things of equal rank rather
                    // than as one setting sitting on top of two lists.
                    Expanded(
                      child: Text(
                        context.l10n.settingsGridDensity,
                        style: context.text.headlineMedium,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    GridDensitySelector(
                      compact: true,
                      value: sl<GridDensityController>().columns,
                      onChanged: (int columns) =>
                          sl<GridDensityController>().setColumns(columns),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                context.l10n.librarySortLabel,
                style: context.text.headlineMedium,
              ),
              SizedBox(height: 8.h),
              for (final LibrarySort value in LibrarySort.values)
                _SortRow(
                  sort: value,
                  isCurrent: value == sort,
                  onTap: () {
                    // Popped first, so the sheet is already on its way out
                    // while the grid re-orders behind it rather than the user
                    // watching a dismissed sheet sit through the work.
                    Navigator.of(context).pop();
                    if (value != sort) onSort(value);
                  },
                ),

              // The whole section is absent until the trait pass has produced
              // a real count, rather than appearing as a list of zeroes and
              // then correcting itself.
              if (offered.isNotEmpty || showScan) ...[
                SizedBox(height: 18.h),
                Text(
                  context.l10n.libraryShowOnly,
                  style: context.text.headlineMedium,
                ),
                SizedBox(height: 8.h),
                // "Everything" is a row rather than an implied state, because
                // leaving a filter has to be as reachable as entering one.
                _TraitRow(
                  icon: Icons.grid_view_rounded,
                  accent: context.colors.textSecondary,
                  label: context.l10n.libraryShowEverything,
                  count: null,
                  isCurrent: lens == null,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (lens != null) onSelectLens(null);
                  },
                ),
                for (final ContentTrait trait in offered)
                  _TraitRow(
                    icon: trait.icon,
                    accent: trait.accent(context),
                    label: trait.label(context),
                    count: traitCounts[trait] ?? 0,
                    isCurrent: lens == trait,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectLens(lens == trait ? null : trait);
                    },
                  ),
                // **The one row that does not close the sheet.**
                //
                // Every other row here answers immediately — a sort or a lens
                // is applied to a grid the sheet is covering, so leaving is
                // the point. Reading takes fifteen seconds, and closing on
                // the tap threw away the only place the progress is visible:
                // the count beside this row falls as each screenshot is
                // recognised, and the rows above appear as their counts stop
                // being zero.
                //
                // So the sheet stays, and the user closes it when they have
                // seen enough. The scan is in the bloc, not the sheet, so
                // leaving early never cancels it.
                if (showScan)
                  _ScanRow(
                    count: unreadCount,
                    isScanning: isScanning,
                    onTap: onScan,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  final LibrarySort sort;
  final bool isCurrent;
  final VoidCallback onTap;

  const _SortRow({
    required this.sort,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String label = switch (sort) {
      LibrarySort.newest => context.l10n.librarySortNewest,
      LibrarySort.oldest => context.l10n.librarySortOldest,
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        // The arrows survive, but only beside the words that explain them.
        sort.isNewestFirst ? Icons.south_rounded : Icons.north_rounded,
        color: isCurrent
            ? context.colors.primary
            : context.colors.textSecondary,
      ),
      title: Text(
        label,
        style: context.text.bodyLarge.weight(
          isCurrent ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isCurrent
          ? Icon(Icons.check_rounded, color: context.colors.primary)
          : null,
      onTap: onTap,
    );
  }
}

/// One content trait, as a row rather than a chip.
///
/// The count sits beside the label instead of inside a pill because a row has
/// the width a chip did not: "Phone or email · 12" was being cut off by the
/// screen edge in the strip this replaces.
class _TraitRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final int? count;
  final bool isCurrent;
  final VoidCallback onTap;

  const _TraitRow({
    required this.icon,
    required this.accent,
    required this.label,
    required this.count,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: accent),
      title: Text(
        count == null ? label : context.l10n.countChip(label, count!),
        style: context.text.bodyLarge.weight(
          isCurrent ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isCurrent
          ? Icon(Icons.check_rounded, color: context.colors.primary)
          : null,
      onTap: onTap,
    );
  }
}

/// What is missing from every count above, and the one tap that fixes it.
class _ScanRow extends StatelessWidget {
  final int count;
  final bool isScanning;
  final VoidCallback onTap;

  const _ScanRow({
    required this.count,
    required this.isScanning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: isScanning
          ? SizedBox(
              width: 22.sp,
              height: 22.sp,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.colors.primary,
                ),
              ),
            )
          : Icon(Icons.auto_awesome_rounded, color: context.colors.primary),
      title: Text(
        isScanning
            ? context.l10n.libraryScanning
            : context.l10n.libraryScanPrompt(count),
        style: context.text.bodyLarge,
      ),
      onTap: isScanning ? null : onTap,
    );
  }
}
