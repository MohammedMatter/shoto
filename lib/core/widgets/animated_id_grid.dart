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
class AnimatedIdGrid<T> extends StatefulWidget {
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
  final double? cacheExtent;

  const AnimatedIdGrid({
    super.key,
    required this.items,
    required this.idOf,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding = EdgeInsets.zero,
    this.cacheExtent,
  });

  @override
  State<AnimatedIdGrid<T>> createState() => _AnimatedIdGridState<T>();
}

class _AnimatedIdGridState<T> extends State<AnimatedIdGrid<T>> {
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
  void didUpdateWidget(AnimatedIdGrid<T> oldWidget) {
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
    // A sliver rather than `AnimatedGrid`, purely for `cacheExtent`: the box
    // version does not expose it, and the library grid depends on it to have
    // thumbnails decoded roughly two rows ahead of the viewport instead of
    // popping in after it. `CustomScrollView` does.
    return KeyedSubtree(
      key: ValueKey<int>(_generation),
      child: CustomScrollView(
        cacheExtent: widget.cacheExtent,
        slivers: [
          SliverPadding(
            padding: widget.padding,
            sliver: SliverAnimatedGrid(
              key: _gridKey,
              gridDelegate: widget.gridDelegate,
              initialItemCount: _shown.length,
              itemBuilder: (context, index, animation) {
                // The grid can ask for an index that is mid-removal on the
                // frame the counts are settling. Rendering nothing beats
                // throwing.
                if (index >= _shown.length) return const SizedBox.shrink();
                return widget.itemBuilder(
                  context,
                  _shown[index],
                  index,
                  animation,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
