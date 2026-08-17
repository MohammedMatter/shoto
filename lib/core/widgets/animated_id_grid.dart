import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_motion.dart';

/// A grid that animates items **out** when they are removed.
///
/// `GridView.builder` has no opinion about what changed: hand it a shorter
/// list and the tiles after the gap simply appear one slot earlier on the next
/// frame. Deleting a screenshot is the most consequential thing this app does
/// and it read as the grid glitching.
///
/// ---
///
/// **Why this is generic, and why it takes an id function.**
///
/// Not for reuse — there is one caller. It is generic so that it can be
/// *tested* with plain strings. The real item type wraps a `photo_manager`
/// `AssetEntity`, which cannot be constructed in a widget test without a
/// platform channel behind it, and the whole reason this widget needs tests is
/// the index bookkeeping below — which has nothing to do with screenshots.
///
/// ---
///
/// **The two hazards this is shaped around.**
///
/// 1. `AnimatedGridState.removeItem` calls `setState`. Diffing in
///    `didUpdateWidget` would call it *during a build*, which the framework
///    forbids. So the diff runs in a post-frame callback: for one frame the
///    grid still shows the old list, which is exactly right — the item is on
///    its way out, not gone.
/// 2. The list this widget renders and the item count `AnimatedGrid` believes
///    in are two separate pieces of state, and if they ever disagree the grid
///    throws a `RangeError` while scrolling. They are therefore only ever
///    mutated together, in [_sync], never anywhere else.
///
/// Anything the diff cannot express as "some removals, then some insertions,
/// with the survivors still in the same relative order" is not animated at
/// all — it rebuilds instantly via [_reset]. A reordered or wholesale-replaced
/// list is rare here (the library is date-ordered), and a silent instant
/// rebuild is a far better failure mode than a wrong animation or a crash.
class AnimatedIdSliverGrid<T> extends StatefulWidget {
  final List<T> items;

  /// Stable identity. Two items with the same id are the same item, however
  /// much the rest of their data has changed.
  final Object Function(T item) idOf;

  /// Builds an item.
  ///
  /// [animation] runs 0 → 1 on insert and 1 → 0 on removal; for items that are
  /// simply present it is always 1. [index] is the position the item occupies
  /// — or occupied, for one that is on its way out. It is passed rather than
  /// looked up because the alternative is an `indexOf` per tile per build,
  /// which is quadratic in the size of a library that can hold thousands.
  final Widget Function(
    BuildContext context,
    T item,
    int index,
    Animation<double> animation,
  )
  itemBuilder;

  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry padding;

