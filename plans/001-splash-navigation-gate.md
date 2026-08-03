# 001 — Splash: stop gating navigation on the animation

- **Commit:** `8204fd8`
- **Severity:** HIGH
- **Category:** Purpose & frequency / Easing & duration
- **File:** `lib/features/splash/presentation/pages/splash_page.dart`
- **Status:** DONE

## The finding

`_SplashPageState` runs a **1100ms** `AnimationController` and navigates from its
status listener:

```dart
late final AnimationController _controller = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1100),
)..forward();

@override
void initState() {
  super.initState();
  _controller.addStatusListener(_onDone);
}

void _onDone(AnimationStatus status) {
  if (status != AnimationStatus.completed || !mounted) return;
  ...
  context.goNamed(...);
}
```

The route decision itself is **entirely synchronous** — `sl<AuthRepository>()
.currentUser` and `sl<AppPreferences>().hasSeenOnboarding` are plain reads, and
the file's own comment on line 59 records that this is safe because
`AppPreferences` is loaded before `runApp`. Nothing is being awaited.

So the 1.1 seconds is pure animation, and every launch of the app pays it. This
is not "the interface feels slow" — the navigation is literally blocked on
`AnimationStatus.completed`.

Two secondary faults in the same widget:

1. **The mark scales in with `Curves.easeOutBack`.** The class doc says this
   screen exists to "pick up exactly where the native launch screen leaves
   off" — and the native window (`android/app/src/main/res/drawable/
   launch_background.xml`) has already painted the mark at rest. Springing it in
   from small is the opposite of continuity: the user watches something they
   were already looking at shrink and bounce back.
2. **No reduced-motion handling.** No `AppMotion.reduced` / `AppMotion.duration`
   anywhere in the file.

## Target values

From `lib/core/theme/app_motion.dart` — do not invent new curves or durations:

| Thing | Value | Token |
| --- | --- | --- |
| Entrance curve | `Cubic(0.23, 1, 0.32, 1)` | `AppMotion.standard` |
| Controller duration | 300ms | (local const `_intro`) |
| Total hold before navigating | 520ms | (local const `_hold`) |
| Reduced-motion hold | 200ms | (local const `_reducedHold`) |
| Mark scale | `0.96 → 1` | never `scale(0)` |

## Steps

1. Replace the single 1100ms controller with a **300ms** one. It no longer
   drives navigation at all.
2. Mark: `FadeTransition` + `ScaleTransition` from **0.96**, curve
   `AppMotion.standard`, over `Interval(0, 0.6)`. Remove `Curves.easeOutBack`.
3. Wordmark and tagline: `FadeTransition` over `Interval(0.35, 1)`, same curve.
4. Navigation moves to a `Timer` started in `initState`, measured from first
   frame, **independent of the controller**. Cancel it in `dispose`.
5. Reduced motion: skip the controller entirely (`_controller.value = 1`) and
   shorten the hold to 200ms. Movement goes; the screen still appears.
6. Keep `_onDone`'s routing logic byte-for-byte — it is correct and out of
   scope.

## Scope boundaries

- Do **not** touch the routing decision, the backfill of `markOnboardingSeen`,
  or `AppRouter`.
- Do **not** change the native `launch_background.xml` / `splash_logo.xml`.
- Do **not** delete the splash screen; the continuity it provides is real.

## Verification

- `flutter analyze` clean.
- Launch on a real device and time first-frame → home. Should drop from ~1.1s
  to ~0.5s.
- **Feel-check:** record the launch (`adb shell screenrecord`) and step through
  it. The mark must not visibly shrink-and-spring; it should look like the
  native window simply gained text under it.
- Toggle "Remove animations" in Android accessibility settings and confirm the
  splash still appears and still navigates.
