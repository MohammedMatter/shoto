# 002 — Onboarding indicator: stop animating a layout property

- **Commit:** `8204fd8`
- **Severity:** MEDIUM
- **Category:** Performance / Cohesion & tokens / Accessibility
- **File:** `lib/features/onboarding/presentation/widgets/onboarding_page_indicator.dart`
- **Status:** DONE

## The finding

Each dot was an `AnimatedContainer` animating its own `width`:

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeOutCubic,
  margin: EdgeInsets.symmetric(horizontal: 3.w),
  width: isActive ? 20.w : 6.w,
  height: 6.w,
  ...
)
```

Three faults:

1. **`width` is a layout property.** Every frame runs layout → paint →
   composite for the whole row. The rule is transform and opacity only.
2. **Hand-typed timing.** `250ms` and `Curves.easeOutCubic` instead of
   `AppMotion.normal` (220ms) and `AppMotion.standard`, and no
   `AppMotion.duration` wrapper, so it ignored reduced motion.
3. **6dp touch targets.** Well under the 48dp minimum.

## Why not `Transform.scale(scaleX:)`

The obvious transform-only rewrite squashes the pill's end caps into
ellipses — the horizontal radius scales with the box while the vertical one
does not. At 6dp tall it reads as a pointed dot.

## The fix

Paint the whole strip in one `CustomPaint`:

- Widths and colours are computed per dot from a single fractional
  `progress`, tweened on the **index** via `TweenAnimationBuilder<double>`
  with `AppMotion.duration(context, AppMotion.normal)` and
  `AppMotion.standard`.
- `RRect` radius is always `dot / 2`, so the caps stay circular at every
  width — the thing scaling cannot do.
- No layout: the `SizedBox` is a fixed max width, only the painter repaints.
- One `GestureDetector` 44dp tall over the strip, split into `count` equal
  zones, mirrored under RTL.

Side effect worth keeping: because the tween runs on the index rather than on
each dot's width, the pill stretches out of one dot and into the next as one
continuous shape instead of two boxes trading size.

## Verification

- `flutter analyze` clean.
- Onboarding renders and dots are tappable, LTR and RTL.
- **Feel-check:** swipe between slides slowly — the pill should read as one
  shape moving, never as two half-pills.
