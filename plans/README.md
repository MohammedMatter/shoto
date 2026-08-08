# Animation plans

Findings from an `improve-animations` audit of Shoto's motion, against
`.claude/skills/improve-animations/AUDIT.md`.

Every value cited comes from `lib/core/theme/app_motion.dart` or from the
audit playbook. Nothing here invents a curve or a duration.

## Corrective — all applied

| # | Finding | Severity | Screen | Status |
| --- | --- | --- | --- | --- |
| 001 | [Splash: stop gating navigation on the animation](001-splash-navigation-gate.md) | HIGH | Splash | DONE |
| 002 | [Onboarding indicator: stop animating a layout property](002-onboarding-indicator-layout-animation.md) | MEDIUM | Onboarding | DONE |
| 003 | [EmptyState ignores reduced motion despite its own doc](003-emptystate-reduced-motion.md) | MEDIUM | app-wide | DONE |
| 004 | [Onboarding copy switcher: linear fade against an eased slide](004-007-sweep.md) | MEDIUM | Onboarding | DONE |
| 005 | [Quick save: 950ms artificial delay before auto-close](004-007-sweep.md) | MEDIUM | Quick save | DONE |
| 006 | [Rule builder chip: AnimatedContainer with no curve](004-007-sweep.md) | LOW | Rules | DONE |
| 007 | [Thumbnail fade: AnimatedOpacity with no curve](004-007-sweep.md) | LOW | Grid | DONE |
| 003b | [Reduced-motion sweep across the remaining files](004-007-sweep.md) | MEDIUM | app-wide | DONE |

Every animation in `lib/` now resolves its duration through
`AppMotion.duration(context, …)` and states its curve explicitly. There are no
remaining implicit-linear animations and no remaining hand-typed durations.

## Additive — deliberately not bundled

Both are real, both are visible, and both are the wrong shape for a sweep.
They change a *mechanism* rather than a value, in flows that cannot be
exercised from this machine.

### 008 — Grid deletion teleports — **DONE**

Shipped, with [eleven widget tests](008-grid-removal-animation.md) standing in
for the device verification that MIUI makes impossible. See the plan for why
the tests are the better instrument here rather than the fallback.

### 009 — Replace the Material SnackBar

Flutter's M3 `SnackBar` fades in on `Curves.easeInCirc` — **ease-in on an
entrance**, the one curve the standards forbid outright — and animates
`height` rather than a transform. Neither is reachable through
`SnackBarThemeData`; the only fix is an `Overlay`-based toast.

`app_snack_bar.dart` already centralises six call sites, but seven more call
`ScaffoldMessenger.showSnackBar` directly, and they sit in sign-in, the
paywall, the share-intent handler and the smart-actions sheet — including a
messenger captured across an `await`. Migrating thirteen sites blind, in flows
that need a purchase, a share intent and a sign-out to reach, is not clean
work. It needs a session where each one can actually be triggered.

## Not fixable from here

`AppMotion.reduced` branches are written but were never exercised on device:
MIUI refuses `adb shell settings put global transition_animation_scale 0`
without `WRITE_SECURE_SETTINGS`. Verifying them needs either that developer
toggle enabled or a manual pass through Settings → Accessibility.
