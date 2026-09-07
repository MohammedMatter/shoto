import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/core/widgets/header_icon_button.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_sort.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/search_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/import_screenshots_action.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_intake_row.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_quota_band.dart';
import 'package:shoto/features/screenshots/presentation/widgets/browsing_only.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_view_sheet.dart';
import 'package:shoto/features/screenshots/presentation/widgets/quick_tile_offer.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshots_body.dart';

/// The full grid of every screenshot.
///
/// This is what Home used to be. Moving it to its own tab is what let Home
/// become a hub instead of a duplicate of the system gallery — the grid is
/// still one tap away for anyone who wants to browse, it just no longer
/// *is* the app.
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ThemeController>(),
      builder: (context, child) => Scaffold(
        backgroundColor: context.colors.background,
        // **The header is a sliver in the grid's own scroll view.**
        //
        // It was a fixed `Column` header, and on the one screen built for
        // browsing that cost the top sixth of the phone on every frame of a
        // hundred-screenshot scroll.
        //
        // A `NestedScrollView` was tried first and cannot work here: it lays
        // its body out under the header's *minimum* extent, so the filter chips
        // — a fixed box at the top of that body — were painted over by a pinned
        // bar, and pushed under the status bar by an unpinned one. Both were
        // reproduced on the device. A box and a sliver cannot share a scroll.
        //
        // So the chips became slivers too, and everything on the screen now
        // belongs to one `CustomScrollView` owned by the grid. This page just
        // hands its header down. See `ScreenshotsBody.leadingSlivers`.
        body: ScreenshotsBody(
          emptyTitle: context.l10n.libraryEmptyTitle,
          emptyMessage: context.l10n.libraryEmptyMessage,
          // Only here. A folder holds one subject rather than one stretch of
          // time, so dated headings there would slice a small, deliberately
          // curated set into runs of one.
          groupByDate: true,
          leadingSlivers: [
            SliverAppBar(
              // Pinned, so import, view options and search stay reachable at
              // any depth — the title shrinks into a compact bar and stops
              // there. This is what the `NestedScrollView` attempt could not
              // deliver without eating the chips.
              pinned: true,
              backgroundColor: context.colors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              expandedHeight: 96.h,
              collapsedHeight: 56.h,
              toolbarHeight: 56.h,
              automaticallyImplyLeading: false,
              flexibleSpace: _SealedHeader(
                hairline: context.colors.border,
                child: FlexibleSpaceBar(
                  // Bottom-anchored and leading-aligned, so the large title
                  // lands exactly where the collapsed one starts: the two read
                  // as one label changing size rather than two swapping.
                  titlePadding: EdgeInsetsDirectional.only(
                    start: 20.w,
                    bottom: 14.h,
                  ),
                  expandedTitleScale: 1.5,
                  title: Text(
                    context.l10n.navLibrary,
                    style: context.text.titleLarge.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
              ),
              actions: [
                const _LibraryActions(),
                SizedBox(width: 20.w),
              ],
            ),
            // Directly under the title, and above everything else on the
            // page: it is the one line that describes the library as a whole
            // rather than any part of it, and it draws nothing at all for a
            // subscriber or before the count lands — so on most screens it
            // costs the layout exactly zero. See [LibraryQuotaBand].
            const SliverToBoxAdapter(child: LibraryQuotaBand()),
            // Above the filter chips rather than among them: those ask which
            // part of the library to show, and this is about something that is
            // not in the library yet.
            const SliverToBoxAdapter(child: LibraryIntakeRow()),
            // The other thing that is not in the library yet — a faster way to
            // put it there. Beneath the intake row because that one is about
            // screenshots actually waiting, and this is about the next one.
            // Drawn once in an install's lifetime and nothing at all after
            // that; see [QuickTileOffer].
            const SliverToBoxAdapter(child: QuickTileOffer()),
          ],
        ),
      ),
    );
  }
}

/// Import, select, view options and search — the controls that belong to the
/// library as a whole rather than to any screenshot in it.
///
/// The count that used to sit under the title is gone. "3 screenshots" was
/// printed directly above a chip reading "All · 3": the same number twice
/// within a hundred pixels, in the tightest part of the screen. The chip wins
/// that argument — it carries the count *and* is the control that changes it,
/// while the subtitle was a label with nothing to do.
///
/// All three stand down while a selection is on — see [BrowsingOnly], which
/// is also what the folder header wraps its own options in.
class _LibraryActions extends StatelessWidget {
  const _LibraryActions();

  @override
  Widget build(BuildContext context) {
    return BrowsingOnly(child: _actions(context));
  }

