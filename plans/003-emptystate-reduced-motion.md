# 003 — EmptyState ignores reduced motion despite its own doc

- **Commit:** `8204fd8`
- **Severity:** MEDIUM
- **Category:** Accessibility
- **File:** `lib/core/widgets/empty_state.dart`
- **Status:** DONE

## The finding

The class doc claimed:

> Still transform + opacity only, still under 300ms, and still gone entirely
> under reduced motion.

The last clause was false. There was no `AppMotion.reduced` check and no
`AppMotion.duration` wrapper anywhere in the file — the controller ran
`..forward()` unconditionally and `build` always returned
`FadeTransition(SlideTransition(...))`.

This is the highest-leverage accessibility finding in the app because
`EmptyState` is not one screen: it is the permission-denied screen, the error
screen, the empty library, the empty folder, the no-favourites state and the
search intro.

## The fix, and why it is not what the doc promised

The doc promised motion would be **gone entirely**. The audit playbook says
the opposite is correct:

> Reduced motion means fewer and gentler animations, **not zero** — keep
> transitions that aid comprehension, remove position changes.

Killing the fade as well would make the screen teleport in, which is a harsher
change than the movement being avoided. So:

- The **fade survives** in both branches.
- Only the `SlideTransition` is conditional on `AppMotion.reduced(context)`.

```dart
return FadeTransition(
  opacity: _in,
  child: AppMotion.reduced(context)
      ? body
      : SlideTransition(position: ..., child: body),
);
```

The doc was rewritten to describe what the code does.

## Still open — same class, other files

Seven files animate without consulting `AppMotion.reduced` or
`AppMotion.duration`. Each is a one-line change; none is bundled here because
they are separate findings on separate screens:

- `lib/features/quick_save/presentation/pages/quick_save_page.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_content_panel.dart`
- `lib/features/rules/presentation/widgets/rules_explainer.dart`
- `lib/features/rules/presentation/pages/rule_builder_sheet.dart`
- `lib/core/widgets/app_bottom_nav_bar.dart`
- `lib/core/widgets/asset_thumbnail_image.dart`
- `lib/features/screenshots/presentation/pages/library_page.dart`

## Verification

- `flutter analyze` clean.
- **Not verified on device.** MIUI refuses `adb shell settings put global
  transition_animation_scale 0` without WRITE_SECURE_SETTINGS, so the reduced
  branch could not be exercised from here. It needs either that developer
  toggle enabled or a manual check via Settings → Accessibility.