  const AnimatedIdSliverGrid({
    super.key,
    required this.items,
    required this.idOf,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<AnimatedIdSliverGrid<T>> createState() =>
      _AnimatedIdSliverGridState<T>();
}

class _AnimatedIdSliverGridState<T> extends State<AnimatedIdSliverGrid<T>> {
  /// What is actually on screen. Diverges from `widget.items` for exactly one
  /// frame after a change, and while items are animating out.
  late List<T> _shown = List<T>.of(widget.items);

  /// Replaced wholesale by [_reset]. A `GlobalKey` preserves State across a
  /// rebuild, and `initialItemCount` is only read when the State is created —
  /// so resetting the count means a genuinely new key, not a new widget under
  /// the old one.
  GlobalKey<SliverAnimatedGridState> _gridKey =
      GlobalKey<SliverAnimatedGridState>();

  /// Forces the subtree holding the grid to be rebuilt from scratch on reset.
  int _generation = 0;

  bool _syncScheduled = false;

  @override
  void didUpdateWidget(AnimatedIdSliverGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameIds(oldWidget.items, widget.items)) {
      // Same items, changed data — a favourite toggled, a folder assigned.
      // No insert or remove, just newer objects in the same slots.
      _shown = List<T>.of(widget.items);
      return;
    }
    _scheduleSync();
  }

  bool _sameIds(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (widget.idOf(a[i]) != widget.idOf(b[i])) return false;
    }
    return true;
  }

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (mounted) _sync();
    });
  }

  void _reset() {
    setState(() {
      _shown = List<T>.of(widget.items);
      _gridKey = GlobalKey<SliverAnimatedGridState>();
      _generation++;
    });
  }

  void _sync() {
    final SliverAnimatedGridState? grid = _gridKey.currentState;
    if (grid == null) {
      _reset();
      return;
    }

    final List<T> target = widget.items;
    final Set<Object> targetIds = {
      for (final T item in target) widget.idOf(item),
    };
    final Set<Object> shownIds = {
      for (final T item in _shown) widget.idOf(item),
    };

    // Survivors must appear in the same relative order on both sides, or the
    // change is something other than removals-plus-insertions.
    final List<Object> keptFromShown = [
      for (final T item in _shown)
        if (targetIds.contains(widget.idOf(item))) widget.idOf(item),
    ];
    final List<Object> keptFromTarget = [
      for (final T item in target)
        if (shownIds.contains(widget.idOf(item))) widget.idOf(item),
    ];
    if (!listEquals(keptFromShown, keptFromTarget)) {
      _reset();
      return;
    }

    // Removals first, back to front, so each index is still valid when it is
    // used. The removed item is captured by value — the list no longer holds
    // it, but it has to keep drawing while it animates away.
    for (int i = _shown.length - 1; i >= 0; i--) {
      if (targetIds.contains(widget.idOf(_shown[i]))) continue;
      final T gone = _shown.removeAt(i);
      grid.removeItem(
        i,
        (context, animation) => widget.itemBuilder(context, gone, i, animation),
        duration: AppMotion.duration(context, AppMotion.normal),
      );
    }

    // Then insertions, front to back. Order is guaranteed to match by the
    // check above, so a mismatch at index i means target[i] is new.
    for (int i = 0; i < target.length; i++) {
      if (i < _shown.length &&
          widget.idOf(_shown[i]) == widget.idOf(target[i])) {
        continue;
      }
      _shown.insert(i, target[i]);
      grid.insertItem(
        i,
        duration: AppMotion.duration(context, AppMotion.normal),
      );
    }

    // Refresh the surviving objects in place, so a favourite toggled in the
    // same update is not lost.
    for (int i = 0; i < _shown.length && i < target.length; i++) {
      _shown[i] = target[i];
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // The generation key rides on the padding rather than on the grid itself:
    // the grid already carries a GlobalKey, a widget gets exactly one key, and
    // a sliver cannot be wrapped in a KeyedSubtree to borrow another.
    return SliverPadding(
      key: ValueKey<int>(_generation),
      padding: widget.padding,
      sliver: SliverAnimatedGrid(
        key: _gridKey,
        gridDelegate: widget.gridDelegate,
        initialItemCount: _shown.length,
        itemBuilder: (context, index, animation) {
          // The grid can ask for an index that is mid-removal on the frame the
          // counts are settling. Rendering nothing beats throwing.
          if (index >= _shown.length) return const SizedBox.shrink();
          return widget.itemBuilder(context, _shown[index], index, animation);
        },
      ),
    );
  }
}

/// A scrollable grid of identified items, animated on insert and removal.
///
/// The original shape of this widget and still its common case. It is now a
/// thin wrapper so that the diff engine above can also be used several times
/// over inside one scroll view — see [SectionedIdGrid].
class AnimatedIdGrid<T> extends StatelessWidget {
  final List<T> items;
  final Object Function(T item) idOf;
  final Widget Function(
    BuildContext context,
    T item,
    int index,
    Animation<double> animation,
  )
  itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry padding;
  final double? cacheExtent;

  /// Slivers placed above the grid inside **this** scroll view.
  ///
  /// The point is that they scroll with the tiles rather than sitting in a
  /// `Column` above them. A page header stacked outside the scroll view is
  /// charged for on every frame no matter how far down the list you are, and
  /// on a screen built for browsing that is the top sixth of the phone
  /// permanently. A caller that passes a `SliverAppBar` here gets it collapsing
  /// for free; one that passes a pinned filter row gets it pinned to the top
  /// edge instead of pushed off it.
  ///
  /// This is also the only way to get either of those right. Wrapping the grid
  /// in a `NestedScrollView` was tried on the library page and cannot work: the
  /// body is laid out under the header's *minimum* extent, so a fixed box at
  /// the top of that body is either painted over by a pinned bar or ends up
  /// under the status bar once an unpinned one leaves. There is no third
  /// setting — a box and a sliver cannot share a scroll.
  final List<Widget> leadingSlivers;