  Widget _actions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          builder: (context) => HeaderIconButton(
            icon: Icons.add_photo_alternate_outlined,
            tooltip: context.l10n.importTitle,
            onTap: () => importScreenshots(
              context,
              bloc: context.read<ScreenshotsBloc>(),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        // Everything about how the library is being *looked at*: the order,
        // the content traits, and the grid density. None of them changes what
        // is in the library.
        //
        // It opens a sheet rather than toggling in place. This was a bare ↓/↑
        // that flipped on tap, and the first person to meet it asked what it
        // filtered — which is the answer: an unlabelled arrow says neither
        // what it changes nor what is currently on.
        //
        // A dot appears whenever a trait is narrowing what is shown: the row
        // of chips it replaced said so by having one lit, and a control that
        // hides an active filter without saying so is worse than the row was.
        BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
          builder: (context, state) {
            if (state is! ScreenshotsLoadedState) {
              return const SizedBox.shrink();
            }

            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // **The affordance the long-press never had.**
                //
                // Bulk actions used to be reachable only by long-pressing a
                // thumbnail, which nothing on the screen said, and per-item
                // actions by a 17dp "⋯" disc drawn on the picture, which
                // nothing could hit. The gesture took over the second job —
                // that is what a photo grid's long-press means everywhere —
                // and this button is the first one's missing sign.
                //
                // Beside the view options rather than in them: that sheet is
                // about how the library is being *looked at*, and this starts
                // a job on it.
                //
                // Absent while there is nothing to pick — an empty grid under
                // a toolbar asking which screenshots to act on is a mode with
                // no way to satisfy it.
                if (state.visibleScreenshots.isNotEmpty) ...[
                  HeaderIconButton(
                    icon: Icons.checklist_rounded,
                    tooltip: context.l10n.librarySelect,
                    onTap: () => bloc.add(EnterSelectionModeEvent()),
                  ),
                  SizedBox(width: 8.w),
                ],
                HeaderIconButton(
                  icon: Icons.tune_rounded,
                  tooltip: context.l10n.librarySortLabel,
                  isMarked: state.lens != null,
                  // The bloc is handed over rather than its values: the sheet
                  // outlives this build, and a scan started from inside it
                  // changes the very numbers it is drawing.
                  onTap: () => showLibraryViewSheet(
                    context,
                    bloc: bloc,
                    onSort: (LibrarySort sort) =>
                        bloc.add(SetLibrarySortEvent(sort)),
                    onSelectLens: (ContentTrait? lens) =>
                        bloc.add(SetLibraryLensEvent(lens)),
                    onScan: () async {
                      // Recognition is the paid feature behind every trait, so
                      // the gate belongs on the thing that starts it rather
                      // than on the counts it eventually fills in.
                      if (!await ensurePremium(context)) return;
                      bloc.add(ScanUnreadForTraitsEvent());
                    },
                  ),
                ),
                SizedBox(width: 8.w),
              ],
            );
          },
        ),
        Builder(
          builder: (context) => HeaderIconButton(
            icon: Icons.search_rounded,
            tooltip: context.l10n.searchTitle,
            onTap: () =>
                openSearchPage(context, bloc: context.read<ScreenshotsBloc>()),
          ),
        ),
      ],
    );
  }
}

/// The hairline that says where the page now begins.
///
/// **Home already does this and the library did not**, which is the whole
/// reason it is here. `_SearchHeader` fades a half-pixel rule in underneath
/// itself the moment content starts passing behind it, because a pinned bar
/// with no edge does not read as a bar — it reads as the content being cut
/// off by nothing.
///
/// It matters more here than it does on Home. What scrolls under this bar is
/// **photographs**: bright, busy, and every one of them a different colour, so
/// the top row of tiles was being sliced along an invisible line that moved as
/// you scrolled. Home's content is cards on the canvas, where the same missing
/// edge is far easier to miss.
///
/// Read off [FlexibleSpaceBarSettings] rather than from a scroll listener,
/// following `FolderDetailPage`: the number is already being computed for the
/// title's own scale, so taking it costs nothing and cannot drift out of step
/// with the collapse it describes.
class _SealedHeader extends StatelessWidget {
  final Color hairline;
  final Widget child;

  const _SealedHeader({required this.hairline, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints _) {
        final FlexibleSpaceBarSettings? settings = context
            .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();

        // 0 fully expanded, 1 fully collapsed — and only at 1 is anything
        // actually underneath. Built outside a sliver app bar, the harmless
        // reading is "expanded", which draws no rule at all.
        final double range = settings == null
            ? 0
            : settings.maxExtent - settings.minExtent;
        final double sealed = settings == null || range <= 0
            ? 0
            : ((settings.maxExtent - settings.currentExtent) / range).clamp(
                0.0,
                1.0,
              );

        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: hairline.withValues(alpha: sealed),
                width: 0.5,
              ),
            ),
          ),
          child: child,
        );
      },
    );
  }
}
