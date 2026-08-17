import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/photo_viewer_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/utils/date_sections.dart';
import 'package:shoto/core/widgets/animated_id_grid.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/screenshots/presentation/widgets/content_trait_visuals.dart';
import 'package:shoto/features/screenshots/presentation/widgets/date_section_header.dart';
import 'package:shoto/features/screenshots/presentation/widgets/lens_provenance_note.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/screenshot_detail_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_actions.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_thumbnail.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshots_filter_row.dart';
import 'package:shoto/features/screenshots/presentation/widgets/selection_toolbar.dart';
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

  /// Whether the scroll position currently wants the selection bar on screen.
  ///
  /// A notifier rather than a piece of `setState` on purpose: this flips while
  /// a finger is dragging, and rebuilding this widget would rebuild the grid
  /// of decoded thumbnails underneath it on the same frame. Only the bar
  /// listens.
  final ValueNotifier<bool> _barRevealed = ValueNotifier<bool>(true);

  /// How tall the floating bar measured itself to be, so the grid can pad its
  /// tail by exactly that much and no row ends up living underneath it.
  final ValueNotifier<double> _barHeight = ValueNotifier<double>(0);

  /// Scroll travelled since the last time the finger changed its mind.
  ///
  /// Reacting to raw direction changes would flip the bar on a two-pixel
  /// wobble; this makes the decision on *intent* instead. Reset whenever the
  /// sign changes, so 200px of scrolling down followed by a small flick up
  /// still reveals immediately rather than having to pay off a debt first.
  double _carried = 0;

  /// The selection this bar was last drawn for. Any change to it re-reveals
  /// the bar: picking another thumbnail while it is hidden is the clearest
  /// possible statement that the user is still in the middle of this job.
  int _lastSelectedCount = 0;

  /// **Asymmetric, because the two mistakes do not cost the same.**
  ///
  /// Hiding takes a deliberate push — a bar that vanishes while you are
  /// nudging the grid into place is a bar that flickers. Revealing takes
  /// barely a nudge, because this bar carries the only way out of selection
  /// mode and reaching for it must never feel like a negotiation.
  static const double _hideAfter = 26;
  static const double _revealAfter = 8;

  /// Above this the bar is simply always shown: nothing is being got out of
  /// the way near the top of a list, and a short list that hid its bar on the
  /// way down could never scroll far enough back up to earn it again.
  static const double _alwaysShownAbove = 24;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barRevealed.dispose();
    _barHeight.dispose();
    super.dispose();
  }

  /// Decides whether the floating selection bar is in the way.
  ///
  /// Returns false always: this is an observer, and swallowing the
  /// notification would keep it from the `RefreshIndicator` and the scrollbar
  /// above it.
  bool _onScroll(ScrollNotification notification) {
    // Depth 0 only. A sheet or a horizontal row nested inside the grid sends
    // its own notifications up through here, and neither of them says
    // anything about where the library is scrolled to.
    if (notification.depth != 0) return false;
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is! ScrollUpdateNotification) return false;

    final double delta = notification.scrollDelta ?? 0;
    if (delta == 0) return false;

    final ScrollMetrics metrics = notification.metrics;

    // Near the top, or bouncing past either end — an overscroll is the list
    // running out, not the user asking for room.
    if (metrics.pixels <= _alwaysShownAbove ||
        metrics.pixels > metrics.maxScrollExtent) {
      _carried = 0;
      _barRevealed.value = true;
      return false;
    }

    if (delta.isNegative != _carried.isNegative) _carried = 0;
    _carried += delta;

    if (_carried >= _hideAfter) {
      _barRevealed.value = false;
    } else if (_carried <= -_revealAfter) {
      _barRevealed.value = true;
    }
    return false;
  }

  /// Puts the bar back, from somewhere it is not safe to write to a notifier
  /// directly.
  ///
  /// Called from `build`, and the bar is listening: setting the value inline
  /// would call `setState` on a widget in the middle of the same build pass.
  void _revealAfterFrame() {
    _carried = 0;
    if (_barRevealed.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _barRevealed.value = true;
    });
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
        // **The page keeps its header while a selection is on.**
        //
        // It used to be torn out — `if (!selecting)` around the host's own
        // slivers — on the argument that a title and a search box are browsing
        // controls with no part in the task. The argument was right about the
        // controls and wrong about the header: a `SliverAppBar` is also what
        // holds the first row of thumbnails clear of the clock and the
        // battery, so removing it slid the grid up under the status bar and
        // made long-pressing a tile look like the page had collapsed. A mode
        // should add its own controls, not demolish the screen it is a mode
        // *of*.
        //
        // So the header stays exactly where it is, at exactly the same height,
        // and only its **actions** stand down for the duration — which each
        // host decides for itself, since only it knows which of its buttons
        // are about browsing. See `_LibraryActions`.
        final bool selecting = loaded.isSelectionMode;

        final List<Widget> head = <Widget>[
          ...widget.leadingSlivers,
          SliverToBoxAdapter(
            // **The one strip that does leave.** Unlike the header, these two
            // can change what is on screen underneath a selection that was
            // made against it: narrowing to Favourites, or switching the lens,
            // hides tiles that are still picked. They collapse together, as
            // one strip, so the grid moves once rather than twice.
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
              child: selecting
                  ? const SizedBox.shrink(key: ValueKey<String>('selection'))
                  // Shown once a filter could change what is on screen — see
                  // [ScreenshotsLoadedState.filtersWouldNarrow]. Three chips
                  // reading zero over an empty library are the widest row on
                  // the first screen saying "nothing" three times.
                  : showFavoritesFilter && loaded.filtersWouldNarrow
                  ? Column(
                      key: const ValueKey<String>('filters'),
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ScreenshotsFilterRow(
                          totalCount: loaded.screenshots.length,
                          unsortedCount: loaded.unsortedCount,
                          favoritesCount: loaded.favoritesCount,
                          filter: loaded.filter,
                          onSelect: (filter) => context
                              .read<ScreenshotsBloc>()
                              .add(SetLibraryFilterEvent(filter)),
                        ),
                        LensProvenanceNote(
                          lens: loaded.lens,
                          unreadCount: loaded.unreadCount,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(key: ValueKey<String>('none')),
            ),
          ),
        ];

        // Any change to what is picked — including entering and leaving the
        // mode — puts the bar back on screen. See [_revealAfterFrame].
        if (loaded.selectedIds.length != _lastSelectedCount) {
          _lastSelectedCount = loaded.selectedIds.length;
          _revealAfterFrame();
        }

        /// The scroll view, with the selection bar floating over it.
        ///
        /// **The bar overlays the grid rather than standing above it.** It was
        /// a `SliverToBoxAdapter` in the head first, which meant the one
        /// control the mode exists for scrolled away the moment you went
        /// looking for the next thing to select — and selecting is a task made
        /// of scrolling. Worse, it is also the way *out* of the mode, so the
        /// screen could be left with no visible exit at all. Then it was a
        /// permanent strip in a `Column` at the top of the page, which fixed
        /// that and bought two new problems: it was nailed to the far end of
        /// the phone from the thumb that had just long-pressed a thumbnail,
        /// and it charged the grid a hundred pixels of height for the entire
        /// duration of the task.
        ///
        /// A `Stack` gives the grid its full height back and puts the bar
        /// within reach at the bottom. It cannot be a `SliverPersistentHeader`
        /// either way: that needs an extent known before the child is laid
        /// out, and this bar has neither a fixed height nor a knowable one —
        /// the count line wraps at two under a guided prompt, the action row
        /// gains and loses buttons with the size of the selection, and all of
        /// it moves with the system text scale. So it measures itself and
        /// reports up, and the grid pads its tail to match.
        Widget framed(Widget content) => PopScope(
          // **Back leaves the mode before it leaves the screen.** Selection is
          // a state the page is in, and on Android the gesture for "undo the
          // state I just entered" is back — without this it closed the folder,
          // or dropped out of the app entirely from the library tab, with a
          // selection still live and nothing having been done with it. It also
          // means the ✕ is no longer the only exit, which is what let the bar
          // hide itself on scroll in the first place.
          canPop: !selecting,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) return;
            context.read<ScreenshotsBloc>().add(ClearSelectionEvent());
          },
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: content,
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: SelectionToolbar(
                  selecting: selecting,
                  revealed: _barRevealed,
                  count: loaded.selectedIds.length,
                  intent: loaded.intent,
                  intentUnsatisfied: loaded.intentUnsatisfied,
                  onHeightChanged: (double height) =>
                      _barHeight.value = height,
                ),
              ),
            ],
          ),
        );

        if (items.isEmpty) {
          return framed(
            CustomScrollView(
              slivers: [
                ...head,
                SliverFillRemaining(
                  hasScrollBody: false,
                  // **Blamed on the narrowing that actually emptied it**, not
                  // simply on the lens being on. Both axes can hide everything,
                  // and testing the lens first meant it answered for the status
                  // filter's empty slices too — see
                  // [ScreenshotsLoadedState.isEmptyBecauseOfLens], which is the
                  // same question the button below is about to answer.
                  child: loaded.isEmptyBecauseOfLens
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
                            onPressed: () => context
                                .read<ScreenshotsBloc>()
                                .add(SetLibraryLensEvent(null)),
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
            ),
          );
        }

        return framed(
          RefreshIndicator(
            color: context.colors.primary,
            backgroundColor: context.colors.surface,
            onRefresh: () async =>
                context.read<ScreenshotsBloc>().add(RefreshScreenshotsEvent()),
            child: ListenableBuilder(
              // The bar's measured height is merged in because it is a second
              // input to the same padding: the grid has to end far enough
              // above the bottom of the screen that the floating bar is not
              // sitting on its last row.
              listenable: Listenable.merge(<Listenable>[
                sl<GridDensityController>(),
                _barHeight,
              ]),
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
                // Only while the bar is there to be under. It stays applied
                // when the bar has scrolled itself away, which is right: the
                // bar is one flick from coming back, and a grid whose length
                // changed every time it did would jump under the finger.
                //
                // A gap on top of the measurement so the last row clears the
                // glass rather than touching it.
                bottomInset: selecting ? _barHeight.value + 12.h : 0,
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
    double bottomInset = 0,
  }) {
    final EdgeInsetsGeometry padding = EdgeInsetsDirectional.fromSTEB(
      20.w,
      4.h,
      20.w,
      // **The larger of the two, not the sum.** 120 is this file's standing
      // guess at the floating nav bar. The selection bar sits *above* that
      // nav and measures itself from the bottom of the screen, so its height
      // already contains the same clearance — adding them stacked the nav's
      // height twice and left a hand's width of empty canvas under the last
      // row.
      math.max(120.h, bottomInset),
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
              // **Two meanings, and the mode decides which** — the same split
              // the tap above already makes.
              //
              // Browsing, a long-press is this screenshot's own actions. That
              // is the gesture every photo grid uses for exactly this, and it
              // is what replaced the "⋯" disc that used to sit on the picture
              // at a third of a legal tap target; see
              // [ScreenshotThumbnail.onLongPress].
              //
              // Selecting, it toggles, like the tap. A sheet about *one*
              // screenshot opened out of a live selection of forty would be
              // answering a question nobody in that mode is asking, and the
              // alternative — a gesture that goes dead half the time — is how
              // people stop trusting a gesture at all.
              onLongPress: () {
                if (loaded.isSelectionMode) {
                  context.read<ScreenshotsBloc>().add(
                    ToggleSelectItemEvent(item.id),
                  );
                  return;
                }
                showScreenshotQuickActionsSheet(context, item);
              },
            ),
          ),
        ),
      ),
    );
  }
}