  /// Slivers placed below the grid, inside the same scroll view.
  ///
  /// The mirror of [leadingSlivers] and there for the smaller of the two jobs:
  /// giving a short list a bottom edge. A list of two tiles on a tall phone is
  /// two tiles and then a screenful of nothing, which reads as content that
  /// failed to load rather than as a list that has ended — and no amount of
  /// styling on the tiles fixes it, because the problem is the absence below
  /// them. A closing line costs one row and answers it.
  final List<Widget> trailingSlivers;

  const AnimatedIdGrid({
    super.key,
    required this.items,
    required this.idOf,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding = EdgeInsets.zero,
    this.cacheExtent,
    this.leadingSlivers = const <Widget>[],
    this.trailingSlivers = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    // A sliver rather than `AnimatedGrid`, purely for `cacheExtent`: the box
    // version does not expose it, and the library grid depends on it to have
    // thumbnails decoded roughly two rows ahead of the viewport instead of
    // popping in after it. `CustomScrollView` does.
    return CustomScrollView(
      cacheExtent: cacheExtent,
      slivers: [
        ...leadingSlivers,
        AnimatedIdSliverGrid<T>(
          items: items,
          idOf: idOf,
          itemBuilder: itemBuilder,
          gridDelegate: gridDelegate,
          padding: padding,
        ),
        ...trailingSlivers,
      ],
    );
  }
}

/// A run of items under one heading.
class GridSection<T> {
  /// Stable across rebuilds — it keys the sliver, so a section arriving above
  /// this one must not make Flutter treat this as a different section.
  final Object id;
  final Widget header;
  final List<T> items;

  const GridSection({
    required this.id,
    required this.header,
    required this.items,
  });
}

/// The same animated grid, split under sticky headings.
///
/// One [AnimatedIdSliverGrid] per section rather than one grid with headers
/// spliced in, because `SliverAnimatedGrid` owns a single contiguous run of
/// tiles and cannot have a heading inserted into the middle of it. Each
/// section therefore diffs and animates on its own — which is also the right
/// behaviour: deleting the last screenshot from Tuesday should collapse
/// Tuesday, not shuffle every tile in the library up by one.
class SectionedIdGrid<T> extends StatelessWidget {
  final List<GridSection<T>> sections;
  final Object Function(T item) idOf;

  /// [index] is the item's position across **all** sections, so a caller that
  /// hands the flat list to another screen can still address into it.
  final Widget Function(
    BuildContext context,
    T item,
    int index,
    Animation<double> animation,
  )
  itemBuilder;

  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry padding;
  final double headerExtent;
  final double? cacheExtent;

  /// See [AnimatedIdGrid.leadingSlivers].
  final List<Widget> leadingSlivers;

  const SectionedIdGrid({
    super.key,
    required this.sections,
    required this.idOf,
    required this.itemBuilder,
    required this.gridDelegate,
    required this.headerExtent,
    this.padding = EdgeInsets.zero,
    this.cacheExtent,
    this.leadingSlivers = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsets resolved = padding.resolve(Directionality.of(context));
    final List<Widget> slivers = <Widget>[...leadingSlivers];
    int offset = 0;

    for (int s = 0; s < sections.length; s++) {
      final GridSection<T> section = sections[s];
      final int start = offset;
      offset += section.items.length;

      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _SectionHeaderDelegate(
            extent: headerExtent,
            // Keyed so a pinned header swapping identity mid-scroll rebuilds
            // rather than animating its text into the next heading's.
            child: KeyedSubtree(
              key: ValueKey<Object>(section.id),
              child: Padding(
                padding: EdgeInsets.only(
                  left: resolved.left,
                  right: resolved.right,
                ),
                child: section.header,
              ),
            ),
          ),
        ),
      );

      slivers.add(
        AnimatedIdSliverGrid<T>(
          key: ValueKey<Object>(section.id),
          items: section.items,
          idOf: idOf,
          gridDelegate: gridDelegate,
          padding: EdgeInsets.only(
            left: resolved.left,
            right: resolved.right,
            // Only the last section carries the tail padding that keeps the
            // final row clear of the navigation bar.
            bottom: s == sections.length - 1 ? resolved.bottom : resolved.top,
          ),
          itemBuilder: (context, item, index, animation) =>
              itemBuilder(context, item, start + index, animation),
        ),
      );
    }

    return CustomScrollView(cacheExtent: cacheExtent, slivers: slivers);
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget child;

  const _SectionHeaderDelegate({required this.extent, required this.child});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_SectionHeaderDelegate old) =>
      old.extent != extent || old.child != child;
}
