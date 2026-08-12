import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/features/safe_share/presentation/pages/safe_share_page.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_full_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/photo_viewer_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/utils/date_sections.dart';
import 'package:shoto/core/widgets/animated_id_grid.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/screenshots/presentation/widgets/content_trait_visuals.dart';
import 'package:shoto/features/screenshots/presentation/widgets/date_section_header.dart';
import 'package:shoto/features/screenshots/presentation/widgets/lens_provenance_note.dart';
import 'package:shoto/features/folders/presentation/widgets/move_to_folder_sheet.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/screenshot_detail_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_actions.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_limit_gate.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_thumbnail.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshots_filter_row.dart';
import 'package:shoto/features/stitch/presentation/pages/open_stitch_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_unavailable.dart';

/// Shared body for any screen that lists screenshots from a
/// [ScreenshotsBloc] already available above it in the widget tree — used by
/// both the Home tab (all screenshots) and a folder's detail page (scoped).
class ScreenshotsBody extends StatefulWidget {
  final String emptyTitle;
  final String emptyMessage;
  final bool showFavoritesFilter;

  /// Whether to break the grid under dated headings.
  final bool groupByDate;

  /// Namespace for this grid's shared-element tags.
  ///
  /// Hero tags have to be unique within a route, and the Library tab and a
  /// folder's detail page are two instances of this same widget that can hold
  /// the same screenshot. They are separate routes, so the default is safe —
  /// but Home is *not*, and it passes its own.
  final String heroPrefix;

  /// Slivers the hosting page wants above the grid, inside its scroll view.
  ///
  /// A page header passed here collapses with the list instead of standing
  /// on top of it forever. Empty for folder detail and the intent pages,
  /// which have no header of their own.
  final List<Widget> leadingSlivers;

  const ScreenshotsBody({
    super.key,
    required this.emptyTitle,
    required this.emptyMessage,
    this.showFavoritesFilter = true,
    this.leadingSlivers = const <Widget>[],
    this.groupByDate = false,
    this.heroPrefix = 'grid',
  });

  @override
  State<ScreenshotsBody> createState() => _ScreenshotsBodyState();
}

