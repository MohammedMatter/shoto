# 008 — Grid deletion teleports

- **Commit:** `8204fd8`
- **Severity:** additive (missing motion, not wrong motion)
- **File:** `lib/core/widgets/animated_id_grid.dart` (new),
  `lib/features/screenshots/presentation/widgets/screenshots_body.dart`
- **Status:** DONE

## The finding

`GridView.builder` has no opinion about what changed. Hand it a shorter list
and the tiles after the gap simply occupy the previous slot on the next frame.
Deleting is the most consequential thing Shoto does and it read as the grid
glitching.

## Why this was held back, and what changed

This was deliberately excluded from the earlier sweep: `AnimatedGrid` means a
`GlobalKey`, manual index bookkeeping and a diff, on the app's most
performance-sensitive screen — which already has a documented history of
thumbnail flicker caused by rebuild churn. Shipping that untested was the
wrong trade.

It could not be tested by hand either. Deleting needs a long-press, a
selection, a delete and a confirm, and MIUI refuses `adb shell input` without
`WRITE_SECURE_SETTINGS`.

So the verification is **eleven widget tests** instead
(`test/animated_id_grid_test.dart`). They are a better instrument than tapping
would have been: the failure they target is a `RangeError` thrown while
scrolling a grid whose internal item count has drifted from the list it draws
from, and that is a state you reach by unlucky timing, not by tapping
carefully.

`AnimatedIdGrid<T>` is generic for exactly this reason — the real item type
wraps a `photo_manager` `AssetEntity`, which cannot be constructed in a widget
test without a platform channel, and none of the index bookkeeping has
anything to do with screenshots. The tests drive it with strings.

## The two hazards it is shaped around

1. **`removeItem` calls `setState`.** Diffing in `didUpdateWidget` would call
   it during a build, which the framework forbids. The diff runs in a
   post-frame callback instead — so for one frame the grid still shows the old
   list, which is correct: the item is on its way out, not gone.
2. **Two pieces of state.** The list this widget renders and the item count
   `SliverAnimatedGrid` believes in must never disagree. They are mutated only
   together, in `_sync`.

Anything the diff cannot express as "removals, then insertions, survivors in
the same relative order" is not animated at all — it rebuilds instantly via
`_reset` with a fresh `GlobalKey`. A reorder or a wholesale replacement is
rare on a date-ordered library, and an instant rebuild is a far better failure
mode than a wrong animation or a crash. Two tests cover exactly that path.

## Details worth keeping

- **`SliverAnimatedGrid` inside a `CustomScrollView`, not `AnimatedGrid`.**
  The box version does not expose `cacheExtent`, and the library grid depends
  on it (600) to decode thumbnails about two rows ahead of the viewport.
- **The exit is scale + fade from 0.85, not fade alone.** A tile that only
  fades leaves a hole the same size behind it, so the grid still looks like it
  snapped shut.
- **The builder is handed its index.** Looking it up with `indexOf` would be
  an O(n) scan per tile per build — quadratic across a library of thousands.
- `EntranceStagger` and the per-tile `RepaintBoundary` are preserved unchanged
  inside the new item builder.

## Verification

- `flutter test` — 149 tests pass, including the 11 new ones.
- `flutter analyze` clean; debug APK built and installed.
- **Feel-check outstanding:** delete a screenshot on device and watch the
  neighbours close the gap rather than jump into it. Also scroll a long
  library immediately after a delete — that is the path the tests are
  standing in for.