class _ScreenshotsBodyState extends State<ScreenshotsBody>
    with WidgetsBindingObserver {
  /// When this grid first appeared. Only items built within a short window of
  /// it are allowed an entrance — see [EntranceStagger].
  final DateTime _openedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Granting photo access happens in the system settings app, which means
  /// Shoto is backgrounded at the time and never learns the answer. Without
  /// this, a user who taps "Open Settings", allows access, and comes back
  /// is still staring at the "Photo access needed" screen with no way
  /// forward except force-quitting the app.
  ///
  /// Dispatches the *silent* recheck, never a load: loading re-requests the
  /// permission, and showing a permission dialog is itself a lifecycle
  /// event, so prompting from here would retrigger this callback forever.
  /// The bloc additionally ignores the event unless access is actually
  /// missing, so ordinary app-switching costs nothing.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!mounted) return;
    context.read<ScreenshotsBloc>().add(RecheckPermissionEvent());
  }

  @override
  Widget build(BuildContext context) {
    final String emptyTitle = widget.emptyTitle;
    final String emptyMessage = widget.emptyMessage;
    final bool showFavoritesFilter = widget.showFavoritesFilter;

    return BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
      builder: (context, state) {
        // Loading, refused and failed all look the same on every screen that
        // reads this bloc, so they are drawn in one place. This is where the
        // three of them were written out first; they moved so that the
        // screens which had them wrong could share the version that is right.
        final Widget? blocked = LibraryUnavailable.maybeOf(state);
        if (blocked != null) return blocked;

        final ScreenshotsLoadedState loaded = state as ScreenshotsLoadedState;
        final items = loaded.visibleScreenshots;

        // **Everything on this screen lives in one scroll view.**
        //
        // The filter chips, the lens note and whatever header the page handed
        // down used to be boxes in a `Column` above the grid — permanently on
        // screen however far you scrolled. On the library that is the top
        // sixth of the phone spent on chrome for the whole length of a
        // hundred-screenshot list.
        //
        // They are slivers now, which is the only arrangement that lets a
        // header collapse and a filter row pin. It is also the only one that
        // *can* work: a `NestedScrollView` was tried first, and a fixed box at
        // the top of its body is either painted over by a pinned bar or pushed
        // under the status bar by an unpinned one. See
        // `AnimatedIdGrid.leadingSlivers`.
        final List<Widget> head = <Widget>[
          ...widget.leadingSlivers,
          SliverToBoxAdapter(
            // Filter row and selection toolbar occupy the same strip, so the
            // swap between them is a change of mode rather than two unrelated
            // bars taking turns. Cutting straight from one to the other made a
            // long-press look like the screen had jumped.
            child: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.instant),
              switchInCurve: AppMotion.standard,
              switchOutCurve: AppMotion.standard,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              ),
              // Height differs between the two, so the outgoing bar must not
              // be laid out on top of the incoming one — they stack and the
              // strip jumps to whichever is taller.
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: loaded.isSelectionMode
                  ? _SelectionToolbar(
                      key: const ValueKey<String>('selection'),
                      count: loaded.selectedIds.length,
                      intent: loaded.intent,
                      intentUnsatisfied: loaded.intentUnsatisfied,
                    )
                  // Shown once a filter could change what is on screen — see
                  // [ScreenshotsLoadedState.filtersWouldNarrow]. Three chips
                  // reading zero over an empty library are the widest row on
                  // the first screen saying "nothing" three times.
                  : showFavoritesFilter && loaded.filtersWouldNarrow
                  ? ScreenshotsFilterRow(
                      key: const ValueKey<String>('filters'),
                      totalCount: loaded.screenshots.length,
                      unsortedCount: loaded.unsortedCount,
                      favoritesCount: loaded.favoritesCount,
                      filter: loaded.filter,
                      onSelect: (filter) => context.read<ScreenshotsBloc>().add(
                        SetLibraryFilterEvent(filter),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey<String>('none')),
            ),
          ),
          // Outside the switcher above: selection mode replaces the filter
          // strip, and a note explaining a lens has no business sitting under
          // a delete button.
          if (!loaded.isSelectionMode &&
              showFavoritesFilter &&
              loaded.filtersWouldNarrow)
            SliverToBoxAdapter(
              child: LensProvenanceNote(
                lens: loaded.lens,
                unreadCount: loaded.unreadCount,
              ),
            ),
        ];

        if (items.isEmpty) {
          return CustomScrollView(
            slivers: [
              ...head,
              SliverFillRemaining(
                hasScrollBody: false,
                child: loaded.lens != null
                    // A lens that matched nothing is its own case, and the
                    // honest wording depends on whether anything is still
                    // unread: "you have none of these" and "nothing that has
                    // been read has these" are different claims, and only one
                    // of them is usually true.
                    ? EmptyState(
                        icon: loaded.lens!.icon,
                        title: context.l10n.libraryNoTraitTitle(
                          loaded.lens!.label(context),
                        ),
                        message: loaded.unreadCount > 0
                            ? context.l10n.libraryNoTraitUnreadMessage(
                                loaded.unreadCount,
                              )
                            : context.l10n.libraryNoTraitMessage,
                        action: PrimaryButton(
                          label: context.l10n.libraryShowAll,
                          onPressed: () => context.read<ScreenshotsBloc>().add(
                            SetLibraryLensEvent(null),
                          ),
                        ),
                      )
                    : EmptyState(
                        // An empty filter is not an empty library, and the
                        // three cases have nothing useful in common: an empty
                        // inbox is the best possible outcome, no favorites is
                        // a feature nobody has used yet, and nothing at all is
                        // a first run. One shared sentence for all three would
                        // be wrong twice.
                        icon: switch (loaded.filter) {
                          LibraryFilter.unsorted =>
                            Icons.check_circle_outline_rounded,
                          _ => Icons.image_search_rounded,
                        },
                        title: switch (loaded.filter) {
                          LibraryFilter.unsorted =>
                            context.l10n.libraryNoUnsortedTitle,
                          LibraryFilter.favorites =>
                            context.l10n.libraryNoFavoritesTitle,
                          LibraryFilter.all => emptyTitle,
                        },
                        message: switch (loaded.filter) {
                          LibraryFilter.unsorted =>
                            context.l10n.libraryNoUnsortedMessage,
                          LibraryFilter.favorites =>
                            context.l10n.libraryNoFavoritesMessage,
                          LibraryFilter.all => emptyMessage,
                        },
                      ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          color: context.colors.primary,
          backgroundColor: context.colors.surface,
          onRefresh: () async =>
              context.read<ScreenshotsBloc>().add(RefreshScreenshotsEvent()),
          child: ListenableBuilder(
            listenable: sl<GridDensityController>(),
            // Deleting used to be the one action in this app with no motion at
            // all: the tile was simply not there on the next frame and
            // everything after it jumped a slot. AnimatedIdGrid keeps the
            // removed tile alive long enough to shrink out of the way, and the
            // rest slide into place rather than teleporting.
            //
            // **The cross-fade between filters is gone**, and it is the one
            // thing this restructure cost. The grid used to sit in an
            // `AnimatedSwitcher` keyed on filter and lens, so narrowing the
            // library dissolved one grid into the next. A switcher needs a box
            // and these are slivers; wrapping them in a `SliverToBoxAdapter`
            // to win it back would build every tile eagerly, which is the
            // opposite of what a long library needs. The tiles diff themselves
            // in and out instead — which says the same thing about what
            // changed, and leaves the ones that survived where they were.
            builder: (context, _) => _buildGrid(
              context,
              items: items,
              loaded: loaded,
              leadingSlivers: head,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: sl<GridDensityController>().columns,
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
                // **Tall tiles, because these are screenshots.**
                //
                // The grid was square, and a square is the one shape a phone
                // screenshot is not: a capture is about 9:19.5, so a 1:1 tile
                // threw away roughly two thirds of every picture in a library
                // whose entire job is helping you recognise them again. The
                // thumbnails already crop from the *top* for that reason — see
                // `AssetThumbnailImage.alignment` — and this is the other half
                // of the same argument.
                //
                // 0.72 rather than the true 0.46: at the real aspect a
                // three-column grid fits barely two rows on a phone. This
                // shows about half again as much of each capture as a square
                // did while keeping three and a half rows in view.
                childAspectRatio: 0.72,
              ),
            ),
          ),
        );
      },
    );
  }

  /// The grid itself, sectioned or flat.
  ///
  /// Both take the same tile builder, so the two modes cannot drift apart in
  /// how a screenshot looks or what tapping it does — the only difference is
  /// whether headings break the run.
  Widget _buildGrid(
    BuildContext context, {
    required List<ScreenshotEntity> items,
    required ScreenshotsLoadedState loaded,
    required SliverGridDelegate gridDelegate,
    required List<Widget> leadingSlivers,
  }) {
    final EdgeInsetsGeometry padding = EdgeInsetsDirectional.fromSTEB(
      20.w,
      4.h,
      20.w,
      120.h,
    );

    Widget tile(
      BuildContext context,
      ScreenshotEntity item,
      int index,
      Animation<double> animation,
    ) => _tile(context, item, index, animation, items: items, loaded: loaded);

    if (!widget.groupByDate) {
      return AnimatedIdGrid<ScreenshotEntity>(
        items: items,
        idOf: (item) => item.id,
        padding: padding,
        cacheExtent: 600,
        gridDelegate: gridDelegate,
        itemBuilder: tile,
        leadingSlivers: leadingSlivers,
      );
    }

    // Grouped fresh on every build rather than cached in the state: it is one
    // pass over a list already in memory, and the alternative is a cache that
    // has to be invalidated when the clock crosses midnight.
    final List<DatedGroup<ScreenshotEntity>> groups =
        groupByDate<ScreenshotEntity>(
          items,
          dateOf: (item) => item.asset.createDateTime,
          now: DateTime.now(),
        );

    // **One group is not a grouping.** A library captured this week is a
    // single "Today", and a heading over the only section on screen divides
    // nothing from nothing — it just moves the first row down by its own
    // height. Dates earn their place the moment there are two of them.
    if (groups.length < 2) {
      return AnimatedIdGrid<ScreenshotEntity>(
        items: items,
        idOf: (item) => item.id,
        padding: padding,
        cacheExtent: 600,
        gridDelegate: gridDelegate,
        itemBuilder: tile,
        leadingSlivers: leadingSlivers,
      );
    }

    return SectionedIdGrid<ScreenshotEntity>(
      idOf: (item) => item.id,
      padding: padding,
      cacheExtent: 600,
      leadingSlivers: leadingSlivers,
      headerExtent: DateSectionHeader.extent,
      gridDelegate: gridDelegate,
      itemBuilder: tile,
      sections: [
        for (final DatedGroup<ScreenshotEntity> group in groups)
          GridSection<ScreenshotEntity>(
            id: group.section.id,
            header: DateSectionHeader(section: group.section),
            items: group.items,
          ),
      ],
    );
  }

  /// One thumbnail.
  ///
  /// [index] addresses into [items] — the whole visible list, across every
  /// section — because that is what the detail page pages through.
  Widget _tile(
    BuildContext context,
    ScreenshotEntity item,
    int index,
    Animation<double> animation, {
    required List<ScreenshotEntity> items,
    required ScreenshotsLoadedState loaded,
  }) {
    // Isolates each tile's raster layer, so one thumbnail finishing decoding
    // doesn't repaint every other tile on screen with it.
    return RepaintBoundary(
      // Scale rather than a fade alone: a tile that only fades leaves a hole
      // the same size behind it, so the grid still looks like it snapped shut.
      // From 0.85 — never from zero.
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(
            CurvedAnimation(parent: animation, curve: AppMotion.standard),
          ),
          // Entrance for the first few tiles on first paint only — see
          // EntranceStagger for why it refuses to run on a recycled item.
          child: EntranceStagger(
            index: index,
            since: _openedAt,
            child: ScreenshotThumbnail(
              asset: item.asset,
              heroTag: '${widget.heroPrefix}-${item.id}',
              isFavorite: item.isFavorite,
              intent: item.intent,
              isSelected: loaded.selectedIds.contains(item.id),
              selectionMode: loaded.isSelectionMode,
              onTap: () {
                if (loaded.isSelectionMode) {
                  context.read<ScreenshotsBloc>().add(
                    ToggleSelectItemEvent(item.id),
                  );
                  return;
                }
                // Looked up by id rather than trusting the index handed in.
                // Sectioned mode composes the index from a section offset plus
                // a position inside it, and for the frame where a deletion is
                // still animating out those two disagree by one — which would
                // open the neighbouring screenshot.
                final int at = items.indexWhere(
                  (ScreenshotEntity s) => s.id == item.id,
                );
                if (at < 0) return;
                Navigator.of(context).push(
                  PhotoViewerRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<ScreenshotsBloc>(),
                      child: ScreenshotDetailPage(
                        screenshots: items,
                        initialIndex: at,
                        heroPrefix: widget.heroPrefix,
                      ),
                    ),
                  ),
                );
              },
              onLongPress: () => context.read<ScreenshotsBloc>().add(
                ToggleSelectItemEvent(item.id),
              ),
              onMoreTap: () => showScreenshotQuickActionsSheet(context, item),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionToolbar extends StatelessWidget {
  final int count;

  /// The job another screen sent the user here to do, if any.
  final LibraryIntent intent;

  /// Whether that job still needs more picked.
  final bool intentUnsatisfied;

  const _SelectionToolbar({
    super.key,
    required this.count,
    this.intent = LibraryIntent.none,
    this.intentUnsatisfied = false,
  });

  @override
  Widget build(BuildContext context) {
    // The count is the right title for selection the user started themselves
    // — they know why they are here. When Home sent them, "2 selected" answers
    // a question nobody asked; what they need is what to pick, and they need
    // it until they have picked enough.
    final String? prompt = !intentUnsatisfied
        ? null
        : switch (intent) {
            LibraryIntent.none => null,
            LibraryIntent.merge => context.l10n.libraryPickForMerge,
            LibraryIntent.protect => context.l10n.libraryPickForProtect,
          };

    // Built as a list first so the row below can size itself from how many
    // there actually are, rather than being written as one long `Row` whose
    // width nobody can work out by reading it.
    final List<Widget> actions = <Widget>[
      // Safe share works on one screenshot, so unlike merging this action
      // appears at exactly one and disappears again at two. It is the same rule
      // stated from the other side: an action that cannot run should not be on
      // screen looking like it can.
      if (count == 1 && intent != LibraryIntent.merge)
        _ToolbarAction(
          icon: Icons.shield_outlined,
          iconColor: context.colors.secondary,
          label: context.l10n.libraryActionProtect,
          onTap: () async {
            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
            final ScreenshotsState state = bloc.state;
            if (state is! ScreenshotsLoadedState) return;

            final String id = state.selectedIds.first;
            final ScreenshotEntity? shot = state.screenshots
                .where((ScreenshotEntity s) => s.id == id)
                .firstOrNull;
            if (shot == null) return;

            bloc.add(ClearSelectionEvent());
            await Navigator.of(context).push(
              FadeSlidePageRoute(
                builder: (_) => SafeSharePage(screenshot: shot),
              ),
            );
          },
        ),
      // Merging needs at least two captures to have anything to join, so the
      // action only appears once that's true rather than sitting there greyed
      // out.
      if (count >= 2 && intent != LibraryIntent.protect)
        _ToolbarAction(
          icon: Icons.view_agenda_outlined,
          iconColor: context.colors.primary,
          label: context.l10n.libraryActionMerge,
          onTap: () async {
            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
            final ScreenshotsState state = bloc.state;
            if (state is! ScreenshotsLoadedState) return;

            final List<String> ids = state.selectedIds.toList();
            final bool merged = await openStitchPage(context, ids);
            if (merged) bloc.add(ClearSelectionEvent());
          },
        ),
      // Move and Delete belong to selection the user started themselves, where
      // "I have some screenshots picked, now what" is the whole point. Somebody
      // who tapped Safe share on Home has already said what they want; offering
      // to file or delete their screenshots instead is a different job wearing
      // the same toolbar — and one of the two is destructive, which is not a
      // thing to put under the thumb of a person who came here to do something
      // else.
      if (!intent.isGuided) ...[
        // **The only way an existing library ever gets answered.**
        //
        // Intents were reachable one screenshot at a time, from a sheet behind
        // a small icon — which is fine for the ones taken from now on and
        // useless for the two thousand already there. Nobody opens two thousand
        // sheets. Here, forty at a time, "what are all of these for" is a
        // question with an answer.
        //
        // Not gated by the free-tier cap, unlike Move: an intent brings nothing
        // under management. It files no screenshot into anything and stars
        // nothing — it records a sentence about pictures the user already has.
        _ToolbarAction(
          icon: Icons.checklist_rtl_rounded,
          iconColor: context.colors.secondary,
          label: context.l10n.intentSelectionAction,
          onTap: () async {
            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
            final IntentPickerResult? result = await showIntentFullPickerSheet(
              context,
              selected: null,
            );
            if (result == null) return;
            bloc.add(SetIntentForSelectionEvent(result.intent));
            if (!context.mounted) return;
            showAppSnackBar(
              context,
              context.l10n.intentSelectionApplied(count),
            );
          },
        ),
        _ToolbarAction(
          icon: Icons.drive_file_move_rounded,
          iconColor: context.colors.secondary,
          label: context.l10n.libraryActionMove,
          onTap: () async {
            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
            final ScreenshotsState state = bloc.state;
            int newItems = count;
            if (state is ScreenshotsLoadedState) {
              newItems = state.screenshots
                  .where(
                    (s) =>
                        state.selectedIds.contains(s.id) &&
                        !s.isFavorite &&
                        s.folderId == null,
                  )
                  .length;
            }
            final bool allowed = await ensureUnderScreenshotLimit(
              context,
              additionalNewItems: newItems,
            );
            if (!allowed || !context.mounted) return;
            showMoveToFolderSheet(
              context,
              onSelected: (folderId) =>
                  bloc.add(MoveSelectedToFolderEvent(folderId)),
            );
          },
        ),
        _ToolbarAction(
          icon: Icons.delete_outline_rounded,
          iconColor: context.colors.error,
          label: context.l10n.libraryActionDelete,
          onTap: () async {
            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
            final bool confirmed = await confirmDeletion(
              context,
              title: context.l10n.libraryDeleteTitle,
              message: context.l10n.libraryDeleteMessage(count),
            );
            if (confirmed) bloc.add(DeleteSelectedEvent());
          },
        ),
      ],
    ];

    // **Two rows, because five controls and a sentence never fitted in one.**
    //
    // This was a single `Row`: a close button, the count, "Select all", and up
    // to four icon-and-label actions. On a 360dp phone the actions alone claim
    // most of the width, and the count sat in the `Expanded` that was left over
    // — so the one piece of information the bar exists to report got whatever
    // nobody else wanted. In practice that was about forty pixels: "10
    // selected" wrapped onto two lines and then ellipsized, and the bar read
    // "10 sel…" with a blue link jammed against a teal icon.
    //
    // Splitting it puts each half on a width it can actually have. The top row
    // is *what is happening* — how many, and how to stop or take everything.
    // The bar underneath is *what you can do about it*, and it is one strip of
    // equal columns, so four actions and two actions are both centred and
    // evenly spaced rather than crowding to one end.
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 2.h, 20.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: [
              PressableScale(
                scale: 0.9,
                onTap: () =>
                    context.read<ScreenshotsBloc>().add(ClearSelectionEvent()),
                child: Icon(
                  Icons.close_rounded,
                  color: context.colors.textPrimary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  prompt ?? context.l10n.librarySelectedCount(count),
                  style: prompt == null
                      ? context.text.titleLarge
                      : context.text.bodyMedium.asMedium.copyWith(
                          color: context.colors.textPrimary,
                        ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // **Select all belongs to selection the user started
              // themselves.**
              //
              // Neither guided job wants it: protecting takes one screenshot,
              // and merging takes the two or three shots of a single scroll —
              // "select all" is a wrong answer to both, offered in the most
              // prominent slot on the bar.
              if (!intent.isGuided) ...[
                SizedBox(width: 10.w),
                PressableScale(
                  scale: 0.94,
                  onTap: () =>
                      context.read<ScreenshotsBloc>().add(SelectAllEvent()),
                  child: Text(
                    context.l10n.librarySelectAll,
                    style: context.text.bodySmall.asMedium.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (actions.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                // A surface, so the actions read as one bar rather than as
                // loose glyphs floating over the grid they act on.
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: <Widget>[
                  for (final Widget action in actions) Expanded(child: action),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ToolbarAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Was an InkWell. Its ripple has to be clipped to the rounded rect to
    // look right, reads as a grey smear on the dark theme, and — the part
    // that matters — only starts once the finger lifts. These four buttons
    // are the destructive end of the app; they should answer on the way down.
    return PressableScale(
      scale: 0.9,
      onTap: onTap,
      child: Padding(
        // **No horizontal padding of its own.** Each of these sits in an
        // `Expanded` inside the action bar, so the column it is given *is* its
        // share of the width — padding here would narrow the label inside an
        // already-equal slot and make "Delete" ellipsize while "Move" had room
        // to spare.
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20.sp),
            SizedBox(height: 3.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.caption.asMedium.copyWith(color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}
